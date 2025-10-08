// document_manager_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onboarding_tnb_app_part_eizul/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DocumentManagerScreen extends StatefulWidget {
  const DocumentManagerScreen({super.key});

  @override
  State<DocumentManagerScreen> createState() => _DocumentManagerScreenState();
}

class _DocumentManagerScreenState extends State<DocumentManagerScreen> {
  // Change the service to SupabaseFileService
  final SupabaseService _fileManagerService = SupabaseService();
  Future<List<dynamic>>? _filesFuture; // Keep for FutureBuilder
  
  // --- NAVIGATION IMPROVEMENT ---
  // Use a list to track the navigation path (breadcrumb)
  final List<_PathSegment> _pathHistory = [];
  String? _currentParentFolderId;

  @override
  void initState() {
    super.initState();
    _pathHistory.add(_PathSegment(id: null, name: 'Home'));
    _loadFiles(); // Initial load for the root folder.
  }

  void _loadFiles() {
    setState(() {
      _filesFuture = _fileManagerService.getFoldersAndFiles(folderId: _currentParentFolderId);
    });
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      // Add the new folder to our path history
      _pathHistory.add(_PathSegment(id: folder.id, name: folder.name));
      _currentParentFolderId = folder.id;
      _loadFiles();
    });
  }

  void _goBack() {
    if (_pathHistory.length > 1) {
      setState(() {
        // Remove the current folder from history to go up one level
        _pathHistory.removeLast();
        _currentParentFolderId = _pathHistory.last.id;
        _loadFiles();
      });
    }
  }

  void _createFolder() async {
    TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Folder Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  try {
                    Navigator.pop(context);
                    await _fileManagerService.createFolder(controller.text, parentId: _currentParentFolderId);
                    _loadFiles();
                    _showSnackbar('Folder "${controller.text}" created.');
                  } catch (e) {
                    _showSnackbar('Error creating folder: $e');
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _addFileToCurrentFolder() async {
    if (_currentParentFolderId == null) {
      _showSnackbar('Please enter a folder to add a file');
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      try {
        final platformFile = result.files.first;
        await _fileManagerService.addFileToFolder(_currentParentFolderId!, platformFile);
        _loadFiles();
        _showSnackbar('File "${platformFile.name}" added successfully!');
      } catch (e) {
        _showSnackbar('Error adding file: $e');
      }
    }
  }

  void _openFile(Document doc) async {
    try {
      final downloadUrl = await _fileManagerService.getDownloadUrl(doc);
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Could not launch URL');
      }
    } catch (e) {
      _showSnackbar('Failed to open file: $e');
    }
  }

  void _removeFile(Document doc) async {
    try {
      await _fileManagerService.removeFile(doc);
      _loadFiles();
      _showSnackbar('File removed successfully!');
    } catch (e) {
      _showSnackbar('Error removing file: $e');
    }
  }

  void _deleteFolder(Folder folder) async {
    try {
      await _fileManagerService.deleteFolder(folder.id);
      _loadFiles();
      _showSnackbar('Folder "${folder.name}" deleted.');
    } catch (e) {
      _showSnackbar('Error deleting folder: $e');
    }
  }

  void _editFile(Document doc) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      try {
        final newFile = result.files.first;
        // Note: The name of the document in the list won't change,
        // only its content is replaced.
        await _fileManagerService.editFile(doc, newFile);
        _loadFiles();
        _showSnackbar('File "${doc.name}" updated successfully!');
      } catch (e) {
        _showSnackbar('Error updating file: $e');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showFileContextMenu(Document doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editFile(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(context);
                _removeFile(doc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderContextMenu(Folder folder) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteFolder(folder);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPathSegment = _pathHistory.last;
    final bool isRoot = currentPathSegment.id == null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // --- BREADCRUMB IMPROVEMENT ---
        // Display the current path as a breadcrumb trail
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true, // Keep the current folder in view
          child: Row(
            children: _pathHistory.map((segment) {
              return Text(
                '${segment.name} ${segment == currentPathSegment ? '' : '> '}',
                style: TextStyle(fontSize: 18, fontWeight: segment == currentPathSegment ? FontWeight.bold : FontWeight.normal),
              );
            }).toList(),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: isRoot
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
      ),
      body: StreamBuilder<AuthState>(
        stream: _fileManagerService.client.auth.onAuthStateChange,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = authSnapshot.data?.session;
          if (session == null) {
            // Not authenticated, you could show a login prompt or a message
            return const Center(child: Text('Please log in to view documents.'));
          }

          return FutureBuilder<List<dynamic>>(
            future: _filesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    isRoot ? 'No folders yet.' : 'This folder is empty.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                );
              } else {
                final currentDirectory = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: currentDirectory.length,
                  itemBuilder: (context, index) {
                    final item = currentDirectory[index];
                    if (item is Folder) {
                      return FolderCard(folder: item, onTap: () => _navigateToFolder(item), onMenuTap: () => _showFolderContextMenu(item));
                    } else if (item is Document) {
                      return DocumentCard(document: item, onTap: () => _openFile(item), onMenuTap: () => _showFileContextMenu(item));
                    }
                    return Container();
                  },
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isRoot ? _createFolder : _addFileToCurrentFolder,
        child: Icon(isRoot ? Icons.create_new_folder : Icons.add),
        tooltip: isRoot ? 'Create New Folder' : 'Add New File',
      ),
    );
  }
}

// Helper class for breadcrumb navigation
class _PathSegment {
  final String? id;
  final String name;

  _PathSegment({required this.id, required this.name});
}


class FolderCard extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.folder_open, color: Colors.blue, size: 40),
        title: Text(
          folder.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMenuTap,
        ),
        onTap: onTap,
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.lightGreen,
          ),
          child: const Center(
            child: Icon(Icons.description, color: Colors.white, size: 24),
          ),
        ),
        title: Text(
          document.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'View',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMenuTap,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}