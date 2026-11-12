import 'dart:io';

import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

typedef TempDirectoryProvider = Future<Directory> Function();
typedef FileSharer = Future<void> Function(String path);

/// "Tải video đầy đủ": gọi playlist trước để kiểm quyền (như Web), tải MP4 có
/// token về file tạm, mở chia sẻ/lưu của hệ điều hành rồi dọn file.
///
/// Lỗi (kể cả 403) được ném lại cho UI hiện `recordingsDownloadError`.
class FullRecordingDownloader {
  FullRecordingDownloader(
    this._repository, {
    TempDirectoryProvider? tempDirectory,
    FileSharer? share,
  }) : _tempDirectory = tempDirectory ?? getTemporaryDirectory,
       _share = share ?? _shareWithSystem;

  final IMatchRecordingCatalogRepository _repository;
  final TempDirectoryProvider _tempDirectory;
  final FileSharer _share;

  static Future<void> _shareWithSystem(String path) async {
    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(path, mimeType: 'video/mp4')]);
  }

  static String _safe(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  Future<void> run(String matchId, String period) async {
    await _repository.getPlaylist(matchId, period: period);
    final directory = await _tempDirectory();
    final path = '${directory.path}/${_safe(matchId)}_${_safe(period)}.mp4';
    try {
      await _repository.downloadFullRecording(
        matchId,
        period: period,
        savePath: path,
      );
      await _share(path);
    } finally {
      try {
        await File(path).delete();
      } on Object {
        // Best effort: hệ điều hành tự dọn thư mục tạm.
      }
    }
  }
}

final fullRecordingDownloaderProvider = Provider<FullRecordingDownloader>(
  (ref) => FullRecordingDownloader(
    ref.watch(matchRecordingCatalogRepositoryProvider),
  ),
);
