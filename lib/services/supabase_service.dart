// supabase_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


// Data models for Document and Folder
class Document {
  final String id;
  final String name;
  final String path;
  final String? folderId;
  final DateTime createdAt;

  Document({
    required this.id,
    required this.name,
    required this.path,
    this.folderId,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      folderId: json['folder_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Folder {
  final String id;
  final String name;
  final String? parentFolderId;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    this.parentFolderId,
    required this.createdAt,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      parentFolderId: json['parent_folder_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}


class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;
  final String _documentBucketName = 'documents';

  String? get _currentUserId => client.auth.currentUser?.id;

  // Get user by uid (returns null if not found)
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle(); // <-- returns null if 0 rows
      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('Failed to get user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  // Create user and return inserted row (or throw on error)
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      // Optionally check username first
      if (userData.containsKey('username') && userData['username'] != null) {
        final exists = await isUsernameExists(userData['username'] as String);
        if (exists) {
          throw Exception('Username already taken');
        }
      }

      final inserted = await client
          .from('users')
          .insert(userData)
          .select()
          .maybeSingle(); // should return the inserted row

      if (inserted == null) {
        throw Exception('Insert returned no row');
      }

      return Map<String, dynamic>.from(inserted as Map);
    } catch (e) {
      print('Failed to create user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await client.from('users').update(updates).eq('uid', uid);
    } catch (e) {
      print('Failed to update user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  Future<bool> isUsernameExists(String username) async {
    try {
      final response = await client
          .from('users')
          .select('username')
          .eq('username', username)
          .limit(1)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('Failed to check username: $e');
      throw Exception('Failed to check username: $e');
    }
  }

  // File upload operations - UPDATED FOR profile-images BUCKET
  Future<String> uploadFile(String bucket, String path, File file) async {
    try {
      final response = await client.storage.from(bucket).upload(path, file);
      return response;
    } catch (e) {
      print('Failed to upload file to bucket $bucket, path $path: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  // NEW: Upload file with overwrite option
  Future<String> uploadFileWithOverwrite(String bucket, String path, File file) async {
    try {
      final response = await client.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
      return response;
    } catch (e) {
      print('Failed to upload file with overwrite to bucket $bucket, path $path: $e');
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> getPublicUrl(String bucket, String path) async {
    try {
      return client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      print('Failed to get public URL for bucket $bucket, path $path: $e');
      throw Exception('Failed to get public URL: $e');
    }
  }

  // NEW: Check if file exists in storage
  Future<bool> fileExists(String bucket, String path) async {
    try {
      final response = await client.storage.from(bucket).list(path: path);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      print('Failed to delete file from bucket $bucket, path $path: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  // NEW: Update user profile with image
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String phoneNumber,
    String? profileImagePath,
  }) async {
    try {
      final updateData = {
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (profileImagePath != null) 'profile_image': profileImagePath,
      };

      await updateUser(uid, updateData);
    } catch (e) {
      print('Failed to update user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // NEW: Upload profile image and return the path
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${uid}_$timestamp.jpg';
      final path = 'profiles/$fileName';

      await uploadFileWithOverwrite('profile-images', path, imageFile);
      return path;
    } catch (e) {
      print('Failed to upload profile image: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // NEW: Get user profile with image URL
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
  try {
    final userData = await getUser(uid);
    if (userData == null) return null;

    // Add profile image URL if exists
    if (userData['profile_image'] != null && (userData['profile_image'] as String).isNotEmpty) {
      try {
        // getPublicUrl is asynchronous and must be awaited.
        userData['profile_image_url'] = await getPublicUrl('profile-images', userData['profile_image'] as String);
        print('🖼 Profile image URL: ${userData['profile_image_url']}');
      } catch (e) {
        print('❌ Error generating profile image URL: $e');
        userData['profile_image_url'] = null;
      }
    } else {
      print('ℹ No profile image found for user');
      userData['profile_image_url'] = null;
    }

    return userData;
  } catch (e) {
    print('❌ Failed to get user profile: $e');
    throw Exception('Failed to get user profile: $e');
  }
}

  // Projects operations
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final response = await client.from('projects').select();
      return response;
    } catch (e) {
      print('Failed to get projects: $e');
      throw Exception('Failed to get projects: $e');
    }
  }

  // Tasks operations
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await client.from('tasks').select('''
        *,
        projects (*)
      ''');
      return response;
    } catch (e) {
      print('Failed to get tasks: $e');
      throw Exception('Failed to get tasks: $e');
    }
  }

  // Learning operations
  Future<List<Map<String, dynamic>>> getLearnings() async {
    try {
      final response = await client.from('learns').select('''
        *,
        lessons (*)
      ''');
      return response;
    } catch (e) {
      print('Failed to get learnings: $e');
      throw Exception('Failed to get learnings: $e');
    }
  }

  // Progress tracking
  Future<void> updateProgress(Map<String, dynamic> progressData) async {
    try {
      await client.from('progress').upsert(progressData);
    } catch (e) {
      print('Failed to update progress: $e');
      throw Exception('Failed to update progress: $e');
    }
  }

  // Get user progress
  Future<List<Map<String, dynamic>>> getUserProgress(String userId) async {
    try {
      final response = await client
          .from('progress')
          .select('''
            *,
            lessons (*),
            learns (*)
          ''')
          .eq('userId', userId);
      return response;
    } catch (e) {
      print('Failed to get user progress: $e');
      throw Exception('Failed to get user progress: $e');
    }
  }

  // GET: Fetch files and folders for the current Supabase user
  Future<List<dynamic>> getFoldersAndFiles({String? folderId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      // Call the database function to get both folders and documents in one go.
      final response = await client.rpc(
        'get_folder_contents',
        params: {
          'p_user_id': userId, // Pass the user's ID
          'p_folder_id': folderId
        },
      );

      // The RPC returns a single list of mixed-type objects.
      // We parse them based on the 'type' field we added in the SQL function.
      final items = (response as List).map((item) {
        final json = item as Map<String, dynamic>;
        if (json['type'] == 'folder') {
          return Folder.fromJson(json);
        } else if (json['type'] == 'document') {
          return Document.fromJson(json);
        }
        return null;
      }).where((item) => item != null).toList();

      // The SQL function already sorts by name, so we can just return the list.
      return items;
    } catch (e) {
      throw Exception('Failed to load items from Supabase: $e');
    }
  }

  // POST: Create a new folder
  Future<void> createFolder(String name, {String? parentId}) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final newFolder = {
        'name': name,
        'parent_folder_id': parentId,
        'user_id': userId,
      };

      await client.from('folders').insert(newFolder);
    } catch (e) {
      throw Exception('Failed to create folder on Supabase: $e');
    }
  }

  // DELETE: Delete a folder (recursively deletes subfolders and files)
  Future<void> deleteFolder(String folderId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      // Call the RPC function to delete the folder and its contents recursively.
      // This is much more efficient than doing it on the client side.
      // Note: This assumes you have a function named `delete_folder` in your Supabase project.
      await client.rpc('delete_folder', params: {'p_folder_id': folderId});
    } catch (e) {
      // Re-throw so the UI can present an error
      throw Exception('Failed to delete folder: $e');
    }
  }

  // POST: Add a new file to a folder
  Future<void> addFileToFolder(String folderId, PlatformFile file) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      // 1. Sanitize the file name to remove illegal characters for URLs.
      final sanitizedFileName = file.name.replaceAll(RegExp(r'[#?]'), '_');

      // 2. Construct a user-scoped file path. This is crucial for RLS policies
      // on Supabase Storage, ensuring users can only access their own 'folder'.
      final filePath = '$userId/$folderId/$sanitizedFileName';

      final fileBytes = file.bytes;

      if (fileBytes == null) {
        throw Exception('File bytes are null.');
      }

      await client.storage.from(_documentBucketName).uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: false,
        ),
      );

      await client.from('documents').insert({
        'name': file.name,
        'path': filePath, // Use the new, correct filePath
        'folder_id': folderId,
        'user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to add file to folder: $e');
    }
  }

  // PUT: Edit/replace an existing file
  Future<void> editFile(Document doc, PlatformFile newFile) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final fileBytes = newFile.bytes;
      if (fileBytes == null) throw Exception('New file bytes are null.');

      // 1. Update/Replace the file in Storage using the existing path (doc.path)
      // The 'upsert: true' option handles the overwrite. This is cleaner than remove/upload.
      await client.storage.from(_documentBucketName).updateBinary(
            doc.path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 2. Optional: Update the document name/updated_at fields in Postgres
      if (doc.name != newFile.name) {
        // If the file name changed, update the metadata record
        await client.from('documents').update({
          'name': newFile.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(), // Good practice
        }).eq('id', doc.id);
      }
    } catch (e) {
      throw Exception('Failed to edit file: $e');
    } 
  }

  // DELETE: Remove a file
  Future<void> removeFile(Document doc) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      // 1. Remove file from Supabase Storage
      await client.storage.from(_documentBucketName).remove([doc.path]);

      // 2. Remove file record from database
      await client.from('documents').delete().eq('id', doc.id);
    } catch (e) {
      throw Exception('Failed to remove file from Supabase: $e');
    }
  }

  // Get a temporary signed URL for secure download
  Future<String> getDownloadUrl(Document doc) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final signedUrl =
          await client.storage.from(_documentBucketName).createSignedUrl(doc.path, 60); // URL is valid for 60 seconds
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}
