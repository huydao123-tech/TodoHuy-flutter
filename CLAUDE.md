# CLAUDE.md

Hướng dẫn cho Claude Code khi làm việc trong repo này.

## Tổng quan

**WeekLoop** (package `todohuy`) — app năng suất cá nhân bằng Flutter, người dùng nói tiếng Việt, chỉ dùng một mình (không có cộng tác). Backend là Firebase (Auth + Firestore), không có Cloud Functions/Storage/FCM. Hiện chỉ phát hành APK Android qua GitHub Releases.

Màn hình chính là `DashboardScreen`, có 3 tab dưới đáy:
- **Tab 0 – Planner**: kế hoạch theo tuần, công việc chia theo Task Group (`features/planner`, `features/task_groups`)
- **Tab 1 – Việc phụ**: checklist ghi nhanh (`dashboard/presentation/widgets/side_panel_tab.dart` + `features/side_tasks/data`)
- **Tab 2 – Ghi chú**: sổ ghi chú dạng lưới masonry (`features/notes`). **Đang được nâng cấp thành "bộ não thứ 2" cho người ADHD**, xem [docs/SRS-second-brain.md](docs/SRS-second-brain.md)

Drawer gồm: Task Groups, Tài liệu & Link (`features/resources`), Thùng rác (task group đã lưu trữ), ngôn ngữ, giao diện, kiểm tra cập nhật, đăng xuất.

## Lệnh thường dùng

```bash
flutter pub get
flutter analyze                         # CI fail nếu có lỗi lint
flutter test                            # unit + widget + test/integration (không cần thiết bị)
flutter test test/widget/notes_screen_test.dart   # chạy một file
flutter test integration_test           # cần emulator/thiết bị
flutter run
```

CI ([.github/workflows/build_and_release.yml](.github/workflows/build_and_release.yml)) chạy trên **mỗi lần push lên `main`**: `analyze` → `test` → build APK → **publish GitHub Release**. Push lên main đồng nghĩa với phát hành, nên `flutter analyze` và `flutter test` phải pass trên máy trước khi push. Tên phiên bản lấy từ `pubspec.yaml` (`version: x.y.z+n`), build number lấy từ số thứ tự lần chạy CI. Trình cập nhật trong app ([lib/core/updater/app_updater.dart](lib/core/updater/app_updater.dart)) đọc GitHub Releases mới nhất.

## Kiến trúc

```
lib/
  main.dart                 # Firebase init, ProviderScope, theme sáng/tối
  core/
    router/app_router.dart  # GoRouter: /login, /forgot-password, / (có auth guard)
    theme/app_colors.dart   # design token + extension BuildContext (context.appTextColor...)
    localization/           # AppLocalizations thủ công (vi mặc định, en), context.l10n
    updater/                # tự cập nhật APK từ GitHub
    utils/week_helper.dart  # tính tuần (thứ Hai là đầu tuần), selectedWeekProvider
  features/<feature>/
    data/                   # *_model.dart (fromFirestore/toFirestore) + *_repository.dart (+ provider)
    presentation/           # screen, bottom sheet, widget
```

### Mẫu tầng dữ liệu (bám theo khi thêm tính năng)
- Mỗi feature có một class repository nhận `FirebaseFirestore` qua constructor, kèm một `Provider<XRepository>`.
- Dữ liệu đọc qua `StreamProvider.autoDispose` theo dõi `authRepositoryProvider.currentUser`; nếu null thì trả về `Stream.empty()`.
- Mọi dữ liệu nằm dưới `users/{uid}/<collection>`: `task_groups`, `work_items`, `weekly_goals`, `side_tasks`, `notes`, `resources`. Security rules ([firestore.rules](firestore.rules)) chỉ kiểm tra chủ sở hữu (`auth.uid == userId`) cho mọi subcollection.
- Việc sắp xếp làm ở **phía client** sau khi lấy snapshot (ví dụ notes sắp theo `updatedAt` giảm dần). Query dùng `where` cần index thì khai báo trong [firestore.indexes.json](firestore.indexes.json).
- Hàm update gắn `updatedAt: FieldValue.serverTimestamp()`. Khi đọc timestamp phải luôn có fallback: `(data['x'] as Timestamp?)?.toDate() ?? DateTime.now()`.
- Model là class bất biến, không dùng codegen (không freezed/json_serializable, cũng không dùng `riverpod_generator` dù đã khai báo `riverpod_annotation`).

