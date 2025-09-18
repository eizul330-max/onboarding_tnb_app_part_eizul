import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';

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

// Service class for managing file and folder data
class FileManagerService {
  final Dio _dio = Dio();
  // TODO: Replace with your actual API base URL
  final String _baseUrl = 'https://your-api-url.com/api';

  // Placeholder data for demonstration
  List<FileItem> _rootFolders = []; // The list is now empty

  Future<List<FileItem>> getFoldersAndFiles({String? folderName}) async {
    // TODO: Replace with your API GET request using Dio
    // Example:
    // final response = await _dio.get('$_baseUrl/files', queryParameters: {'folder': folderName});
    // return response.data.map((json) => ...).toList();
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    if (folderName == null) {
      return _rootFolders;
    } else {
      final folder = _rootFolders.firstWhere((f) => f.name == folderName && f is Folder) as Folder;
      return folder.children;
    }
  }

  Future<Folder> createFolder(String name) async {
    // TODO: Replace with your API POST request using Dio
    // Example:
    // final response = await _dio.post('$_baseUrl/folders', data: {'name': name});
    // return Folder.fromJson(response.data);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final newFolder = Folder(name: name, children: []);
    _rootFolders.add(newFolder);
    return newFolder;
  }

  Future<void> deleteFolder(Folder folder) async {
    // TODO: Replace with your API DELETE request using Dio
    // Example:
    // await _dio.delete('$_baseUrl/folders/${folder.id}');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    _rootFolders.remove(folder);
  }

  Future<Document> addFileToFolder(Folder parent, PlatformFile file) async {
    // TODO: Replace with your API POST request for file upload using Dio
    // Example:
    // final formData = FormData.fromMap({'file': await MultipartFile.fromFile(file.path!)});
    // final response = await _dio.post('$_baseUrl/folders/${parent.id}/files', data: formData);
    // return Document.fromJson(response.data);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    final newFile = Document(name: file.name!, path: file.path!, status: DocumentStatus.uploaded);
    parent.children.add(newFile);
    return newFile;
  }

  Future<void> removeFile(Document file) async {
    // TODO: Replace with your API DELETE request for file
    // Example:
    // await _dio.delete('$_baseUrl/files/${file.id}');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
  }

  Future<void> editFile(Document file, PlatformFile newFile) async {
    // TODO: Replace with your API PUT request for file
    // Example:
    // final formData = FormData.fromMap({'file': await MultipartFile.fromFile(newFile.path!)});
    // await _dio.put('$_baseUrl/files/${file.id}', data: formData);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
  }

  void sortFolders() {
    _rootFolders.sort((a, b) => a.name.compareTo(b.name));
  }
}

// NOTE: This class name was changed from DocumentManagerScreen
class DocumentManagerScreen extends StatefulWidget {
  const DocumentManagerScreen({super.key});

  @override
  State<DocumentManagerScreen> createState() => _DocumentManagerScreenState();
}

class _DocumentManagerScreenState extends State<DocumentManagerScreen> {
  final FileManagerService _fileManagerService = FileManagerService();
  String _currentPath = 'Home';
  Folder? _currentParentFolder;

  void _navigateToFolder(Folder folder) {
    setState(() {
      _currentParentFolder = folder;
      _currentPath = folder.name;
    });
  }

  void _goBack() {
    setState(() {
      _currentParentFolder = null;
      _currentPath = 'Home';
    });
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
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _fileManagerService.createFolder(controller.text);
                  setState(() {}); // Trigger a rebuild to refresh the UI
                  _showSnackbar('Folder "${controller.text}" created.');
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
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && _currentParentFolder != null) {
      final platformFile = result.files.first;
      await _fileManagerService.addFileToFolder(_currentParentFolder!, platformFile);
      setState(() {}); // Trigger a rebuild to refresh the UI
      _showSnackbar('File "${platformFile.name}" added successfully!');
    }
  }

  void _openFile(Document doc) async {
    if (doc.path.isNotEmpty) {
      await OpenFilex.open(doc.path);
    }
  }

  void _removeFile(Document doc) async {
    // This is the new line that fixes the issue
    _currentParentFolder?.children.remove(doc);

    // This line is for API calls, which is currently a placeholder
    await _fileManagerService.removeFile(doc);

    setState(() {}); // Trigger a rebuild to refresh the UI
    _showSnackbar('File removed successfully!');
  }

  void _deleteFolder(Folder folder) async {
    await _fileManagerService.deleteFolder(folder);
    setState(() {}); // Trigger a rebuild to refresh the UI
    _showSnackbar('Folder "${folder.name}" deleted.');
  }

  void _editFile(Document doc) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final newFile = result.files.first;
      await _fileManagerService.editFile(doc, newFile);
      setState(() {}); // Trigger a rebuild to refresh the UI
      _showSnackbar('File "${doc.name}" updated successfully!');
    }
  }

  void _sortFolders() {
    _fileManagerService.sortFolders();
    setState(() {}); // Trigger a rebuild to refresh the UI
    _showSnackbar('Folders sorted alphabetically.');
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
              leading: const Icon(Icons.drive_file_move_outlined),
              title: const Text('Move'),
              onTap: () {
                Navigator.pop(context);
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
            ? null
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
      body: FutureBuilder<List<FileItem>>(
        future: _fileManagerService.getFoldersAndFiles(folderName: _currentParentFolder?.name),
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
                  return FolderCard(
                    folder: item,
                    onTap: () => _navigateToFolder(item),
                    onMenuTap: () => _showFolderContextMenu(item),
                  );
                } else if (item is Document) {
                  return DocumentCard(
                    document: item,
                    onTap: () {
                      if (item.status == DocumentStatus.uploaded) {
                        _openFile(item);
                      } else {
                        _editFile(item);
                      }
                    },
                    onMenuTap: () => _showFileContextMenu(item),
                  );
                }
                return Container();
              },
            );
          }
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
        subtitle: Text('${folder.children.length} items'),
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
        title: Text(
          document.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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