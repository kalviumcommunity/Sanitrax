import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String _cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  // Local fallback values for quick development runs when dart-defines are not passed.
  static const String _fallbackCloudName = 'dnhovbddc';
  static const String _fallbackUploadPreset = 'flutter_upload';
  static const String _folder = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_FOLDER',
    defaultValue: 'sanitrax/driver_checkins',
  );

  String get _resolvedCloudName =>
      _cloudName.isNotEmpty ? _cloudName : _fallbackCloudName;

  String get _resolvedUploadPreset =>
      _uploadPreset.isNotEmpty ? _uploadPreset : _fallbackUploadPreset;

  Future<String> uploadImageFile({
    required XFile file,
    String? folder,
    String? publicId,
  }) async {
    if (_resolvedCloudName.isEmpty || _resolvedUploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Set fallback constants in cloudinary_service.dart or run with --dart-define=CLOUDINARY_CLOUD_NAME=... --dart-define=CLOUDINARY_UPLOAD_PRESET=...',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_resolvedCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _resolvedUploadPreset
      ..fields['folder'] = folder ?? _folder;

    if (publicId != null && publicId.isNotEmpty) {
      request.fields['public_id'] = publicId;
    }

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: file.name,
        ),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): $body',
      );
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response missing secure_url');
    }

    return secureUrl;
  }

  Future<String> uploadDriverSelfie({
    required XFile file,
    required String driverUid,
    required String dayKey,
  }) async {
    return uploadImageFile(
      file: file,
      folder: _folder,
      publicId:
          '${driverUid}_${dayKey}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}

Future<String> uploadImage(File imageFile) {
  return CloudinaryService().uploadImageFile(
    file: XFile(imageFile.path),
    folder: 'sanitrax/issues',
    publicId: 'issue_${DateTime.now().millisecondsSinceEpoch}',
  );
}
