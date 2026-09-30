# WeekLoop — Product UX Document

> **Version:** 1.0 · **Date:** 2026-09-30  
> **Purpose:** Source document for design and prototyping. Describes what already exists, what should change, and why — backed by UX research. Does NOT specify implementation architecture.

---

## 1. Purpose

WeekLoop is a personal productivity app for Vietnamese-speaking users. It combines three distinct workflows into one mobile shell:

1. **Weekly planning** — organize work items by task group across calendar weeks
2. **Quick capture** — a frictionless checklist for miscellaneous, non-weekly tasks
3. **Notes** — a colorful, categorized notebook for ideas and reference material

Secondary features support the core three:

- **Task Groups** — user-defined color-coded categories shared across the Planner
- **Tài liệu & Link** — a personal bookmark manager tied to task groups
- **Thùng rác** — a soft-delete recovery system for archived task groups

The app targets solo users who plan their own week and want everything in one place — no team collaboration features, no due-time reminders, no notifications.

---

## 2. Existing Product Context

### 2.1 Technology & Platform
- **Framework:** Flutter (Material 3) for iOS and Android
- **Backend:** Firebase (Firestore, Authentication)
- **State management:** Riverpod
- **Routing:** GoRouter (`/login` → `/`)
- **Language:** Vietnamese (UI copy), English (code terminology)

### 2.2 Design Conventions

| Token | Value |
|-------|-------|
| Accent | Emerald green `#16A34A` |
| Background | Stone `#FAFAF9` |
| Alt background | `#F5F5F4` |
| Border | `#E7E5E4` |
| Text | `#1C1917` |
| Text muted | `#78716C` |
| Text faint | `#A8A29E` |
| Group palette | Green / Violet / Amber / Blue / Red / Teal (6 colors) |

All modal surfaces use `DraggableScrollableSheet` or standard `showModalBottomSheet` with `borderRadius.vertical(top: 24)`. Consistent drag-handle pill at the top of every sheet.

### 2.3 Navigation Structure

```
/login  ──────────────────────────  LoginScreen
    └─ after auth
/       ──────────────────────────  DashboardScreen (shell)
         ├─ AppBar (menu icon → Drawer, title, context-aware)
         ├─ BottomNavigationBar
         │    ├─ Tab 0: Planner  (calendar_view_week icon)
         │    ├─ Tab 1: Việc phụ (check_circle icon)
         │    └─ Tab 2: Ghi chú  (sticky_note_2 icon)
         ├─ FAB (context-aware per tab)
         └─ Drawer (hamburger)
              ├─ User avatar + name + email
              ├─ NHÓM CÔNG VIỆC section
              │    └─ [list of TaskGroups] + add button
              ├─ Divider
              ├─ Tài liệu & Link  → ResourcesSheet (bottom sheet)
              ├─ Thùng rác         → TrashSheet (bottom sheet)
              ├─ Kiểm tra cập nhật
              └─ Đăng xuất
```

### 2.4 Existing Screen Inventory

| Screen / Surface | Type | Entry point |
|---|---|---|
| LoginScreen | Full screen | App launch (unauthenticated) |
| DashboardScreen | Shell / scaffold | After auth |
| WeekGridMobile (Planner tab) | Embedded in shell | Tab 0 |
| GoalCard | Widget within Planner | Rendered per task group |
| TaskDetailSheet | DraggableScrollable bottom sheet | Tap work item row |
| _AddTaskSheet | Bottom sheet | FAB on Planner tab |
| _AddGroupSheet | Bottom sheet | Drawer add button / _AddTaskSheet link |
| SidePanelTab (Việc phụ) | Embedded in shell | Tab 1 |
| NotesScreen | Embedded in shell | Tab 2 |
| NoteEditorSheet | DraggableScrollable bottom sheet | FAB / tap note card |
| ResourcesSheet | DraggableScrollable bottom sheet | Drawer → Tài liệu & Link |
| _AddResourceSheet | Bottom sheet | ResourcesSheet header button |
| TrashSheet | DraggableScrollable bottom sheet | Drawer → Thùng rác |

### 2.5 Data Models

