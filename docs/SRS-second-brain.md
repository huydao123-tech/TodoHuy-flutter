# SRS: Bộ não thứ 2 (thay cho tab Ghi chú)

| | |
|---|---|
| Phiên bản tài liệu | 0.2 (viết lại toàn bộ, thay bản 0.1) |
| Ngày | 2026-10-16 |
| App | WeekLoop (`todohuy`), hiện tại v1.3.0+5 |
| Ràng buộc | **Không dùng AI, không backend mới.** Mọi xử lý chạy trên máy, dữ liệu vẫn nằm ở Firestore như hiện tại |

---

## 1. Bộ não này dùng để làm gì

Đây không phải chỗ cất ghi chú. Nó **gánh thay hai việc mà não ADHD làm kém**:

| Vấn đề | Não ADHD | Bộ não thứ 2 làm thay |
|---|---|---|
| **Bị cắt ngang là mất mạch** | Trí nhớ làm việc rơi mất ngay khi chuyển sự chú ý. Quay lại phải "khởi động lạnh": đang làm gì? nghĩ tới đâu? định làm gì tiếp? | Giữ **mạch suy nghĩ** của từng việc, ghi lại **chỗ dừng**. Lúc quay lại, app đưa đúng ngữ cảnh đó ra trước mặt |
| **Ý tưởng bị chìm** | Không thấy là quên (thiếu object permanence). Ghi rồi không bao giờ gặp lại, nên ý mới không nối được với ý cũ | Tự **nối ý mới với ý cũ** ngay lúc đang viết, và đưa ý cũ quay lại **đúng lúc nó liên quan**, không đợi người dùng đi tìm |

**Không làm:** chọn việc hộ, chia nhỏ việc, quản lý thời gian/năng lượng, thông báo đẩy, AI. Cũng không thêm bước tổ chức hay trang trí nào. Người dùng tự lưu và tự sắp xếp, app không can thiệp vào phần đó.

---

## 2. Khái niệm

| Khái niệm | Định nghĩa |
|---|---|
| **Mạch** (thread) | Dòng suy nghĩ về **một việc** đang theo đuổi, ví dụ "Sửa bug đăng nhập", "Ý tưởng app học từ vựng", "Chuyển nhà". Mạch là một chuỗi các mảnh theo thời gian, đọc như đang nhắn tin với chính mình |
| **Mảnh** (fragment) | Một ý ngắn: một suy nghĩ, một phát hiện, một quyết định. Mảnh nằm trong một mạch, hoặc đứng rời nếu chưa thuộc mạch nào |
| **Chỗ dừng** (stop point) | Một mảnh đặc biệt ghi lại *"đang làm gì"* và *"bước tiếp theo"* tại thời điểm rời mạch |
| **Lạc đề** (sidetrack) | Một ý nảy ra giữa chừng nhưng không thuộc mạch đang viết. Lưu ngay để khỏi quên, nhưng **không làm lệch mạch** |
| **Liên kết** | Quan hệ giữa hai mảnh mà app **tự tìm ra** bằng độ trùng từ khóa. Người dùng có thể nối tay thêm |

Trạng thái của mạch: `active` (đang làm) → `parked` (tạm dừng, có chỗ dừng) → `done` / `dropped`.

---

## 3. Trụ cột A: Giữ mạch (MCH)

### 3.1 Luồng chính

```
Đang viết trong mạch "Sửa bug đăng nhập"
  └─ bị gọi đi họp → bấm [Dừng ở đây]
       └─ sheet 2 dòng: "Đang làm:" ___  "Bước tiếp:" ___   (có thể bỏ trống cả hai)
            └─ mạch chuyển sang parked
...2 ngày sau, mở app
  └─ thẻ "Bạn đang dở" ở đầu tab:
       Sửa bug đăng nhập · dừng 2 ngày trước
       Đang làm: nghi do refresh token hết hạn
       Bước tiếp: log thời điểm gọi refreshToken()
       [Tiếp tục]
  └─ bấm Tiếp tục → mở mạch, cuộn tới chỗ dừng, ô nhập sẵn sàng
```

### 3.2 Yêu cầu

