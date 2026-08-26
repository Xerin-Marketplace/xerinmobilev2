import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_client.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/security/security_service.dart';
import '../../core/services/location_service.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme_cubit.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/customer/data/datasources/cart_remote_datasource.dart';
import '../../features/customer/data/datasources/customer_remote_datasource.dart';
import '../../features/customer/data/datasources/notification_remote_datasource.dart';
import '../../features/customer/data/datasources/payment_remote_datasource.dart';
import '../../features/customer/data/datasources/product_qa_remote_datasource.dart';
import '../../features/customer/data/datasources/product_remote_datasource.dart';
import '../../features/customer/data/datasources/promotion_remote_datasource.dart';
import '../../features/customer/data/datasources/recommendation_remote_datasource.dart';
import '../../features/customer/data/datasources/review_remote_datasource.dart';
import '../../features/customer/data/datasources/search_remote_datasource.dart';
import '../../features/customer/data/datasources/wishlist_remote_datasource.dart';
import '../../features/customer/presentation/cubit/cart_cubit.dart';
import '../../features/customer/presentation/cubit/customer_cubit.dart';
import '../../features/customer/presentation/cubit/home_cubit.dart';
import '../../features/customer/presentation/cubit/notification_cubit.dart';
import '../../features/customer/presentation/cubit/product_qa_cubit.dart';
import '../../features/customer/presentation/cubit/products_cubit.dart';
import '../../features/customer/presentation/cubit/promotion_cubit.dart';
import '../../features/customer/presentation/cubit/recommendation_cubit.dart';
import '../../features/customer/presentation/cubit/review_cubit.dart';
import '../../features/customer/presentation/cubit/search_cubit.dart';
import '../../features/customer/presentation/cubit/wishlist_cubit.dart';
import '../../features/seller/data/datasources/seller_remote_datasource.dart';
import '../../features/seller/presentation/cubit/seller_cubit.dart';
import '../../features/admin/data/datasources/admin_remote_datasource.dart';
import '../../features/admin/presentation/cubit/admin_cubit.dart';
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
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton<LocationService>(() => LocationService());

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
    () {
      final dio = Dio(
        BaseOptions(
          baseUrl: '${ApiConstants.baseUrl}/api/v1',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': ApiConstants.contentType},
        ),
      );
      // Allow self-signed certificates for development/staging servers
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient()
            ..badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
      return dio;
    },
  );

  // Core
  final tokenStorage = TokenStorage(sharedPreferences, sl<FlutterSecureStorage>());
  await tokenStorage.initialize();
  sl.registerLazySingleton<TokenStorage>(() => tokenStorage);
  sl.registerLazySingleton<ApiClient>(
      () => ApiClient(sl<Dio>(), sl<TokenStorage>(), sl<Logger>()));

  // Security
  final securityService = SecurityService(sharedPreferences, sl<FlutterSecureStorage>());
  await securityService.initialize();
  sl.registerLazySingleton<SecurityService>(() => securityService);

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
  sl.registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSource(sl()));
  sl.registerLazySingleton<PaymentRemoteDataSource>(
      () => PaymentRemoteDataSource(sl()));
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
      paymentDataSource: sl(),
      logger: sl(),
    ),
  );
  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Recommendations
  sl.registerLazySingleton<RecommendationRemoteDataSource>(
      () => RecommendationRemoteDataSource(sl(), sl()));
  sl.registerLazySingleton<RecommendationCubit>(
    () => RecommendationCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Reviews
  sl.registerLazySingleton<ReviewRemoteDataSource>(
      () => ReviewRemoteDataSource(sl()));
  sl.registerFactory<ReviewCubit>(
    () => ReviewCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Product Q&A
  sl.registerLazySingleton<ProductQaRemoteDataSource>(
      () => ProductQaRemoteDataSource(sl()));
  sl.registerFactory<ProductQaCubit>(
    () => ProductQaCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSource(sl()));
  sl.registerFactory<NotificationCubit>(
    () => NotificationCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Promotions
  sl.registerLazySingleton<PromotionRemoteDataSource>(
      () => PromotionRemoteDataSource(sl()));
  sl.registerFactory<PromotionCubit>(
    () => PromotionCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

  // Search
  sl.registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSource(sl()));
  sl.registerFactory<SearchCubit>(
    () => SearchCubit(
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

  // Admin
  sl.registerLazySingleton<AdminRemoteDataSource>(
      () => AdminRemoteDataSource(sl(), sl()));
  sl.registerFactory<AdminCubit>(
    () => AdminCubit(
      dataSource: sl(),
      logger: sl(),
    ),
  );

}