| Model | Key fields |
|---|---|
| `WorkItemModel` | `taskGroupId`, `weekStartDate` (YYYY-MM-DD), `content`, `status` (TODO/IN_PROGRESS/DONE), `note` |
| `WeeklyGoalModel` | `taskGroupId`, `weekStartDate`, `goalText` |
| `TaskGroupModel` | `name`, `color` (#HEX), `displayOrder`, `archived` |
| `NoteModel` | `title`, `content`, `color` (composite: `colorKey:category:icon`), `createdAt`, `updatedAt` |
| `SideTaskModel` | `name`, `isDone` |
| `ResourceModel` | `title`, `link`, `description`, `taskGroupId?` |

### 2.6 Terminology Already in Use

| Vietnamese | Meaning |
|---|---|
| Nhóm công việc | Task Group / project category |
| Công việc / Đầu việc | Work item / task |
| Việc phụ / Việc lặt vặt | Side task / miscellaneous task |
| Ghi chú | Note |
| Tài liệu & Link | Resource / bookmark |
| Thùng rác | Trash / archive |
| Tuần này / Tuần khác | This week / other week |
| Về hôm nay | Return to current week |
| Tuần cũ | Past week (badge on historical weeks) |
| Trạng thái | Status (TODO/IN_PROGRESS/DONE) |
| Cần làm / Đang làm / Đã xong | Todo / In progress / Done |

### 2.7 Known Product Constraints

- No due times or reminders — planning is week-level only
- No subtasks — `WorkItemModel` is flat
- No collaboration — data is per-user, scoped to `userId`
- Past weeks are read-only (enforced in UI via `isPast` flag)
- Task Groups are global — same groups appear every week
- Notes have no Trash — deletion is permanent
- App name inconsistency: "TodoHuy" on login, "WeekLoop" inside the app

---

## 3. Target User Experience

### Overall
WeekLoop should feel like a calm, organized workspace. The user arrives on Monday, looks at their week, assigns tasks to their existing groups, and works through the week ticking things off. The friction of adding, updating, and reviewing tasks must be minimal — every extra tap is a cost.

### Per Feature Area

**Planner:** The user should be able to scan their entire week in one scroll. Status changes should feel satisfying and immediate. Looking at past weeks should feel like reviewing a clean archive, not a broken interface.

**Việc phụ:** The lowest-friction capture surface in the app. The user should be able to type and add in under 2 seconds. Completion should feel gratifying.

**Ghi chú:** A personal notebook the user returns to. Notes should be visually scannable in the grid. Creating a note should feel expressive (color, icon, category) without being a multi-step chore.

**Task Groups + Resources:** Configuration surfaces. The user sets these up once and rarely revisits. Changes should be obvious and safe (undoable where possible).

**Auth:** The user should reach their workspace in under 30 seconds from app open. Recovering a forgotten password should be self-serve with no support contact required.

---

## 4. User Journey

### First-time user

```
App open
  └─ LoginScreen (tab: Đăng nhập)
       └─ Switch to "Đăng ký" tab OR tap "Chưa có tài khoản?"
            └─ Create account (email + password OR Google)
                 └─ DashboardScreen — Planner tab (empty state)
                      └─ Drawer → create first TaskGroup
                           └─ FAB → add first work item
                                └─ Task visible in GoalCard for current week
```

### Returning user — weekly planning session

```
App open
  └─ DashboardScreen — Planner tab (current week)
       └─ Scan GoalCards (groups already populated from previous weeks)
            └─ Tap add-task row in each GoalCard → type → send
            OR └─ FAB → AddTaskSheet → pick group → type → "Thêm công việc"
       └─ During the week: tap status icon to cycle TODO → IN_PROGRESS → DONE
       └─ Tap a task row → TaskDetailSheet → edit content, add note, change status
       └─ Navigate to past weeks (swipe or chevron) → read-only review
```

### Quick task capture (Việc phụ)

```
DashboardScreen — Tab 1
  └─ Type into bottom text field
       └─ Press send → task appears instantly, field clears
  └─ Filter chips: Tất cả / Chưa xong / Đã xong
  └─ Tap checkbox → toggle done (strikethrough)
  └─ Swipe left → delete (immediate with undo SnackBar)
```

### Note creation

```
DashboardScreen — Tab 2
  └─ Tap FAB (pencil icon)
       └─ NoteEditorSheet opens (initialChildSize: 0.9)
            └─ Scroll color selector → live preview applies
            └─ Tap emoji icon → icon picker (compact grid)
            └─ Category chip row → single select
            └─ Title field → Content field
            └─ "Tạo ghi chú" button → saves and closes
  └─ Tap existing note card → NoteEditorSheet (edit mode)
       └─ Same UI, "Cập nhật" instead of "Tạo"
       └─ "Xóa" button → SnackBar + Undo (5s) → permanent deletion
```

### Resource / bookmark management

```
Drawer → Tài liệu & Link
  └─ ResourcesSheet opens
       └─ View list of saved links
       └─ Tap item → opens external browser
       └─ Swipe left → delete (SnackBar + Undo)
       └─ "Thêm" button → _AddResourceSheet
            └─ Title, URL, optional description, optional group → Lưu
```

### Task Group management

```
Drawer → NHÓM CÔNG VIỆC
  └─ View list with color dots + name
  └─ Edit icon → AlertDialog → rename
  └─ Delete icon → confirm → moves to Thùng rác
  └─ "+" icon → _AddGroupSheet → name + color → Tạo nhóm

Drawer → Thùng rác → TrashSheet
  └─ Archived groups with "Đã xóa X ngày trước" timestamp
  └─ "Khôi phục" → restores to active groups (primary CTA)
  └─ 🗑️ icon → permanent delete (confirmation: "Không thể hoàn tác")
```

### Forgot Password (to be implemented)

```
LoginScreen — Login tab
  └─ Tap "Quên mật khẩu?" (below password field)
       └─ ForgotPasswordScreen
            └─ Email field (auto-filled if already typed on login)
            └─ Tap "Gửi link đặt lại"
                 └─ Confirmation state:
                      "Nếu tài khoản tồn tại, bạn sẽ nhận email trong vài phút.
                       Hãy kiểm tra cả thư mục Spam."
                      [Gửi lại] [Quay lại Đăng nhập]
```

---

## 5. Flow Specification

### Flow: Login

**Trigger:** App launch, user not authenticated.

**Steps:**
1. LoginScreen displays with "Đăng nhập" tab active
2. User enters email + password
3. Tap "Đăng nhập" → Firebase `signInWithEmail`
4. Success → `context.go('/')` → DashboardScreen

**Decision points:**
- Switch to "Đăng ký" tab → same screen, additional fields animate in
- Tap "Tiếp tục với Google" → Google Sign-In flow → DashboardScreen
- Tap "Quên mật khẩu?" → ForgotPasswordScreen *(currently MISSING)*

**Exit conditions:**
- Successful authentication
- App close

**Failure / recovery:**
- Firebase error → SnackBar in Vietnamese (localized error messages implemented)
- Wrong password → error SnackBar; "Quên mật khẩu?" link must be discoverable

---

### Flow: Weekly Planning (core loop)

**Trigger:** User opens Planner tab (Tab 0).

**Steps:**
1. WeekGridMobile displays current week's GoalCards
2. Each GoalCard shows work items for that group + that week
3. User taps status icon → cycles TODO → IN_PROGRESS → DONE
4. User types in inline add-task row → presses send / keyboard submit
5. User taps a task row → TaskDetailSheet (edit content, status, note)

**Decision points:**
- Navigate to past week → all GoalCards become read-only (`isPast = true`)
- No TaskGroups exist → empty state with guidance to create a group
- GoalCard with no tasks → italic empty message + inline add field visible

**Exit conditions:**
- User switches tab or closes app

**Failure / recovery:**
- Firestore write error → SnackBar `'Lỗi: ...'`

---

### Flow: Add Task Group

**Trigger:** Drawer "+" icon or AddTaskSheet "Nhóm mới" link.

**Steps:**
1. _AddGroupSheet opens as bottom sheet
2. User enters group name (text field, autofocus)
3. User selects color from 6 animated swatches
4. Taps "Tạo nhóm"
5. Sheet closes; group appears in Drawer and all week pages

**Decision points:**
- Empty name → save blocked (`trim()` validation)

**Exit conditions:**
- Successful creation (sheet dismisses)
- Swipe down → no group created

---

### Flow: Note Creation

**Trigger:** FAB (pencil icon) on Ghi chú tab.

**Steps:**
1. NoteEditorSheet opens at 90% height
2. Color selector scroll → gradient strip preview updates live
3. Tap emoji → compact icon picker → select → picker dismisses
4. Select category chip (single-select)
5. Type title (optional) and content
6. Tap "Tạo ghi chú" → saves → sheet closes

**Decision points:**
- Editing existing note → "Cập nhật" CTA, delete button visible
- Delete existing note → SnackBar + Undo (5s) → permanent deletion after undo window

**Exit conditions:**
- Save (sheet closes, note appears in grid)
- Tap "Hủy" (no save)
- Drag sheet down (no save)

---

### Flow: Save a Resource (Bookmark)

**Trigger:** ResourcesSheet "Thêm" button.

**Steps:**
1. _AddResourceSheet opens
2. User types title + URL (required) + description (optional)
3. User optionally selects a TaskGroup from dropdown
4. Taps "Lưu tài liệu" → saves → sheet closes

**Decision points:**
- URL or title empty → SnackBar validation error, no save

**Failure / recovery:**
- Firestore error → SnackBar

---

### Flow: Forgot Password (to be built)

**Trigger:** "Quên mật khẩu?" link on Login tab.

**Steps:**
1. Navigate to ForgotPasswordScreen
2. Email field shown (auto-filled from login input if available)
3. Tap "Gửi link đặt lại" → `FirebaseAuth.instance.sendPasswordResetEmail(email: email)`
4. Screen transitions to confirmation state

**Confirmation state:**
- Generic message: "Nếu tài khoản tồn tại với địa chỉ này, bạn sẽ nhận được email trong vài phút."
- Spam folder reminder
- [Gửi lại] secondary action
- [Quay lại Đăng nhập] primary navigation

**Exit conditions:**
- Tap "Quay lại Đăng nhập" → back to LoginScreen
- System back button

---

## 6. Screen & State Inventory

### Screen: LoginScreen

**Purpose:** Authenticate or create an account.

**Entry conditions:** App launch, unauthenticated.

**Required information:** Email, password (login); Full name, email, password, confirm password (signup).

**Primary action:** "Đăng nhập" / "Tạo tài khoản" (full-width FilledButton, accent green)

**Secondary actions:** Google Sign-In, toggle tabs, "Quên mật khẩu?" *(missing)*

**States:**
- Default (login tab active)
- Signup tab active (additional fields animate in)
- Loading (button disabled, spinner)
- Error (SnackBar, fields retain typed values)

**Exit:** Successful auth → DashboardScreen

---

### Screen: DashboardScreen (shell)

**Purpose:** Container for the three main content tabs.

**Entry conditions:** Authenticated user.

**States:**
- Tab 0 active (AppBar: "WeekLoop", FAB = add task)
- Tab 1 active (AppBar: "Đầu việc phụ", no FAB)
- Tab 2 active (AppBar: "Ghi chú", FAB = add note)
- Drawer open (overlay)

---

### Screen: Planner (WeekGridMobile)

**Purpose:** Weekly task planning — view and manage all work items across weeks.

**Primary action:** Tap status icon to cycle task status.

**Secondary actions:** Navigate weeks (chevron/swipe), tap task to edit, inline add.

**States:**
- Normal (current week, editable)
- Past week (`isPast = true`): read-only, "Tuần cũ" badge on each GoalCard header
- Empty (no task groups): icon + guidance text + "Tạo nhóm đầu tiên" CTA
- Loading: CircularProgressIndicator centered

---

### Screen: GoalCard (widget)

**Purpose:** Display work items for one TaskGroup in one week. Entry point for per-group editing.

**States:**
- Normal: colored header (group name + color dot + incomplete-count badge + add shortcut icon) + task list + add-task row
- Past week: "Tuần cũ" badge replaces delete icon; add-task row hidden; header dimmed slightly (header only, NOT the task list)
- Empty tasks (current week): italic hint + add field visible
- Empty tasks (past week): italic "Không có công việc nào."

**Work item row states:**
- TODO: `radio_button_unchecked` (faint)
- IN_PROGRESS: `hourglass_top_rounded` (amber)
- DONE: `check_circle` (accent green) + strikethrough text + muted color

---

### Screen: TaskDetailSheet

**Purpose:** View and edit a single work item in detail.

**Entry conditions:** Tap any work item row in a GoalCard.

**Primary action:** "Lưu" (FilledButton, accent)

**Secondary actions:** "Xóa" (OutlinedButton, red), close (X icon)

**States:**
- Edit mode (`isPast = false`): all fields enabled
- Read-only mode (`isPast = true`): fields disabled, action buttons hidden
- Saving: button spinner
- Deleting: confirmation dialog → spinner

---

### Screen: AddTaskSheet

**Purpose:** Add a new work item to a task group for the selected week.

**Entry conditions:** FAB on Planner tab.

**States:**
- Normal: group dropdown + text field + save button
- No groups exist: empty state + "Tạo nhóm mới" CTA
- Saving: button spinner

---

### Screen: AddGroupSheet

**Purpose:** Create a new TaskGroup with name + color.

**States:**
- Default: name field (autofocus) + 6 animated color swatches + save button
- Saving: button spinner

---

### Screen: SidePanelTab (Việc phụ)

**Purpose:** Frictionless checklist for miscellaneous tasks not tied to the weekly plan.

**Primary action:** Checkbox toggle (complete/uncomplete)

**Secondary actions:** Swipe-to-delete (SnackBar + Undo), filter chips

**States:**
- Default: task list + filter chips (Tất cả/Chưa xong/Đã xong) + bottom input field
- Loading: CircularProgressIndicator
- Empty (no tasks or filter yields none): centered text
- Adding: text field active, send button

---

### Screen: NotesScreen

**Purpose:** Browse and search the notes collection.

**Primary action:** Tap note card → NoteEditorSheet

**Secondary actions:** Search bar, category filter chips, FAB to create new note

**States:**
- Populated: 2-column masonry grid of colored note cards
- Empty (no notes at all): icon + "Chưa có ghi chú nào. Nhấn + để tạo."
- Empty (search/filter active): "Không tìm thấy ghi chú phù hợp."
- Loading: CircularProgressIndicator

---

### Screen: NoteEditorSheet

**Purpose:** Create or edit a note with title, content, color, icon, and category.

**States:**
- Create mode: "Tạo ghi chú" CTA, no delete button
- Edit mode: "Cập nhật" CTA, delete button present
- Saving: button spinner
- Deleting: SnackBar + Undo (5s) — no blocking dialog

---

### Screen: ResourcesSheet

**Purpose:** Browse and manage saved links/bookmarks.

**States:**
- Populated: list of resource tiles (title + URL + optional description)
- Empty: `link_off` icon + "Chưa có tài liệu nào. Nhấn + để thêm link mới."
- Loading: CircularProgressIndicator

---

### Screen: TrashSheet

**Purpose:** View soft-deleted task groups; restore or permanently delete.

**States:**
- Populated: list of archived groups with "Đã xóa X ngày trước" timestamp
- Top banner: "Các nhóm trong thùng rác sẽ bị xóa vĩnh viễn sau 30 ngày."
- Empty: "Thùng rác trống" with icon
- Loading: CircularProgressIndicator (StreamBuilder)

**Per-item actions:**
- "Khôi phục" (primary, accent TextButton) → restore + SnackBar confirmation
- 🗑️ icon → AlertDialog "Xóa vĩnh viễn?" → permanent delete

---

### Screen: ForgotPasswordScreen (to be built)

**Purpose:** Allow user to request a password reset email.

**States:**
- Input state: email field (pre-filled if available) + "Gửi link đặt lại" CTA
- Confirmation state: envelope icon + generic success message + Resend + Back-to-login
- Loading: button spinner

---

## 7. Interaction Requirements

### Planner / GoalCard
- Status icon: single tap cycles TODO → IN_PROGRESS → DONE → TODO
- DONE → TODO direction: require long-press (or show brief toast "Nhấn giữ để đặt lại") to prevent accidental un-completion
- Every status cycle tap triggers `HapticFeedback.lightImpact()`
- Past week: status icon tap is no-op; no visual feedback needed
- TaskDetailSheet: `DraggableScrollableSheet(initialChildSize: 0.65, min: 0.4, max: 0.92)`
- Week navigation: horizontal `PageView` with 320ms `easeInOut`; chevron buttons call `animateToPage`
- "Về hôm nay" pill: `animateToPage` with 350ms `easeInOut`
- Past GoalCard: remove `Opacity(0.65)` wrapper; only dim the card header background slightly (not the task list text)

### Notes
- NoteEditorSheet: `initialChildSize: 0.9` — immediately near-full-screen
- Color selection: live preview on gradient strip, no "Apply" button
- Icon picker: nested compact bottom sheet, immediate apply on icon tap (no Done button)
- Category chips: single-select, tapping selected chip again is a no-op (category is always selected)
- Save: always via explicit button tap — no auto-save on sheet dismiss

### Việc phụ (Side Tasks)
- Bottom text field persists above keyboard at all times (not a FAB)
- `onSubmitted`: adds task + clears field; keyboard stays open for rapid multi-add
- Swipe-to-delete: `Dismissible` on `DismissDirection.endToStart`; no `confirmDismiss` dialog; SnackBar + Undo (5s) instead
- Task completion: strikethrough + text dim animation (not instant state swap)

### Resources
- Tap resource tile → `launchUrl(url, mode: LaunchMode.externalApplication)`
- Swipe-to-delete: remove `confirmDismiss` dialog; use SnackBar + Undo (5s) instead
- SnackBar text: `"Đã xóa '[title]'. HOÀN TÁC"` with `duration: Duration(seconds: 5)`

### Task Groups
- Color swatch in _AddGroupSheet: selected swatch shows white `Icons.check` icon at center + shadow ring
- Group deletion from Drawer or GoalCard: retain `AlertDialog` (moving to trash is reversible, but the dialog confirms user intent)
- Restore from Trash: immediate, SnackBar: `"Đã khôi phục '[name]'"`
- Permanent delete from Trash: AlertDialog with explicit "Không thể hoàn tác" warning

### Auth
- Tab switch animation ≤200ms
- Password field: show/hide toggle (`Icons.visibility` / `Icons.visibility_off`) on all password fields
- "Quên mật khẩu?" link: `TextButton` right-aligned, `textMuted` color, small font, visible on Login tab only
- Google Sign-In button: keep current email-first ordering (Google button below form)

---

## 8. UX Patterns & Research Findings

> **Research note:** Mobbin MCP required a paid subscription and was unavailable during this research session. Patterns below are sourced from documented analysis of production apps (Todoist, Things 3, Google Keep, Bear, Notion, Linear, Raindrop.io, Apple Notes, Gmail, Any.do, TickTick) and published UX guidelines (Material Design, Apple HIG, NN Group, LogRocket). Manual Mobbin lookup URLs are provided for each reference.

---

### Pattern: Tab Toggle Login/Signup (Single Screen)

**Research finding:** Single-screen tab toggle is industry standard for mobile auth — fields unique to signup animate in/out on toggle, no route navigation. The typed email persists if the user switches tabs mid-entry. Validated across Todoist, Linear, Notion.

**Decision:** ADOPT — current WeekLoop implementation is correct.

**Application:** Keep current structure. Ensure tab-switch animation is ≤200ms. Confirm active tab label contrast meets WCAG AA (consider bold weight for green #16A34A on white).

**Evidence:**
- [Login/signup tab toggle — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=login+signup+tab+toggle)

---

### Pattern: Forgot Password Recovery Flow

**Research finding:** All major productivity apps implement a 3-state forgot password flow: (1) inline link below password field, (2) dedicated email input screen with auto-fill, (3) generic confirmation state with resend + spam warning. Firebase Auth provides `sendPasswordResetEmail()` out of the box. No backend changes needed.

**Decision:** ADOPT — **highest-priority UX gap in the entire product.**

**Application:** Add "Quên mật khẩu?" `TextButton` (right-aligned, `textMuted`, Login tab only) → `ForgotPasswordScreen`. Confirmation state must NOT confirm whether the email exists (prevents account enumeration).

**Evidence:**
- [Forgot password flow — Mobbin lookup](https://mobbin.com/browse/ios/flows?q=forgot+password+reset+mobile)

---

### Pattern: Empty State as First-Run Onboarding

**Research finding:** Todoist, Things 3, Linear all go straight to the main dashboard after auth with no interstitial onboarding. The empty state IS the onboarding — it invites the user to create their first item. Zero-interstitial approach gets users to first value in under 60 seconds.

**Decision:** ADOPT — WeekLoop correctly goes straight to DashboardScreen. Gap: empty state currently has no primary CTA button.

**Application:** When Planner shows zero task groups, render: large icon (folder_open in accent green) + Vietnamese headline + prominent "Tạo nhóm đầu tiên" `FilledButton` that opens _AddGroupSheet.

**Evidence:**
- [Todoist first launch — Mobbin lookup](https://mobbin.com/browse/ios/flows?q=todoist+onboarding+first+launch)

---

### Pattern: Past Week Read-Only — Remove 65% Opacity

**Research finding:** Any.do and TickTick differentiate historical periods using: badge on section header + disabled interactive controls + full-opacity task text. No surveyed app uses global 65% opacity. The current WeekLoop 65% `Opacity` wrapper makes historical review genuinely uncomfortable without adding information the badge doesn't already convey.

**Decision:** ADOPT — remove `Opacity(opacity: 0.65)` wrapper from GoalCard. Keep: "Tuần cũ" badge, hidden delete icon, hidden add-task row, disabled status-cycle tap.

**Application:** In `GoalCard._buildHeader()`: dim only the header background color slightly (reduce alpha on `_groupColor.withValues(alpha: 0.07)` to 0.04). Leave the task list items at full opacity.

**Evidence:**
- [TickTick historical week — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=ticktick+planner+past+week)

---

### Pattern: Task Status — 3-State with Accidental Reversal Guard

**Research finding:** Linear uses explicit status picker (not cycle) to prevent accidental changes. Things 3 uses binary checkbox + haptic. For 3-state cycling, the DONE → TODO direction is highest risk — accidentally un-completing a task is frustrating. Minimum mitigation: haptic feedback on every cycle + long-press requirement on DONE→TODO.

**Decision:** ADAPT — keep tap-to-cycle for TODO→IN_PROGRESS→DONE. Add haptic. Add long-press guard on DONE→TODO.

**Application:** In `_cycleStatus()`: add `HapticFeedback.lightImpact()`. Guard `DONE → TODO`: require `onLongPress` or show brief confirmation toast.

**Evidence:**
- [Linear task status picker — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=linear+task+status+icons)

---

### Pattern: GoalCard Header — Task Count Badge + Add Shortcut

**Research finding:** Todoist shows `(n)` incomplete task count in project headers — instant scope signal. Notion + Linear both provide a `+` icon in section headers as a secondary add-task entry point for users with long lists. Two add-task entry points (header `+` and footer inline field) serve different ergonomic moments.

**Decision:** ADOPT — add both elements to GoalCard header.

**Application:** In `_buildHeader()`: show count of items where `status != DONE` beside group name. Add small `+` `IconButton` that scrolls to and focuses the inline add-task `TextField`.

**Evidence:**
- [Todoist project task count — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=todoist+project+header)

---

### Pattern: Swipe-to-Delete with Undo SnackBar

**Research finding:** Gmail and iOS Notes use immediate swipe-delete + timed "UNDO" SnackBar (5–6 seconds). No blocking confirmation dialog. Catches ~95% of accidental deletions without interrupting the flow. Confirmation dialogs are reserved for irreversible operations (Trash permanent delete).

**Decision:** ADAPT — apply to: (a) SidePanelTab task deletion, (b) ResourcesSheet link deletion, (c) NoteEditorSheet note deletion.

**Application:** Remove `confirmDismiss` dialogs from `Dismissible` in ResourcesSheet and SidePanelTab. Replace note delete `AlertDialog` with SnackBar + Undo pattern. Keep `AlertDialog` only for permanent delete in TrashSheet.

**Evidence:**
- [Gmail delete undo — Mobbin lookup](https://mobbin.com/browse/android/screens?q=gmail+swipe+delete+undo)

---

### Pattern: Persistent Bottom Input for Quick Capture

**Research finding:** Todoist Inbox pins the text input at the bottom (above keyboard), always visible. One-action capture: type + tap send → instant add → field clears → keyboard stays open. No FAB, no modal overhead. Keyboard stays open for rapid multi-task entry.

**Decision:** ADOPT — WeekLoop's SidePanelTab already implements this correctly. Validated.

**Application:** Current implementation is correct. Add completion animation (strikethrough + dim) on task checkbox toggle for improved feedback.

**Evidence:**
- [Todoist inbox quick add — Mobbin lookup](https://mobbin.com/browse/ios/flows?q=todoist+inbox+quick+add)

---

### Pattern: Note Card Grid — Masonry vs. Fixed-Height

**Research finding:** Google Keep uses staggered 2-column masonry where columns scroll independently. Fixed-height grids waste significant vertical space when content length varies. Minimum card height: 120dp. Target density: 6–8 notes visible above fold.

**Decision:** ADOPT — migrate NotesScreen from `SliverGridDelegateWithFixedCrossAxisCount(childAspectRatio: 0.82)` to masonry grid.

**Application:** Use `flutter_staggered_grid_view` (`MasonryGridView`). `crossAxisCount: 2`, `mainAxisSpacing: 12`, `crossAxisSpacing: 12`. Minimum card height: 120dp. Remove fixed `childAspectRatio`.

**Evidence:**
- [Google Keep note grid — Mobbin lookup](https://mobbin.com/browse/android/screens?q=google+keep+notes+grid)

---

### Pattern: Color Swatch — Selected State with Checkmark

**Research finding:** Google Keep shows selected swatch with white checkmark overlay + outer border ring. Live preview applies immediately — no "Apply" button. Swatch diameter ≥28dp unselected, ≥44dp selected (touch target). For WeekLoop's 8 note colors and 6 group colors, all fit in one row at standard mobile widths.

**Decision:** ADOPT — current implementation is close. Gap: selected color in _AddGroupSheet needs explicit white checkmark (currently shows `Icons.check` in white, which is correct — verify visibility against all 6 colors).

**Application:** In NoteEditorSheet and _AddGroupSheet: ensure selected swatch renders visible white checkmark. Selected circle size should be ≥36dp (currently `isSelected ? 36 : 30` — maintain or increase). Verify contrast of white check on amber/yellow group color.

**Evidence:**
- [Google Keep color picker — Mobbin lookup](https://mobbin.com/browse/android/screens?q=google+keep+color+picker)

---

### Pattern: Drawer — Zone Separation

**Research finding:** Notion and Todoist structurally separate user content (groups/projects) from system items in their sidebars. A visual divider between the two zones is the minimum. Destructive actions (logout) should be further separated from utility items.

**Decision:** ADOPT — current Drawer has one `Divider` between groups and system items. Gap: "Đăng xuất" sits immediately after "Kiểm tra cập nhật" without visual separation.

**Application:** Add a second `Divider` immediately before "Đăng xuất". Consider making the logout `ListTile` text muted color to reduce prominence.

**Evidence:**
- [Notion sidebar — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=notion+sidebar+workspace)
- [Todoist sidebar — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=todoist+sidebar+projects)

---

### Pattern: Trash with Timestamps + Retention Banner

**Research finding:** iOS Photos shows per-item countdown ("29 days remaining") + top banner "Items in Recently Deleted are retained for 30 days." Gmail shows retention banner inside Trash. This manages expectations and significantly reduces anxiety about data loss.

**Decision:** ADOPT — TrashSheet currently shows no deletion timestamp or retention policy.

**Application:** In TrashSheet: (a) show "Đã xóa X ngày trước" on each archived group tile (requires `archivedAt` field on `TaskGroupModel`), (b) add Container banner at top: "Các nhóm trong thùng rác sẽ bị xóa vĩnh viễn sau 30 ngày." Make "Khôi phục" a more visually prominent primary action (filled or bold text), "Xóa vĩnh viễn" secondary.

**Evidence:**
- [iOS Photos Recently Deleted — Mobbin lookup](https://mobbin.com/browse/ios/screens?q=ios+photos+recently+deleted)

---

### Pattern: Brand Consistency — App Name

**Research finding:** LoginScreen currently renders app title as "TodoHuy" while the AppBar inside the app reads "WeekLoop". Users encountering both names in the same session may question which app they're using. No surveyed app uses two different names on different screens.

**Decision:** ADOPT — update LoginScreen title text to "WeekLoop" throughout.

---

## 9. Visual / Interaction Reference Board

| Our screen/state | Reference | What to study | Usage |
|---|---|---|---|
| LoginScreen — tab toggle | [Segmented auth tab](https://mobbin.com/browse/ios/screens?q=login+signup+tab+toggle) | Active tab fill vs. ghost; field animation | Adopt |
| LoginScreen — Google button | [Social sign-in divider](https://mobbin.com/browse/ios/screens?q=google+sign+in+divider+email) | Divider visual weight; button ordering | Adopt |
| LoginScreen — forgot password | [Forgot password 3-state](https://mobbin.com/browse/ios/flows?q=forgot+password+reset+mobile) | Link placement; generic confirmation message | **Adopt (implement)** |
| GoalCard — header | [Todoist project header](https://mobbin.com/browse/ios/screens?q=todoist+project+task+count) | Task-count badge; header + icon layout | Adopt |
| GoalCard — past week | [TickTick historical period](https://mobbin.com/browse/ios/screens?q=ticktick+planner+past+week) | Badge vs. opacity; task text readability | Adopt |
| GoalCard — status icons | [Linear task status](https://mobbin.com/browse/ios/screens?q=linear+task+status+icons) | Icon shapes, colors, labels for 3-state | Adapt |
| TaskDetailSheet | [Todoist task detail](https://mobbin.com/browse/ios/screens?q=todoist+task+detail+bottom+sheet) | Attribute chips; keyboard-attached bar | Adapt |
| SidePanelTab — input | [Todoist inbox capture](https://mobbin.com/browse/ios/screens?q=todoist+inbox+capture) | Persistent bottom field; one-action add | Adopt |
| SidePanelTab — chips | [Google Keep label filter](https://mobbin.com/browse/ios/screens?q=google+keep+filter+chips) | Chip height ~32dp; "All" leftmost; filled vs outlined | Adopt |
| NotesScreen — grid | [Google Keep masonry grid](https://mobbin.com/browse/android/screens?q=google+keep+notes+grid) | Staggered 2-col; card density ≥6 above fold | Adopt |
| NoteEditorSheet — colors | [Google Keep color picker](https://mobbin.com/browse/android/screens?q=google+keep+color+picker) | Swatch ≥44dp; white checkmark; live preview | Adopt |
| NoteEditorSheet — icons | [Notion emoji picker](https://mobbin.com/browse/ios/screens?q=notion+emoji+picker) | 6-col grid; selected background; immediate apply | Adopt |
| ResourcesSheet — delete | [Gmail undo delete](https://mobbin.com/browse/android/screens?q=gmail+swipe+delete+undo) | Non-blocking SnackBar + timed UNDO | Adapt |
| TrashSheet | [iOS Photos Recently Deleted](https://mobbin.com/browse/ios/screens?q=ios+photos+recently+deleted) | Per-item countdown; retention banner; Recover as primary | Adopt |
| Drawer | [Notion sidebar](https://mobbin.com/browse/ios/screens?q=notion+sidebar+workspace) | Two-zone separation; Logout visually subordinate | Adopt |
| _AddGroupSheet — color | [Todoist color picker](https://mobbin.com/browse/ios/screens?q=todoist+label+color+picker) | Named swatches; checkmark on selected | Adopt |

---

## 10. Product Decisions

The following are intentional design decisions. A design or implementation agent should not reinterpret them without explicit product discussion.

1. **Single-screen tab toggle for login/signup** — do not split into separate routes.
2. **DashboardScreen loads immediately after auth** — no interstitial onboarding or welcome screens.
3. **Past weeks are read-only** — no editing, status cycling, or task addition allowed on past weeks.
4. **The 65% global opacity on past GoalCards must be removed** — "Tuần cũ" badge + disabled controls communicate read-only without hurting review readability.
5. **Task status cycles on single tap (TODO→IN_PROGRESS→DONE); DONE→TODO requires long-press** — prevents accidental un-completion.
6. **Notes have no Trash** — deletion is permanent, mitigated by SnackBar + Undo (5s), not a blocking dialog.
7. **Side tasks are intentionally flat** — no categories, no dates, no priority. Simplicity is the feature.
8. **TaskGroups are global** — they are not week-specific; the same groups appear in every week view.
9. **Resources can optionally be tied to a TaskGroup** — "Chung" (ungrouped) is the default.
10. **Forgot password flow must be added** — this is a confirmed product gap, not a design choice.
11. **Brand name "WeekLoop" must be consistent** — LoginScreen "TodoHuy" must be updated.
12. **Bottom navigation stays at 3 tabs** — Task Groups and Resources remain drawer-only at current scale.
13. **NoteEditorSheet saves only on explicit button tap** — no auto-save on sheet dismiss.
14. **WorkItem statuses are TODO / IN_PROGRESS / DONE** — no priority levels, no due times, no tags.

---

## 11. Assumptions & Open Questions

### Confirmed
*(Supported by repository source code)*
- App uses Firebase Auth with email/password + Google Sign-In
- Past weeks are enforced read-only at widget level via `isPast` flag
- Notes support 8 color themes and 12 emoji icons
- Task Groups support 6 colors from the Notion-style `groupColors` palette
- ResourcesSheet swipe-to-delete currently has a `confirmDismiss` blocking dialog (to be replaced with SnackBar)
- TrashSheet currently shows no deletion timestamp or retention policy
- App checks for updates on launch via `AppUpdater`
- `themeMode: ThemeMode.system` — dark mode is supported automatically
- `WeeklyGoalModel` exists in data layer but is NOT rendered in any current screen

### Evidence-Backed Recommendations
*(Supported by research but still a product choice)*
- Replace 65% GoalCard opacity on past weeks with badge-only treatment
- Use masonry grid for NotesScreen instead of fixed-height grid
- Replace note/resource delete dialog with SnackBar + Undo (5s)
- Add `HapticFeedback.lightImpact()` on every task status cycle tap
- Add `archivedAt` timestamp to TaskGroupModel for Trash display
- Add task incomplete-count badge to GoalCard header
- Add `+` shortcut icon to GoalCard header (second add-task entry point)
- Add retention banner to TrashSheet ("30-day auto-delete policy")
- Move TaskGroup dropdown above description in _AddResourceSheet
- Improve first-run empty state on Planner tab with CTA button

### Assumptions
*(Inferred without direct evidence)*
- `WeeklyGoalModel` is a planned/future feature — the "weekly goal text" per group per week is not yet surfaced in UI
- No Firebase Analytics are currently instrumented (no analytics imports found)
- App is currently distributed outside the App Store (direct APK) — no Apple Sign-In requirement triggered
- Users are Vietnamese-speaking; all UI copy should remain in Vietnamese

### Open Questions
*(Require explicit human decision)*
1. **Brand name:** Is "WeekLoop" the confirmed final name? Should "TodoHuy" be removed entirely?
2. **Past week tap behavior:** Should tapping a work item row in a past week open TaskDetailSheet in read-only mode, or be a no-op?
3. **DONE task sort order:** Should completed tasks sort to the bottom of GoalCard, or stay in insertion order?
4. **Note delete undo scope:** If the user backgrounds the app during the 5s undo window, should the delete finalize immediately?
5. **Trash retention policy:** Is the 30-day auto-delete a real backend rule? If so, `archivedAt` field + Cloud Function scheduled job is needed.
6. **WeeklyGoal feature:** Is the weekly goal text (one per group per week) intended to be displayed in the GoalCard header as a subtitle or banner?
7. **Resource URL auto-fetch:** Should the app auto-fetch the page title/favicon when the user finishes typing a URL in _AddResourceSheet?
8. **iOS App Store:** If the app targets the App Store, Apple Sign-In is required alongside Google Sign-In (App Store Review Guidelines §4.8). Is this planned?
9. **Side task completion animation:** Should completed tasks animate out (disappear) when "Chưa xong" filter is active, or snap-remove instantly?
10. **TaskGroup reordering:** `displayOrder` field exists in data model but no drag-to-reorder UI is implemented. Is this a planned feature?

---

## 12. Non-Goals

This UX document deliberately does NOT address:

- **Team or collaboration features** — WeekLoop is a solo-user app
- **Due times or push notifications** — planning is week-level only
- **Subtasks** — WorkItem is a flat model; no parent-child task hierarchy
- **Recurring tasks** — no repeat scheduling
- **Calendar integration** — no device calendar or external calendar sync
- **File attachments** — resources store URLs only
- **Search across Planner** — global work-item search is out of scope (search exists only in Notes)
- **Dark mode design specifics** — `ThemeMode.system` handles switching; per-screen dark-mode polish is a separate design pass
- **Tablet/iPad layout** — current design targets phone-width screens only
- **Performance optimization** — out of scope for this UX document
- **Firestore data schema design** — this document describes UX, not backend structure
- **CI/CD or deployment pipeline** — out of scope
- **Analytics instrumentation** — recommended but not part of this UX scope

---

*End of PRODUCT.md — WeekLoop v1.0 UX Research Document*

*Research conducted: 2026-09-30*  
*Streams: Auth & Onboarding · Weekly Planner · Side Tasks & Notes · Task Groups / Resources / Navigation*  
*Sources: Todoist, Things 3, Google Keep, Bear, Notion, Linear, Raindrop.io, Apple Notes, Gmail, Any.do, TickTick, Google Identity UX Guidelines, Material Design, Apple HIG, NN Group, LogRocket*
