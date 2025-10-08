// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Onboarding App';

  @override
  String get settings => 'Settings';

  @override
  String get manageYourAccount => 'Manage Your Account';

  @override
  String get devicePermission => 'Device Permission';

  @override
  String get languageAndTranslations => 'Language and Translations';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get version => 'Version';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get bahasaMelayu => 'Bahasa Melayu';

  @override
  String get languageChangeNote => 'Note: Changing the language will affect all text in the application.';

  @override
  String get languageChangedToEnglish => 'Language changed to English';

  @override
  String get languageChangedToMalay => 'Bahasa ditukar kepada Bahasa Melayu';

  @override
  String get preferences => 'Preferences';

  @override
  String get account => 'Account';

  @override
  String get about => 'About';

  @override
  String get somethingWentWrong => 'Something went wrong!';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get typeAMessage => 'Type a message...';

  @override
  String get quickReplyTimeOff => 'Ask about time off';

  @override
  String get quickReplyWifi => 'Wi-Fi password';

  @override
  String get quickReplyPortal => 'HR Portal link';

  @override
  String get quickReplyBenefits => 'View my benefits';

  @override
  String get quickReplyEmergencyContact => 'Emergency contact';

  @override
  String chatWelcomeHR(String name) {
    return 'Hello! I\'m $name, your HR buddy. How can I assist you with policies, benefits, or anything else today?';
  }

  @override
  String chatWelcomeTechnical(String name) {
    return 'Hi there! I\'m $name from the IT department. Are you facing any technical issues with software, hardware, or access?';
  }

  @override
  String get chatReplyWifi => 'The guest Wi-Fi password is \'TNBGuest2024\'. If you need access to the corporate network, please let me know your device details.';

  @override
  String get chatReplyTimeOff => 'You can apply for time off through the HR Portal. The policy allows for 20 days of annual leave. Would you like a link to the portal?';

  @override
  String get chatReplyBenefits => 'You can view a summary of your benefits, including medical and insurance, on the HR portal under the \'My Benefits\' section.';

  @override
  String get chatReplyDefault => 'I\'m not sure how to answer that, but I\'m learning! Could you rephrase, or would you like me to connect you to a human agent?';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get faq => 'FAQ';

  @override
  String get reportIssue => 'Report an Issue';
}
