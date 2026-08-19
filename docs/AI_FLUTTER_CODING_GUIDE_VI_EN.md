# Hướng dẫn Coding Flutter Việt–Anh / Vietnamese–English Flutter Coding Guide

**Dự án / Project:** `app_quanly_giaidau`  
**Mục đích / Purpose:** Làm chuẩn làm việc trước khi AI hoặc developer sửa code Flutter.  
**Trạng thái / Status:** Hướng dẫn bổ sung, không thay thế `docs/SKILLS.md`.

## 1. Nguyên tắc làm việc bắt buộc / Mandatory working principles

### VI

Từ thời điểm này, trước khi sửa hoặc thêm bất kỳ dòng code nào, phải đọc đúng phạm vi liên quan. Không được đoán tên field, endpoint, provider, role hoặc route. Nếu chưa xác định được hợp đồng dữ liệu, phải dừng ở bước đọc và hỏi hoặc kiểm tra tài liệu trước.

Quy trình an toàn là: đọc knowledge graph; đọc `SKILLS.md`; đọc `PROJECT_OVERVIEW.md`; đọc `endpoint_url.md` nếu có API; đọc `SPEC.md`/`PLAN.md` nếu có thay đổi nghiệp vụ; đọc file hiện tại và interface liên quan; lập kế hoạch nhỏ; sửa ít nhất có thể; chạy format/analyze/test; kiểm tra diff; chỉ sau đó mới cập nhật graph.

### EN

From this point onward, before changing or adding any code, the relevant scope must be read first. Do not guess field names, endpoints, providers, roles, or routes. If the data contract is unclear, stop at the reading stage and verify the documentation before coding.

The safe workflow is: read the knowledge graph; read `SKILLS.md`; read `PROJECT_OVERVIEW.md`; read `endpoint_url.md` for API work; read `SPEC.md`/`PLAN.md` for business changes; read the existing file and related interfaces; create a small plan; make the smallest possible change; run formatting, analysis, and tests; inspect the diff; and only then update the graph.

## 2. Quy ước ngôn ngữ / Language convention

| Khu vực / Area | Quy định chuẩn / Standard |
|---|---|
| Dart class, enum, typedef | **English PascalCase**, ví dụ `TournamentModel`, `MatchStatus`. / English PascalCase, e.g. `TournamentModel`, `MatchStatus`. |
| File và thư mục | **English snake_case**, ví dụ `tournament_detail_screen.dart`. / English snake_case. |
| Variable và method | **English camelCase**, tên method bắt đầu bằng động từ, ví dụ `fetchTournaments()`. / English camelCase with action-oriented method names. |
| Provider và repository | Tên tiếng Anh nhất quán với domain, ví dụ `tournamentRepositoryProvider`. / Consistent English domain naming. |
| Comment trong code | Có thể dùng **Việt–Anh ngắn gọn** khi cần giải thích nghiệp vụ hoặc lý do kỹ thuật. / Use short Vietnamese–English comments only when the business rule or technical reason needs clarification. |
| Documentation | Có thể viết **song ngữ VI/EN**; phần tiếng Việt phải rõ nghĩa, phần tiếng Anh không được dịch máy gây sai nghiệp vụ. / Documentation may be bilingual; English must preserve the business meaning. |
| UI hiển thị cho người dùng | Theo `SKILLS.md`: **100% tiếng Việt**. Không tự ý đưa English vào button, error message, title hoặc empty state. / Per `SKILLS.md`, user-facing UI is **100% Vietnamese**. |
| Log | Có thể dùng tiếng Việt hoặc tiếng Anh, nhưng phải thống nhất trong cùng module và không lộ token/password/PII. / Vietnamese or English is acceptable, but keep module consistency and never log secrets. |
| API JSON key | Giữ đúng contract backend, thường là English; không dịch tên key. / Preserve the backend contract exactly; never translate JSON keys. |

### Quy tắc diễn đạt song ngữ / Bilingual wording rule

Khi viết tài liệu hoặc giải thích code, dùng cấu trúc:

> **VI:** Mô tả ngắn, nêu rõ mục đích và điều kiện.  
> **EN:** A short description preserving the same intent and conditions.

