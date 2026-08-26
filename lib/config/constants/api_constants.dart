/// API-related constants.
abstract class ApiConstants {
    static const String _defaultBaseUrl = 'https://api.xerinmarketplace.com';
    static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

    static String get baseUrl => _resolveBaseUrl(_envBaseUrl);

    static String _resolveBaseUrl(String candidate) {
        final raw = candidate.trim();
        if (raw.isEmpty) return _defaultBaseUrl;

        final withScheme = raw.contains('://') ? raw : 'http://$raw';
        final parsed = Uri.tryParse(withScheme);
        if (parsed == null || parsed.host.isEmpty) return _defaultBaseUrl;

        return parsed.toString().replaceFirst(RegExp(r'/$'), '');
    }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String registerSeller = '/auth/register-seller';
  static const String registerBroker = '/auth/register-broker';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';

  // User endpoints
  static const String myProfile = '/users/me';

  // Address endpoints
  static const String addresses = '/addresses';
  static String addressById(String id) => '/addresses/$id';

  // Seller endpoints
  static const String sellerRegister = '/sellers/register';
  static const String sellerProfile = '/sellers/me';
  static const String sellerBusinessProfile = '/sellers/profile';
  static const String sellerKycDocuments = '/sellers/kyc-documents';
  static const String sellerKycBulkUpload = '/sellers/kyc-documents/bulk';
  static const String sellerKycStatus = '/sellers/kyc-status';
  static const String sellerPayoutAccounts = '/sellers/payout-accounts';
  static String sellerPayoutAccountById(String id) =>
      '/sellers/payout-accounts/$id';
  static String sellerKycDocumentById(String id) => '/sellers/kyc-documents/$id';
  static String sellerKycDocumentViewUrl(String id) => '/sellers/kyc-documents/$id/view';
  static const String sellerDashboard = '/seller/dashboard';
  static const String sellerPricingPreview = '/seller/pricing/preview';
  static const String businessCategories = '/admin/business-categories';

  // Seller admin endpoints
  static const String adminPendingSellers = '/sellers/admin/pending';
  static String adminSellerDocuments(String sellerId) =>
      '/sellers/admin/$sellerId/documents';
  static String adminApproveSeller(String sellerId) =>
      '/sellers/admin/$sellerId/approve';
  static String adminRejectSeller(String sellerId) =>
      '/sellers/admin/$sellerId/reject';

  // Admin endpoints
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static const String adminCreateAdmin = '/admin/admins';
  static const String adminBusinessCategories = '/admin/business-categories';
  static String adminBusinessCategoryById(String id) =>
      '/admin/business-categories/$id';
  static const String adminProductCategories = '/admin/product-categories';
  static String adminProductCategoryById(String id) =>
      '/admin/product-categories/$id';
  static const String adminBrands = '/admin/brands';
  static String adminBrandById(String id) => '/admin/brands/$id';
  static const String adminSellers = '/admin/sellers';
  static const String adminSellersPending = '/admin/sellers/pending';
  static String adminSellerById(String id) => '/admin/sellers/$id';
  static String adminSellerDocs(String id) => '/admin/sellers/$id/documents';
  static String adminApproveSellerById(String id) =>
      '/admin/sellers/$id/approve';
  static String adminRejectSellerById(String id) =>
      '/admin/sellers/$id/reject';
  static String adminStartSellerReview(String id) =>
      '/admin/sellers/$id/start-review';
  static const String adminPermissions = '/admin/permissions';
  static String adminUserPermissions(String userId) =>
      '/admin/users/$userId/permissions';
  static const String adminRoles = '/admin/roles';
  static String adminRolePermissions(String roleId) =>
      '/admin/roles/$roleId/permissions';
  static const String adminProductsPending = '/admin/products/pending';
  static String adminApproveProduct(String id) =>
      '/admin/products/$id/approve';
  static String adminRejectProduct(String id) =>
      '/admin/products/$id/reject';

