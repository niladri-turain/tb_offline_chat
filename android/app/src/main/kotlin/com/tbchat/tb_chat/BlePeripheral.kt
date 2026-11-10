package com.tbchat.tb_chat

import android.annotation.SuppressLint
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothGattServer
import android.bluetooth.BluetoothGattServerCallback
import android.bluetooth.BluetoothGattService
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * The BLE advertiser and GATT server that lets iPhones reach this phone; Google Nearby can't.
 * The Dart side (BleLink) owns the protocol; this only advertises, hands up writes and sends
 * notifications. It never bonds, so no system pairing prompt appears.
 */
@SuppressLint("MissingPermission")
class BlePeripheral(context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private class Outgoing(val device: BluetoothDevice, val value: ByteArray, val result: MethodChannel.Result)

    private val appContext = context.applicationContext
    private val channel = MethodChannel(messenger, "tb_chat/ble_peripheral")
    private val main = Handler(Looper.getMainLooper())
    private val manager = appContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    private var server: BluetoothGattServer? = null
    private var serviceUuid: UUID? = null
    private var rxUuid: UUID? = null
    private var tx: BluetoothGattCharacteristic? = null
    private var startResult: MethodChannel.Result? = null
    private var advertising = false
    private var shouldAdvertise = true

    private val subscribed = HashMap<String, BluetoothDevice>()
    private val maxLengths = HashMap<String, Int>()
    private val outbox = ArrayDeque<Outgoing>()
    private var sending: Outgoing? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> start(call, result)
            "stopAdvertising" -> {
                stopAdvertising()
                result.success(null)
            }
            "notify" -> {
                val device = subscribed[call.argument<String>("device")]
                val value = call.argument<ByteArray>("value")
                if (device == null || value == null) {
                    result.error("not_subscribed", "Central is gone", null)
                } else {
                    outbox.addLast(Outgoing(device, value, result))
                    pump()
                }
            }
            "disconnect" -> {
                subscribed[call.argument<String>("device")]?.let { server?.cancelConnection(it) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        if (manager.adapter?.bluetoothLeAdvertiser == null) {
            return result.error("start_failed", "This phone can't advertise over BLE", null)
        }
        shouldAdvertise = call.argument<Boolean>("advertise") ?: true
        val service = UUID.fromString(call.argument<String>("service"))
        // A new ID means a new service UUID, so the old server can't be reused.
        if (server != null && service != serviceUuid) closeServer()
        startResult = result
        if (server != null) return advertise()

        val rxId = UUID.fromString(call.argument<String>("rx"))
        val txId = UUID.fromString(call.argument<String>("tx"))
        serviceUuid = service
        rxUuid = rxId

        val opened = manager.openGattServer(appContext, callback)
            ?: return finishStart("Couldn't open the GATT server")
        server = opened
        val rx = BluetoothGattCharacteristic(
            rxId,
            BluetoothGattCharacteristic.PROPERTY_WRITE,
            BluetoothGattCharacteristic.PERMISSION_WRITE,
        )
        val notifying = BluetoothGattCharacteristic(
            txId,
            BluetoothGattCharacteristic.PROPERTY_NOTIFY,
            BluetoothGattCharacteristic.PERMISSION_READ,
        )
        notifying.addDescriptor(
            BluetoothGattDescriptor(
                CCCD,
                BluetoothGattDescriptor.PERMISSION_READ or BluetoothGattDescriptor.PERMISSION_WRITE,
            ),
        )
        tx = notifying
        val gattService = BluetoothGattService(service, BluetoothGattService.SERVICE_TYPE_PRIMARY)
        gattService.addCharacteristic(rx)
        gattService.addCharacteristic(notifying)
        opened.addService(gattService)
    }

    private fun closeServer() {
        server?.close()
        server = null
        subscribed.clear()
        maxLengths.clear()
    }

    private fun advertise() {
        // Hidden: keep the server for links this phone opens, but don't announce it.
        if (!shouldAdvertise) return finishStart(null)
        if (advertising) return finishStart(null)
        val advertiser = manager.adapter?.bluetoothLeAdvertiser ?: return finishStart("BLE advertiser is gone")
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .setTimeout(0)
            .build()
        // No device name: the ID travels in the service UUID, and the packet has no room for both.
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(ParcelUuid(serviceUuid))
            .build()
        advertiser.startAdvertising(settings, data, advertiseCallback)
    }

    private fun stopAdvertising() {
        if (!advertising) return
        advertising = false
        manager.adapter?.bluetoothLeAdvertiser?.stopAdvertising(advertiseCallback)
    }

    private fun finishStart(error: String?) {
        val result = startResult ?: return
        startResult = null
        if (error == null) result.success(null) else result.error("start_failed", error, null)
    }

    /** Sends one notification at a time; Android reports each in onNotificationSent. */
    private fun pump() {
        if (sending != null) return
        val next = outbox.removeFirstOrNull() ?: return
        val characteristic = tx
        val gatt = server
        if (characteristic == null || gatt == null) {
            next.result.error("not_subscribed", "Server is gone", null)
            return pump()
        }
        sending = next
        val queued = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            gatt.notifyCharacteristicChanged(next.device, characteristic, false, next.value) == BluetoothGatt.GATT_SUCCESS
        } else {
            @Suppress("DEPRECATION")
            characteristic.value = next.value
            @Suppress("DEPRECATION")
            gatt.notifyCharacteristicChanged(next.device, characteristic, false)
        }
        if (!queued) finishSending(false)
    }

    private fun finishSending(sent: Boolean) {
        val item = sending ?: return
        sending = null
        if (sent) item.result.success(null) else item.result.error("notify_failed", "Notification failed", null)
        pump()
    }

    private fun dropDevice(device: BluetoothDevice) {
        subscribed.remove(device.address)
        maxLengths.remove(device.address)
        outbox.filter { it.device == device }.forEach {
            it.result.error("not_subscribed", "Central is gone", null)
            outbox.remove(it)
        }
        if (sending?.device == device) finishSending(false)
        channel.invokeMethod("disconnected", mapOf("device" to device.address))
    }

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            main.post {
                advertising = true
                finishStart(null)
            }
        }

        override fun onStartFailure(errorCode: Int) {
            main.post {
                if (errorCode == ADVERTISE_FAILED_ALREADY_STARTED) {
                    advertising = true
                    finishStart(null)
                } else {
                    finishStart("Advertising failed: $errorCode")
                }
            }
        }
    }

    private val callback = object : BluetoothGattServerCallback() {
        override fun onServiceAdded(status: Int, service: BluetoothGattService) {
            main.post {
                if (status == BluetoothGatt.GATT_SUCCESS) advertise() else finishStart("Adding the service failed: $status")
            }
        }

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            if (newState == BluetoothProfile.STATE_DISCONNECTED) main.post { dropDevice(device) }
        }

        override fun onMtuChanged(device: BluetoothDevice, mtu: Int) {
            main.post {
                maxLengths[device.address] = mtu - 3
                channel.invokeMethod("mtu", mapOf("device" to device.address, "maxLength" to mtu - 3))
            }
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?,
        ) {
            if (responseNeeded) server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            main.post {
                if (value != null && value.isNotEmpty() && value[0].toInt() != 0) {
                    subscribed[device.address] = device
                    val maxLength = maxLengths[device.address] ?: 20
                    channel.invokeMethod("mtu", mapOf("device" to device.address, "maxLength" to maxLength))
                } else {
                    subscribed.remove(device.address)
                }
            }
        }

        override fun onCharacteristicWriteRequest(
            device: BluetoothDevice,
            requestId: Int,
            characteristic: BluetoothGattCharacteristic,
            preparedWrite: Boolean,
            responseNeeded: Boolean,
            offset: Int,
            value: ByteArray?,
        ) {
            if (responseNeeded) server?.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, null)
            if (characteristic.uuid != rxUuid || value == null) return
            main.post {
                channel.invokeMethod("write", mapOf("device" to device.address, "value" to value))
            }
        }

        override fun onNotificationSent(device: BluetoothDevice, status: Int) {
            main.post { finishSending(status == BluetoothGatt.GATT_SUCCESS) }
        }
    }

    private companion object {
        val CCCD: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }
}