Không viết comment dài trong thân method. Nếu giải thích dài hơn hai câu, đưa vào tài liệu hoặc doc comment ở cấp class/method. Tên code vẫn giữ English; Vietnamese–English dùng ở comment, tài liệu và trao đổi, không trộn hai ngôn ngữ vào identifier.

## 3. Quy tắc ưu tiên tài liệu / Documentation precedence

Trong repository hiện tại có tài liệu cũ và tài liệu mới cùng tồn tại. Khi có mâu thuẫn, áp dụng thứ tự sau:

| Ưu tiên / Priority | Nguồn / Source | Cách dùng / Use |
|---:|---|---|
| 1 | `graphify-out/GRAPH_REPORT.md` | Hiểu quan hệ file, provider, route và điểm vào trước khi sửa. / Understand code relationships before editing. |
| 2 | `docs/PROJECT_OVERVIEW.md` | Nguồn hiện hành cho product direction và kiến trúc mobile. / Current product and mobile architecture direction. |
| 3 | `docs/endpoint_url.md` | Nguồn hiện hành cho REST API, DTO, response và auth protocol. / Current REST API, DTO, response, and auth contract. |
| 4 | `docs/PLAN.md` và `docs/SPEC.md` | Xác định scope và nghiệp vụ được phép làm trên mobile. / Define mobile scope and business behavior. |
| 5 | Code hiện tại và test hiện tại | Xác nhận behavior đang tồn tại trước khi thay đổi. / Confirm current behavior before changing it. |
| 6 | `docs/SKILLS.md` | Bắt buộc cho SOLID, naming, Riverpod, logging, error handling, security và workflow. / Mandatory for design, naming, Riverpod, logging, errors, security, and workflow. |
| 7 | `docs/ARCHITECTURE.md`, `docs/Tech.md` | Dùng làm mẫu tổng quát có chọn lọc; phải bỏ qua phần Firebase cũ nếu trái với backend hiện hành. / Use selectively; ignore Firebase-era sections when they conflict with the current backend. |

### Mâu thuẫn quan trọng cần nhớ / Important conflict to remember

`SKILLS.md`, `ARCHITECTURE.md` và một số ví dụ trong `Tech.md` còn có đoạn minh họa Firebase/Firestore. Tuy nhiên, `PROJECT_OVERVIEW.md` và `endpoint_url.md` xác định kiến trúc hiện tại là **NestJS + PostgreSQL + REST API + Socket.IO**, với Firebase chỉ dùng cho **FCM push notification**. Vì vậy:

- **VI:** Không copy ví dụ Firestore CRUD/stream vào code mới. Dùng API repository, Dio, Riverpod và Socket.IO theo code hiện tại.
- **EN:** Do not copy Firestore CRUD/stream examples into new code. Use API repositories, Dio, Riverpod, and Socket.IO according to the current codebase.

## 4. Kiến trúc code bắt buộc / Required code architecture

### VI

App phải giữ hướng **Feature-first + Clean Architecture**:

```text
lib/
├── core/                         # Shared infrastructure
├── domain/                       # Entities, repository contracts, pure business rules
├── data/                         # DTO/model mapping and API/local implementations
├── providers/                    # Riverpod state and orchestration
└── features/                    # Screens, feature widgets, feature UI behavior
```

`domain` không được phụ thuộc Flutter UI hoặc Dio. `data` được phép biết Dio và JSON. `features` không được tự gọi Dio. `providers` gọi use case hoặc repository interface; UI chỉ watch/read provider, hiển thị state và phát sự kiện người dùng.

### EN

The app must preserve the **Feature-first + Clean Architecture** direction. `domain` must not depend on Flutter UI or Dio. `data` may depend on Dio and JSON mapping. `features` must not call Dio directly. `providers` call use cases or repository interfaces; UI watches/reads providers, renders state, and emits user actions.

| Layer | Được phép / Allowed | Không được phép / Not allowed |
|---|---|---|
| `domain/entities` | Pure Dart entities, immutable fields, business meaning. | Flutter widgets, Dio, JSON parsing tied to transport. |
| `domain/repositories` | Abstract contracts. | Concrete HTTP/database implementation. |
| `data/models` | `fromJson`, `toJson`, DTO mapping, explicit casts. | UI state or `BuildContext`. |
| `data/repositories/api` | Dio calls, endpoint mapping, response parsing, logging. | Rendering UI or direct `setState`. |
| `providers` | `Notifier`, `AsyncNotifier`, orchestration, immutable state. | Widget layout or hardcoded API calls in UI. |
| `features` | Screens/widgets, UI events, localized Vietnamese text. | Direct Dio, direct storage, large business algorithms. |
| `core/services` | Reusable services such as token, socket, bracket, logger. | Feature-specific widget layout. |

