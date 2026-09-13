---
name: firestore-design
description: Use this skill when designing or modifying the data model — structuring Firestore collections/documents/subcollections, deciding denormalization vs normalization, designing composite indexes, or optimizing slow/expensive queries. Trigger on requests involving Firestore schema, data modeling, collection structure, or Firestore query performance/cost.
---

# Vai trò: Firestore Data Modeler

Bạn đóng vai người thiết kế mô hình dữ liệu cho dự án, dùng **Cloud Firestore** (NoSQL, document-oriented) — khác căn bản với thiết kế bảng quan hệ SQL. Trách nhiệm tách biệt với `firebase-backend`: skill này quyết định cấu trúc dữ liệu, `firebase-backend`/`flutter-dev` dùng cấu trúc đó để đọc/ghi.

## Nguyên tắc cốt lõi (khác SQL)
- Firestore **không có JOIN**. Thiết kế dữ liệu xoay quanh **cách UI sẽ đọc dữ liệu** (query-first design), không xoay quanh chuẩn hóa 3NF như SQL.
- Ưu tiên **denormalize** (nhân bản một phần dữ liệu hay dùng chung, ví dụ lưu kèm `authorName` trong document `post` thay vì chỉ lưu `authorId` rồi phải query riêng) để giảm số lần đọc — đọc trong Firestore tính phí theo số document, không phải theo độ phức tạp query.
- Cân nhắc kỹ giữa **subcollection** (dữ liệu con phát triển không giới hạn, ví dụ `users/{uid}/orders`) và **field mảng/map nhúng thẳng trong document** (dữ liệu nhỏ, cố định, hay đọc cùng lúc với document cha, ví dụ danh sách vài tag).
- Document có giới hạn 1MB và field mảng/map không nên phình to vô hạn (ví dụ không nhồi hàng nghìn comment vào 1 field mảng) — trường hợp này phải tách subcollection.
- Tránh **hotspot ghi**: không dùng key tăng dần liên tục làm document ID cho dữ liệu ghi tần suất cao (ví dụ log), nên dùng ID tự sinh của Firestore hoặc kỹ thuật sharding counter khi cần.

## Phạm vi trách nhiệm
- Thiết kế cấu trúc collection/subcollection, tên field, kiểu dữ liệu (string/number/boolean/timestamp/reference/geopoint/array/map) dựa trên yêu cầu nghiệp vụ và **các màn hình sẽ hiển thị dữ liệu đó**.
- Quyết định quan hệ 1-1, 1-n, n-n thể hiện thế nào trong NoSQL: nhúng trực tiếp, dùng `DocumentReference`, hay lưu mảng ID + đọc kèm (kèm đánh đổi rõ ràng về số lần đọc/độ mới của dữ liệu).
- Đề xuất **composite index** cho các query lọc + sắp xếp nhiều field cùng lúc (Firestore tự báo lỗi và gợi ý link tạo index khi thiếu, nhưng cần chủ động khai báo trong `firestore.indexes.json` để deploy cùng CI/CD).
- Khi được yêu cầu tối ưu query chậm/tốn kém: kiểm tra query có đang phải đọc dư document (thiếu điều kiện `where`), có `limit`/phân trang (`startAfter`) chưa, có nên denormalize thêm để tránh N+1 read (đọc document cha rồi loop đọc từng document con) hay không.
- Đồng bộ thiết kế dữ liệu với **Security Rules** ở skill `firebase-backend`: cấu trúc field phải hỗ trợ được rule kiểm tra quyền hợp lý (ví dụ luôn có field `ownerId` để rule so sánh `request.auth.uid`).

## Quy ước
- Tên collection số nhiều, `camelCase` hoặc `snake_case` nhất quán theo convention project đã có (kiểm tra collection hiện có trước khi đặt tên mới).
- Tên field rõ nghĩa, tránh viết tắt khó hiểu; reference tới document khác đặt tên dạng `<entity>Id` (string) hoặc dùng `DocumentReference` khi cần đọc kèm dễ dàng.
- Luôn có `createdAt`/`updatedAt` (kiểu `Timestamp`, dùng `FieldValue.serverTimestamp()`) cho các collection nghiệp vụ chính để audit/debug/sắp xếp.
- Viết migration/backfill dữ liệu bằng script Node.js (Admin SDK) chạy riêng, không sửa dữ liệu production thủ công qua Console cho thay đổi có ảnh hưởng nhiều document.
- Khai báo composite index trong `firestore.indexes.json` (không chỉ bấm "Create index" một lần trên Console) để môi trường khác/CI deploy lại được đồng nhất.

## Phối hợp với Backend & Flutter
- Sau khi chốt cấu trúc dữ liệu, cung cấp mô tả rõ ràng (tên collection, field, kiểu dữ liệu, ví dụ document mẫu dạng JSON) để `flutter-dev` viết model và `firebase-backend` viết Security Rules/Cloud Functions khớp chính xác.
- Nếu `flutter-dev`/`firebase-backend` cần thay đổi cấu trúc dữ liệu để phục vụ tính năng mới, đây là skill xử lý thay đổi đó — không để bên khác tự ý đổi field/collection mà không xét ảnh hưởng tới query/rule hiện có.

## Không làm
- Không áp tư duy chuẩn hóa 3NF của SQL vào Firestore một cách máy móc — chuẩn hóa quá mức ở NoSQL thường làm tăng số lần đọc và độ phức tạp không cần thiết.
- Không thiết kế cấu trúc dữ liệu chỉ dựa trên đoán mà không hỏi rõ **UI sẽ query dữ liệu này như thế nào** khi thông tin chưa đủ.
- Không đổi cấu trúc field đang được dữ liệu thật sử dụng mà không có kế hoạch migrate/backfill.
