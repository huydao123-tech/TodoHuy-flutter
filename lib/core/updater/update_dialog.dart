import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import 'app_updater.dart';

class UpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo updateInfo) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _progressText = '';
  String? _errorMessage;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _progress = 0.0;
      _progressText = 'Đang chuẩn bị tải...';
    });

    try {
      final result = await AppUpdater.downloadAndInstallApk(
        downloadUrl: widget.updateInfo.downloadUrl,
        onProgress: (progress, received, total) {
          if (!mounted) return;
          setState(() {
            _progress = progress >= 0 ? progress : 0;
            if (total > 0) {
              final recStr = _formatBytes(received);
              final totalStr = _formatBytes(total);
              final pct = (progress * 100).toInt();
              _progressText = '$pct% ($recStr / $totalStr)';
            } else {
              _progressText = _formatBytes(received);
            }
          });
        },
      );

      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _isDownloading = false;
          _errorMessage =
              'Không thể khởi động trình cài đặt: ${result.message}\nBạn có thể mở trình duyệt để cài đặt trực tiếp.';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _progressText = 'Đã mở trình cài đặt APK';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _errorMessage = 'Lỗi tải bản cập nhật: $e';
      });
    }
  }

  Future<void> _openBrowser() async {
    final uri = Uri.parse(
      widget.updateInfo.downloadUrl.isNotEmpty
          ? widget.updateInfo.downloadUrl
          : widget.updateInfo.releaseHtmlUrl,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.updateInfo;
    final sizeText = info.apkSize != null ? _formatBytes(info.apkSize!) : '';

    return PopScope(
      canPop: !_isDownloading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: context.cardBgColor,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cập nhật phiên bản mới',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.appTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'v${info.latestVersion} ${sizeText.isNotEmpty ? "($sizeText)" : ""}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Version comparison pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.subtleBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bản hiện tại: v${info.currentVersion.split("+").first}',
                      style: TextStyle(fontSize: 12, color: context.appTextMutedColor),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: context.appTextMutedColor),
                    Text(
                      'Bản mới: v${info.latestVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Release notes
              Text(
                'Nội dung thay đổi:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.subtleBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.appBorderColor),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.releaseNotes,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.appTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Download progress section
              if (_isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: context.appBorderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _progressText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.appTextMutedColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isDownloading)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Để sau',
                        style: TextStyle(color: context.appTextMutedColor),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (_errorMessage != null) ...[
                    OutlinedButton(
                      onPressed: _openBrowser,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Mở trình duyệt', style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.icon(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      _isDownloading ? 'Đang tải...' : 'Cập nhật ngay',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
