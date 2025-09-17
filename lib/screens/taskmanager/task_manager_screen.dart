import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const TaskManager());
}

class TaskManager extends StatelessWidget {
  const TaskManager({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Manager UI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const DocumentManagerScreen(),
    );
  }
}

class DocumentManagerScreen extends StatelessWidget {
  const DocumentManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Task Manager',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        leading: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(224, 124, 124, 1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Required Documents Section
            Text(
              'Required Documents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Removed initialFile for Lampiran A to make it empty initially
            const DocumentCard(
              title: 'Lampiran A',
              subtitle: 'Upload the required files', // Changed subtitle to reflect empty state
              subtitleColor: Colors.grey, // Changed color to reflect empty state
            ),
            const SizedBox(height: 12),
            // 'Sijil Tanggung Diri' is now handled correctly for "In Progress"
            const DocumentCard(
              title: 'Sijil Tanggung Diri',
              subtitle: 'Upload in Progress',
            ),
            const SizedBox(height: 12),
            DocumentCard(
              title: 'Penyata Bank',
              subtitle: 'Upload the required files',
              subtitleColor: Colors.grey[600],
            ),
            const SizedBox(height: 32),
            // Private Details and Certs Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Private Details and Certs',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle View All for Private Details
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DocumentCard(
              title: 'Identity Card (IC)',
              subtitle: 'Upload Required',
              subtitleColor: Colors.red,
            ),
            const SizedBox(height: 12),
            DocumentCard(
              title: 'Driving License',
              subtitle: 'Optional',
              subtitleColor: Colors.grey[600],
            ),
            const SizedBox(height: 12),
            DocumentCard(
              title: 'Certificates',
              subtitle: 'Optional',
              subtitleColor: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
// test
class DocumentCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final String? initialFile; // Keep this for cases where a file might pre-exist

  const DocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.initialFile,
  });

  @override
  _DocumentCardState createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Initialize _selectedFileName ONLY if initialFile is provided
    if (widget.initialFile != null) {
      _selectedFileName = widget.initialFile;
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _selectedFileName = file.name; // Update selected file name
        });
        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 2));
        _showSnackbar('File "${file.name}" selected successfully!');
      } else {
        _showSnackbar('File selection canceled.');
      }
    } catch (e) {
      _showSnackbar('Error picking file: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false; // Ensure uploading state is reset
        });
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if a file is currently selected/uploaded
    final bool hasFile = _selectedFileName != null;

    // Define icon and color based on status priority: Uploading > Has File > Empty
    IconData cardIcon;
    Color cardIconColor;
    String currentSubtitle;
    Color currentSubtitleColor;

    if (_isUploading) {
      cardIcon = Icons.upload_file; // Icon for uploading
      cardIconColor = Colors.blue;
      currentSubtitle = 'Uploading...';
      currentSubtitleColor = Colors.blue[600]!;
    } else if (hasFile) {
      cardIcon = Icons.check_circle; // Icon for file uploaded
      cardIconColor = Colors.green;
      currentSubtitle = _selectedFileName!;
      currentSubtitleColor = Colors.green;
    } else {
      cardIcon = Icons.add_circle; // Icon for empty/no file
      cardIconColor = Colors.grey;
      currentSubtitle = widget.subtitle; // Use the default subtitle (e.g., "Upload the required files")
      currentSubtitleColor = widget.subtitleColor ?? Colors.grey[600]!;
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardIconColor.withOpacity(0.1),
              ),
              child: _isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(cardIconColor),
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      cardIcon,
                      color: cardIconColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: currentSubtitleColor,
                      fontStyle: hasFile ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: _isUploading ? null : _pickFile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  _isUploading
                      ? 'Uploading'
                      : (_selectedFileName != null ? 'View' : 'Upload'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}