  // Store endpoints (used by seller datasource)
  static const String myStore = '/stores/me';
  static const String myStoreLogo = '/stores/me/logo';
  static const String myStoreBanner = '/stores/me/banner';
  static const String myStoreGallery = '/stores/me/gallery';
  static String myStoreGalleryImageById(String id) => '/stores/me/gallery/$id';
  static const String myStoreOpeningHours = '/stores/me/opening-hours';
  static String myStoreOpeningHourById(String id) =>
      '/stores/me/opening-hours/$id';
  static const String publicStores = '/stores';
  static String publicStoreBySlug(String slug) => '/stores/$slug';

  // Inventory endpoints (used by seller datasource)
  static const String inventory = '/inventory';
  static const String myInventory = '/inventory/my-inventory';
  static const String lowStockInventory = '/inventory/low-stock';
  static String inventoryByProduct(String productId) =>
      '/inventory/product/$productId';
  static String inventoryById(String id) => '/inventory/$id';

  // Product endpoints
  static const String products = '/products';
  static const String myProducts = '/products/my-products';
  static const String productCategories = '/products/categories';
  static const String productBrands = '/products/brands';
  static String productById(String id) => '/products/$id';
  static String productImages(String id) => '/products/$id/images';
  static String productImageById(String productId, String imageId) =>
      '/products/$productId/images/$imageId';
  static String productVariants(String id) => '/products/$id/variants';
  static String productVariantById(String productId, String variantId) =>
      '/products/$productId/variants/$variantId';
  static String productTags(String id) => '/products/$id/tags';
  static String productTagById(String productId, String tagId) =>
      '/products/$productId/tags/$tagId';
  static String categoryById(String id) => '/products/categories/$id';
  static String brandById(String id) => '/products/brands/$id';

  // Cart endpoints
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItemById(String id) => '/cart/items/$id';
  static const String cartApplyCoupon = '/cart/apply-coupon';
  static const String cartRemoveCoupon = '/cart/coupon';
  static const String cartAvailablePromotions = '/cart/promotions/available';
  static const String cartApplyPromotion = '/cart/apply-promotion';
  static const String cartRemovePromotion = '/cart/promotion';
  static const String cartValidate = '/cart/validate';
  static const String cartMerge = '/cart/merge';

  // Order endpoints
  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  static String orderCustomerDetail(String id) => '/orders/$id/customer-detail';
  static String orderEscrow(String id) => '/orders/$id/escrow';
  static String orderApproveReceipt(String id) => '/orders/$id/approve-receipt';
  static String orderWorkflow(String id) => '/orders/$id/workflow';
  static String orderWorkflowReconcile(String id) => '/orders/$id/workflow/reconcile';
  static String orderInvoice(String id) => '/orders/$id/invoice.pdf';
  static String orderReceipt(String id) => '/orders/$id/receipt.pdf';
  static String orderRef(String orderNumber) => '/orders/ref/$orderNumber';

  // Payment endpoints
  static const String paymentsInitiate = '/payments/initiate';
  static const String paymentsCallback = '/payments/callback';
  static const String paymentsMyPayments = '/payments/my-payments';
  static String paymentById(String id) => '/payments/$id';
  static String paymentRetry(String id) => '/payments/$id/retry';
  static String paymentVerifyStatus(String id) => '/payments/$id/verify-status';
  static String paymentOrderState(String orderId) => '/payments/orders/$orderId/state';
  static String paymentCallbackByProvider(String provider) =>
      '/payments/callback/$provider';

  // Payment method endpoints
  static const String paymentMethods = '/payment-methods';
  static String paymentMethodById(String id) => '/payment-methods/$id';

  // Coupon endpoints
  static const String coupons = '/coupons';
  static String couponById(String id) => '/coupons/$id';
  static String couponValidate(String code) => '/coupons/validate/$code';

  // Recommendation endpoints
  static const String recommendedProducts = '/recommendations';
  static const String recentlyViewed = '/recommendations/recently-viewed';
  static const String relatedProducts = '/products/related';
  static String relatedByProduct(String productId) =>
      '/products/$productId/related';
  // Discovery feeds that don't have dedicated endpoints use /products
  static const String trendingProducts = '/products';
  static const String flashDeals = '/products';
  static const String newArrivals = '/products';
  static const String topRated = '/products';
  static const String bestSellers = '/products';

