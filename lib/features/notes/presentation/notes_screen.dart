import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notes_repository.dart';
import '../data/note_model.dart';
import 'note_editor_sheet.dart';
import '../../../core/localization/app_localizations.dart';

// Color map: colorId → [background, border/accent]
const _colorMap = {
  'stone':  [Color(0xFFFAFAF9), Color(0xFFE7E5E4)],
  'red':    [Color(0xFFFEF2F2), Color(0xFFFECACA)],
  'orange': [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
  'yellow': [Color(0xFFFEFCE8), Color(0xFFFEF08A)],
  'green':  [Color(0xFFF0FDF4), Color(0xFFBBF7D0)],
  'blue':   [Color(0xFFEFF6FF), Color(0xFFBFDBFE)],
  'violet': [Color(0xFFFAF5FF), Color(0xFFDDD6FE)],
  'pink':   [Color(0xFFFDF2F8), Color(0xFFFBCFE8)],
};

const _categories = ['Tất cả', 'Ý tưởng', 'Công việc', 'Học tập', 'Cá nhân', 'Dự án'];

List<Color> _colorsFor(String colorId) =>
    _colorMap[colorId] ?? _colorMap['stone']!;

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notesAsync = ref.watch(notesProvider);

    return Column(
      children: [
        // ─── Things 3 / Linear Search Bar ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: const [AppColors.softShadow],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 14, color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tiêu đề, nội dung ghi chú...',
                hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.cancel_rounded, color: AppColors.textFaint, size: 18),
                      )
                    : null,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),

        // ─── Category Filter Chips ───────────────────────────────────
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                selectedColor: AppColors.accent.withValues(alpha: 0.12),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: isSelected ? 1.2 : 0.8,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ─── Notes Grid ──────────────────────────────────────────────
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.accent),
            ),
            error: (err, _) => Center(child: Text('Lỗi: $err', style: const TextStyle(color: Colors.red))),
            data: (notes) {
              // Filter
              final filtered = notes.where((n) {
                final matchSearch = _searchQuery.isEmpty ||
                    n.title.toLowerCase().contains(_searchQuery) ||
                    n.content.toLowerCase().contains(_searchQuery);
                final matchCategory = _selectedCategory == 'Tất cả' ||
                    n.category == _selectedCategory;
                return matchSearch && matchCategory;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sticky_note_2_outlined,
                              size: 32, color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedCategory != 'Tất cả'
                              ? (l10n.isVietnamese ? 'Không tìm thấy ghi chú phù hợp.' : 'No matching notes found.')
                              : l10n.noNotesEmpty,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _buildMasonryGrid(filtered);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasonryGrid(List<NoteModel> notes) {
    final left = <NoteModel>[];
    final right = <NoteModel>[];
    double leftHeight = 0;
    double rightHeight = 0;
    for (final note in notes) {
      final h = _estimateHeight(note);
      if (leftHeight <= rightHeight) {
        left.add(note);
        leftHeight += h;
      } else {
        right.add(note);
        rightHeight += h;
      }
    }

    Widget column(List<NoteModel> items) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NoteCard(note: note, onTap: () => _openEditor(context, note: note)),
            ),
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          const SizedBox(width: 12),
          Expanded(child: column(right)),
        ],
      ),
    );
  }

  double _estimateHeight(NoteModel note) {
    double h = 36 + 24; // header + padding
    if (note.title.isNotEmpty) h += 24;
    h += (note.content.length / 22).ceil() * 16;
    h += 24; // footer
    return h;
  }

  void _openEditor(BuildContext context, {NoteModel? note}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(note: note),
    );
  }
}

// ─── Things 3 / Bear Style Individual Note Card ──────────────────────────────
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(note.colorId);
    final dateStr = DateFormat('dd/MM').format(note.updatedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors[1], width: 1.2),
        boxShadow: const [AppColors.softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: colors[1].withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Emoji badge + Category pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors[0],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors[1], width: 0.8),
                      ),
                      alignment: Alignment.center,
                      child: Text(note.icon, style: const TextStyle(fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors[0],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors[1], width: 0.8),
                      ),
                      child: Text(
                        note.category,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Note Title
                if (note.title.isNotEmpty) ...[
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.text,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],

                // Note Content preview
                if (note.content.isNotEmpty)
                  Text(
                    note.content,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 6,
                  ),

                const SizedBox(height: 10),
                // Card Footer: Date
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textFaint),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textFaint, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