## 5. Riverpod: chỉ dùng API mới / Riverpod: use only the current API

### VI

Bắt buộc dùng `Notifier`, `AsyncNotifier`, `FamilyAsyncNotifier`, `NotifierProvider`, `AsyncNotifierProvider` và `Provider` cho dependency injection. Không dùng `StateNotifier` hoặc `StateNotifierProvider` cho code mới.

State phải immutable: thuộc tính `final`, có `copyWith()` nếu cần, không mutate list/map trực tiếp. Khi cập nhật list, tạo list mới:

```dart
state = state.copyWith(
  items: [...state.items, newItem],
);
```

Tác vụ bất đồng bộ phải có trạng thái loading/success/error rõ ràng. Không gọi `ref.read()` tùy tiện trong build nếu có thể dùng `ref.watch()` đúng mục đích. Provider family phải dùng argument có kiểu rõ ràng, không truyền một `Map` dynamic nếu có thể dùng record hoặc class argument.

### EN

New code must use `Notifier`, `AsyncNotifier`, `FamilyAsyncNotifier`, `NotifierProvider`, `AsyncNotifierProvider`, and `Provider` for dependency injection. Do not introduce `StateNotifier` or `StateNotifierProvider`.

State must be immutable: use `final` fields and `copyWith()` where appropriate; never mutate a list or map in place. Asynchronous tasks must expose explicit loading, success, and error states. Use `ref.watch()` for reactive dependencies and use `ref.read()` for intentional one-time actions. Provider-family arguments must be strongly typed.

## 6. API và authentication / API and authentication

### VI

Backend hiện hành là REST API dưới `/api/v1`, không phải Firestore. Access token gửi bằng:

```http
Authorization: Bearer <access_token>
```

Refresh token dùng endpoint `/api/v1/auth/mobile/refresh` và phải được lưu trong secure storage theo quy định của project. Mọi API call phải đi qua repository/service trung gian; không gọi endpoint trực tiếp từ screen.

Khi viết API code, phải kiểm tra đủ: HTTP method, path, query parameters, request DTO, response shape, pagination `meta`, status code, nullable fields và error response. Không đoán response từ tên endpoint.

### EN

The current backend is a REST API under `/api/v1`, not Firestore. The access token is sent in the `Authorization: Bearer <access_token>` header. The refresh token uses `/api/v1/auth/mobile/refresh` and must be stored in secure storage according to the project rules.

Every API call must go through a repository/service abstraction; screens must not call endpoints directly. For each API change, verify the HTTP method, path, query parameters, request DTO, response shape, pagination metadata, status codes, nullable fields, and error response. Never infer a response from the endpoint name alone.

## 7. Logging và error handling / Logging and error handling

### VI

Mỗi repository, notifier và service quan trọng phải có `AppLogger` riêng theo module. Log theo vòng đời:

| Giai đoạn / Stage | Log |
|---|---|
| Bắt đầu | `info` với tên tác vụ và ID không nhạy cảm. / `info` with task name and safe IDs. |
| Chi tiết debug | `debug`, chỉ bật thông tin cần thiết. / `debug` for non-sensitive diagnostics. |
| Thành công | `success` với kết quả chính. / `success` with the key result. |
| Dữ liệu bất thường | `warning`. / `warning`. |
| Exception | `error(message, error, stackTrace)`. |

Không dùng `print()` trong code production. Không log password, full token, refresh token, authorization header, email nhạy cảm hoặc thông tin cá nhân không cần thiết. UI chỉ hiển thị thông báo tiếng Việt dễ hiểu, không hiển thị stack trace hoặc raw exception.

### EN

Important repositories, notifiers, and services must use a module-specific `AppLogger`. Follow the lifecycle `info → debug/warning → success` or `error(message, error, stackTrace)`. Do not use `print()` in production code. Never log passwords, full tokens, refresh tokens, authorization headers, sensitive email data, or unnecessary personal information. UI errors must be human-readable Vietnamese messages and must never expose stack traces or raw exceptions.

