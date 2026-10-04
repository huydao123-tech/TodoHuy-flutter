import 'package:flutter/material.dart';

/// Supported locales in TodoHuy (WeekLoop)
enum AppLanguage {
  vi('vi', 'Tiếng Việt', '🇻🇳'),
  en('en', 'English', '🇬🇧');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

/// Application localizations class holding translations for Vietnamese (default) and English.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        fallbackVietnamese();
  }

  static AppLocalizations fallbackVietnamese() =>
      const AppLocalizations(Locale('vi'));

  bool get isVietnamese => locale.languageCode == 'vi';

  // ─── Common & App ───────────────────────────────────────────────────────────
  String get appName => 'WeekLoop';
  String get tagline => isVietnamese
      ? 'Kế hoạch tuần & Quản lý công việc'
      : 'Weekly Planning & Task Management';
  String get cancel => isVietnamese ? 'Hủy' : 'Cancel';
  String get save => isVietnamese ? 'Lưu' : 'Save';
  String get create => isVietnamese ? 'Tạo' : 'Create';
  String get delete => isVietnamese ? 'Xóa' : 'Delete';
  String get edit => isVietnamese ? 'Sửa' : 'Edit';
  String get restore => isVietnamese ? 'Khôi phục' : 'Restore';
  String get undo => isVietnamese ? 'Hoàn tác' : 'Undo';
  String get orDivider => isVietnamese ? 'HOẶC' : 'OR';
  String get loading => isVietnamese ? 'Đang tải...' : 'Loading...';
  String get error => isVietnamese ? 'Lỗi' : 'Error';
  String get retry => isVietnamese ? 'Thử lại' : 'Retry';
  String get version => isVietnamese ? 'Phiên bản' : 'Version';
  String get language => isVietnamese ? 'Ngôn ngữ' : 'Language';
  String get selectLanguage =>
      isVietnamese ? 'Chọn ngôn ngữ' : 'Select Language';
  String get vietnamese => isVietnamese ? 'Tiếng Việt' : 'Vietnamese';
  String get english => isVietnamese ? 'Tiếng Anh' : 'English';
  String get theme => isVietnamese ? 'Giao diện' : 'Theme';
  String get themeMode => isVietnamese ? 'Chế độ giao diện' : 'Theme Mode';
  String get lightTheme => isVietnamese ? 'Sáng' : 'Light';
  String get darkTheme => isVietnamese ? 'Tối' : 'Dark';
  String get systemTheme => isVietnamese ? 'Theo hệ thống' : 'System';

  // ─── Auth ──────────────────────────────────────────────────────────────────
  String get login => isVietnamese ? 'Đăng Nhập' : 'Log In';
  String get signUp => isVietnamese ? 'Đăng Ký' : 'Sign Up';
  String get fullName => isVietnamese ? 'Họ và tên' : 'Full name';
  String get email => 'Email';
  String get password => isVietnamese ? 'Mật khẩu' : 'Password';
  String get confirmPassword =>
      isVietnamese ? 'Xác nhận lại mật khẩu' : 'Confirm password';
  String get forgotPassword =>
      isVietnamese ? 'Quên mật khẩu?' : 'Forgot password?';
  String get forgotPasswordTitle =>
      isVietnamese ? 'Quên mật khẩu' : 'Forgot Password';
  String get resetPassword =>
      isVietnamese ? 'Đặt lại mật khẩu' : 'Reset Password';
  String get resetPasswordInstruction => isVietnamese
      ? 'Nhập email của bạn và chúng tôi sẽ gửi link đặt lại mật khẩu.'
      : 'Enter your email and we will send a password reset link.';
  String get sendResetLink =>
      isVietnamese ? 'Gửi link đặt lại' : 'Send reset link';
  String get checkYourEmail =>
      isVietnamese ? 'Kiểm tra email của bạn' : 'Check your email';
  String get resetConfirmationDesc => isVietnamese
      ? 'Nếu tài khoản tồn tại với địa chỉ này, bạn sẽ nhận được email trong vài phút.\nHãy kiểm tra cả thư mục Spam.'
      : 'If an account exists with this email, you will receive an email shortly.\nPlease also check your Spam folder.';
  String get resend => isVietnamese ? 'Gửi lại' : 'Resend';
  String get backToLogin =>
      isVietnamese ? 'Quay lại Đăng nhập' : 'Back to Login';
  String get createAccountToStart => isVietnamese
      ? 'Tạo tài khoản mới để bắt đầu'
      : 'Create a new account to get started';
  String get createAccountBtn =>
      isVietnamese ? 'Tạo Tài Khoản' : 'Create Account';
  String get continueWithGoogle =>
      isVietnamese ? 'Tiếp tục với Google' : 'Continue with Google';
  String get alreadyHaveAccount => isVietnamese
      ? 'Đã có tài khoản? Đăng nhập ngay'
      : 'Already have an account? Log in';
  String get dontHaveAccount => isVietnamese
      ? 'Chưa có tài khoản? Đăng ký ngay'
      : 'Don\'t have an account? Sign up';
  String get defaultUserName => isVietnamese ? 'Người dùng' : 'User';

  // Validation & Auth Errors
  String get errEnterName =>
      isVietnamese ? 'Vui lòng nhập họ và tên' : 'Please enter your full name';
  String get errEnterEmail =>
      isVietnamese ? 'Vui lòng nhập email' : 'Please enter your email';
  String get errInvalidEmail =>
      isVietnamese ? 'Email không hợp lệ' : 'Invalid email address';
  String get errEnterPassword =>
      isVietnamese ? 'Vui lòng nhập mật khẩu' : 'Please enter your password';
  String get errPasswordTooShort => isVietnamese
      ? 'Mật khẩu phải từ 6 ký tự trở lên'
      : 'Password must be at least 6 characters';
  String get errPasswordMismatch => isVietnamese
      ? 'Mật khẩu xác nhận không khớp'
      : 'Passwords do not match';
  String get errUserNotFound => isVietnamese
      ? 'Không tìm thấy tài khoản với email này.'
      : 'No account found with this email.';
  String get errWrongPassword =>
      isVietnamese ? 'Sai mật khẩu.' : 'Incorrect password.';
  String get errEmailInUse => isVietnamese
      ? 'Email này đã được sử dụng. Vui lòng đăng nhập.'
      : 'This email is already in use. Please log in.';
  String get errWeakPassword => isVietnamese
      ? 'Mật khẩu quá yếu (tối thiểu 6 ký tự).'
      : 'Password is too weak (minimum 6 characters).';
  String get errPopupClosed => isVietnamese
      ? 'Bạn đã đóng cửa sổ đăng nhập Google.'
      : 'Google sign-in popup was closed.';
  String get errPopupBlocked => isVietnamese
      ? 'Trình duyệt chặn popup. Vui lòng cấp quyền mở popup.'
      : 'Browser blocked popup. Please allow popups.';
  String get errGoogleSignInPrefix =>
      isVietnamese ? 'Lỗi Google Sign-In: ' : 'Google Sign-In Error: ';

  // ─── Dashboard & Navigation ────────────────────────────────────────────────
  String get planner => 'Planner';
  String get sideTasks => isVietnamese ? 'Việc phụ' : 'Side Tasks';
  String get sideTasksTitle => isVietnamese ? 'Đầu việc phụ' : 'Side Tasks';
  String get notes => isVietnamese ? 'Ghi chú' : 'Notes';
  String get categoriesSection => isVietnamese ? 'DANH MỤC' : 'CATEGORIES';
  String get utilitiesSection => isVietnamese ? 'TIỆN ÍCH' : 'UTILITIES';
  String get resourcesAndLinks =>
      isVietnamese ? 'Tài liệu & Link' : 'Resources & Links';
  String get trash => isVietnamese ? 'Thùng rác' : 'Trash';
  String get checkForUpdates =>
      isVietnamese ? 'Kiểm tra bản cập nhật' : 'Check for Updates';
  String get checkingForUpdates =>
      isVietnamese ? 'Đang kiểm tra bản cập nhật...' : 'Checking for updates...';
  String appUpToDate(String ver) => isVietnamese
      ? 'Ứng dụng đang ở phiên bản mới nhất ($ver)'
      : 'The app is up to date ($ver)';
  String get logout => isVietnamese ? 'Đăng xuất' : 'Log out';
  String get logoutConfirm =>
      isVietnamese ? 'Bạn có chắc chắn muốn đăng xuất?' : 'Are you sure you want to log out?';

  // ─── Task Groups & Drawer ──────────────────────────────────────────────────
  String get createCategory =>
      isVietnamese ? 'Tạo danh mục mới' : 'Create new category';
  String get editCategory =>
      isVietnamese ? 'Sửa tên danh mục' : 'Edit category name';
  String get categoryName =>
      isVietnamese ? 'Tên danh mục' : 'Category name';
  String get categoryColor => isVietnamese ? 'Màu sắc' : 'Color';
  String get archiveToTrashTooltip =>
      isVietnamese ? 'Lưu trữ vào thùng rác' : 'Move to trash';
  String get renameTooltip => isVietnamese ? 'Sửa tên' : 'Rename';
  String get trashSheetTitle =>
      isVietnamese ? 'Thùng rác danh mục' : 'Archived Categories';
  String get trashEmpty => isVietnamese ? 'Thùng rác trống' : 'Trash is empty';
  String get trashEmptyDesc => isVietnamese
      ? 'Các danh mục đã lưu trữ sẽ xuất hiện tại đây'
      : 'Archived categories will appear here';

  // ─── Planner ───────────────────────────────────────────────────────────────
  String get currentWeek => isVietnamese ? 'TUẦN HIỆN TẠI' : 'CURRENT WEEK';
  String get pastWeek => isVietnamese ? 'TUẦN ĐÃ QUA' : 'PAST WEEK';
  String get upcomingWeek => isVietnamese ? 'TUẦN SẮP TỚI' : 'UPCOMING WEEK';
  String get previousWeek => isVietnamese ? 'Tuần trước' : 'Previous week';
  String get nextWeek => isVietnamese ? 'Tuần sau' : 'Next week';
  String get backToToday => isVietnamese ? 'Về hôm nay' : 'Back to Today';
  String get weeklyGoals => isVietnamese ? 'Mục tiêu tuần' : 'Weekly Goals';
  String get addGoalHint =>
      isVietnamese ? 'Thêm mục tiêu...' : 'Add a goal...';
  String get addTaskForGroupHint =>
      isVietnamese ? 'Thêm việc cho nhóm này...' : 'Add a task for this group...';
  String get addNoteHint =>
      isVietnamese ? 'Ghi chú thêm...' : 'Add notes...';
  String get noCategoriesYet =>
      isVietnamese ? 'Chưa có danh mục nào' : 'No categories yet';
  String get createCategoryToStart => isVietnamese
      ? 'Nhấn + ở góc trên để tạo danh mục'
      : 'Tap + above to create your first category';
  String get moveToCurrentWeek =>
      isVietnamese ? 'Dời sang tuần này' : 'Move to this week';
  String get moveToNextWeek =>
      isVietnamese ? 'Dời sang tuần sau' : 'Move to next week';
  String taskMovedToWeek(String weekLabel) => isVietnamese
      ? 'Đã dời công việc sang $weekLabel'
      : 'Moved task to $weekLabel';
  String get pastWeekTaskNotice => isVietnamese
      ? 'Công việc thuộc tuần cũ. Bạn có thể dời sang tuần này để tiếp tục thực hiện.'
      : 'This task is from a past week. You can move it to this week to continue working on it.';

  // Days
  String get mon => isVietnamese ? 'T2' : 'Mon';
  String get tue => isVietnamese ? 'T3' : 'Tue';
  String get wed => isVietnamese ? 'T4' : 'Wed';
  String get thu => isVietnamese ? 'T5' : 'Thu';
  String get fri => isVietnamese ? 'T6' : 'Fri';
  String get sat => isVietnamese ? 'T7' : 'Sat';
  String get sun => isVietnamese ? 'CN' : 'Sun';

  // Quick Add Sheet
  String get quickAddTask =>
      isVietnamese ? 'Thêm việc nhanh' : 'Quick Add Task';
  String get selectCategory =>
      isVietnamese ? 'Chọn danh mục' : 'Select Category';
  String get taskContent =>
      isVietnamese ? 'Nội dung công việc' : 'Task content';
  String get taskNoteOptional =>
      isVietnamese ? 'Ghi chú (tùy chọn)' : 'Note (optional)';
  String get enterTaskContent =>
      isVietnamese ? 'Nhập việc cần làm...' : 'Enter task to do...';

  // ─── Side Tasks ────────────────────────────────────────────────────────────
  String get sideTasksScreenTitle =>
      isVietnamese ? 'Việc phụ (Lặt vặt)' : 'Side Tasks';
  String get sideTaskInputHint =>
      isVietnamese ? 'Thêm việc lặt vặt...' : 'Add a side task...';
  String get filterAll => isVietnamese ? 'Tất cả' : 'All';
  String get filterTodo => isVietnamese ? 'Chưa xong' : 'Pending';
  String get filterDone => isVietnamese ? 'Đã xong' : 'Completed';
  String get noSideTasksEmpty =>
      isVietnamese ? 'Chưa có việc phụ nào.' : 'No side tasks yet.';
  String get noSideTasksSub => isVietnamese
      ? 'Thêm việc phụ đầu tiên của bạn ở trên'
      : 'Add your first side task above';
  String get taskDeleted => isVietnamese ? 'Đã xóa việc' : 'Task deleted';
  String get editSideTask =>
      isVietnamese ? 'Sửa việc phụ' : 'Edit side task';
  String get editSideTaskTitle =>
      isVietnamese ? 'Chỉnh sửa việc phụ' : 'Edit Side Task';

  // ─── Notes ─────────────────────────────────────────────────────────────────
  String get searchNotesHint =>
      isVietnamese ? 'Tìm kiếm ghi chú...' : 'Search notes...';
  String get noNotesEmpty => isVietnamese
      ? 'Chưa có ghi chú nào.\nNhấn + để tạo ghi chú đầu tiên.'
      : 'No notes yet.\nTap + to create your first note.';
  String get newNote => isVietnamese ? 'Ghi chú mới' : 'New Note';
  String get editNote => isVietnamese ? 'Chỉnh sửa ghi chú' : 'Edit Note';
  String get noteTitle => isVietnamese ? 'Tiêu đề' : 'Title';
  String get noteContentHint =>
      isVietnamese ? 'Nội dung ghi chú...' : 'Note content...';
  String get category => isVietnamese ? 'Danh mục' : 'Category';

  // ─── Resources ─────────────────────────────────────────────────────────────
  String get resourcesSheetTitle =>
      isVietnamese ? 'Tài liệu & Link hữu ích' : 'Useful Resources & Links';
  String get noResourcesYet =>
      isVietnamese ? 'Chưa có tài liệu nào' : 'No resources yet';
  String get addResource =>
      isVietnamese ? 'Thêm tài liệu' : 'Add Resource';
  String get resourceTitle =>
      isVietnamese ? 'Tiêu đề tài liệu' : 'Resource title';
  String get resourceUrl =>
      isVietnamese ? 'Đường dẫn (URL)' : 'URL Link';
  String get resourceDescOptional =>
      isVietnamese ? 'Mô tả (tùy chọn)' : 'Description (optional)';
  String get belongsToCategoryOptional => isVietnamese
      ? 'Thuộc danh mục (tùy chọn)'
      : 'Category (optional)';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