  // Store endpoints (public browsing)
  static String storeProducts(String slug) => '/stores/$slug/products';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String notificationsSummary = '/notifications/summary';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';
  static const String notificationPreferences = '/notifications/preferences';
  static const String notificationDeviceTokens = '/notifications/device-tokens';
  static String notificationDeviceTokenById(String id) => '/notifications/device-tokens/$id';
  static const String adminNotificationTemplates = '/admin/notification-templates';
  static String adminNotificationTemplateById(String id) => '/admin/notification-templates/$id';

  // Wishlist endpoints (prefix /wishlist)
  static const String wishlistProducts = '/wishlist/products';
  static String wishlistAddProduct(String productId) => '/wishlist/products/$productId';
  static String wishlistRemoveProduct(String productId) => '/wishlist/products/$productId';
  static const String wishlistStores = '/wishlist/stores';
  static String wishlistAddStore(String slug) => '/wishlist/stores/$slug';
  static String wishlistRemoveStore(String slug) => '/wishlist/stores/$slug';
  static const String wishlistSummary = '/wishlist/summary';
  static const String wishlistClear = '/wishlist/clear';

  // Review endpoints
  static String productReviews(String productId) => '/products/$productId/reviews';
  static String reviewById(String reviewId) => '/reviews/$reviewId';
  static String storeReviews(String slug) => '/stores/$slug/reviews';
  static const String sellerReviews = '/seller/reviews';
  static String sellerReviewReply(String reviewId) => '/seller/reviews/$reviewId/reply';
  static String sellerReviewReport(String reviewId) => '/seller/reviews/$reviewId/report';
  static const String adminReviews = '/admin/reviews';
  static String adminReviewModerate(String reviewId) => '/admin/reviews/$reviewId/moderate';

  // Product Q&A endpoints
  static String productQuestions(String productId) => '/products/$productId/questions';
  static String questionById(String questionId) => '/questions/$questionId';
  static String questionAnswers(String questionId) => '/questions/$questionId/answers';
  static String answerById(String answerId) => '/answers/$answerId';
  static String questionHelpful(String questionId) => '/questions/$questionId/helpful';
  static String answerHelpful(String answerId) => '/answers/$answerId/helpful';
  static String questionReport(String questionId) => '/questions/$questionId/report';
  static const String sellerQuestions = '/seller/questions';
  static String sellerAnswerQuestion(String questionId) => '/seller/questions/$questionId/answer';
  static const String adminQuestions = '/admin/questions';
  static String adminQuestionModerate(String questionId) => '/admin/questions/$questionId/moderate';

  // Promotion endpoints
  static const String promotionsAvailable = '/promotions/available';
  static const String promotionsApply = '/promotions/apply';
  static const String sellerPromotions = '/seller/promotions';
  static String sellerPromotionById(String promotionId) => '/seller/promotions/$promotionId';
  static const String campaigns = '/campaigns';
  static const String adminCampaigns = '/admin/campaigns';

  // Search & Recommendation endpoints
  static const String searchProducts = '/search/products';
  static const String searchSuggestions = '/search/suggestions';
  static const String searchTrending = '/search/trending';
  static String productView(String productId) => '/products/$productId/view';
  static String relatedProductsBySearch(String productId) => '/products/$productId/related';
  static const String recommendations = '/recommendations';
  static const String recommendationsRecentlyViewed = '/recommendations/recently-viewed';
  static const String sellerSearchAnalytics = '/seller/search-analytics';
  static const String sellerProductPerformance = '/seller/product-performance';

  // Seller Storefront endpoints
  static const String sellerStore = '/seller/store';
  static const String sellerStoreLogo = '/seller/store/logo';
  static const String sellerStoreBanner = '/seller/store/banner';
  static String storeProductsBySlug(String slug) => '/stores/$slug/products';
  static String storeCategoriesBySlug(String slug) => '/stores/$slug/categories';

  // Delivery Integration endpoints (prefix /delivery)
  static const String deliveryQuote = '/delivery/quote';
  static String deliveryBySellerOrder(String sellerOrderId) => '/delivery/seller-orders/$sellerOrderId';
  static String deliveryRequest(String sellerOrderId) => '/delivery/seller-orders/$sellerOrderId/request';

