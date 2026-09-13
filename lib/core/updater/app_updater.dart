import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final int? apkSize;
  final String releaseHtmlUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.apkSize,
    required this.releaseHtmlUrl,
  });

  factory AppUpdateInfo.noUpdate({required String currentVersion}) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      releaseNotes: '',
      downloadUrl: '',
      releaseHtmlUrl: '',
    );
  }
}

class AppUpdater {
  static const String repoOwner = 'huydao123-tech';
  static const String repoName = 'TodoHuy-flutter';

  /// Kiểm tra có bản phát hành mới trên GitHub Releases không
  static Future<AppUpdateInfo> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVerStr = '${packageInfo.version}+${packageInfo.buildNumber}';

      final url = Uri.parse(
        'https://api.github.com/repos/$repoOwner/$repoName/releases/latest',
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[AppUpdater] GitHub API status: ${response.statusCode}');
        return AppUpdateInfo.noUpdate(currentVersion: currentVerStr);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String? ?? '').trim();
      final bodyNotes = (data['body'] as String? ?? '').trim();
      final htmlUrl = (data['html_url'] as String? ?? '').trim();
      final assets = (data['assets'] as List<dynamic>? ?? []);

      // Tìm asset APK (ưu tiên app-release.apk hoặc file có đuôi .apk)
      String downloadUrl = '';
      int? apkSize;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          apkSize = asset['size'] as int?;
          if (name.contains('release')) {
            break; // Ưu tiên bản release APK
          }
        }
      }

      final isNewer = isVersionNewer(
        remoteTag: tagName,
        localVersion: packageInfo.version,
        localBuildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
      );

      if (isNewer && downloadUrl.isNotEmpty) {
        return AppUpdateInfo(
          hasUpdate: true,
          currentVersion: currentVerStr,
          latestVersion: tagName.replaceAll(RegExp(r'^[vV]'), ''),
          releaseNotes: bodyNotes.isNotEmpty ? bodyNotes : 'Bản cập nhật cải tiến hiệu năng và sửa lỗi.',
          downloadUrl: downloadUrl,
          apkSize: apkSize,
          releaseHtmlUrl: htmlUrl,
        );
      }

      return AppUpdateInfo.noUpdate(currentVersion: currentVerStr);
    } catch (e) {
      debugPrint('[AppUpdater] Lỗi khi kiểm tra cập nhật: $e');
      final packageInfo = await PackageInfo.fromPlatform().catchError((_) => PackageInfo(
            appName: '',
            packageName: '',
            version: '1.0.0',
            buildNumber: '1',
          ));
      return AppUpdateInfo.noUpdate(
        currentVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      );
    }
  }

  @visibleForTesting
  static bool isVersionNewer({
    required String remoteTag,
    required String localVersion,
    required int localBuildNumber,
  }) {
    if (remoteTag.isEmpty) return false;
    final cleanRemote = remoteTag.replaceAll(RegExp(r'^[vV]'), '').trim();

    final remoteParts = cleanRemote.split('+');
    final remoteVer = remoteParts[0];
    final remoteBuildSegments = remoteParts.length > 1
        ? RegExp(r'\d+')
            .allMatches(remoteParts[1])
            .map((m) => int.tryParse(m.group(0) ?? '') ?? 0)
            .toList()
        : <int>[];

    final rSegments = remoteVer.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final lSegments = localVersion.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    final maxLen = rSegments.length > lSegments.length ? rSegments.length : lSegments.length;
    while (rSegments.length < maxLen) {
      rSegments.add(0);
    }
    while (lSegments.length < maxLen) {
      lSegments.add(0);
    }

    for (int i = 0; i < maxLen; i++) {
      if (rSegments[i] > lSegments[i]) return true;
      if (rSegments[i] < lSegments[i]) return false;
    }

    // Nếu version chính bằng nhau thì so sánh các phân đoạn của build number
    if (remoteBuildSegments.isNotEmpty && localBuildNumber > 0) {
      final localBuildSegments = [localBuildNumber];
      final maxBuildLen = remoteBuildSegments.length > localBuildSegments.length
          ? remoteBuildSegments.length
          : localBuildSegments.length;
      while (remoteBuildSegments.length < maxBuildLen) {
        remoteBuildSegments.add(0);
      }
      while (localBuildSegments.length < maxBuildLen) {
        localBuildSegments.add(0);
      }
      for (int i = 0; i < maxBuildLen; i++) {
        if (remoteBuildSegments[i] > localBuildSegments[i]) return true;
        if (remoteBuildSegments[i] < localBuildSegments[i]) return false;
      }
    }

    return false;
  }

  /// Tải file APK với tiến trình và kích hoạt trình cài đặt hệ thống Android
  static Future<OpenResult> downloadAndInstallApk({
    required String downloadUrl,
    required void Function(double progress, int received, int total) onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Tải APK thất bại với mã lỗi HTTP: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/WeekLoop_update.apk';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes, receivedBytes, totalBytes);
        } else {
          onProgress(-1.0, receivedBytes, 0);
        }
      }

      await sink.flush();
      await sink.close();

      // Mở trình cài đặt Android
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      return result;
    } finally {
      client.close();
    }
  }
}
