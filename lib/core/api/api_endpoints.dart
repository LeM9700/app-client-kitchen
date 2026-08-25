/// Constantes des endpoints de l'API api-pizza.
/// Jamais d'URL construites à la main dans les repositories.
abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────────
  // [🔒 CORRECTIF] `/auth/register` crée un TENANT (RegisterRequest exige
  // tenant_slug + tenant_name) — c'est l'inscription d'un restaurant, pas d'un
  // client. L'inscription client passe par `/customer/register`
  // (CustomerRegisterRequest : email, password, full_name requis, phone
  // optionnel). `/auth/login` reste partagé entre tous les rôles mais exige
  // `tenant_slug` dans le BODY (pas seulement le header X-Tenant-Slug).
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';
  static const String sessions = '/auth/sessions';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Client (customer) ────────────────────────────────────────────────────
  // TokenResponse (access_token, refresh_token, session_id) — ne contient
  // JAMAIS d'objet `user` imbriqué, ni au login ni au register. Le profil
  // doit être récupéré séparément via `customerMe`.
  static const String customerRegister = '/customer/register';
  static const String customerMe = '/customer/me';

  // ── Tenant ────────────────────────────────────────────────────────────────
  static const String tenantBranding = '/tenant/branding';

  // ── Catalogue ─────────────────────────────────────────────────────────────
  static const String products = '/catalog/products';
  static const String categories = '/catalog/categories';
  static const String catalogSearch = '/catalog/search';
  static const String featuredProducts = '/catalog/products/featured';

  /// Produits d'une catégorie : `GET /catalog/categories/{id}/products`
  static String productsByCategory(int categoryId) =>
      '/catalog/categories/$categoryId/products';

  /// Détail d'un produit : `GET /catalog/products/{id}`
  static String product(int productId) => '/catalog/products/$productId';

  // ── Commandes ─────────────────────────────────────────────────────────────
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';

  /// Détail d'une commande : `GET /orders/{id}` (Plan 14 : refetch après
  /// notification WS / polling de secours ; Plan 15 : écran de reçu).
  static String orderDetail(int orderId) => '/orders/$orderId';

  /// Recommander : `POST /orders/{id}/reorder` (Plan 15).
  /// [🔒 CORRECTIF api-corrections-phase-d.md §5] L'id est dans le CHEMIN,
  /// pas dans le body — `reorder = '/orders/reorder'` (constante statique)
  /// était l'hypothèse erronée du plan d'origine.
  static String reorder(int orderId) => '/orders/$orderId/reorder';

  // ── Notifications / temps réel (Plan 14) ─────────────────────────────────
  // [🔒 CORRECTIF api-corrections-phase-d.md §4] Canal générique par user, pas
  // par commande — il n'existe PAS de route `/ws/orders/{id}`.
  static const String wsNotifications = '/ws/notifications';
  static const String notificationsDevices = '/notifications/devices';

  // ── Paiement ──────────────────────────────────────────────────────────────
  static const String paymentIntent = '/payments/intent';
  static const String paymentConfirm = '/payments/confirm';
  static const String localTestPaymentConfirm = '/payments/local-test/confirm';

  // ── Livraison ─────────────────────────────────────────────────────────────
  static const String deliveryCheck = '/delivery/check';

  // ── Promotions & Fidélité ─────────────────────────────────────────────────
  static const String promotions = '/promotions';
  static const String promotionsValidate = '/promotions/validate';

  /// [🔒 CORRECTIF api-corrections-phase-d.md §6] Solde : `GET /loyalty/me`,
  /// PAS `/loyalty/account` (hypothèse erronée du plan d'origine, aucune
  /// route de ce nom n'existe côté serveur).
  static const String loyaltyAccount = '/loyalty/me';

  /// `GET /loyalty/transactions?page=&limit=&type=` — pagination par `limit`
  /// (pas `page_size`), sans champ `pages` (voir api-corrections-phase-d.md
  /// §6, `LoyaltyTransactionPage`).
  static const String loyaltyTransactions = '/loyalty/transactions';

  /// `GET /loyalty/preview?order_total=` — aperçu des points qu'une commande
  /// va générer (Plan 09, cart/promo_repository.dart). Concept DIFFÉRENT du
  /// solde de compte / catalogue de récompenses (Plan 16) — ne pas confondre.
  static const String loyaltyPreview = '/loyalty/preview';

  /// `GET /loyalty/rewards` — authentifié (passe par [ApiClient], le token
  /// est déjà attaché par défaut).
  static const String loyaltyRewards = '/loyalty/rewards';

  /// `POST /loyalty/rewards/{reward_id}/redeem` — l'id est dans le CHEMIN,
  /// PAS `POST /loyalty/redeem {reward_id}` (hypothèse erronée du plan
  /// d'origine ; ce dernier endpoint existe bien côté serveur mais échange
  /// des points bruts hors catalogue, hors scope de cet écran — voir
  /// api-corrections-phase-d.md §6).
  static String loyaltyRedeem(int rewardId) =>
      '/loyalty/rewards/$rewardId/redeem';
}
