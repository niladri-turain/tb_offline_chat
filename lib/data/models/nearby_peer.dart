import 'peer.dart';

enum PairState { notPaired, waiting, paired }

class NearbyPeer {
  const NearbyPeer({
    required this.peer,
    required this.distance,
    required this.state,
  });

  final Peer peer;
  final String distance;
  final PairState state;
}
