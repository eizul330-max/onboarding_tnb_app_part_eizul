import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/buddy_card.dart';
import '../../models/buddy_model.dart'; // Import Buddy model
import 'chat_screen.dart';
import 'pre_chat_form_screen.dart';
import '../../services/supabase_service.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  // final SupabaseService _supabaseService = SupabaseService(); // Not used directly here
  late Future<List<dynamic>> _buddiesFuture;

  @override
  void initState() {
    super.initState();
    _buddiesFuture = _fetchBuddies();
  }

  Future<List<dynamic>> _fetchBuddies() async {
    return Future.value([
      Buddy(id: '1', name: 'John Doe', role: 'HR Manager', department: 'HR', imageUrl: 'https://i.pravatar.cc/150?img=1', isOnline: true, specialties: ['Benefits', 'Policies'], email: 'john.doe@example.com', phone: '123-456-7890'),
      Buddy(id: '2', name: 'Jane Smith', role: 'IT Support', department: 'IT', imageUrl: 'https://i.pravatar.cc/150?img=2', isOnline: false, specialties: ['Software', 'Hardware'], email: 'jane.smith@example.com', phone: '098-765-4321'),
      Buddy(id: '3', name: 'Alice Brown', role: 'HR Assistant', department: 'HR', imageUrl: 'https://i.pravatar.cc/150?img=3', isOnline: true, specialties: ['Recruitment', 'Onboarding'], email: 'alice.brown@example.com', phone: '111-222-3333'),
      Buddy(id: '4', name: 'Bob Johnson', role: 'Network Engineer', department: 'IT', imageUrl: 'https://i.pravatar.cc/150?img=4', isOnline: true, specialties: ['Networking', 'Security'], email: 'bob.j@example.com', phone: '444-555-6666'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support & Help Center'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
              'How can we help you today?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a support option below',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Quick Support Cards
            Row(
              children: [
                Expanded(
                  child: _buildSupportCard(
                    context,
                    icon: Icons.computer,
                    title: 'Technical Support',
                    subtitle: 'Software, hardware, access issues',
                    color: Colors.orange,
                    onTap: () => _navigateToTechSupport(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSupportCard(
                    context,
                    icon: Icons.people,
                    title: 'HR Buddy',
                    subtitle: 'Policies, benefits, culture',
                    color: Colors.green,
                    onTap: () => _navigateToHRBuddy(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Assigned Buddies Section
            const Text(
              'Your Support Buddies',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _buddiesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) { // Changed from dynamic to Buddy
                    return const Center(
                        child: Text('No support buddies available.'));
                  }

                  final List<Buddy> buddies = snapshot.data!.cast<Buddy>(); // Cast to List<Buddy>
                  return ListView.builder(
                    itemCount: buddies.length,
                    itemBuilder: (context, index) {
                      return BuddyCard(
                        buddy: buddies[index],
                        onTap: () => _navigateToChat(context, buddies[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTechSupport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreChatFormScreen(
          supportType: 'Technical Support',
          onStartChat: (issue) {
            // Handle starting chat with tech support
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  buddy: Buddy(
                    id: 'tech_bot',
                    name: 'Technical Support Bot',
                    role: 'AI Assistant',
                    department: 'IT',
                    imageUrl:
                        'https://i.pravatar.cc/150?u=techbot', // Placeholder
                    isOnline: true,
                    specialties: ['Software', 'Hardware', 'Access'],
                    email: 'tech@company.com',
                    phone: '',
                  ),
                  initialMessage: issue,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToHRBuddy(BuildContext context) async {
    final buddies = await _buddiesFuture;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreChatFormScreen(
          supportType: 'HR Support',
          onStartChat: (issue) {
            final hrBuddy = buddies.cast<Buddy>().firstWhere(
              (buddy) => buddy.department == 'HR',
              orElse: () => Buddy(
                  id: 'hr_bot',
                  name: 'HR Support Bot',
                  role: 'AI Assistant',
                  department: 'HR',
                  imageUrl: 'https://i.pravatar.cc/150?u=hrbot',
                  isOnline: true,
                  specialties: ['Policies', 'Benefits'],
                  email: 'hr@company.com',
                  phone: ''),
            );

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>
              ChatScreen(buddy: hrBuddy, initialMessage: issue),
            ));
          },
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, Buddy buddy) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(buddy: buddy),
      ),
    );
  }
}