  // Seller Orders endpoints (prefix /seller/orders)
  static const String sellerOrdersSummary = '/seller/orders/summary';
  static const String sellerOrders = '/seller/orders';
  static String sellerOrderById(String id) => '/seller/orders/$id';
  static String sellerOrderAccept(String id) => '/seller/orders/$id/accept';
  static String sellerOrderStartProcessing(String id) => '/seller/orders/$id/start-processing';
  static String sellerOrderReadyToShip(String id) => '/seller/orders/$id/ready-to-ship';
  static String sellerOrderDispatch(String id) => '/seller/orders/$id/dispatch';
  static String sellerOrderRequestCancellation(String id) => '/seller/orders/$id/request-cancellation';
  static String sellerOrderMessages(String id) => '/seller/orders/$id/messages';
  static String sellerOrderPackage(String id) => '/seller/orders/$id/package';
  static String sellerOrderReadiness(String id) => '/seller/orders/$id/fulfillment-readiness';

  // Seller Inventory endpoints (prefix /seller/inventory)
  static const String sellerInventory = '/seller/inventory';
  static const String sellerInventorySummary = '/seller/inventory/summary';
  static const String sellerInventoryLowStock = '/seller/inventory/low-stock';
  static const String sellerInventoryHistory = '/seller/inventory/history';
  static String sellerInventoryById(String id) => '/seller/inventory/$id';
  static String sellerInventoryAdjust(String id) => '/seller/inventory/$id/adjust';
  static String sellerInventoryRestock(String id) => '/seller/inventory/$id/restock';

  // Admin Dashboard endpoints (prefix /admin/dashboard)
  static const String adminDashboardSummary = '/admin/dashboard/summary';
  static const String adminDashboardSales = '/admin/dashboard/sales';
  static const String adminDashboardOrders = '/admin/dashboard/orders';
  static const String adminDashboardSellers = '/admin/dashboard/sellers';
  static const String adminDashboardProducts = '/admin/dashboard/products';
  static const String adminDashboardCustomers = '/admin/dashboard/customers';
  static const String adminDashboardPayments = '/admin/dashboard/payments';
  static const String adminDashboardRefunds = '/admin/dashboard/refunds';
  static const String adminDashboardDelivery = '/admin/dashboard/delivery';
  static const String adminDashboardNotifications = '/admin/dashboard/notifications';
  static const String adminDashboardSearch = '/admin/dashboard/search';
  static const String adminDashboardAlerts = '/admin/dashboard/alerts';
  static String adminDashboardAlertResolve(String alertId) => '/admin/dashboard/alerts/$alertId/resolve';
  static const String adminDashboardActivityLogs = '/admin/dashboard/activity-logs';

  // Analytics endpoints
  static const String analyticsAdminOverview = '/analytics/admin/overview';
  static const String analyticsAdminSales = '/analytics/admin/sales';
  static const String analyticsAdminSellers = '/analytics/admin/sellers';
  static const String analyticsAdminProducts = '/analytics/admin/products';
  static const String analyticsAdminReconciliation = '/analytics/admin/reconciliation';
  static const String analyticsSellerOverview = '/analytics/seller/me/overview';
  static const String analyticsSellerSales = '/analytics/seller/me/sales';
  static const String analyticsSellerProducts = '/analytics/seller/me/products';

  // Wallet endpoints
  static const String myWallet = '/wallet/me';
  static const String myWalletTransactions = '/wallet/me/transactions';
  static const String myWalletPayouts = '/wallet/me/payouts';
  static const String requestPayout = '/wallet/me/payouts';
  static String cancelPayout(String payoutId) => '/wallet/me/payouts/$payoutId/cancel';
  static const String adminWallets = '/wallet/admin/wallets';
  static const String adminPayouts = '/wallet/admin/payouts';
  static String adminUpdatePayout(String payoutId) => '/wallet/admin/payouts/$payoutId';
  static String adminWalletAdjustment(String sellerId) => '/wallet/admin/wallets/$sellerId/adjustments';

