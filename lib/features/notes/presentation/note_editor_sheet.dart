import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
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

  // Theme-aware surfaces: pastel in light mode, tinted dark surface in dark mode.
  Color get _sheetBg => context.isDarkMode
      ? Color.alphaBlend(_currentColors[1].withValues(alpha: 0.10), AppColors.darkSurface)
      : _currentColors[0];
  Color get _headerTop => context.isDarkMode
      ? Color.alphaBlend(_currentColors[1].withValues(alpha: 0.22), AppColors.darkSurface)
      : _currentColors[1];
  Color get _lineColor =>
      context.isDarkMode ? _currentColors[1].withValues(alpha: 0.35) : _currentColors[1];

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
    final note = widget.note;
    if (note == null) return;
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(notesRepositoryProvider).deleteNote(user.uid, note.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${note.title.isEmpty ? 'Ghi chú' : note.title}"'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'HOÀN TÁC',
            onPressed: () {
              ref.read(notesRepositoryProvider).addNote(user.uid, note);
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: screenHeight * 0.88,
        decoration: BoxDecoration(
          color: _sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            children: [
              // ─── Header: Drag Handle + Cover Color Palette ─────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_headerTop, _sheetBg],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Color selector row
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
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedColorKey = key);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 10),
                              width: isSelected ? 28 : 22,
                              height: isSelected ? 28 : 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [colors[0], colors[1]]),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? context.appTextColor
                                      : (context.isDarkMode ? AppColors.darkTextFaint : Colors.white),
                                  width: isSelected ? 2.2 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)]
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

              // ─── Metadata Bar: Icon Button + Category Selector Chips ───────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Row(
                  children: [
                    // Icon Picker Button
                    InkWell(
                      onTap: _showIconPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: context.cardBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _lineColor, width: 1.2),
                          boxShadow: context.isDarkMode ? null : const [AppColors.softShadow],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedIcon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down_rounded, size: 18, color: context.appTextMutedColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Categories horizontal list
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final cat = _categories[i];
                            final isSelected = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedCategory = cat);
                              },
                              selectedColor: AppColors.accent,
                              backgroundColor: context.cardBgColor,
                              side: BorderSide(
                                color: isSelected ? AppColors.accent : _lineColor,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : context.appTextMutedColor,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable Note Content (Title + Divider + Content) ───────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Note Title TextField (Clean borderless, no clipping!)
                      TextField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.appTextColor,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.isVietnamese ? 'Tiêu đề ghi chú...' : 'Note title...',
                          hintStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textFaint.withValues(alpha: 0.7),
                            letterSpacing: -0.3,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 2),
                      Divider(
                        color: _lineColor.withValues(alpha: 0.9),
                        thickness: 1,
                        height: 14,
                      ),
                      const SizedBox(height: 2),
                      // Note Body TextField
                      TextField(
                        controller: _contentController,
                        style: TextStyle(
                          fontSize: 15,
                          color: context.appTextColor,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: l10n.isVietnamese ? 'Bắt đầu viết...' : 'Start writing...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: AppColors.textFaint.withValues(alpha: 0.7),
                            height: 1.6,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        maxLines: null,
                        minLines: 8,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ─── Fixed Bottom Action Dock ─────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  border: Border(top: BorderSide(color: _lineColor, width: 0.9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (_isEditing)
                        OutlinedButton.icon(
                          onPressed: _isDeleting ? null : _delete,
                          icon: _isDeleting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
                              : const Icon(Icons.delete_outline_rounded, size: 18),
                          label: Text(l10n.isVietnamese ? 'Xóa' : 'Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.appTextMutedColor,
                          side: BorderSide(color: context.appBorderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l10n.cancel),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isEditing
                            ? (l10n.isVietnamese ? 'Cập nhật' : 'Update')
                            : (l10n.isVietnamese ? 'Tạo ghi chú' : 'Create Note')),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.isVietnamese ? 'Chọn biểu tượng' : 'Choose Icon',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.appTextColor),
              ),
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
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent.withValues(alpha: 0.12) : context.subtleBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : context.appBorderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
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
      ),
    );
  }
}

