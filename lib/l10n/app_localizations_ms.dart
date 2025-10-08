// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get appTitle => 'Aplikasi onboarding';

  @override
  String get settings => 'Tetapan';

  @override
  String get manageYourAccount => 'Urus Akaun Anda';

  @override
  String get devicePermission => 'Kebenaran Peranti';

  @override
  String get languageAndTranslations => 'Bahasa dan Terjemahan';

  @override
  String get darkMode => 'Mod Gelap';

  @override
  String get version => 'Versi';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get english => 'English';

  @override
  String get bahasaMelayu => 'Bahasa Melayu';

  @override
  String get languageChangeNote => 'Nota: Menukar bahasa akan mempengaruhi semua teks dalam aplikasi.';

  @override
  String get languageChangedToEnglish => 'Bahasa telah ditukar kepada English';

  @override
  String get languageChangedToMalay => 'Language changed to Malay';

  @override
  String get preferences => 'Keutamaan';

  @override
  String get account => 'Akaun';

  @override
  String get about => 'Tentang';

  @override
  String get somethingWentWrong => 'Sesuatu telah berlaku!';

  @override
  String get online => 'Dalam Talian';

  @override
  String get offline => 'Luar Talian';

  @override
  String get typeAMessage => 'Taip mesej...';

  @override
  String get quickReplyTimeOff => 'Tanya tentang cuti';

  @override
  String get quickReplyWifi => 'Kata laluan Wi-Fi';

  @override
  String get quickReplyPortal => 'Pautan Portal HR';

  @override
  String get quickReplyBenefits => 'Lihat faedah saya';

  @override
  String get quickReplyEmergencyContact => 'Hubungan kecemasan';

  @override
  String chatWelcomeHR(String name) {
    return 'Helo! Saya $name, rakan HR anda. Bagaimana saya boleh bantu anda dengan polisi, faedah, atau apa-apa sahaja hari ini?';
  }

  @override
  String chatWelcomeTechnical(String name) {
    return 'Hai! Saya $name dari jabatan IT. Adakah anda menghadapi sebarang isu teknikal dengan perisian, perkakasan, atau akses?';
  }

  @override
  String get chatReplyWifi => 'Kata laluan Wi-Fi untuk tetamu ialah \'TNBGuest2024\'. Jika anda perlukan akses ke rangkaian korporat, sila beritahu saya butiran peranti anda.';

  @override
  String get chatReplyTimeOff => 'Anda boleh memohon cuti melalui Portal HR. Polisi membenarkan 20 hari cuti tahunan. Adakah anda mahu pautan ke portal tersebut?';

  @override
  String get chatReplyBenefits => 'Anda boleh melihat ringkasan faedah anda, termasuk perubatan dan insurans, di portal HR di bawah bahagian \'Faedah Saya\'.';

  @override
  String get chatReplyDefault => 'Saya tidak pasti bagaimana untuk menjawabnya, tetapi saya sedang belajar! Boleh anda ulang semula, atau adakah anda mahu saya sambungkan anda kepada ejen manusia?';

  @override
  String get chatHistory => 'Sejarah Sembang';

  @override
  String get faq => 'Soalan Lazim';

  @override
  String get reportIssue => 'Laporkan Isu';
}