  // Commission endpoints
  static const String commissionRules = '/commissions/rules';
  static String commissionRuleById(String ruleId) => '/commissions/rules/$ruleId';
  static String orderCommissions(String orderId) => '/commissions/orders/$orderId';
  static const String sellerEarningsSummary = '/commissions/seller/me/summary';

  // System settings endpoints
  static const String systemSettings = '/settings';
  static String systemSettingByKey(String key) => '/settings/$key';

  // Refund endpoints
  static const String refunds = '/refunds';
  static const String adminRefunds = '/refunds/admin';
  static String refundById(String refundId) => '/refunds/$refundId';
  static String cancelRefund(String refundId) => '/refunds/$refundId/cancel';
  static String reviewRefund(String refundId) => '/refunds/$refundId/review';
  static String approveRefund(String refundId) => '/refunds/$refundId/approve';
  static String rejectRefund(String refundId) => '/refunds/$refundId/reject';
  static String processRefund(String refundId) => '/refunds/$refundId/process';

  // Shipping endpoints
  static const String shippingZones = '/shipping/zones';
  static String shippingZoneById(String zoneId) => '/shipping/zones/$zoneId';
  static const String shippingMethods = '/shipping/methods';
  static String shippingMethodById(String methodId) => '/shipping/methods/$methodId';
  static const String shippingRates = '/shipping/rates';
  static String shippingRateById(String rateId) => '/shipping/rates/$rateId';
  static const String shippingQuote = '/shipping/quote';
  static const String shippingCheckoutConfig = '/shipping/checkout-config';
  static const String shippingDetectDeliveryMode = '/shipping/detect-delivery-mode';
  static const String shippingEligibleLogistics = '/shipping/eligible-logistics';
  static const String shippingMultiSellerPricing = '/shipping/multi-seller-pricing';
  static const String shippingCheckoutDeliveryQuote = '/shipping/checkout-delivery-quote';
  static const String myShipments = '/shipping/shipments/my';
  static const String sellerShipments = '/shipping/shipments/seller';
  static String shipmentById(String shipmentId) => '/shipping/shipments/$shipmentId';
  static String shipmentEvent(String shipmentId) => '/shipping/shipments/$shipmentId/events';
  static const String adminAllOrders = '/orders/admin/all';

  // Audit log endpoints
  static const String auditLogs = '/audit-logs';
  static String auditLogById(String auditId) => '/audit-logs/$auditId';
  static const String auditLogSecurityEvents = '/audit-logs/security/events';
  static String auditLogSecurityEventResolve(String eventId) => '/audit-logs/security/events/$eventId/resolve';

  // Broker endpoints
  static const String brokerMe = '/brokers/me';
  static const String brokerKycStatus = '/brokers/kyc-status';
  static const String brokerKycDocuments = '/brokers/kyc-documents';
  static String brokerKycDocumentById(String id) => '/brokers/kyc-documents/$id';
  static const String brokerSubmitKyc = '/brokers/submit-kyc';
  static const String brokerProducts = '/brokers/products';
  static String brokerProductById(String id) => '/brokers/products/$id';
  static String brokerProductImages(String id) => '/brokers/products/$id/images';
  static String brokerProductImageById(String productId, String imageId) =>
      '/brokers/products/$productId/images/$imageId';
  static String brokerProductPublish(String id) => '/brokers/products/$id/publish';
  static const String brokerOpportunities = '/brokers/opportunities';
  static const String brokerAcceptedOpportunities = '/brokers/accepted-opportunities';
  static String brokerAcceptOpportunity(String id) => '/brokers/opportunities/$id/accept';
  static String brokerOpportunityReferral(String id) => '/brokers/opportunities/$id/referral';
  static const String brokerCommissionSummary = '/brokers/commissions/summary';
  static const String brokerCommissions = '/brokers/commissions';
  static const String brokerWallet = '/brokers/wallet';
  static const String brokerWalletTransactions = '/brokers/wallet/transactions';
  static const String brokerPayoutAccounts = '/brokers/payout-accounts';
  static String brokerPayoutAccountById(String id) => '/brokers/payout-accounts/$id';
  static const String brokerPayouts = '/brokers/payouts';
  static String brokerPayoutCancel(String id) => '/brokers/payouts/$id/cancel';
  static const String brokerAnalyticsOverview = '/brokers/analytics/overview';
  static const String brokerAnalyticsCampaigns = '/brokers/analytics/campaigns';

