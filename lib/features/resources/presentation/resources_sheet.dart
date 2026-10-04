import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../planner/data/planner_repository.dart';
import '../data/resources_repository.dart';
import '../data/resource_model.dart';

class ResourcesSheet extends ConsumerWidget {
  const ResourcesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(resourcesProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.scaffoldBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle + header
              _buildHeader(context, ref),
              Divider(height: 1, color: context.appBorderColor),

              // List
              Expanded(
                child: resourcesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Lỗi: $err')),
                  data: (resources) {
                    if (resources.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_off, size: 48, color: context.appTextFaintColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có tài liệu nào.\nNhấn + để thêm link mới.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.appTextMutedColor, height: 1.5),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: resources.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: context.appBorderColor),
                      itemBuilder: (context, i) => _ResourceTile(resource: resources[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: context.appBorderColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Tài liệu & Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appTextColor)),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddSheet(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddResourceSheet(),
    );
  }
}

// ─── Individual Resource Tile ─────────────────────────────────────────────────
class _ResourceTile extends ConsumerWidget {
  final ResourceModel resource;

  const _ResourceTile({required this.resource});

  Future<void> _launchLink(BuildContext context) async {
    try {
      final url = Uri.parse(resource.link);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Không thể mở link');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(resource.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        final user = ref.read(authRepositoryProvider).currentUser;
        if (user != null) {
          ref.read(resourcesRepositoryProvider).deleteResource(user.uid, resource.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa "${resource.title}"'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'HOÀN TÁC',
                onPressed: () {
                  ref.read(resourcesRepositoryProvider).addResource(
                        user.uid,
                        resource.title,
                        resource.link,
                        resource.description,
                        resource.taskGroupId,
                      );
                },
              ),
            ),
          );
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.link, color: AppColors.accent, size: 20),
        ),
        title: Text(
          resource.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.appTextColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource.link,
              style: const TextStyle(fontSize: 12, color: AppColors.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (resource.description.isNotEmpty)
              Text(
                resource.description,
                style: TextStyle(fontSize: 12, color: context.appTextMutedColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Icon(Icons.open_in_new, size: 18, color: context.appTextFaintColor),
        onTap: () => _launchLink(context),
      ),
    );
  }
}

// ─── Add Resource Sheet ───────────────────────────────────────────────────────
class _AddResourceSheet extends ConsumerStatefulWidget {
  const _AddResourceSheet();

  @override
  ConsumerState<_AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends ConsumerState<_AddResourceSheet> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedGroupId;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _descController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecor(String hint, {IconData? icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: context.appTextFaintColor, fontSize: 14),
    prefixIcon: icon != null ? Icon(icon, size: 18, color: context.appTextMutedColor) : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: context.appBorderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent),
    ),
    fillColor: context.subtleBgColor,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();
    if (title.isEmpty || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tiêu đề và link')));
      return;
    }
    setState(() => _isSaving = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        await ref.read(resourcesRepositoryProvider).addResource(
          user.uid, title, link, _descController.text.trim(), _selectedGroupId,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final taskGroupsAsync = ref.watch(taskGroupsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16, bottom: bottomInset + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: context.appBorderColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Thêm tài liệu / Link',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.appTextColor)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: _fieldDecor('Tiêu đề tài liệu...', icon: Icons.title),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _linkController,
              keyboardType: TextInputType.url,
              decoration: _fieldDecor('https://...', icon: Icons.link),
            ),
            const SizedBox(height: 12),

            // TaskGroup selector
            taskGroupsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (groups) {
                if (groups.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String?>(
                  initialValue: _selectedGroupId,
                  decoration: _fieldDecor('Gắn vào nhóm (tuỳ chọn)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Chung')),
                    ...groups.map((g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(g.name),
                    )),
                  ],
                  onChanged: (val) => setState(() => _selectedGroupId = val),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: _fieldDecor('Mô tả ngắn (tuỳ chọn)...', icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Lưu tài liệu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
