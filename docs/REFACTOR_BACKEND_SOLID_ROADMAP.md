# Refactor Roadmap - Backend API + SOLID + Riverpod

> Muc tieu cua tai lieu nay la lam roadmap refactor thuc te cho `app_quanly_giaidau` theo cac nguyen tac trong `docs/SKILLS.md`, nhung ap dung cho trang thai hien tai: app da bo Firebase va chay tren NestJS Backend API.
>
> Tai lieu nay duoc xem la roadmap chinh de don kien truc truoc khi lam UI moi.

---

## 1. Executive Summary

Codebase hien tai co nen tang kha tot:

- Da dung `flutter_riverpod` lam state management chinh.
- Da co `domain/repositories/` va `data/repositories/api/`.
- Da co `DioClient`, `TokenManager`, `GoRouter`, `AppLogger`.
- Phan lon flow du lieu da di qua Backend API.

Tuy nhien, codebase chua dat muc "clean architecture + SOLID" dung nghia cho dot lam UI moi vi cac van de chinh sau:

1. `domain/` dang phu thuoc vao `data/models/`.
2. Mot so screen van goi repository truc tiep.
3. `AuthNotifier` dang om qua nhieu trach nhiem.
4. Cac repository interface hien tai qua rong so voi kha nang thuc te cua mobile app.
5. Ton tai duplicate DI providers va mot so abstraction tam thoi/gia lap.

Neu khong refactor truoc, UI moi se tiep tuc bam vao tang nghiep vu chua on dinh, dan den viec:

- Screen moi tiep tuc chua logic.
- Kho test.
- Kho doi API.
- Kho tach nhom lam UI va nhom lam logic doc lap.

---

## 2. Nguon chuan va pham vi ap dung

Roadmap nay bam theo:

- `docs/SKILLS.md`
- `docs/ARCHITECTURE.md`
- `docs/PROJECT_OVERVIEW.md`
- `docs/REFACTOR_APP_API_PLAN.md`
- `docs/endpoint_url.md`

Luu y:

- `SKILLS.md` va `ARCHITECTURE.md` van con vi du Firebase cu.
- Khi co mau thuan, uu tien:
  1. Nguyen tac SOLID / Riverpod / DIP trong `SKILLS.md`
  2. Backend API reality trong code hien tai
  3. `PROJECT_OVERVIEW.md` va `endpoint_url.md`

---

## 3. Quy tac kien truc dich

Refactor phai dat toi trang thai dich sau:

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/
│   ├── di/
│   ├── errors/
│   ├── router/
│   ├── services/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── dto/
│   ├── mappers/
│   ├── datasources/
│   └── repositories/api/
├── application/
│   ├── state/
│   └── notifiers/
└── features/
    └── <feature>/
        └── presentation/
            ├── screens/
            └── widgets/
