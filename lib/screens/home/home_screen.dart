import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/buddychat/help_center_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/documentmanager/document_manager_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/learninghub/learning_hub_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/meettheteam/meet_the_team_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/myjourney/appbar_my_journey.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/myjourney/timeline_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/qrcodescanner/qr_code_scanner.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/setting/setting_screen.dart';
import 'package:onboarding_tnb_app_part_eizul/screens/taskmanager/task_manager_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  bool _isCheckingVerification = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // Jangan tampilkan dialog verifikasi di sini karena akan mengganggu auto login
    // Pemeriksaan verifikasi sebaiknya dilakukan setelah UI ditampilkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    // Jika nanti ada subscription / timer, batalkan di sini.
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted)
          return; // penting: jangan update state kalau sudah dispose
        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _checkEmailVerification() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && !user.emailVerified) {
        if (!mounted) return;
        _showVerificationDialog(context, user);
      }

      if (!mounted) return;
      setState(() {
        _isCheckingVerification = false;
      });
    } catch (e) {
      print("Error checking email verification: $e");
      if (!mounted) return;
      setState(() {
        _isCheckingVerification = false;
      });
    }
  }

  void _showVerificationDialog(BuildContext context, User user) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text(
              'Please verify your email address before using the app. '
              'Check your inbox for a verification email.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Resend Verification'),
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Colors that adapt to theme
    final primaryColor = isDarkMode
        ? const Color.fromRGBO(180, 100, 100, 1) // Darker pink for dark mode
        : const Color.fromRGBO(224, 124, 124, 1);

    // Show loading indicator while checking verification
    if (_isCheckingVerification) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeContent(userData: _userData), // Pass user data here
          const ScanQrScreen(),
          const SettingScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(primaryColor),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar(Color primaryColor) {
    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: primaryColor,
      buttonBackgroundColor: primaryColor,
      height: 60,
      items: const <Widget>[
        Icon(Icons.home, size: 30, color: Colors.white),
        Icon(Icons.qr_code_scanner, size: 30, color: Colors.white),
        Icon(Icons.settings, size: 30, color: Colors.white),
      ],
      index: _selectedIndex,
      onTap: _onItemTapped,
      letIndexChange: (index) => true,
    );
  }
}

