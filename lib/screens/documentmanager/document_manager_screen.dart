import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const TaskManager());
}

// Enums to manage file status more clearly
enum DocumentStatus { uploaded, pending, uploading }

// A data model for a single file
class DocumentFile {
  final String name;
  final String path;
  final DocumentStatus status;

  const DocumentFile({
    required this.name,
    required this.path,
    this.status = DocumentStatus.pending,
  });

  DocumentFile copyWith({String? name, String? path, DocumentStatus? status}) {
    return DocumentFile(
      name: name ?? this.name,
      path: path ?? this.path,
      status: status ?? this.status,
    );
  }
}

// A data model for a folder
class DocumentFolder {
  final String name;
  final List<DocumentFile> files;

  const DocumentFolder({
    required this.name,
    required this.files,
  });

  DocumentFolder copyWith({String? name, List<DocumentFile>? files}) {
    return DocumentFolder(
      name: name ?? this.name,
      files: files ?? this.files,
    );
  }
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

class DocumentManagerScreen extends StatefulWidget {
  const DocumentManagerScreen({super.key});

  @override
  State<DocumentManagerScreen> createState() => _DocumentManagerScreenState();
}

class _DocumentManagerScreenState extends State<DocumentManagerScreen> {
  final List<DocumentFolder> _documentFolders = [
    const DocumentFolder(
      name: 'Required Documents',
      files: [
        DocumentFile(
          name: 'Lampiran A',
          path: 'assets/documents/lampiran_a.pdf',
          status: DocumentStatus.uploaded,
        ),
        DocumentFile(
          name: 'Sijil Tanggung Diri',
          path: '',
          status: DocumentStatus.pending,
        ),
        DocumentFile(
          name: 'Penyata Bank',
          path: '',
          status: DocumentStatus.pending,
        ),
      ],
    ),
    const DocumentFolder(
      name: 'Private Details and Certs',
      files: [
        DocumentFile(
          name: 'Identity Card (IC)',
          path: '',
          status: DocumentStatus.pending,
        ),
        DocumentFile(
          name: 'Driving License',
          path: '',
          status: DocumentStatus.pending,
        ),
        DocumentFile(
          name: 'Certificates',
          path: '',
          status: DocumentStatus.pending,
        ),
      ],
    ),
  ];

  void _onFileAction(DocumentFile file, DocumentFolder folder) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _pickAndReplaceFile(file, folder);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove'),
              onTap: () {
                Navigator.pop(context);
                _removeFile(file, folder);
              },
            ),
          ],
        );
      },
    );
  }

  void _removeFile(DocumentFile file, DocumentFolder folder) {
    setState(() {
      final folderIndex = _documentFolders.indexOf(folder);
      final fileIndex = folder.files.indexOf(file);

      final updatedFile = file.copyWith(
        name: file.name,
        path: '',
        status: DocumentStatus.pending,
      );

      final updatedFiles = List<DocumentFile>.from(folder.files);
      updatedFiles[fileIndex] = updatedFile;

      final updatedFolder = folder.copyWith(files: updatedFiles);
      _documentFolders[folderIndex] = updatedFolder;
    });
  }

  Future<void> _pickAndReplaceFile(DocumentFile file, DocumentFolder folder) async {
    setState(() {
      final folderIndex = _documentFolders.indexOf(folder);
      final fileIndex = folder.files.indexOf(file);

      final updatedFile = file.copyWith(status: DocumentStatus.uploading);
      final updatedFiles = List<DocumentFile>.from(folder.files);
      updatedFiles[fileIndex] = updatedFile;
      _documentFolders[folderIndex] = folder.copyWith(files: updatedFiles);
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        final platformFile = result.files.first;
        final folderIndex = _documentFolders.indexOf(folder);
        final fileIndex = folder.files.indexOf(file);

        final updatedFile = DocumentFile(
          name: platformFile.name,
          path: platformFile.path!,
          status: DocumentStatus.uploaded,
        );

        final updatedFiles = List<DocumentFile>.from(folder.files);
        updatedFiles[fileIndex] = updatedFile;
        _documentFolders[folderIndex] = folder.copyWith(files: updatedFiles);
      }
    } finally {
      setState(() {
        final folderIndex = _documentFolders.indexOf(folder);
        final fileIndex = folder.files.indexOf(file);
        final updatedFile = folder.files[fileIndex].copyWith(
          status: folder.files[fileIndex].path.isNotEmpty
              ? DocumentStatus.uploaded
              : DocumentStatus.pending,
        );
        final updatedFiles = List<DocumentFile>.from(folder.files);
        updatedFiles[fileIndex] = updatedFile;
        _documentFolders[folderIndex] = folder.copyWith(files: updatedFiles);
      });
    }
  }

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
        backgroundColor: Colors.transparent,
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
          children: _documentFolders.map((folder) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(
                  folder.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
                children: folder.files.map((file) {
                  return FileCard(
                    file: file,
                    onTap: () {
                      if (file.status == DocumentStatus.uploaded) {
                        OpenFilex.open(file.path);
                      } else {
                        _pickAndReplaceFile(file, folder);
                      }
                    },
                    onLongPress: () {
                      if (file.status == DocumentStatus.uploaded) {
                        _onFileAction(file, folder);
                      }
                    },
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FileCard extends StatelessWidget {
  final DocumentFile file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileCard({
    required this.file,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUploaded = file.status == DocumentStatus.uploaded;
    final bool isUploading = file.status == DocumentStatus.uploading;

    IconData icon;
    Color iconColor;
    String subtitle;
    Color subtitleColor;

    if (isUploading) {
      icon = Icons.upload;
      iconColor = Colors.red;
      subtitle = 'Uploading...';
      subtitleColor = Colors.red;
    } else if (isUploaded) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
      subtitle = 'Uploaded';
      subtitleColor = Colors.green;
    } else {
      icon = Icons.add_circle;
      iconColor = Colors.grey;
      subtitle = file.name.contains('Optional') ? 'Optional' : 'Upload the required files';
      subtitleColor = Colors.grey;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: iconColor.withOpacity(0.1),
                ),
                child: isUploading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
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
                        color: subtitleColor,
                        fontStyle: isUploaded ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: isUploading ? null : onTap,
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
                    isUploaded ? 'View' : 'Upload',
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