import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../data/notes_repository.dart';
import '../data/note_model.dart';

const _coverColors = <String, List<Color>>{
  'stone':  [Color(0xFFF5F5F4), Color(0xFFE7E5E4)],
  'red':    [Color(0xFFFEE2E2), Color(0xFFFECACA)],
  'orange': [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
  'yellow': [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
  'green':  [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
  'blue':   [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
  'violet': [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
  'pink':   [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
};

const _colorKeys = ['stone', 'red', 'orange', 'yellow', 'green', 'blue', 'violet', 'pink'];

const _icons = ['📝', '💡', '📌', '🎯', '📚', '💼', '🎨', '🔖', '⭐', '🚀', '❤️', '🌱'];

const _categories = ['Ý tưởng', 'Công việc', 'Học tập', 'Cá nhân', 'Dự án'];

class NoteEditorSheet extends ConsumerStatefulWidget {
  final NoteModel? note; // null = create new

  const NoteEditorSheet({super.key, this.note});

  @override
  ConsumerState<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<NoteEditorSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedColorKey;
  late String _selectedIcon;
  late String _selectedCategory;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedColorKey = widget.note?.colorId ?? 'stone';
    _selectedIcon = widget.note?.icon ?? '📝';
    _selectedCategory = widget.note?.category ?? 'Ý tưởng';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String get _compositeColor => '$_selectedColorKey:$_selectedCategory:$_selectedIcon';

  List<Color> get _currentColors => _coverColors[_selectedColorKey] ?? _coverColors['stone']!;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        if (_isEditing) {
          await ref.read(notesRepositoryProvider).updateNote(
            user.uid,
            widget.note!.id,
            {
              'title': _titleController.text.trim(),
              'content': _contentController.text.trim(),
              'color': _compositeColor,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          final newNote = NoteModel(
            id: '',
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            color: _compositeColor,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await ref.read(notesRepositoryProvider).addNote(user.uid, newNote);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú?'),
        content: const Text('Ghi chú này sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeleting = true);
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      try {
        await ref.read(notesRepositoryProvider).deleteNote(user.uid, widget.note!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
    if (mounted) setState(() => _isDeleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: _currentColors[0],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ─── Drag handle + cover color row ───────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_currentColors[1], _currentColors[0]],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 36, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Color selector
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorKeys.length,
                        itemBuilder: (_, i) {
                          final key = _colorKeys[i];
                          final colors = _coverColors[key]!;
                          final isSelected = key == _selectedColorKey;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColorKey = key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              width: isSelected ? 30 : 24,
                              height: isSelected ? 30 : 24,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [colors[0], colors[1]]),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.text : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]
                                    : [],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable content ───────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    // Icon row
                    Row(
                      children: [
                        // Big icon display
                        GestureDetector(
                          onTap: () => _showIconPicker(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _currentColors[1].withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(_selectedIcon, style: const TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Danh mục', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              _buildCategoryRow(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        height: 1.3,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tiêu đề ghi chú...',
                        hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textFaint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Content
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(fontSize: 15, color: AppColors.text, height: 1.6),
                      decoration: const InputDecoration(
                        hintText: 'Bắt đầu viết...',
                        hintStyle: TextStyle(fontSize: 15, color: AppColors.textFaint, height: 1.6),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: null,
                      minLines: 8,
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        if (_isEditing)
                          OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _delete,
                            icon: _isDeleting
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Xóa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                            ),
                          ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(_isEditing ? 'Cập nhật' : 'Tạo ghi chú'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn biểu tượng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _icons.length,
              itemBuilder: (_, i) {
                final icon = _icons[i];
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedIcon = icon);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.bgAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
