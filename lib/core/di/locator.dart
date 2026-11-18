import 'package:get_it/get_it.dart';

import '../../data/auth.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_provider.dart';
import '../api/api_service.dart';

final locator = GetIt.instance;

/// Registers the app's services once, before runApp.
void setupLocator() {
  locator
    ..registerLazySingleton<ApiService>(() => ApiService(tokenProvider: () => Auth.loggedIn ? Auth.token : null))
    ..registerLazySingleton<AuthRepository>(() => AuthRepository(locator<ApiService>()))
    ..registerLazySingleton<AuthProvider>(() => AuthProvider(locator<AuthRepository>()));
}