| ID | Ưu tiên | Yêu cầu | Tiêu chí chấp nhận |
|---|---|---|---|
| MCH-01 | M | Tạo mạch chỉ cần **một tên** | Tạo xong là vào thẳng màn hình mạch, ô nhập có sẵn con trỏ |
| MCH-02 | M | Màn hình mạch dạng dòng thời gian: các mảnh xếp từ cũ tới mới, ô nhập cố định ở đáy | Gửi xong mảnh mới hiện ngay, bàn phím vẫn mở. Mảnh hiện giờ tạo. Hai mảnh cách nhau > 6 tiếng thì chèn vạch ngày ("Thứ Ba, 14/10") để thấy rõ khoảng đứt |
| MCH-03 | M | Nút **[Dừng ở đây]** trên thanh tiêu đề mạch | Mở sheet có 2 ô ("Đang làm", "Bước tiếp"). Cả hai đều không bắt buộc. Lưu → tạo mảnh `kind=stop`, mạch chuyển `parked` |
| MCH-04 | M | Rời mạch đang `active` mà không bấm Dừng (back, chuyển tab, tắt app) | Mạch vẫn được tính là "đang dở". Chỗ dừng tự lấy là **mảnh cuối cùng** (không có "Bước tiếp") |
| MCH-05 | M | Thẻ **"Bạn đang dở"** ở đầu tab Bộ não | Hiện các mạch `active`/`parked`, sắp theo lần chạm gần nhất, tối đa 3 thẻ đầy đủ (phần còn lại thu gọn thành "+N mạch khác"). Mỗi thẻ có: tên mạch, thời gian kể từ lần chạm cuối (dạng tương đối), "Đang làm", "Bước tiếp", nút [Tiếp tục] |
| MCH-06 | M | Bấm [Tiếp tục] | Mở mạch, cuộn tới chỗ dừng và **làm nổi** nó trong 2 giây. Mạch chuyển lại `active` |
| MCH-07 | M | **Lạc đề**: nhấn giữ nút gửi (hoặc bật công tắc "↗ Lạc đề" cạnh ô nhập) | Mảnh được lưu với `kind=sidetrack` và **không hiện trong dòng chính của mạch**, chỉ hiện ở ngăn "Lạc đề (N)" trong mạch đó và trong danh sách mảnh rời. Có SnackBar "Đã cất, quay lại việc chính" |
| MCH-08 | M | Biến một mảnh lạc đề thành mạch mới | Nhấn giữ mảnh → "Mở mạch mới từ đây" → mạch mới có mảnh này là mảnh đầu, đồng thời giữ liên kết với mạch gốc |
| MCH-09 | M | Đóng mạch: [Xong] hoặc [Bỏ] | Mạch biến khỏi "Bạn đang dở" nhưng vẫn tìm thấy được, và mảnh của nó vẫn tham gia nối ý (trụ cột B) |
| MCH-10 | S | Nối mạch với **công việc trong Planner** | Trong TaskDetailSheet có nút "Mở mạch" (tạo mới hoặc mở mạch đã gắn). Công việc có mạch thì hiện icon nhỏ ở dòng công việc trong GoalCard. Công việc đã chuyển sang tuần mới thì mạch vẫn đi theo |
| MCH-11 | S | **Banner tiếp tục** khi mở app | Mở app (cold start hoặc quay lại sau > 30 phút) mà có mạch `parked` được chạm trong 7 ngày gần đây → hiện banner mỏng trên mọi tab: "Tiếp tục: <tên mạch> →". Đóng được, mỗi phiên chỉ hiện 1 lần |
| MCH-12 | C | Thêm mảnh vào một mạch từ ngoài màn hình mạch | Nhấn giữ thẻ "Bạn đang dở" → ô nhập nhanh → thêm mảnh mà không cần mở mạch |

---

## 4. Trụ cột B: Không để ý bị chìm (NOI)

Cơ chế: **app tự đưa ý cũ ra khi chúng liên quan tới thứ đang làm**. Có ba thời điểm làm việc này:

1. **Khi đang viết**: gõ một mảnh mới thì hiện các mảnh cũ có liên quan.
2. **Khi mở một mạch hoặc một công việc**: hiện các ý cũ liên quan tới mạch/công việc đó.
3. **Mỗi ngày một lần**: đưa ra 1 ý cũ lâu không gặp lại.

