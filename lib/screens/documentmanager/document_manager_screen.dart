import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

// Enums to manage file status
enum DocumentStatus { uploaded, pending, uploading }

// Data model for a single file or a folder
abstract class FileItem {
  final String name;
  FileItem({required this.name});
}

// Represents a single file
class Document extends FileItem {
  final String path;
  final DocumentStatus status;

  Document({
    required super.name,
    required this.path,
    this.status = DocumentStatus.pending,
  });

  Document copyWith({String? name, String? path, DocumentStatus? status}) {
    return Document(
      name: name ?? this.name,
      path: path ?? this.path,
      status: status ?? this.status,
    );
  }
}

// Represents a folder
class Folder extends FileItem {
  final List<FileItem> children;
  Folder({required super.name, required this.children});

  Folder copyWith({String? name, List<FileItem>? children}) {
    return Folder(
      name: name ?? this.name,
      children: children ?? this.children,
    );
  }
}

class DocumentManagerScreen extends StatefulWidget {
  const DocumentManagerScreen({super.key});

  @override
  State<DocumentManagerScreen> createState() => _DocumentManagerScreenState();
}

class _DocumentManagerScreenState extends State<DocumentManagerScreen> {
  List<FileItem> _rootFolders = [
    Folder(
      name: 'Required Documents',
      children: [
        Document(name: 'Lampiran A', path: 'path/to/lampiran_a.pdf', status: DocumentStatus.uploaded),
        Document(name: 'Sijil Tanggung Diri', path: '', status: DocumentStatus.pending),
        Document(name: 'Penyata Bank', path: '', status: DocumentStatus.pending),
      ],
    ),
    Folder(
      name: 'Private Details and Certs',
      children: [
        Document(name: 'Identity Card (IC)', path: '', status: DocumentStatus.pending),
        Document(name: 'Driving License', path: '', status: DocumentStatus.pending),
        Document(name: 'Certificates', path: '', status: DocumentStatus.pending),
      ],
    ),
  ];
  List<FileItem> _currentDirectory = [];
  String _currentPath = '';

  @override
  void initState() {
    super.initState();
    _currentDirectory = _rootFolders;
    _currentPath = 'Home';
  }

  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentDirectory = folder.children;
      _currentPath = folder.name;
    });
  }

  void _goBack() {
    setState(() {
      _currentDirectory = _rootFolders;
      _currentPath = 'Home';
    });
  }

  Future<void> _pickAndUploadFile(Document doc) async {
    setState(() {
      final docIndex = _currentDirectory.indexOf(doc);
      if (docIndex != -1) {
        _currentDirectory[docIndex] = doc.copyWith(status: DocumentStatus.uploading);
      }
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final platformFile = result.files.first;
        final docIndex = _currentDirectory.indexOf(doc);
        if (docIndex != -1) {
          setState(() {
            _currentDirectory[docIndex] = Document(
              name: platformFile.name!,
              path: platformFile.path!,
              status: DocumentStatus.uploaded,
            );
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          final docIndex = _currentDirectory.indexOf(doc);
          if (docIndex != -1) {
            final item = _currentDirectory[docIndex];
            if (item is Document) {
              _currentDirectory[docIndex] = item.copyWith(
                status: item.path.isNotEmpty ? DocumentStatus.uploaded : DocumentStatus.pending,
              );
            }
          }
        });
      }
    }
  }

  void _removeFile(Document doc) {
    setState(() {
      final docIndex = _currentDirectory.indexOf(doc);
      if (docIndex != -1) {
        _currentDirectory[docIndex] = doc.copyWith(path: '', status: DocumentStatus.pending);
      }
    });
    _showSnackbar('File removed successfully!');
  }

  void _openFile(Document doc) async {
    if (doc.path.isNotEmpty) {
      await OpenFilex.open(doc.path);
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
                _pickAndUploadFile(doc);
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
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
                // Implementation for moving folder
                _showSnackbar('Move functionality coming soon!');
              },
            ),
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
  
  void _deleteFolder(Folder folder) {
    setState(() {
      _rootFolders.removeWhere((item) => item is Folder && item.name == folder.name);
    });
    _showSnackbar('Folder "${folder.name}" deleted.');
  }

  void _createFolder() {
    TextEditingController controller = TextEditingController();
    showDialog(
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
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _rootFolders.add(Folder(name: controller.text, children: []));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _sortFolders() {
    setState(() {
      _rootFolders.sort((a, b) => a.name.compareTo(b.name));
    });
    _showSnackbar('Folders sorted alphabetically.');
  }

  @override
  Widget build(BuildContext context) {
    final bool isRoot = _currentPath == 'Home';
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_currentPath),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: isRoot
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              ),
        actions: [
          if (isRoot)
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'sort') {
                  _sortFolders();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'sort',
                  child: Text('Sort by Name (A-Z)'),
                ),
              ],
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _currentDirectory.length,
        itemBuilder: (context, index) {
          final item = _currentDirectory[index];
          if (item is Folder) {
            return FolderCard(
              folder: item,
              onTap: () => _navigateToFolder(item),
              onLongPress: () => _showFolderContextMenu(item),
            );
          } else if (item is Document) {
            return DocumentCard(
              document: item,
              onTap: () {
                if (item.status == DocumentStatus.uploaded) {
                  _openFile(item);
                } else {
                  _pickAndUploadFile(item);
                }
              },
              onLongPress: () => _showFileContextMenu(item),
            );
          }
          return Container();
        },
      ),
      floatingActionButton: isRoot
          ? FloatingActionButton(
              onPressed: _createFolder,
              child: const Icon(Icons.create_new_folder),
              tooltip: 'Create New Folder',
            )
          : null,
    );
  }
}

class FolderCard extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FolderCard({
    super.key,
    required this.folder,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ListTile(
          leading: const Icon(Icons.folder_open, color: Colors.blue, size: 40),
          title: Text(
            folder.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${folder.children.length} items'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String subtitle;
    String buttonText;

    switch (document.status) {
      case DocumentStatus.uploaded:
        icon = Icons.check_circle;
        iconColor = Colors.green;
        subtitle = document.name;
        buttonText = 'View';
        break;
      case DocumentStatus.uploading:
        icon = Icons.cloud_upload;
        iconColor = Colors.blue;
        subtitle = 'Uploading...';
        buttonText = 'Uploading';
        break;
      case DocumentStatus.pending:
        icon = Icons.add_circle;
        iconColor = Colors.grey;
        subtitle = document.name;
        buttonText = 'Upload';
        break;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.1),
                ),
                child: Center(
                  child: document.status == DocumentStatus.uploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        )
                      : Icon(icon, color: iconColor, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: document.status == DocumentStatus.uploading ? null : onTap,
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
                    buttonText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}