// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navExplore => 'Explore';

  @override
  String get navTournaments => 'Tournaments';

  @override
  String get navRankings => 'Rankings';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Account Login';

  @override
  String get registerTitle => 'Member Registration';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get loginButton => 'Sign In';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get registerNow => 'Sign up now';

  @override
  String get loginNow => 'Sign in';

  @override
  String get exploreWithoutLogin => 'Explore without logging in';
}