// Home Content Widget (extracted from the original HomeScreen)
class HomeContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const HomeContent({super.key, this.userData});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  bool _isHeaderExpanded = false;
  Color? primaryColor;

  @override
  void dispose() {
    // Jika ada subscription atau timer, batalkan di sini.
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  void _toggleHeaderExpansion() {
    if (!mounted) return;
    setState(() {
      _isHeaderExpanded = !_isHeaderExpanded;
    });
  }

  // Add this function to handle URL launching
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Colors that adapt to theme
    primaryColor = isDarkMode
        ? const Color.fromRGBO(180, 100, 100, 1) // Darker pink for dark mode
        : const Color.fromRGBO(224, 124, 124, 1);

    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final hintColor = theme.hintColor;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pengguna dengan kemampuan stretch
            _buildExpandableUserHeader(primaryColor!),
            const SizedBox(height: 24),

            // Bahagian Quick Action
            _buildQuickActions(primaryColor!, cardColor, textColor),
            const SizedBox(height: 24),

            // Bahagian Berita
            _buildNewsSection(textColor),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget untuk header pengguna yang dapat di-expand
  Widget _buildExpandableUserHeader(Color primaryColor) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: _toggleHeaderExpansion,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isHeaderExpanded
            ? Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow(
                          Icons.person, widget.userData?['fullName'] ?? "Loading..."),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          Icons.email, widget.userData?['email'] ?? "Loading..."),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.phone,
                          widget.userData?['phoneNumber'] ?? "Loading..."),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.business,
                          "${widget.userData?['workUnit'] ?? "Loading"} | ${widget.userData?['workplace'] ?? "Loading"}"),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                          Icons.work, widget.userData?['workType'] ?? "Loading..."),
                      const SizedBox(height: 12),
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white,
                        size: 30,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hello,",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          Text(
                            widget.userData?['username'] ?? "Loading...",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout,
                            color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
      ),
    );
  }

  // Widget untuk baris detail (di expanded state)
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // -----------------------------
  // Quick Actions - design with 3 columns (more compact)
  // -----------------------------
  Widget _buildQuickActions(
      Color primaryColor, Color cardColor, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Action",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Kolom 1: kosong, Learning Hub, Facilities, kosong
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/Learning Hub.svg"),
                          "Learning\nHub",
                          primaryColor,
                          textColor),
                      const SizedBox(height: 20),
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/Facilities.svg"),
                          "Facilities\n",
                          primaryColor,
                          textColor),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),

                // Kolom 2: My Document, My Journey, Task Manager
                Expanded(
                  child: Column(
                    children: [
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/My Document.svg"),
                          "My\nDocument",
                          primaryColor,
                          textColor),
                      const SizedBox(height: 20),
                      _buildCenterJourneyCompact(primaryColor),
                      const SizedBox(height: 20),
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/Task Manager.svg"),
                          "Task\nManager",
                          primaryColor,
                          textColor),
                    ],
                  ),
                ),

                // Kolom 3: kosong, Meet the Team, Buddy Chat, kosong
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/Meet the Team.svg"),
                          "Meet the\nTeam",
                          primaryColor,
                          textColor),
                      const SizedBox(height: 20),
                      _buildSmallActionCompact(
                          SvgPicture.asset("assets/svgs/Buddy Chat.svg"),
                          "Buddy\nChat",
                          primaryColor,
                          textColor),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Compact small action item
  Widget _buildSmallActionCompact(
      Widget icon, String label, Color color, Color? textColor) {
    return GestureDetector(
      onTap: () {
        if (label == "Learning\nHub") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LearningHubScreen(),
            ),
          );
        }
        if (label == "My\nDocument") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DocumentManagerScreen(),
            ),
          );
        }
        if (label == "Facilities\n") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TimelineScreen(),
            ),
          );
        }
        if (label == "Task\nManager") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskManagerScreen(),
            ),
          );
        }
        if (label == "Meet the\nTeam") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeetTheTeamScreen(),
            ),
          );
        }
        if (label == "Buddy\nChat") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HelpCenterScreen(),
            ),
          );
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 50, height: 50, child: icon),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: textColor),
          ),
        ],
      ),
    );
  }

  // Compact center big circular "My Journey"
  Widget _buildCenterJourneyCompact(Color color) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppBarMyJourney()),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // This container is the large circular background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode
                  ? Colors.grey[800]
                  : const Color.fromRGBO(245, 245, 247, 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.18)
                      : Colors.white.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 0),
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // This container is the smaller, tappable, colored circle with the icon and text
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag, size: 50, color: Colors.white),
                SizedBox(height: 4),
                Text(
                  "My\nJourney",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // News section with multiple news items and external links
  // -----------------------------
  Widget _buildNewsSection(Color? textColor) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    // Sample news data - replace with your actual news data
    final List<Map<String, String>> newsItems = [
      {
        'title':
            'New App Onboard X: Cleaner, easier to use, and faster to navigate.',
        'image': 'assets/images/background_news.jpeg',
        'url': 'https://asean.bernama.com/news.php?id=2468953',
      },
      {
        'title': 'Latest Developments in Technology Sector',
        'image': 'assets/images/background_news.jpeg',
        'url': 'https://theedgemalaysia.com/node/770755',
      },
      {
        'title': 'Market Trends and Financial Updates',
        'image': 'assets/images/background_news.jpeg',
        'url': 'https://finance.yahoo.com/quote/5347.KL/news/',
      },
      // Add more news items as needed
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "News",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: newsItems.length,
            itemBuilder: (context, index) {
              final news = newsItems[index];
              return GestureDetector(
                onTap: () => _launchURL(news['url']!),
                child: Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/background_news.jpeg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black54,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          news['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}