### 4.1 Yêu cầu

| ID | Ưu tiên | Yêu cầu | Tiêu chí chấp nhận |
|---|---|---|---|
| NOI-01 | M | **Gợi ý khi đang viết**: gõ trong ô nhập (≥ 3 từ có nghĩa, ngừng gõ 600ms) | Hiện tối đa 3 mảnh cũ liên quan thành một dải mỏng phía trên ô nhập, dạng "💭 Bạn từng ghi: …". Không lấy mảnh trong cùng mạch và trong vòng 24h. Không có gì liên quan thì không hiện gì cả, không để chỗ trống |
| NOI-02 | M | Mỗi gợi ý hiện **lý do liên quan** | Hiện những từ trùng, ví dụ "trùng: *refresh token*, *đăng nhập*", để người dùng hiểu vì sao app gợi ý mảnh này |
| NOI-03 | M | Thao tác với gợi ý | Chạm → xem nhanh mảnh (bottom sheet) và mạch chứa nó. **[Nối]** → lưu liên kết cố định giữa hai mảnh. **[×]** → ẩn cặp này vĩnh viễn |
| NOI-04 | M | Ngăn **"Liên quan"** trong màn hình mạch | Liệt kê tối đa 5 mảnh/mạch khác liên quan tới *toàn bộ* mạch này (tính trên gộp nội dung mạch), cộng thêm các liên kết người dùng đã nối tay |
| NOI-05 | M | Thẻ **"Nhớ lại"** ở tab Bộ não, mỗi ngày 1 mảnh | Chọn mảnh ≥ 14 ngày chưa được hiện lại, ưu tiên mảnh lạc đề và mảnh rời (dễ chìm nhất). Kết quả cố định trong cả ngày (seed theo ngày). Có 3 nút: **[Đưa vào mạch…]** (chọn mạch) / **[Mở mạch mới]** / **[Thôi, buông]** (mảnh không bao giờ được chọn lại ở thẻ này) |
| NOI-06 | S | Gợi ý ở **Planner** | Mở TaskDetailSheet thì dưới phần ghi chú có dòng "Bộ não có 2 ý liên quan", chạm vào để xem. Tính trên nội dung + ghi chú của công việc |
| NOI-07 | M | Tìm kiếm toàn bộ mảnh và mạch | Không phân biệt dấu ("hop" khớp "họp", "d" khớp "đ"). Kết quả nhóm theo mạch |
| NOI-08 | S | Màn hình mảnh hiện "Được nối với" | Gồm liên kết nối tay và liên kết tự động ≥ ngưỡng. Chạm vào để nhảy sang mảnh đó |

### 4.2 Thuật toán liên quan (không dùng AI)

Chạy hoàn toàn trên máy, trên dữ liệu đã có sẵn trong stream Firestore:

1. **Tách từ tiếng Việt:** chuẩn hóa Unicode NFC, chuyển chữ thường, bỏ dấu câu. Tách theo âm tiết, sau đó tạo **bigram âm tiết** ("refresh token", "đăng nhập") vì từ tiếng Việt thường gồm 2 âm tiết. Bỏ stopword (danh sách cố định khoảng 150 từ: "là", "thì", "mà", "của", "cái", "được", "này"…). **Giữ dấu khi so khớp** (vì "bàn"/"bạn"/"bán" khác nhau), chỉ bỏ dấu cho tìm kiếm.
2. **Đánh trọng số TF-IDF** trên toàn bộ mảnh của người dùng. Bigram nhân trọng số ×1.5.
3. **Cosine similarity** giữa vector của văn bản đang gõ (hoặc mạch) và từng mảnh. Ngưỡng hiện gợi ý là 0.18 (tinh chỉnh trong lúc dùng thử). Mảnh có liên kết nối tay được cộng điểm.
4. **Hiệu năng:** chỉ mục (vector thưa) được dựng lại trong `Isolate` mỗi khi stream đổi, có cache. Mục tiêu là truy vấn < 50ms với 3.000 mảnh trên máy tầm trung.
5. **Lý do liên quan (NOI-02)** là 2–3 từ/bigram đóng góp điểm cao nhất.

