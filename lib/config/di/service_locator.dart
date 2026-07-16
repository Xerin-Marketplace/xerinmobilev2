import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/customer/data/datasources/customer_remote_datasource.dart';
import '../../features/customer/data/datasources/product_remote_datasource.dart';
import '../../features/customer/data/datasources/wishlist_remote_datasource.dart';
import '../../features/customer/presentation/cubit/customer_cubit.dart';
import '../../features/customer/presentation/cubit/home_cubit.dart';
import '../../features/customer/presentation/cubit/products_cubit.dart';
import '../../features/customer/presentation/cubit/wishlist_cubit.dart';
import '../../features/seller/data/datasources/seller_remote_datasource.dart';
import '../../features/seller/presentation/cubit/seller_cubit.dart';
import '../constants/api_constants.dart';

final GetIt sl = GetIt.instance;

/// Initialize all app dependencies.
Future<void> initServiceLocator({bool reset = false}) async {
  if (reset) {
    await sl.reset();
  }

  if (sl.isRegistered<SharedPreferences>()) {
    return;
  }

  // External services
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
      ),
    ),
  );

  sl.registerLazySingleton<AppThemeCubit>(
      () => AppThemeCubit(sharedPreferences));

  sl.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': ApiConstants.contentType},
      ),
    ),
  );

  // Core
  final tokenStorage = TokenStorage(sharedPreferences, sl<FlutterSecureStorage>());
  await tokenStorage.initialize();
  sl.registerLazySingleton<TokenStorage>(() => tokenStorage);
  sl.registerLazySingleton<ApiClient>(
      () => ApiClient(sl<Dio>(), sl<TokenStorage>(), sl<Logger>()));

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(sl()));
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(
      dataSource: sl(),
      tokenStorage: sl(),
      logger: sl(),
    ),
  );

  // Customer / Products
  sl.registerLazySingleton<ProductRemoteDataSource>(
      () => ProductRemoteDataSource(sl()));
  sl.registerLazySingleton<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSource(sl()));
  sl.registerFactory<HomeCubit>(
    () => HomeCubit(
      productDataSource: sl(),
      customerDataSource: sl(),
      authDataSource: sl(),
      logger: sl(),
    ),
  );
  sl.registerFactory<ProductsCubit>(
    () => ProductsCubit(
      productDataSource: sl(),
      logger: sl(),
    ),
  );
  sl.registerLazySingleton<WishlistRemoteDataSource>(
      () => WishlistRemoteDataSource(sl()));
  sl.registerFactory<WishlistCubit>(
    () => WishlistCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );
  sl.registerFactory<CustomerCubit>(
    () => CustomerCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Seller
  sl.registerLazySingleton<SellerRemoteDataSource>(
      () => SellerRemoteDataSource(sl()));
  sl.registerFactory<SellerCubit>(
    () => SellerCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );
}