```

### 3.1 Trac nhiem cua tung tang

- `features/presentation/`
  - Chi render UI, nhan input, goi notifier.
  - Khong goi repository, Dio, SharedPreferences, TokenManager truc tiep.

- `application/notifiers/`
  - Quan ly state va orchestration.
  - Goi use case.
  - Khong parse HTTP response thu cong neu co the day xuong repository/mapper.

- `domain/entities/`
  - Pure Dart.
  - Khong import Dio, Flutter, API DTO.

- `domain/repositories/`
  - Chi khai bao abstraction.
  - Chi phu thuoc `domain/entities/`.

- `domain/usecases/`
  - Chua business flow co y nghia nghiep vu.
  - Vi du: login, tao giai, import team, generate bracket.

- `data/`
  - DTO, mapper, datasource API, repository implementation.
  - Day la noi duy nhat duoc biet schema JSON backend.

---

## 4. Van de hien tai can sua

### 4.1 Dependency direction sai

Hien tai `domain/repositories/*.dart` import truc tiep `data/models/*`.

Tac dong:

- Vi pham DIP.
- `domain` khong con doc lap.
- UI moi se kho dung lai neu doi DTO/model.

### 4.2 UI bypass nghiep vu

Cac file can uu tien sua:

- `lib/features/tournament/screens/create_tournament_screen.dart`
- `lib/features/bracket/screens/auto_draw_screen.dart`

Van de:

- Screen goi truc tiep repository provider.
- Logic tao entity, validate, submit dang nam trong screen.

### 4.3 Notifier qua tai

File uu tien:

- `lib/providers/auth_provider.dart`

Van de:

- Vua quan ly auth state.
- Vua goi HTTP.
- Vua parse loi backend.
- Vua luu SharedPreferences.
- Vua quan ly JWT access/refresh.
- Vua listen token invalidation.

### 4.4 Interface qua lon / implementation khong thay the duoc

File uu tien:

- `lib/domain/repositories/token_repository.dart`
- `lib/domain/repositories/match_repository.dart`
- `lib/data/repositories/api/api_token_repository.dart`
- `lib/data/repositories/api/api_match_repository.dart`

Van de:

- Interface khai bao capability ma mobile thuc te khong support.
- Implementation nem `UnimplementedError`.

Tac dong:

- Vi pham LSP.
- De vo runtime.

### 4.5 DI graph trung lap

File:

- `lib/providers/app_providers.dart`
- `lib/providers/network_providers.dart`

Van de:

- `tokenManagerProvider` va `dioClientProvider` dang bi dinh nghia 2 noi.

### 4.6 Abstraction tam thoi / gia lap

Vi du:

- `presenceCountProvider` luon `0`
- `watchToken()` tra stream gia thay vi invalidation flow that

Tac dong:

- Code nhiu abstraction nhung chua phan tach "feature da hoan tat" va "feature tam disable".

---

## 5. Nguyen tac refactor bat buoc

1. Khong viet them UI moi tren screen cu chua duoc refactor.
2. Khong de `features/` import `data/repositories/api/*`.
3. Khong de `domain/` import `data/*`.
4. Moi action nghiep vu co side effect phai di qua use case.
5. Moi state async moi phai uu tien `AsyncNotifier`.
6. Chi giu `StreamProvider` cho stream that su can thiet.
7. Khong giu `UnimplementedError` o flow ma mobile dang co the cham toi.
8. Moi file moi phai theo rule ten va phan lop trong `SKILLS.md`.

---

## 6. Muc tieu refactor de UI moi co the bat dau

UI moi duoc xem la co the bat dau an toan khi dat du cac dieu kien sau:

- `Auth`, `Tournament`, `Team`, `Match` deu co notifier/use case ro rang.
- Screen khong con goi repository truc tiep.
- `domain/entities` da on dinh.
- `data/dto` va `data/mappers` da co boundary ro.
- Error message cho UI duoc map tap trung.
- Dependency injection chi con mot graph duy nhat.

---

## 7. Phase-by-phase roadmap

## Phase 0 - Chot target va dong bang boundary

### Muc tieu

- Xac nhan architecture dich.
- Tao tai lieu va checklist de ca nhom cung bam.

### Cong viec

1. Chot roadmap nay la tai lieu chinh.
2. Danh dau `docs/refactor_roadmap.md` la tai lieu cu/template.
3. Chot convention ten thu muc:
   - `domain/entities`
   - `domain/usecases`
   - `application/notifiers`
   - `features/<feature>/presentation`
4. Chot quy uoc:
   - DTO nam o `data/dto`
   - Mapper nam o `data/mappers`
   - API client wrapper nam o `data/datasources`

### Deliverable

- Roadmap duoc merge.
- Team thong nhat architecture dich.

---

## Phase 1 - Refactor core DI va boundaries

### Muc tieu

- Xoa duplicate DI.
- Xay ranh gioi ro rang giua `core`, `domain`, `data`, `application`.

### Cong viec

1. Tao thu muc:
   - `lib/core/di/`
   - `lib/domain/entities/`
   - `lib/domain/usecases/`
   - `lib/data/dto/`
   - `lib/data/mappers/`
   - `lib/application/notifiers/`
2. Gop:
   - `providers/app_providers.dart`
   - `providers/network_providers.dart`
   thanh he DI ro vai tro.
3. Tach provider theo nhom:
   - `core_di_providers.dart`
   - `repository_providers.dart`
   - `usecase_providers.dart`
   - `state_providers.dart`

### File hien tai bi anh huong

- `lib/providers/app_providers.dart`
- `lib/providers/network_providers.dart`

### Done criteria

- Moi dependency chi dinh nghia mot lan.
- Khong con duplicate `dioClientProvider`, `tokenManagerProvider`.

---

## Phase 2 - Domain purification

### Muc tieu

- `domain/` doc lap hoan toan khoi `data/`.

### Cong viec

1. Tao entity thuần cho:
   - `Tournament`
   - `Team`
   - `Match`
   - `Token`
   - `Standing`
   - `AuthSession` neu can
2. Doi `domain/repositories/*.dart` sang import `domain/entities/*`.
3. Chuyen `data/models/*` thanh:
   - DTO neu chung mo ta JSON backend
   - hoac xoa neu entity da du dung
4. Tao mapper:
   - `TournamentDtoMapper`
   - `TeamDtoMapper`
   - `MatchDtoMapper`
   - `TokenDtoMapper`

### File hien tai uu tien

- `lib/domain/repositories/tournament_repository.dart`
- `lib/domain/repositories/team_repository.dart`
- `lib/domain/repositories/match_repository.dart`
- `lib/domain/repositories/token_repository.dart`
- `lib/data/models/*`

### Done criteria

- `rg "import 'package:app_quanly_giaidau/data/" lib/domain` khong con ket qua.

---

## Phase 3 - Auth va session flow

### Muc tieu

- Giam tai `AuthNotifier`.
- Chot auth flow de UI moi bam vao mot API state gon.

### Kien truc dich

```text
features/auth/presentation/*
        ↓
application/notifiers/auth_notifier.dart
        ↓
domain/usecases/auth/*
        ↓
domain/repositories/i_auth_repository.dart
domain/repositories/i_session_repository.dart
        ↓
data/repositories/api/api_auth_repository.dart
data/repositories/local/session_repository.dart
```

### Cong viec

1. Tao:
   - `IAuthRepository`
   - `ISessionRepository`
2. Tach logic dang nam trong `auth_provider.dart` thanh use case:
   - `RestoreSessionUseCase`
   - `LoginWithEmailUseCase`
   - `RegisterWithEmailUseCase`
   - `ValidateInviteTokenUseCase`
   - `SignOutUseCase`
3. Tao `AuthErrorMapper`.
4. Doi `AuthNotifier` thanh coordinator state:
   - state machine
   - call use case
   - map result -> `AuthState`
5. Chuyen truy cap `SharedPreferences.getInstance()` ra repository/session layer.

### File hien tai uu tien

- `lib/providers/auth_provider.dart`
- `lib/core/services/token_manager.dart`
- `lib/data/repositories/api/api_token_repository.dart`

### Done criteria

- `AuthNotifier` khong goi `dio.post(...)` truc tiep nua.
- `AuthNotifier` khong goi `SharedPreferences.getInstance()` truc tiep nua.

---

## Phase 4 - Tournament feature

### Muc tieu

- Tinh nang giai dau co application flow ro rang truoc khi lam UI moi.

### Kien truc dich

```text
CreateTournamentScreen
  -> CreateTournamentNotifier
  -> CreateTournamentUseCase
  -> ITournamentRepository

TournamentDetailScreen
  -> TournamentDetailNotifier
  -> GetTournamentDetailUseCase
  -> ITournamentQueryRepository
```

### Cong viec

1. Tao use case:
   - `CreateTournamentUseCase`
   - `GetTournamentDetailUseCase`
   - `UpdateTournamentUseCase`
   - `FinalizeTournamentUseCase`
   - `DeleteTournamentUseCase`
2. Doi `create_tournament_screen.dart`:
   - bo tao entity va submit truc tiep trong screen
   - bo `ref.read(tournamentRepositoryProvider).create(...)`
3. Doi `tournament_action_notifier.dart` thanh notifier theo use case.
4. Chuan hoa phan generate invite token:
   - neu backend tra token sau create -> map tai repository
   - neu mobile tam generate local -> dua vao use case/service ro nghia

### File hien tai uu tien

- `lib/features/tournament/screens/create_tournament_screen.dart`
- `lib/providers/tournament_action_notifier.dart`
- `lib/data/repositories/api/api_tournament_repository.dart`

### Done criteria

- Screen tao giai chi submit form state.
- Khong con repository call truc tiep trong tournament screens.

---

## Phase 5 - Team feature

### Muc tieu

- Team management tro thanh mot feature clean, de thay UI moi.

### Cong viec

1. Doi `TeamService` hien tai thanh use case/service o tang dung.
2. Tao use case:
   - `AddTeamUseCase`
   - `UpdateTeamUseCase`
   - `DeleteTeamUseCase`
   - `ImportTeamsUseCase`
   - `DeleteAllTeamsUseCase`
3. Tach Excel import parsing khoi screen.
4. Tao `TeamListNotifier` va `TeamMutationNotifier` neu can tach read/write.

### File hien tai uu tien

- `lib/providers/team_notifier.dart`
- `lib/features/teams/screens/team_list_screen.dart`
- `lib/features/teams/screens/add_team_screen.dart`

### Done criteria

- `team_list_screen.dart` khong con parse Excel truc tiep.
- Team CRUD khong con business rule trong UI.

---

## Phase 6 - Bracket va match feature

### Muc tieu

- Dua nghiep vu tran dau/bracket ra khoi UI.
- Chuan bi cho UI moi cua live/bracket/score.

### Cong viec

1. Tach use case:
   - `GenerateBracketUseCase`
   - `ResetBracketUseCase`
   - `StartMatchUseCase`
   - `UpdateMatchScoreUseCase`
   - `AddPenaltyUseCase`
   - `EndMatchUseCase`
   - `AdminOverrideMatchResultUseCase`
2. Doi `auto_draw_screen.dart`:
   - bo repository call truc tiep
3. Giam tai `match_control_notifier.dart`
   - de notifier giu state orchestration
   - day scoring/penalty rule sang service/use case
4. Xac dinh chien luoc live data:
   - polling repository
   - hoac websocket repository
   - nhung application layer khong can biet implementation cu the

### File hien tai uu tien

- `lib/features/bracket/screens/auto_draw_screen.dart`
- `lib/providers/match_control_notifier.dart`
- `lib/data/repositories/api/api_match_repository.dart`
- `lib/core/services/penalty_service.dart`
- `lib/core/utils/bracket_generator.dart`

### Done criteria

- UI score/bracket khong con chua nghiep vu.
- Match flow co use case ro rang.

---

## Phase 7 - Token, live state, va feature tam disable

### Muc tieu

- Loai bo abstraction "gia" hoac chuyen no thanh feature co chu thich ro.

### Cong viec

1. Tach token capability:
   - query token
   - admin token management
2. Neu mobile khong duoc quyen mutate token:
   - bo method khoi interface mobile
   - hoac tao interface rieng chi cho admin/web
3. Xu ly `presenceCountProvider`:
   - neu chua co backend support -> dua vao "disabled feature adapter"
   - hoac xoa khoi UI moi
4. Chot live update strategy:
   - Polling cho mobile v1
   - Socket cho live score v2

### Done criteria

- Khong con `UnimplementedError` o flow co the bi UI goi toi.
- Moi feature tam disable duoc danh dau ro trong code va docs.

---

## Phase 8 - UI-ready cleanup

### Muc tieu

- Don mat bang de bat dau UI moi.

### Cong viec

1. Tach screen lon > 100 dong thanh widget con.
2. Tao shared widgets co the tai su dung cho UI moi:
   - `AppScaffoldShell`
   - `LoadingView`
   - `EmptyStateView`
   - `ErrorStateView`
   - `SectionCard`
3. Chuan hoa `AsyncValue` handling helper.
4. Bo cac warning/info cu lien quan file vua refactor.

### Done criteria

- Mỗi feature co notifier + state API ro rang.
- UI moi co the phat trien song song ma khong can sua repository.

---

## 8. Mapping file hien tai -> dich refactor

| File hien tai | Van de | Dich de xuat |
|---|---|---|
| `lib/providers/auth_provider.dart` | Qua tai, tron HTTP + session + state | `application/notifiers/auth_notifier.dart` + `domain/usecases/auth/*` + `data/repositories/api/api_auth_repository.dart` |
| `lib/providers/app_providers.dart` | Tron DI va state providers | Tach thanh `core/di/*` + `application/notifiers/*` |
| `lib/providers/network_providers.dart` | Duplicate DI | Gop vao `core/di/core_di_providers.dart` |
| `lib/providers/team_notifier.dart` | Service nam sai layer | Chuyen thanh use case + notifier |
| `lib/providers/match_control_notifier.dart` | Chua nghiep vu match | Tach use case, giu notifier lam coordinator |
| `lib/providers/tournament_action_notifier.dart` | Mutation flow chua qua use case | Doi thanh use case-driven notifier |
| `lib/features/tournament/screens/create_tournament_screen.dart` | UI goi repo truc tiep | Doi qua `CreateTournamentNotifier` |
| `lib/features/bracket/screens/auto_draw_screen.dart` | UI goi repo truc tiep | Doi qua `GenerateBracketNotifier` |
| `lib/data/models/*` | Dang vua dong vai entity vua dong vai DTO | Tach `domain/entities` va `data/dto` |
| `lib/domain/repositories/*` | Import sai tang | Chi import `domain/entities` |

---

## 9. Thu tu thuc hien de giam rui ro

Thu tu uu tien:

1. Phase 1 - DI va boundaries
2. Phase 2 - Domain purification
3. Phase 3 - Auth/session
4. Phase 4 - Tournament
5. Phase 5 - Team
6. Phase 6 - Bracket/match
7. Phase 7 - Token/live/presence cleanup
8. Phase 8 - UI-ready cleanup

Ly do:

- `Auth` la flow xuyen suot, phai on truoc.
- `Tournament` va `Team` la base cho UI moi.
- `Bracket` va `Match` phuc tap hon, nen xu ly sau khi boundaries da sach.

---

## 10. Danh sach backend dependency can theo doi

Mot so phan refactor phu thuoc backend hien tai:

1. Presence / viewer count
   - Chua co endpoint/socket mobile ro rang.
2. Token invalidation that su
   - Hien tai mobile dang dung flow gia lap.
3. Live score strategy
   - Polling da co the dung tam.
   - Socket nen duoc xem la phase tiep theo.
4. Token management capability
   - Can chot ro mobile co duoc mutate token hay chi query.

Neu backend chua support, app phai:

- Hoac disable feature minh bach.
- Hoac tao adapter tam thoi co chu thich ro.

---

## 11. Definition of Done cho dot refactor

- [ ] `domain/` khong import `data/`
- [ ] Screen khong goi repository provider truc tiep
- [ ] Moi async mutation chinh di qua `AsyncNotifier` + use case
- [ ] Khong con duplicate DI providers
- [ ] Khong con `UnimplementedError` o flow mobile chinh
- [ ] `AuthNotifier` khong goi HTTP va storage truc tiep
- [ ] Team import/delete flow khong con logic nghiep vu trong UI
- [ ] Match/bracket flow khong con nghiep vu nam trong screen
- [ ] UI moi co the chi lam trong `features/*/presentation/`

---

## 12. Cach su dung roadmap nay khi lam UI moi

### Truoc khi lam UI moi

Phai hoan thanh toi thieu:

- Phase 1
- Phase 2
- Phase 3
- Phase 4
- Phase 5

### Trong luc lam UI moi

UI chi nen phu thuoc:

- `AuthState`
- `TournamentListState`
- `TournamentDetailState`
- `TeamListState`
- `MatchLiveState`
- Cac notifier public methods

UI khong duoc phu thuoc:

- `ApiTournamentRepository`
- `DioClient`
- `TokenManager`
- `SharedPreferences`
- JSON response schema

### Sau khi UI moi xong

Neu can them feature moi, uu tien mo rong:

- use case
- notifier
- presentation state

Khong sua truc tiep repository neu chi la doi cach hien thi.

---

## 13. Ghi chu chuyen tiep

- `docs/SKILLS.md` nen duoc cap nhat sau dot refactor de bo vi du Firebase cu va thay bang backend API.
- `docs/ARCHITECTURE.md` nen duoc cap nhat lai khi structure moi on dinh.
- `docs/refactor_roadmap.md` hien la tai lieu cu/template, khong nen dung lam nguon chinh nua.