  // Support ticket endpoints
  static const String supportTickets = '/support/tickets';
  static const String supportMyTickets = '/support/tickets/my';
  static String supportTicketById(String id) => '/support/tickets/$id';
  static String supportTicketMessages(String id) => '/support/tickets/$id/messages';

  // Seller Fulfillment endpoints
  static const String sellerFulfillmentSummary = '/seller/fulfillment/summary';
  static const String sellerFulfillment = '/seller/fulfillment';
  static String sellerFulfillmentById(String sellerOrderId) =>
      '/seller/fulfillment/$sellerOrderId';
  static String sellerFulfillmentTracking(String sellerOrderId) =>
      '/seller/fulfillment/$sellerOrderId/tracking';

  // Seller Pickup Locations endpoints
  static const String sellerPickupLocations = '/seller/pickup-locations';
  static String sellerPickupLocationById(String id) =>
      '/seller/pickup-locations/$id';
  static String sellerPickupLocationDefault(String id) =>
      '/seller/pickup-locations/$id/default';

  // Map Locations endpoints
  static const String mapConfig = '/locations/map/config';
  static const String mapAutocomplete = '/locations/map/autocomplete';
  static String mapPlaceDetails(String placeId) =>
      '/locations/map/places/$placeId';
  static const String mapReverseGeocode = '/locations/map/reverse-geocode';

  // Delivery Verification endpoints
  static String deliveryVerificationStart(String shipmentId) =>
      '/delivery-verification/logistics/shipments/$shipmentId/start';
  static String deliveryVerificationVerify(String proofId) =>
      '/delivery-verification/logistics/proofs/$proofId/verify';
  static const String deliveryVerificationMy = '/delivery-verification/customer/my';
  static String deliveryVerificationDispute(String proofId) =>
      '/delivery-verification/customer/proofs/$proofId/dispute';

  // Advertisement endpoints (public)
  static const String advertisementsActive = '/advertisements/active';
  static String advertisementImpression(String id) =>
      '/advertisements/$id/impression';
  static String advertisementClick(String id) => '/advertisements/$id/click';
  static String advertisementsBySlot(String placement) =>
      '/advertisements/slot/$placement';
  static const String advertisementSlots = '/advertisements/slots';

  // Admin Advertisement endpoints
  static const String adminAdvertisements = '/admin/advertisements';
  static const String adminAdvertisementUploadImage =
      '/admin/advertisements/upload-image';
  static const String adminAdvertisementAnalytics =
      '/admin/advertisements/analytics/overview';
  static String adminAdvertisementById(String id) => '/admin/advertisements/$id';
  static String adminAdvertisementActivate(String id) =>
      '/admin/advertisements/$id/activate';
  static String adminAdvertisementPause(String id) =>
      '/admin/advertisements/$id/pause';

  // Admin Finance endpoints
  static String adminFinanceOrderLifecycle(String orderId) =>
      '/admin/finance/orders/$orderId/lifecycle';
  static String adminFinanceReconciliationOrder(String orderId) =>
      '/admin/finance/reconciliation/orders/$orderId';
  static const String adminFinanceReconciliation = '/admin/finance/reconciliation';
  static String adminFinanceReconciliationEvents(String recordId) =>
      '/admin/finance/reconciliation/$recordId/events';
  static const String adminFinanceSettings = '/admin/finance/settings';
  static const String adminFinanceFxConvert = '/admin/finance/fx/convert';
  static const String adminFinanceEscrowHolds = '/admin/finance/escrow-holds';
  static String adminFinanceEscrowHoldById(String holdId) =>
      '/admin/finance/escrow-holds/$holdId';
  static String adminFinanceEscrowHoldDispute(String holdId) =>
      '/admin/finance/escrow-holds/$holdId/dispute';
  static String adminFinanceEscrowHoldRelease(String holdId) =>
      '/admin/finance/escrow-holds/$holdId/release';