## 8. Flutter UI an toàn / Safe Flutter UI

### VI

UI mới phải dùng `AppTheme`, typography và spacing hiện có; không hardcode màu, kích thước hoặc style nếu đã có token tương ứng. Dùng `const` tối đa. Mỗi screen chỉ nên điều phối layout; các section lớn phải tách thành widget riêng.

Giới hạn thực hành: file nên dưới 300 dòng; method `build()` dưới 50 dòng; widget lớn hơn khoảng 100 dòng nên được tách. Với màn hình hiện tại như `HomeScreen`, `ChatDetailScreen` hoặc `ClubDetailScreen`, không mở rộng tiếp file lớn; phải tách dần theo section hoặc notifier trước.

Luôn kiểm tra `mounted` trước khi dùng `context` sau `await`. Không giữ `BuildContext` qua async gap nếu có thể tránh. Với list/network UI, phải có đủ loading, empty, error, retry và success states.

### EN

New UI must use the existing `AppTheme`, typography, and spacing tokens. Avoid hardcoded colors, sizes, and styles when a project token exists. Use `const` aggressively. A screen should coordinate layout only; large sections must become separate widgets.

Practical limits are: keep files below approximately 300 lines, keep `build()` methods below 50 lines, and split widgets larger than approximately 100 lines. For existing large screens such as `HomeScreen`, `ChatDetailScreen`, or `ClubDetailScreen`, do not add more complexity directly; extract sections or notifiers first.

Always check `mounted` before using `context` after an `await`. For network/list UI, provide loading, empty, error, retry, and success states.

## 9. Quy tắc nghiệp vụ hiện hành / Current business rules

| Quy tắc / Rule | Áp dụng khi code / Coding implication |
|---|---|
| Mobile không phải web thu nhỏ. / Mobile is not a small web clone. | Ưu tiên thao tác nhanh: lịch trận, bracket, live score, registration, payment confirmation, profile. |
| Tạo tournament đầy đủ thuộc Web. / Full tournament setup belongs to Web. | Không tự thêm wizard cấu hình giải đầy đủ vào mobile nếu chưa có yêu cầu mới. |
| Lite tournament trong CLB là flow quan trọng. / Club lite tournaments are important. | Giữ form ngắn, quyền nội bộ CLB, nhanh xem bracket/live/result. |
| Scoring cần theo môn. / Scoring is sport-specific. | Không dùng một modal score chung cho mọi môn nếu khác rule. |
| Quyền phải kiểm tra ở router và UI. / Permissions must be checked in router and UI. | Không chỉ ẩn button; backend vẫn là nguồn quyết định cuối cùng. |
| Firebase chỉ dùng FCM. / Firebase is only for FCM. | Không thêm Firestore/Realtime Database SDK cho data domain. |
| REST + Socket.IO là data path hiện tại. / REST + Socket.IO are the current data paths. | Repository dùng Dio; realtime dùng socket service và provider phù hợp. |

## 10. Checklist trước khi sửa / Before-edit checklist

### VI

- [ ] Đã đọc `graphify-out/GRAPH_REPORT.md` và tìm đúng file/provider/route.
- [ ] Đã đọc `SKILLS.md` và tài liệu nghiệp vụ liên quan.
- [ ] Đã xác định source of truth nếu tài liệu cũ/mới mâu thuẫn.
- [ ] Đã đọc file hiện tại, interface repository, model/DTO và provider liên quan.
- [ ] Đã xác định route, role, loading/error state và deep link nếu feature có điều hướng.
- [ ] Đã xác định text UI cần tiếng Việt và identifier/code cần tiếng Anh.
- [ ] Đã kiểm tra widget dùng chung để không tạo bản sao.
- [ ] Đã quyết định test nào phải thêm hoặc cập nhật.

### EN

- [ ] Read the graph report and located the correct file/provider/route.
- [ ] Read `SKILLS.md` and the relevant business documents.
- [ ] Identified the source of truth when old and new documents conflict.
- [ ] Read the existing file, repository interface, model/DTO, and provider.
- [ ] Identified route, role, loading/error states, and deep links where relevant.
- [ ] Confirmed Vietnamese UI text and English code identifiers.
- [ ] Checked shared widgets before creating new ones.
- [ ] Decided which tests must be added or updated.