Logic này là hàm thuần trong `domain/`, không phụ thuộc Flutter, và được unit test đầy đủ.

---

## 5. Màn hình

**Tab 2 – "Bộ não"** (thay cho "Ghi chú", vẫn giữ 3 tab):
```
[ 🔍 Tìm trong bộ não...                     ]
── Bạn đang dở ─────────────────────────────
 ┌ Sửa bug đăng nhập · 2 ngày trước        ┐
 │ Đang làm: nghi do refresh token…        │
 │ Bước tiếp: log thời điểm gọi…  [Tiếp tục]│
 └──────────────────────────────────────────┘
 ┌ Ý tưởng app từ vựng · 5 giờ trước  …     ┐
── Nhớ lại ─────────────────────────────────
 💭 "Dùng spaced repetition cho flashcard…" (23 ngày trước)
    [Đưa vào mạch…] [Mở mạch mới] [Thôi, buông]
── Tất cả mạch ──  (đã xong/bỏ thu gọn ở cuối)
── Mảnh rời ──
[ Ghi một ý…                           ➤ ]   ← mảnh rời, gợi ý NOI-01 vẫn chạy
FAB: + Mạch mới
```

**Màn hình mạch** (route đầy đủ, không dùng bottom sheet, vì đây là nơi làm việc chính):
```
← Sửa bug đăng nhập        [Dừng ở đây] ⋯
   Liên quan (3) · Lạc đề (2)
 ─ Thứ Ba, 14/10 ─
  09:12  Login fail trên Android 14
  09:30  Không phải do Google Sign-In
  ⏸ 10:05  Đang làm: … / Bước tiếp: …
 ─ Hôm nay ─
  …
 💭 Bạn từng ghi: "token hết hạn sau 1h…" [Nối][×]
[ ↗ |  Viết tiếp…                       ➤ ]
```

---

## 6. Dữ liệu

### 6.1 `users/{uid}/threads/{threadId}` (mới)

| Field | Kiểu | Ghi chú |
|---|---|---|
| `title` | string | |
| `status` | string | `active` \| `parked` \| `done` \| `dropped` |
| `lastTouchedAt` | timestamp | cập nhật khi thêm mảnh, mở mạch hoặc dừng |
| `stopDoing`, `stopNext` | string? | bản sao của chỗ dừng mới nhất, để vẽ thẻ "đang dở" mà không phải đọc mảnh |
| `stoppedAt` | timestamp? | |
| `workItemId` | string? | MCH-10 |
| `parentThreadId` | string? | khi mạch được tách ra từ một mảnh lạc đề |
| `createdAt`, `updatedAt` | timestamp | |

### 6.2 `users/{uid}/notes/{noteId}` (mở rộng, mỗi document là một mảnh)

Dùng lại collection `notes` để **ghi chú cũ tự trở thành mảnh rời**, không cần migration.

| Field mới | Kiểu | Ghi chú |
|---|---|---|
| `threadId` | string? | null = mảnh rời |
| `kind` | string | `entry` \| `stop` \| `sidetrack`. Thiếu field (dữ liệu cũ) thì coi là `entry` |
| `stopDoing`, `stopNext` | string? | chỉ có khi `kind=stop` |
| `linkedIds` | array<string> | liên kết nối tay (lưu ở cả hai phía) |
| `dismissedIds` | array<string> | cặp gợi ý đã bấm × |
| `lastSurfacedAt` | timestamp? | NOI-05 |
| `letGo` | bool | NOI-05 "Thôi, buông" |

Giữ nguyên `title`, `content`, `color`, `createdAt`, `updatedAt` để bản APK cũ vẫn đọc được. Mảnh mới ghi `title=''` và `color='stone:Ý tưởng:📝'`. Mảnh cũ có `title` thì hiển thị title in đậm ở dòng đầu.

### 6.3 Đọc dữ liệu
- 2 listener: `threads` và `notes`, tức là chỉ thêm 1 so với hiện tại. Lọc theo mạch, tính "đang dở", "nhớ lại" và chỉ mục liên quan đều làm phía client.
- Không cần index mới. `firestore.rules` không đổi.

---

## 7. Thay đổi code dự kiến

