import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../data/notes_repository.dart';
import '../data/note_model.dart';
import 'note_editor_sheet.dart';

// Color map: colorId → gradient colors
const _colorMap = {
  'stone':  [Color(0xFFF5F5F4), Color(0xFFE7E5E4)],
  'red':    [Color(0xFFFEE2E2), Color(0xFFFECACA)],
  'orange': [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
  'yellow': [Color(0xFFFEF9C3), Color(0xFFFEF08A)],
  'green':  [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
  'blue':   [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
  'violet': [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
  'pink':   [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
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
    final notesAsync = ref.watch(notesProvider);

    return Column(
      children: [
        // ─── Search Bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm ghi chú...',
              hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textFaint, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, color: AppColors.textFaint, size: 20),
                    )
                  : null,
              fillColor: AppColors.bgAlt,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
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
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor: AppColors.accent.withValues(alpha: 0.12),
                backgroundColor: AppColors.bgAlt,
                side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ─── Notes Grid ──────────────────────────────────────────────
        Expanded(
          child: notesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Lỗi: $err')),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 52, color: AppColors.textFaint.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != 'Tất cả'
                            ? 'Không tìm thấy ghi chú phù hợp.'
                            : 'Chưa có ghi chú nào.\nNhấn + để tạo ghi chú đầu tiên.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _NoteCard(
                  note: filtered[i],
                  onTap: () => _openEditor(context, note: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context, {NoteModel? note}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditorSheet(note: note),
    );
  }
}

// ─── Individual Note Card ──────────────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(note.colorId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors[0],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors[1]),
          boxShadow: [
            BoxShadow(
              color: colors[1].withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover gradient strip
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors[1], colors[0]],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              alignment: Alignment.center,
              child: Text(note.icon, style: const TextStyle(fontSize: 24)),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title.isNotEmpty) ...[
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                    ],
                    Expanded(
                      child: Text(
                        note.content,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                        overflow: TextOverflow.fade,
                        maxLines: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors[1],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.category,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
