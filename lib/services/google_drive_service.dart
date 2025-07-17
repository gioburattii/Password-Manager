import 'dart:convert';


import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';


class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  drive.DriveApi? _driveApi;

  Future<void> init() async {
    final account = await _googleSignIn.signInSilently();
    if (account != null) {
      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(client);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final authHeaders = await account.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      _driveApi = drive.DriveApi(client);
      return true;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> uploadBackup(String filename, String content) async {
    if (_driveApi == null) return;

    final fileList = await _driveApi!.files.list(spaces: 'appDataFolder');
    final existing = fileList.files?.firstWhere(
      (f) => f.name == filename,
      orElse: () => drive.File(),
    );

    final media = drive.Media(
      Stream.value(utf8.encode(content)),
      utf8.encode(content).length,
    );

    final file = drive.File()
      ..name = filename
      ..parents = ['appDataFolder'];

    if (existing != null && existing.id != null) {
      await _driveApi!.files.update(file, existing.id!, uploadMedia: media);
    } else {
      await _driveApi!.files.create(file, uploadMedia: media);
    }
  }

  Future<String?> downloadBackup(String filename) async {
    if (_driveApi == null) return null;

    final fileList = await _driveApi!.files.list(spaces: 'appDataFolder');
    final file = fileList.files?.firstWhere(
      (f) => f.name == filename,
      orElse: () => drive.File(),
    );

    if (file == null || file.id == null) return null;

    final media = await _driveApi!.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia);

    if (media is drive.Media) {
      final bytes = await media.stream.fold<List<int>>([], (prev, element) => prev..addAll(element));
      return utf8.decode(Uint8List.fromList(bytes));
    }

    return null;
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = IOClient();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