```
lib/features/brain/                 # thay thế lib/features/notes (giữ notes/data cho tương thích)
  data/   thread_model.dart, fragment_model.dart (thay NoteModel), brain_repository.dart
  domain/ vi_tokenizer.dart, vi_stopwords.dart, relevance_index.dart (TF-IDF + cosine),
          resurface_picker.dart, open_loops.dart (tính "đang dở")
  presentation/ brain_screen.dart, thread_screen.dart, stop_point_sheet.dart,
                fragment_peek_sheet.dart, widgets/{open_loop_card, recall_card, related_strip, capture_bar}.dart
```
- Thêm route `/thread/:id` vào `app_router.dart`.
- `TaskDetailSheet` thêm nút "Mở mạch" (MCH-10) và dòng ý liên quan (NOI-06).
- Banner tiếp tục (MCH-11) đặt trong `DashboardScreen`, theo dõi `AppLifecycleState`.
- **Không thêm package nào.**
- `NoteEditorSheet` và lưới masonry bị bỏ. Mảnh cũ mở bằng `fragment_peek_sheet` và vẫn sửa được.

---

## 8. Phi chức năng

| ID | Yêu cầu |
|---|---|
| NFR-01 | Từ lúc bấm [Tiếp tục] đến khi thấy chỗ dừng: ≤ 400ms |
| NFR-02 | Gợi ý NOI-01 hiện ≤ 150ms sau khi hết debounce. Không bao giờ làm giật ô nhập (tính trong isolate) |
| NFR-03 | Mọi thao tác chạy được offline (dựa vào cache Firestore) |
| NFR-04 | Gợi ý **không gây phiền**: tối đa 3 gợi ý, có ngưỡng, có ×, không hiện lại cặp đã bị ẩn |
| NFR-05 | Giao diện đúng ở sáng/tối và vi/en. Cập nhật `flutter analyze`, test và CLAUDE.md |

---

## 9. Kiểm thử
- **Unit:**
  - `vi_tokenizer`: bigram, stopword, giữ/bỏ dấu.
  - `relevance_index`: mảnh liên quan rõ ràng phải xếp trên mảnh không liên quan; đúng ngưỡng; loại trừ đúng (cùng mạch, < 24h, cặp đã ×); lý do liên quan đúng.
  - `open_loops`: chỗ dừng tường minh và chỗ dừng tự lấy từ mảnh cuối.
  - `resurface_picker`: cố định trong ngày, bỏ qua `letGo`, ưu tiên mảnh lạc đề.
  - `FragmentModel` đọc được note cũ.
- **Widget:** luồng Dừng → Tiếp tục cuộn tới đúng mảnh; lạc đề không hiện trong dòng chính; dải gợi ý hiện/ẩn đúng; thẻ Nhớ lại đủ 3 hành động.
- Viết lại `test/widget/notes_screen_test.dart` theo màn hình mới.

---

## 10. Phát hành

| Giai đoạn | Nội dung |
|---|---|
| **1.4.0 – Giữ mạch** | MCH-01…09, NOI-07, màn hình Bộ não + mạch, ghi chú cũ hiện thành mảnh rời |
| **1.5.0 – Nối ý** | NOI-01…05, NOI-08 (bộ máy liên quan), MCH-10, MCH-11 |
| **1.6.0** | NOI-06, MCH-12, tinh chỉnh ngưỡng dựa trên dữ liệu thật |

---

## 11. Câu hỏi mở

| # | Câu hỏi | Đề xuất |
|---|---|---|
| OQ-1 | Nhãn tab: "Bộ não" hay giữ "Ghi chú"? | "Bộ não" |
| OQ-2 | Có giới hạn số mạch `active`/`parked` cùng lúc không (để "đang dở" không thành một danh sách dài)? | Không giới hạn, nhưng chỉ hiện 3 thẻ đầy đủ |
| OQ-3 | Mạch không được chạm > 30 ngày có tự chuyển sang `dropped` không? | Không tự chuyển. Thay vào đó, đưa mạch đó vào thẻ "Nhớ lại" để người dùng tự quyết |
| OQ-4 | Banner tiếp tục (MCH-11) hiện trên mọi tab hay chỉ ở Planner? | Mọi tab |
