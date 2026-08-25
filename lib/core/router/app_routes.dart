/// Constantes des routes de l'application.
/// Utilisées dans [AppRouter] et dans les appels [context.go()] / [context.push()].
abstract final class AppRoutes {
  // Splash
  static const String splash = '/';

  // Catalogue (bottom nav — branche 0)
  static const String home = '/home';
  static const String search = '/home/search';
  static const String promotions = '/home/promotions';

  /// Génère le chemin vers la fiche produit : `/home/product/{id}`.
  static String productDetail(String productId) => '/home/product/$productId';

  // Panier & Checkout (bottom nav — branche 1)
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String checkoutAuth = '/checkout/auth';
  static const String payment = '/checkout/payment';
  static const String paymentSuccess = '/checkout/success';

  // Commandes (bottom nav — branche 2)
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String orderTracking = '/orders/:id/tracking';

  // Compte (bottom nav — branche 3)
  static const String account = '/account';
  static const String profileEdit = '/account/profile/edit';
  static const String changePassword = '/account/change-password';
  static const String sessions = '/account/sessions';
  static const String loyalty = '/account/loyalty';

  // Auth (hors bottom nav)
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  // Legal (public)
  static const String privacy = '/legal/privacy';
  static const String terms = '/legal/terms';
  static const String generalConditions = '/legal/conditions-generales';
  static const String cgv = '/legal/cgv';
  static const String cgu = '/legal/cgu';
}