## 11. Checklist sau khi sửa / After-edit checklist

| Bước / Step | Kết quả bắt buộc / Required result |
|---|---|
| Format | Chạy `dart format` trên file thay đổi. / Run `dart format` on changed files. |
| Static analysis | Chạy `flutter analyze`; không tạo thêm error/warning không cần thiết. / Run `flutter analyze`; do not introduce new issues. |
| Tests | Chạy unit/widget/integration tests phù hợp. / Run relevant unit/widget/integration tests. |
| Runtime | Kiểm tra loading, empty, error, retry, permission và logout behavior. |
| Security | Không lộ token, password, secret; không bypass certificate trong production. |
| Diff | Đọc lại diff, kiểm tra import, route, nullability và side effects. |
| Documentation | Cập nhật task tracker và ghi chú VI/EN nếu thay đổi nghiệp vụ. |
| Graph | Sau khi hoàn thành chỉnh sửa, cập nhật graph theo project workflow. |

## 12. Cách tôi sẽ làm việc từ đây / How I will work from now on

### VI

Tôi sẽ không viết code ngay khi thấy yêu cầu ngắn hoặc chưa rõ. Trước tiên tôi sẽ nêu file/layer cần đọc, xác nhận luồng và hợp đồng dữ liệu, sau đó mới sửa một phạm vi nhỏ. Mỗi lần sửa sẽ cố gắng tạo patch dễ kiểm tra, không gom nhiều thay đổi không liên quan. Sau mỗi patch, tôi sẽ kiểm tra format, analyzer, test và diff. Nếu tài liệu mâu thuẫn, tôi sẽ báo rõ mâu thuẫn thay vì tự chọn im lặng.

Khi giải thích cho bạn, tôi sẽ trình bày theo hai phần **VI** và **EN**. Code identifier sẽ dùng English chuẩn Dart; UI sẽ dùng Vietnamese theo quy định của project. Tôi sẽ đánh dấu rõ phần nào là “đang có trong code”, phần nào là “quy định tài liệu”, và phần nào là “đề xuất”, để tránh nhầm giữa hiện trạng và mục tiêu.

### EN

I will not start coding immediately when a request is short or ambiguous. I will first identify the files/layers to read, confirm the flow and data contract, and then make a small scoped change. Each change will be easy to review and will avoid unrelated edits. After each patch, I will check formatting, analyzer output, tests, and the diff. If documentation conflicts, I will report the conflict instead of silently choosing one interpretation.

When explaining work to you, I will use separate **VI** and **EN** sections. Code identifiers will follow English Dart conventions; user-facing UI will follow the project’s Vietnamese-only rule. I will clearly label what is “already in code,” what is “documented rule,” and what is “recommendation,” so current behavior is not confused with the target design.

## 13. Kết luận / Conclusion

### VI

Đúng như bạn nói, Flutter app này khá lớn nên chỉ cần sai một route, provider, nullable field, async lifecycle hoặc API response là có thể phát sinh lỗi dây chuyền. Vì vậy, từ đây ưu tiên sẽ là **đọc đúng trước, sửa nhỏ, kiểm tra ngay, giải thích song ngữ rõ ràng**, không viết nhanh theo phỏng đoán.

### EN

As you noted, this Flutter app is large, and a mistake in a route, provider, nullable field, async lifecycle, or API response can cause cascading failures. Therefore, the priority from now on is **read correctly first, make small changes, verify immediately, and explain clearly in both languages**, rather than coding from assumptions.

## References / Tài liệu tham chiếu

1. [`docs/SKILLS.md`](./SKILLS.md) — Project AI skills, coding, security, logging, Riverpod, and workflow rules.
2. [`docs/PROJECT_OVERVIEW.md`](./PROJECT_OVERVIEW.md) — Current mobile direction and NestJS/PostgreSQL architecture.
3. [`docs/endpoint_url.md`](./endpoint_url.md) — Current mobile REST API and authentication contract.
4. [`docs/PLAN.md`](./PLAN.md) — Mobile scope, priorities, lite tournament flow, and product rules.
5. [`graphify-out/GRAPH_REPORT.md`](../graphify-out/GRAPH_REPORT.md) — Current codebase relationship graph.

**Author / Tác giả:** Manus AI
