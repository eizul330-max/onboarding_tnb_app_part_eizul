// main.dart
import 'package:firebase_auth/firebase_auth.dart' as auth_user;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onboarding_tnb_app_part_eizul/firebase_options.dart';
import 'package:onboarding_tnb_app_part_eizul/l10n/app_localizations.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/auth/login_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:onboarding_tnb_app_part_eizul/providers/local_auth_provider.dart';
import 'package:onboarding_tnb_app_part_eizul/providers/locale_provider.dart';
import 'package:onboarding_tnb_app_part_eizul/services/theme_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Supabase.initialize(
      url: 'https://onboardx.jomcloud.com',
      // IMPORTANT: Replace this placeholder with your actual Supabase anon key.
      // You can find it in your Supabase project settings under API.
      anonKey: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc1OTA3MzQ2MCwiZXhwIjo0OTE0NzQ3MDYwLCJyb2xlIjoiYW5vbiJ9.uwjzLVaB3pmtadpSjahKtCRdWGbvntFpFOBCSQLMkck',
    );

    themeNotifier.value = ThemeMode.light;

    runApp(const MyApp());
  } catch (e) {
    print('!!!!!!!!!! CRASH ON STARTUP !!!!!!!!!');
    print(e);
    print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This future will represent the one-time setup of the Supabase session.
  Future<bool>? _supabaseSyncFuture;

  /// Kicks off the process to get a Supabase token from Firebase.
  /// Returns true on success, false on failure.
  Future<bool> _syncFirebaseToSupabase() async {
    final firebaseUser = auth_user.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      debugPrint('Sync failed: No Firebase user.');
      return false;
    }

    try {
      // 1. Get the Firebase ID token from the current user.
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        debugPrint('Sync failed: Could not get Firebase ID token.');
        return false;
      }

      // 2. Use the token to sign into Supabase.
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.idToken,
        idToken: idToken,
      );
      return true;
    } catch (e) {
      debugPrint('Error syncing Firebase user to Supabase: $e');
      return false;
    }
  }

  /// Clears the Supabase session and resets the sync future.
  Future<void> _clearSupabaseSession() async {
    // Reset the future when logging out
    _supabaseSyncFuture = null;
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalAuthenticationProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()..loadLocale()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, ThemeMode currentMode, _) {
          return Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              return MaterialApp(
                title: 'OnboardX TNB',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  brightness: Brightness.light,
                  primarySwatch: Colors.red,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
                  scaffoldBackgroundColor: const Color(0xFFF5F5F7),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    iconTheme: const IconThemeData(color: Colors.black),
                  ),
                  iconTheme: const IconThemeData(color: Colors.black87),
                  listTileTheme: const ListTileThemeData(
                    iconColor: Colors.black87,
                    textColor: Colors.black87,
                  ),
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  primarySwatch: Colors.red,
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                  scaffoldBackgroundColor: const Color(0xFF121212),
                  appBarTheme: AppBarTheme(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    titleTextStyle: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  listTileTheme: const ListTileThemeData(
                    iconColor: Colors.white,
                    textColor: Colors.white,
                  ),
                ),
                themeMode: currentMode,
                locale: localeProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('ms'), // Malay
                ],
                home: StreamBuilder<auth_user.User?>(
                  stream: auth_user.FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    // Show a loading indicator while waiting for the auth state
                    if (snapshot.connectionState == ConnectionState.active) {
                      if (snapshot.hasError) {
                        return Scaffold(
                          body: Center(
                            child: Text(AppLocalizations.of(context)!.somethingWentWrong),
                          ),
                        );
                      }

                      final user = snapshot.data;
                      if (user != null) {
                        // User is logged in. Start the Supabase sync if it hasn't been started.
                        final syncFuture = _supabaseSyncFuture ??= _syncFirebaseToSupabase();

                        // Use a FutureBuilder to wait for the sync to complete.
                        return FutureBuilder<bool>(
                          future: syncFuture,
                          builder: (context, futureSnapshot) {
                            if (futureSnapshot.connectionState == ConnectionState.waiting) {
                              return const Scaffold(body: Center(child: CircularProgressIndicator()));
                            }

                            // If sync was successful, go to HomeScreen.
                            if (futureSnapshot.hasData && futureSnapshot.data == true) {
                              return const HomeScreen();
                            }

                            // If sync failed, show an error and maybe a retry button.
                            return Scaffold(
                              body: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(AppLocalizations.of(context)!.failedToSync),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => setState(() => _supabaseSyncFuture = _syncFirebaseToSupabase()),
                                      child: Text(AppLocalizations.of(context)!.retry),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        // User is logged out. Clear the Supabase session and reset the future.
                        _clearSupabaseSession();
                        return const LoginScreen();
                      }
                    }

                    // Initial loading screen before Firebase auth state is resolved.
                    return const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}