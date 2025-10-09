//supabase_service.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
  
  // Storage bucket names
  final String _documentBucketName = 'mydocument';
  final String _profileBucketName = 'profile-images';

  // List of supported image formats
  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'heic', 'heif'
  ];

  // Maximum file size (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  // ============ USER MANAGEMENT ============

  // Get user by uid (returns null if not found)
  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('uid', uid)
          .maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      debugPrint('❌ Failed to get user: $e');
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
          .maybeSingle();

      if (inserted == null) {
        throw Exception('Insert returned no row');
      }

      return Map<String, dynamic>.from(inserted as Map);
    } catch (e) {
      debugPrint('❌ Failed to create user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await client.from('users').update(updates).eq('uid', uid);
    } catch (e) {
      debugPrint('❌ Failed to update user: $e');
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
      debugPrint('❌ Failed to check username: $e');
      throw Exception('Failed to check username: $e');
    }
  }

  // ============ PROFILE MANAGEMENT ============

  Future<Map<String, dynamic>?> getUserProfileForApp(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return null;

      // Build camelCase map
      final Map<String, dynamic> out = {
        'uid': user['uid'],
        'fullName': user['full_name'] ?? '',
        'username': user['username'] ?? '',
        'email': user['email'] ?? '',
        'phoneNumber': user['phone_number'] ?? '',
        'workType': user['work_type'] ?? '',
        'workplace': user['workplace'] ?? '',
        'workUnit': user['work_unit'] ?? '',
      };

      // If user has team_id, fetch team by no_team
      if (user['team_id'] != null) {
        try {
          final team = await getTeamByNoTeam(user['team_id'].toString());
          if (team != null) {
            out['workUnit'] = team['work_team'] ?? out['workUnit'] ?? '';
            out['workTeam'] = team['work_team'] ?? '';
            out['workPlace'] = team['work_place'] ?? '';
            if ((out['workplace'] == null || out['workplace'].toString().isEmpty) &&
                (team['work_place'] != null)) {
              out['workplace'] = team['work_place'];
            }
          }
        } catch (e) {
          debugPrint('⚠ Failed to fetch team info for user $uid: $e');
        }
      }

      // profile image -> public url
      if (user['profile_image'] != null && (user['profile_image'] as String).isNotEmpty) {
        try {
          out['profileImageUrl'] = getPublicUrl(_profileBucketName, user['profile_image']);
        } catch (e) {
          debugPrint('⚠ Failed to generate profile image URL: $e');
        }
      }

      return out;
    } catch (e) {
      debugPrint('❌ getUserProfileForApp failed: $e');
      throw Exception('Failed to get user profile for app: $e');
    }
  }

  Future<Map<String, dynamic>?> getTeamByNoTeam(String noTeam) async {
    try {
      final response = await client
          .from('teams')
          .select()
          .eq('no_team', noTeam)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get team by no_team: $e');
      throw Exception('Failed to get team by no_team: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllTeams() async {
    try {
      final response = await client.from('teams').select().order('no_team');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get teams: $e');
      throw Exception('Failed to get teams: $e');
    }
  }

  // ============ FILE STORAGE OPERATIONS ============

  // Generic file upload
  Future<String> uploadFile(String bucket, String path, File file) async {
    try {
      debugPrint('📤 Uploading file to bucket: $bucket, path: $path');
      final response = await client.storage.from(bucket).upload(path, file);
      debugPrint('✅ File uploaded successfully: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to upload file to bucket $bucket, path $path: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Upload file with overwrite option
  Future<String> uploadFileWithOverwrite(String bucket, String path, File file) async {
    try {
      debugPrint('📤 Uploading file to bucket: $bucket, path: $path');

      // Check file size before upload
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size too large. Maximum allowed: ${maxFileSize ~/ (1024 * 1024)}MB');
      }

      final response = await client.storage.from(bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      debugPrint('✅ File uploaded with overwrite successfully: $response');
      return response;
    } on StorageException catch (e) {
      debugPrint('❌ StorageException during upload: $e');
      if (e.message.contains('File size limit exceeded')) {
        throw Exception('File too large. Maximum size is ${maxFileSize ~/ (1024 * 1024)}MB.');
      }
      throw Exception('Failed to upload file: ${e.message}');
    } catch (e) {
      debugPrint('❌ Failed to upload file with overwrite to bucket $bucket, path $path: $e');
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  // Get public URL for file
  String getPublicUrl(String bucket, String path) {
    try {
      // Clean path from bucket prefix if present
      String cleanPath = path;
      if (cleanPath.startsWith('$bucket/')) {
        cleanPath = cleanPath.substring(bucket.length + 1);
      }
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      final url = client.storage.from(bucket).getPublicUrl(cleanPath);
      debugPrint('🔗 Generated public URL for $bucket: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Failed to get public URL for bucket $bucket, path $path: $e');
      throw Exception('Failed to get public URL: $e');
    }
  }

  // Check if file exists in storage
  Future<bool> fileExists(String bucket, String path) async {
    try {
      await client.storage.from(bucket).download(path);
      return true;
    } catch (e) {
      debugPrint('File does not exist: $path, error: $e');
      return false;
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String bucket, String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
      debugPrint('🗑 File deleted: $path from bucket: $bucket');
    } catch (e) {
      debugPrint('❌ Failed to delete file from bucket $bucket, path $path: $e');
      throw Exception('Failed to delete file: $e');
    }
  }

  // ============ PROFILE IMAGE MANAGEMENT ============

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String phoneNumber,
    String? profileImagePath,
  }) async {
    try {
      debugPrint('👤 Updating user profile for: $uid');

      final updateData = {
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (profileImagePath != null) 'profile_image': profileImagePath,
      };

      await updateUser(uid, updateData);
      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Validate image file
  Future<void> _validateImageFile(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

    final fileSize = await imageFile.length();
    if (fileSize > maxFileSize) {
      throw Exception('Image file too large. Maximum size is ${maxFileSize ~/ (1024 * 1024)}MB.');
    }

    final fileExtension = imageFile.path.split('.').last.toLowerCase();
    if (!supportedImageFormats.contains(fileExtension)) {
      throw Exception('Unsupported image format. Supported formats: ${supportedImageFormats.join(', ')}');
    }
  }

  String _getFileExtension(String path) {
    try {
      final extension = path.split('.').last.toLowerCase();
      return supportedImageFormats.contains(extension) ? extension : 'jpg';
    } catch (e) {
      return 'jpg';
    }
  }

  String _getFileExtensionFromFile(File file) {
    return _getFileExtension(file.path);
  }

  Future<String?> getCurrentProfileImagePath(String uid) async {
    try {
      final user = await getUser(uid);
      return user?['profile_image'] as String?;
    } catch (e) {
      debugPrint('❌ Failed to get current profile image path: $e');
      return null;
    }
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    String? oldImagePath;

    try {
      debugPrint('🖼 Starting profile image upload for user: $uid');
      await _validateImageFile(imageFile);

      oldImagePath = await getCurrentProfileImagePath(uid);
      if (oldImagePath != null && oldImagePath.isNotEmpty) {
        debugPrint('📁 Current profile image path: $oldImagePath');
      }

      final fileExtension = _getFileExtensionFromFile(imageFile);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_$timestamp.$fileExtension';
      final path = 'profiles/$uid/$fileName';

      debugPrint('📁 Uploading to new path: $path (format: $fileExtension)');
      final result = await uploadFileWithOverwrite(_profileBucketName, path, imageFile);
      debugPrint('✅ Profile image uploaded successfully: $result');

      if (oldImagePath != null && oldImagePath.isNotEmpty && oldImagePath != path) {
        await _deleteOldProfileImage(oldImagePath);
      }

      return path;
    } catch (e) {
      debugPrint('❌ Failed to upload profile image: $e');
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  Future<void> _deleteOldProfileImage(String oldImagePath) async {
    try {
      debugPrint('🗑 Attempting to delete old profile image: $oldImagePath');

      String cleanPath = oldImagePath;
      if (cleanPath.startsWith('$_profileBucketName/')) {
        cleanPath = cleanPath.replaceFirst('$_profileBucketName/', '');
      }

      final exists = await fileExists(_profileBucketName, cleanPath);
      if (exists) {
        await deleteFile(_profileBucketName, cleanPath);
        debugPrint('✅ Old profile image deleted successfully: $cleanPath');
      } else {
        debugPrint('ℹ Old profile image not found, skipping deletion: $cleanPath');
      }
    } catch (e) {
      debugPrint('⚠ Failed to delete old profile image (non-critical): $e');
    }
  }

  Future<void> updateUserProfileWithImage({
    required String uid,
    required String fullName,
    required String username,
    required String phoneNumber,
    File? newProfileImage,
  }) async {
    String? newProfileImagePath;
    String? oldProfileImagePath;

    try {
      debugPrint('👤 Updating user profile for: $uid');
      oldProfileImagePath = await getCurrentProfileImagePath(uid);

      if (newProfileImage != null) {
        newProfileImagePath = await uploadProfileImage(uid, newProfileImage);
      }

      final updateData = {
        'full_name': fullName,
        'username': username,
        'phone_number': phoneNumber,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        if (newProfileImagePath != null) 'profile_image': newProfileImagePath,
      };

      await updateUser(uid, updateData);
      debugPrint('✅ User profile updated successfully');

      if (newProfileImage != null &&
          oldProfileImagePath != null &&
          oldProfileImagePath.isNotEmpty &&
          newProfileImagePath != oldProfileImagePath) {
        await _deleteOldProfileImage(oldProfileImagePath);
      }
    } catch (e) {
      debugPrint('❌ Failed to update user profile: $e');

      if (newProfileImagePath != null) {
        debugPrint('🔄 Cleaning up newly uploaded image due to failure: $newProfileImagePath');
        try {
          await deleteFile(_profileBucketName, newProfileImagePath);
        } catch (cleanupError) {
          debugPrint('⚠ Failed to cleanup new image: $cleanupError');
        }
      }
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final userData = await getUser(uid);
      if (userData == null) return null;

      if (userData['profile_image'] != null && userData['profile_image'].isNotEmpty) {
        userData['profile_image_url'] = getPublicUrl(_profileBucketName, userData['profile_image']);
        debugPrint('🖼 Profile image URL: ${userData['profile_image_url']}');
      } else {
        debugPrint('ℹ No profile image found for user');
      }

      return userData;
    } catch (e) {
      debugPrint('❌ Failed to get user profile: $e');
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<void> cleanupOrphanedProfileImages() async {
    try {
      final allImages = await client.storage.from(_profileBucketName).list();
      final users = await client.from('users').select('profile_image');

      final usedImagePaths = users
          .where((user) => user['profile_image'] != null)
          .map((user) => user['profile_image'] as String)
          .toSet();

      final orphanedImages = allImages
          .where((image) => !usedImagePaths.contains(image.name))
          .toList();

      for (final image in orphanedImages) {
        debugPrint('🗑 Deleting orphaned image: ${image.name}');
        await deleteFile(_profileBucketName, image.name);
      }

      debugPrint('✅ Cleanup completed. Deleted ${orphanedImages.length} orphaned images');
    } catch (e) {
      debugPrint('❌ Failed to cleanup orphaned images: $e');
    }
  }

  // ============ DOCUMENT & FOLDER MANAGEMENT ============

  Future<List<dynamic>> getFoldersAndFiles(
      {String? folderId}) async {
    final userId = client.auth.currentUser?.id; // Use Supabase user ID for consistency
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final response = await client.rpc(
        'get_folder_contents', // This RPC fetches items for the specified user and folder
        params: {
          'p_user_id': userId,
          'p_folder_id': folderId,
        },
      );

      final items = (response as List).map((item) {
        final json = item as Map<String, dynamic>;
        if (json['type'] == 'folder') {
          return Folder.fromJson(json);
        } else if (json['type'] == 'document') {
          return Document.fromJson(json);
        }
        return null;
      }).where((item) => item != null).toList();

      return items;
    } catch (e) {
      debugPrint('❌ Failed to load items from Supabase: $e');
      throw Exception('Failed to load items from Supabase: $e');
    }
  }

  Future<void> createFolder(String name, {String? parentId}) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final newFolder = {
        'name': name,
        'parent_folder_id': parentId,
        'user_id': userId,
        'created_by': userId,
      };

      await client.from('folders').insert(newFolder);
    } catch (e) {
      throw Exception('Failed to create folder on Supabase: $e');
    }
  }

  Future<void> deleteFolder(String folderId) async {
    final userId = client.auth.currentUser?.id; // Use Supabase user ID for consistency
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      debugPrint('🗑️ Deleting folder: $folderId for user: $userId');
      // The RPC function `delete_folder` should use `auth.uid()` internally for security.
      await client.rpc('delete_folder', params: {'p_folder_id': folderId});
      debugPrint('✅ Folder deleted successfully: $folderId');
    } catch (e) {
      debugPrint('❌ Failed to delete folder: $e');
      throw Exception('Failed to delete folder: $e');
    }
  }

  Future<void> addFileToFolder(String folderId, PlatformFile file) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final sanitizedFileName = file.name.replaceAll(RegExp(r'[#?]'), '_');
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
        'path': filePath,
        'folder_id': folderId,
        'user_id': userId,
        'created_by': userId,
      });
    } catch (e) {
      throw Exception('Failed to add file to folder: $e');
    }
  }

  Future<void> editFile(Document doc, PlatformFile newFile) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final fileBytes = newFile.bytes;
      if (fileBytes == null) throw Exception('New file bytes are null.');

      await client.storage.from(_documentBucketName).updateBinary(
        doc.path,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      if (doc.name != newFile.name) {
        await client.from('documents').update({
          'name': newFile.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', doc.id);
      }
    } catch (e) {
      throw Exception('Failed to edit file: $e');
    } 
  }

  Future<void> removeFile(Document doc) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      await client.storage.from(_documentBucketName).remove([doc.path]);
      await client.from('documents').delete().eq('id', doc.id);
    } catch (e) {
      throw Exception('Failed to remove file from Supabase: $e');
    }
  }

  Future<String> getDownloadUrl(Document doc) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    try {
      final signedUrl = await client.storage.from(_documentBucketName).createSignedUrl(doc.path, 60);
      return signedUrl;
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}