  // Admin Marketplace Settings endpoints
  static const String adminMarketplaceSettings = '/admin/marketplace-settings';
  static const String adminMarketplaceCommissionRules =
      '/admin/marketplace-settings/commission-rules';
  static String adminMarketplaceCommissionRuleById(String ruleId) =>
      '/admin/marketplace-settings/commission-rules/$ruleId';
  static const String adminMarketplaceCommissionPreview =
      '/admin/marketplace-settings/commission-preview';

  // Admin Catalog endpoints
  static const String adminCatalogSummary = '/admin/catalog/summary';
  static const String adminCatalogProducts = '/admin/catalog/products';
  static const String adminCatalogProductCategories =
      '/admin/catalog/product-categories';
  static const String adminCatalogBusinessCategories =
      '/admin/catalog/business-categories';
  static const String adminCatalogBrands = '/admin/catalog/brands';

  // Admin Payments endpoints
  static const String adminPaymentsDashboard = '/admin/payments/dashboard';
  static const String adminPayments = '/admin/payments';
  static String adminPaymentById(String paymentId) => '/admin/payments/$paymentId';
  static const String adminRefundsAdmin = '/admin/refunds';
  static String adminRefundById(String refundId) => '/admin/refunds/$refundId';

  // Admin Orders endpoints
  static const String adminOrdersAll = '/orders/admin/all';
  static String adminOrderDetail(String orderId) => '/orders/$orderId';
  static String adminOrderWorkflow(String orderId) =>
      '/orders/$orderId/workflow';
  static String adminOrderStatus(String orderId) => '/orders/$orderId/status';

  // Logistics endpoints
  static const String logisticsCountryOptions = '/logistics/country-options';
  static const String logisticsCompanies = '/logistics/companies';
  static const String logisticsCompaniesOnboard = '/logistics/companies/onboard';
  static String logisticsCompanyById(String companyId) =>
      '/logistics/companies/$companyId';
  static String logisticsCompanyResendCredentials(String companyId) =>
      '/logistics/companies/$companyId/administrator/resend-credentials';
  static String logisticsCompanyUsers(String companyId) =>
      '/logistics/companies/$companyId/users';
  static String logisticsCompanyUserById(String companyId, String userId) =>
      '/logistics/companies/$companyId/users/$userId';
  static const String logisticsMeUsers = '/logistics/me/users';
  static String logisticsMeUserById(String userId) => '/logistics/me/users/$userId';
  static const String logisticsServices = '/logistics/services';
  static String logisticsServiceById(String serviceId) =>
      '/logistics/services/$serviceId';
  static const String logisticsZones = '/logistics/zones';
  static String logisticsZoneById(String zoneId) => '/logistics/zones/$zoneId';
  static const String logisticsMeZones = '/logistics/me/zones';
  static String logisticsMeZoneById(String zoneId) => '/logistics/me/zones/$zoneId';
  static const String logisticsRates = '/logistics/rates';
  static String logisticsRateById(String rateId) => '/logistics/rates/$rateId';
  static const String logisticsMePricing = '/logistics/me/pricing';
  static const String logisticsMeServices = '/logistics/me/services';
  static String logisticsMeServiceById(String serviceId) =>
      '/logistics/me/services/$serviceId';
  static const String logisticsMeRates = '/logistics/me/rates';
  static String logisticsMeRateById(String rateId) => '/logistics/me/rates/$rateId';
  static String logisticsCompanyIntegration(String companyId) =>
      '/logistics/companies/$companyId/integration';
  static const String logisticsMeIntegration = '/logistics/me/integration';
  static const String logisticsMeWebhookEvents = '/logistics/me/webhook-events';
  static const String logisticsMeDashboard = '/logistics/me/dashboard';
  static const String logisticsMeAccount = '/logistics/me/account';
  static const String logisticsMeCompany = '/logistics/me/company';
  static const String logisticsMeShipments = '/logistics/me/shipments';
  static String logisticsMeShipmentHandover(String shipmentId) =>
      '/logistics/me/shipments/$shipmentId/handover';
  static String logisticsMeShipmentArrivedForPickup(String shipmentId) =>
      '/logistics/me/shipments/$shipmentId/arrived-for-pickup';
  static String logisticsMeShipmentPickupProof(String shipmentId) =>
      '/logistics/me/shipments/$shipmentId/pickup-proof';
  static const String logisticsMeOnboarding = '/logistics/me/onboarding';
  static const String logisticsMeOnboardingSubmit =
      '/logistics/me/onboarding/submit';
  static const String logisticsMeDocuments = '/logistics/me/documents';
  static const String logisticsMeDocumentsRequirements =
      '/logistics/me/documents/requirements';
  static String logisticsMeDocumentById(String docId) =>
      '/logistics/me/documents/$docId';
  static String logisticsMeDocumentView(String docId) =>
      '/logistics/me/documents/$docId/view';