### Quy ước UI
- Màu: chỉ dùng `AppColors.*` và extension theo theme (`context.cardBgColor`, `context.appTextColor`, `context.appBorderColor`, `context.subtleBgColor`, `context.isDarkMode`). Mọi UI mới phải hiển thị đúng ở **cả chế độ sáng lẫn tối**.
- Màu nhấn `AppColors.accent` (#16A34A). Bo góc: thẻ 16, ô nhập 12–14, bottom sheet `vertical(top: 24)` có thanh kéo 36×4.
- Modal: `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent, ...)`, sheet tự vẽ container và chừa chỗ cho `viewInsets.bottom`.
- Xóa: xóa ngay rồi hiện SnackBar kèm Hoàn tác (5 giây). Chỉ dùng AlertDialog cho thao tác không hoàn tác được.
- Gọi `HapticFeedback.selectionClick()` khi chọn và `lightImpact()` khi thực hiện hành động.
- Chuỗi hiển thị: dùng getter trong `AppLocalizations` khi đã có, nếu không thì dùng ternary inline `l10n.isVietnamese ? '...' : '...'`. Chuỗi mới nên thêm thành getter trong `app_localizations.dart`. Tiếng Việt là ngôn ngữ chính.

### Test
- Widget test override provider dữ liệu bằng stream giả, ví dụ `notesProvider.overrideWith((ref) => Stream.value(notes))` (xem [test/widget/notes_screen_test.dart](test/widget/notes_screen_test.dart)).
- Repository giả dùng chung (auth, task group, ...) nằm trong [integration_test/helpers/test_app_harness.dart](integration_test/helpers/test_app_harness.dart), dùng `mocktail`.
- Test hiện có đang kiểm tra theo text tiếng Việt cụ thể (ví dụ `'Tất cả'`, `'Ý tưởng'`). Khi đổi nội dung chữ thì phải cập nhật test.

## Những điểm dễ vướng

- **`NoteModel.color` là chuỗi ghép** `"colorKey:category:icon"` (ví dụ `"blue:Ý tưởng:💡"`), được tách ra qua các getter `colorId`/`category`/`icon`. Danh sách category hiện đang hardcode tiếng Việt ở cả `notes_screen.dart` và `note_editor_sheet.dart`. Mọi thay đổi schema phải **đọc được dữ liệu cũ**, vì các bản APK cũ vẫn đang ghi theo định dạng này.
- Việc phụ **tự bị xóa khi tick hoàn thành** (có delay 350ms và SnackBar hoàn tác). `isDone` gần như không còn dùng.
- [PRODUCT.md](PRODUCT.md) (UX doc ngày 2026-09-30) đã **cũ một phần**: hiện đã có quên mật khẩu, dark mode và grid masonry tự viết (không dùng `flutter_staggered_grid_view`). Hãy coi code là nguồn đúng. Mục "Product Decisions" trong đó vẫn còn hiệu lực, trừ những điểm SRS bộ não thứ 2 ghi rõ là thay thế.
- Code không còn dùng (đừng mở rộng, có thể xóa khi chạm tới): `SideTasksScreen`, `ResourcesScreen`, `AddTaskDialog`, biến `goRouter` tĩnh trong `app_router.dart`. `WeeklyGoalModel` có repository nhưng chưa có UI.
- Có hai provider task group gần như trùng nhau: `taskGroupsProvider` (planner_repository, autoDispose) và `activeTaskGroupsProvider` (task_group_repository). Dashboard đang dùng `taskGroupsProvider`.
- `dashboard_screen.dart` dài hơn 1100 dòng và chứa các class private `_AddTaskSheet` và `_AddGroupSheet`. UI mới nên tách thành file riêng thay vì viết thêm vào đây.
- `todohuy-spring/` nằm trong gitignore (backend Spring cũ), không liên quan.
- Hiện không có thông báo đẩy, Cloud Functions hay analytics. Thêm bất kỳ thứ nào trong số đó là quyết định sản phẩm và cần khai báo dependency mới cho cả Android lẫn iOS.

## Agent/skill nội bộ

`.agents/` chứa định nghĩa vai trò (flutter-dev, firestore-design, firebase-backend, ui-ux-design, automation-tester, mobile-devops, tech-lead) viết bằng tiếng Việt. Đây là tài liệu tham khảo về quy ước, Claude Code không tự nạp chúng.
