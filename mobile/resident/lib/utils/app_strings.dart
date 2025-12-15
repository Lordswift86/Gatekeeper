/// Localization strings for the GateKeeper app
/// Usage: AppStrings.current.welcomeBack
/// To add a new language, create a new class extending LocalizedStrings

abstract class LocalizedStrings {
  String get appName;
  String get welcomeBack;
  String get login;
  String get logout;
  String get email;
  String get password;
  String get forgotPassword;
  String get register;
  String get dashboard;
  String get passes;
  String get payments;
  String get history;
  String get settings;
  String get createPass;
  String get guestName;
  String get passType;
  String get oneTimePass;
  String get recurringPass;
  String get deliveryPass;
  String get payNow;
  String get paid;
  String get unpaid;
  String get totalOutstanding;
  String get noOutstandingBills;
  String get error;
  String get success;
  String get cancel;
  String get confirm;
  String get loading;
  String get retry;
  String get offline;
  String get online;
}

class EnglishStrings implements LocalizedStrings {
  @override String get appName => 'GateKeeper';
  @override String get welcomeBack => 'Welcome Back';
  @override String get login => 'Login';
  @override String get logout => 'Logout';
  @override String get email => 'Email';
  @override String get password => 'Password';
  @override String get forgotPassword => 'Forgot Password?';
  @override String get register => 'Register';
  @override String get dashboard => 'Dashboard';
  @override String get passes => 'Passes';
  @override String get payments => 'Payments';
  @override String get history => 'History';
  @override String get settings => 'Settings';
  @override String get createPass => 'Create Pass';
  @override String get guestName => 'Guest Name';
  @override String get passType => 'Pass Type';
  @override String get oneTimePass => 'One-Time';
  @override String get recurringPass => 'Recurring';
  @override String get deliveryPass => 'Delivery';
  @override String get payNow => 'Pay Now';
  @override String get paid => 'Paid';
  @override String get unpaid => 'Unpaid';
  @override String get totalOutstanding => 'Total Outstanding';
  @override String get noOutstandingBills => 'No outstanding bills';
  @override String get error => 'Error';
  @override String get success => 'Success';
  @override String get cancel => 'Cancel';
  @override String get confirm => 'Confirm';
  @override String get loading => 'Loading...';
  @override String get retry => 'Retry';
  @override String get offline => 'Offline';
  @override String get online => 'Online';
}

// Add more languages as needed
class FrenchStrings implements LocalizedStrings {
  @override String get appName => 'GateKeeper';
  @override String get welcomeBack => 'Bienvenue';
  @override String get login => 'Connexion';
  @override String get logout => 'Déconnexion';
  @override String get email => 'E-mail';
  @override String get password => 'Mot de passe';
  @override String get forgotPassword => 'Mot de passe oublié?';
  @override String get register => 'S\'inscrire';
  @override String get dashboard => 'Tableau de bord';
  @override String get passes => 'Laissez-passer';
  @override String get payments => 'Paiements';
  @override String get history => 'Historique';
  @override String get settings => 'Paramètres';
  @override String get createPass => 'Créer un pass';
  @override String get guestName => 'Nom de l\'invité';
  @override String get passType => 'Type de pass';
  @override String get oneTimePass => 'Usage unique';
  @override String get recurringPass => 'Récurrent';
  @override String get deliveryPass => 'Livraison';
  @override String get payNow => 'Payer maintenant';
  @override String get paid => 'Payé';
  @override String get unpaid => 'Non payé';
  @override String get totalOutstanding => 'Total dû';
  @override String get noOutstandingBills => 'Aucune facture impayée';
  @override String get error => 'Erreur';
  @override String get success => 'Succès';
  @override String get cancel => 'Annuler';
  @override String get confirm => 'Confirmer';
  @override String get loading => 'Chargement...';
  @override String get retry => 'Réessayer';
  @override String get offline => 'Hors ligne';
  @override String get online => 'En ligne';
}

/// App strings manager
class AppStrings {
  static LocalizedStrings _current = EnglishStrings();
  
  static LocalizedStrings get current => _current;
  
  static void setLanguage(String languageCode) {
    switch (languageCode) {
      case 'fr':
        _current = FrenchStrings();
        break;
      default:
        _current = EnglishStrings();
    }
  }
  
  static List<String> get supportedLanguages => ['en', 'fr'];
}