  // Logistics Wallet endpoints
  static const String logisticsWalletMe = '/logistics/wallet/me';
  static const String logisticsWalletMeTransactions =
      '/logistics/wallet/me/transactions';
  static const String logisticsWalletMePayoutAccounts =
      '/logistics/wallet/me/payout-accounts';
  static String logisticsWalletMePayoutAccountById(String accountId) =>
      '/logistics/wallet/me/payout-accounts/$accountId';
  static const String logisticsWalletMePayouts = '/logistics/wallet/me/payouts';
  static String logisticsWalletPayoutCancel(String payoutId) =>
      '/logistics/wallet/me/payouts/$payoutId/cancel';
  static String logisticsAdminPayoutAccountVerify(String accountId) =>
      '/logistics/wallet/admin/payout-accounts/$accountId/verification';
  static String logisticsAdminPayoutUpdate(String payoutId) =>
      '/logistics/wallet/admin/payouts/$payoutId';
  static String logisticsAdminWalletAdjust(String companyId) =>
      '/logistics/wallet/admin/wallets/$companyId/adjustments';

  // Broker admin endpoints
  static const String brokerAdminList = '/brokers/admin';
  static String brokerAdminById(String brokerId) => '/brokers/admin/$brokerId';
  static String brokerAdminDocuments(String brokerId) =>
      '/brokers/admin/$brokerId/documents';
  static String brokerAdminDocumentView(String brokerId, String docId) =>
      '/brokers/admin/$brokerId/documents/$docId/view';
  static String brokerAdminStartReview(String brokerId) =>
      '/brokers/admin/$brokerId/start-review';
  static String brokerAdminApprove(String brokerId) =>
      '/brokers/admin/$brokerId/approve';
  static String brokerAdminReject(String brokerId) =>
      '/brokers/admin/$brokerId/reject';
  static String brokerAdminSuspend(String brokerId) =>
      '/brokers/admin/$brokerId/suspend';
  static String brokerAdminArchiveProduct(String productId) =>
      '/brokers/admin/products/$productId/archive';
  static const String brokerAdminRiskEvents = '/brokers/admin/security/risk-events';
  static String brokerAdminRiskEventResolve(String eventId) =>
      '/brokers/admin/security/risk-events/$eventId/resolve';
  static String brokerAdminWalletFreeze(String brokerId) =>
      '/brokers/admin/$brokerId/security/wallet-freeze';
  static const String brokerAdminPayoutAccounts = '/brokers/admin/payout-accounts';
  static String brokerAdminPayoutAccountVerify(String accountId) =>
      '/brokers/admin/payout-accounts/$accountId/verification';
  static const String brokerAdminPayouts = '/brokers/admin/payouts';
  static String brokerAdminPayoutUpdate(String payoutId) =>
      '/brokers/admin/payouts/$payoutId';
  static const String brokerReferralClick = '/brokers/referrals';

  // Seller admin document endpoints
  static String adminSellerDocumentView(String docId) =>
      '/sellers/admin/documents/$docId/view';
  static String adminSellerDocumentDownload(String docId) =>
      '/sellers/admin/documents/$docId/download';

  // Seller apply endpoint
  static const String sellerApply = '/sellers/apply';
  static const String sellerApplicationStatus = '/sellers/application-status';

  // Common headers
  static const String contentType = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';

  /// Resolves a relative image path to a full URL using the API base URL.
  /// If [path] is already a full URL (starts with http), it is returned as-is.
  /// If [path] is null or empty, null is returned.
  static String? resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '$baseUrl$trimmed';
  }
}
