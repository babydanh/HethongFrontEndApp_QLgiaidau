# Flutter Test Plan — app_quanly_giaidau

> **Project**: `app_quanly_giaidau` (Flutter + Riverpod + Dio + GoRouter)
> **Generated**: 2026-07-07
> **Author**: Claude Code

---

## A. Phan tich Flutter App — nhung gi can test

### A.1. Man hinh (Screens) can test

| Screen | File | Do phuc tap | Ly do |
|---|---|---|---|
| CreateClubTournamentScreen | `lib/features/community/screens/create_club_tournament_screen.dart` | Cao | Form validation, API POST, snackbar, pop, provider invalidate |
| ClubDetailScreen | `lib/features/community/screens/club_detail_screen.dart` | Rat cao | 5 tabs, async data, membership, join/leave, member management |
| ProfileScreen | `lib/features/profile/screens/profile_screen.dart` | Rat cao | Avatar/cover upload, rankings, my tournaments, account settings, long press delete |
| DashboardScreen | `lib/features/dashboard/screens/dashboard_screen.dart` | Cao | Workspace loading, 6 sections (header, overview, invites, roles, organizer-lite, tournaments) |

### A.2. API calls can test

| API Endpoint | Method | Repository method | Su dung boi |
|---|---|---|---|
| `POST /tournaments/lite` | POST | Dung truc tiep `dio.post` trong `CreateClubTournamentScreen` | CreateClubTournamentScreen |
| `GET /communities/:id/tournaments` | GET | `ApiCommunityRepository.getTournaments()` | ClubDetailScreen > Tournaments tab |
| `GET /communities/:id` | GET | `ApiCommunityRepository.getCommunityById()` | ClubDetailScreen |
| `GET /tournaments/workspace/me` | GET | `ApiTournamentRepository.getMyWorkspace()` | ProfileScreen, DashboardScreen |
| `DELETE /tournaments/:id` | DELETE | `ApiTournamentRepository.delete()` | ProfileScreen (long press) |
| `POST /communities/:id/join` | POST | `ApiCommunityRepository.joinCommunity()` | ClubDetailScreen |
| `PATCH /tournaments/:id` | PATCH | `ApiTournamentRepository.updateStatus()` | (general flow) |
| `GET /users/search` | GET | Dung truc tiep `dio.get` trong dialog | ClubDetailScreen > Invite dialog |
| `POST /communities/:id/members/invite` | POST | `ApiCommunityRepository.inviteMember()` | ClubDetailScreen > Invite dialog |

### A.3. State management can test

| Provider | Type | File | Su dung boi |
|---|---|---|---|
| `communityTournamentsProvider` | `FutureProvider.family<List<CommunityTournamentModel>, String>` | `community_provider.dart` | ClubDetailScreen |
| `communityDetailProvider` | `FutureProvider.family<Community?, String>` | `community_provider.dart` | ClubDetailScreen |
| `communityMembersProvider` | `FutureProvider.family<List<CommunityMemberModel>, String>` | `community_provider.dart` | ClubDetailScreen |
| `communityGalleryProvider` | `FutureProvider.family<List<GalleryImageModel>, String>` | `community_provider.dart` | ClubDetailScreen |
| `communityRankingsProvider` | `FutureProvider.family<List<CommunityRankingModel>, String>` | `community_provider.dart` | ClubDetailScreen |
| `myTournamentWorkspaceProvider` | `AsyncNotifierProvider<MyTournamentWorkspaceNotifier, TournamentWorkspace>` | `my_tournament_workspace_provider.dart` | ProfileScreen, DashboardScreen |
| `tournamentActionProvider` | `AsyncNotifierProvider<TournamentActionNotifier, void>` | `tournament_action_notifier.dart` | ProfileScreen (delete) |
| `authProvider` | `NotifierProvider<AuthNotifier, AuthState>` | `auth_provider.dart` | Tat ca screens |
| `userProfileProvider` | `FutureProvider<UserProfile>` | `user_provider.dart` | ProfileScreen, DashboardScreen |
| `userRankingsProvider` | `FutureProvider<List<Ranking>>` | `ranking_provider.dart` | ProfileScreen, DashboardScreen |

### A.4. Navigation can test

| Action | Method | Target |
|---|---|---|
| Pop after success | `context.pop()` | CreateClubTournamentScreen |
| Push to create form | `context.push('/club/:id/create-tournament')` | ClubDetailScreen |
| Push to tournament intro | `context.push('/intro/:id')` | ClubDetailScreen, ProfileScreen |
| Push to dashboard | `context.go('/dashboard')` | ProfileScreen |
| Push to home | `context.go('/home')` | ProfileScreen (after logout) |
| Push to login | `context.push('/login')` | ClubDetailScreen, ProfileScreen |
| Push to club manage | `context.push('/club/:id/manage')` | ClubDetailScreen |
| Push to organizer lite | `context.push('/organizer-lite/:id')` | DashboardScreen |

### A.5. Business logic can test

| Logic | Mo ta |
|---|---|
| Sport slug mapping | `_mapSportSlug()` — maps App constants to backend slug |
| Form validation | Name required, maxTeams 2-128, sport/format/bracket required |
| Tournament sorting & dedup | `visibleTournaments` getter in `TournamentWorkspace` |
| Role counting | `activeRoleCount` in `TournamentWorkspace` |
| Status normalization | `StatusHelper.normalizeTournamentStatus()` |
| Auth state machine | `AuthNotifier` — login, logout, token refresh |
| Optimistic workspace | `_optimisticWorkspace()` in `MyTournamentWorkspaceNotifier` |

---

## B. De xuat test strategy

### B.1. Khuyen nghi: Unit / Widget test (mock) la chinh

| Tieu chi | Unit/Widget test (mock) | Integration test (that) |
|---|---|---|
| Toc do | Nhanh (ms) | Cham (s) |
| Phu thuoc backend | Khong (mock Dio) | Co |
| Coverage UI states | Cao (loading, error, empty, data) | Thap (chi happy path) |
| Debug errors | De dang | Kho hon |
| CI/CD | Chay ngay | Can backend sandbox |

**Ket luan**: Uu tien **unit test + widget test voi mock**. Integration test chi bo sung cho critical end-to-end flow (create tournament -> verify trong DB).

### B.2. Packages can cai them

| Package | Muc dich | Command |
|---|---|---|
| `mocktail: ^1.0.4` | Mock dependencies (Dio, SharedPreferences, etc.) | `flutter pub add dev:mocktail` |
| `flutter_lints` | Da co san | — |
| `riverpod_test` | Test Riverpod providers | (co the dung `ProviderContainer` truc tiep) |

### B.3. Cau truc thu muc test de xuat

```
test/
  providers/
    community_provider_test.dart
    my_tournament_workspace_provider_test.dart
    tournament_action_notifier_test.dart
  screens/
    create_club_tournament_screen_test.dart
    club_detail_screen_test.dart
    profile_screen_test.dart
    dashboard_screen_test.dart
  models/
    community_tournament_model_test.dart
    tournament_workspace_test.dart
  repositories/
    api_community_repository_test.dart
    api_tournament_repository_test.dart
  services/
    dio_client_test.dart       # Da co networking_test.dart
    token_manager_test.dart
  helpers/
    test_helpers.dart           # Fake classes, mock data, test providers
```

### B.4. % Coverage khuyen nghi

| Area | Target coverage |
|---|---|
| Models (fromJson) | 100% |
| Repositories (API calls) | 90% |
| Providers (state transitions) | 85% |
| Screens (widget tests) | 75% |
| Utils (helpers, formatters) | 90% |

---

## C. Test cases cu the (TC-FLUTTER-XX)

### Module: FLUTTER (Flutter Mobile App)

---

#### TC-FLUTTER-01: Tao Lite tournament trong CLB — Happy Path

- **id**: TC_FLUTTER_01
- **canonicalId**: TC-FLUTTER-01
- **module**: Flutter App
- **title**: Tao Lite tournament trong CLB — form dien day du, submit thanh cong
- **preconditions**: Da dang nhap. Co clubId. Da vao CreateClubTournamentScreen.
- **steps**:
  1. Nhap ten giai: "Giai Cau Long CN 2026"
  2. Chon mon the thao: "Cau long"
  3. Chon hinh thuc: "Danh don"
  4. Chon the thuc: "Loai truc tiep"
  5. Nhap so doi toi da: "16"
  6. Nhap mo ta: "Giai thuong nien"
  7. Nhan nut "Tao giai dau"
- **testData**: `{ name: "Giai Cau Long CN 2026", communityId: "club-123", sport: "badminton", format: "SINGLES", bracketType: "SINGLE_ELIMINATION", maxTeams: 16, description: "Giai thuong nien" }`
- **expectedResult**: `dio.post('/tournaments/lite')` duoc goi voi body chinh xac. HTTP 200/201. Snackbar "Tao giai dau thanh cong!". `context.pop()` duoc goi. `communityTournamentsProvider(clubId)` bi invalidate. `communityDetailProvider(clubId)` bi invalidate.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-02: Tao Lite tournament — form validation loi

- **id**: TC_FLUTTER_02
- **canonicalId**: TC-FLUTTER-02
- **module**: Flutter App
- **title**: Tao Lite tournament — form validation (ten rong, so doi khong hop le)
- **preconditions**: Da vao CreateClubTournamentScreen.
- **steps**:
  1. De trong ten giai
  2. Nhap so doi: "1" (nho hon 2)
  3. Nhan nut "Tao giai dau"
- **testData**: `{ name: "", maxTeams: "1" }`
- **expectedResult**: Nut "Tao giai dau" van enable. Form hien thi loi validation: "Vui long nhap ten giai dau", "Tu 2-128 doi". API khong duoc goi.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-03: Tao Lite tournament — API error

- **id**: TC_FLUTTER_03
- **canonicalId**: TC-FLUTTER-03
- **module**: Flutter App
- **title**: Tao Lite tournament — DioException (network error)
- **preconditions**: Da nhap form day du. Mock Dio tra ve DioException.
- **steps**:
  1. Nhap day du thong tin
  2. Nhan "Tao giai dau"
- **testData**: `Mock DioException: connection timeout`
- **expectedResult**: Snackbar do hien thi loi. `_isLoading` chuyen ve false. Khong pop. Khong invalidate provider.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-04: Tao Lite tournament — sport slug mapping

- **id**: TC_FLUTTER_04
- **canonicalId**: TC-FLUTTER-04
- **module**: Flutter App
- **title**: Tao Lite tournament — sport slug mapping cho 4 mon
- **preconditions**: Da vao CreateClubTournamentScreen.
- **steps**:
  1. Chon "Cau long" -> submit -> kiem tra slug
  2. Chon "Tennis" -> submit -> kiem tra slug
  3. Chon "Pickleball" -> submit -> kiem tra slug
  4. Chon "Bong ban" -> submit -> kiem tra slug
- **testData**: `{ sport: [badminton, tennis, pickleball, table_tennis] }`
- **expectedResult**: `_mapSportSlug()` tra ve dung slug: "badminton", "tennis", "pickleball", "table_tennis"
- **execution**: `status: "New"`

---

#### TC-FLUTTER-05: Xem danh sach tournament trong CLB — co du lieu

- **id**: TC_FLUTTER_05
- **canonicalId**: TC-FLUTTER-05
- **module**: Flutter App
- **title**: Xem tab Giai dau trong ClubDetailScreen — co tournament
- **preconditions**: Da vao ClubDetailScreen. Club co 2 tournament.
- **steps**:
  1. Vao ClubDetailScreen
  2. Cho load xong club detail
  3. Chuyen sang tab "Giai dau"
- **testData**: `communityTournamentsProvider(clubId)` tra ve 2 `CommunityTournamentModel`
- **expectedResult**: Hien thi "Tao giai dau moi" button. Hien thi 2 tournament card. Moi card hien: ten, so doi/maxTeams, ngay, status badge.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-06: Xem danh sach tournament trong CLB — rong

- **id**: TC_FLUTTER_06
- **canonicalId**: TC-FLUTTER-06
- **module**: Flutter App
- **title**: Xem tab Giai dau — empty state
- **preconditions**: Da vao ClubDetailScreen. Club khong co tournament nao.
- **steps**:
  1. Chuyen sang tab "Giai dau"
- **testData**: `communityTournamentsProvider(clubId)` tra ve `[]`
- **expectedResult**: Hien thi icon cup + text "Chua co giai dau nao" + button "Tao giai dau". Button dan den `/club/:id/create-tournament`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-07: Xem danh sach tournament trong CLB — loading state

- **id**: TC_FLUTTER_07
- **canonicalId**: TC-FLUTTER-07
- **module**: Flutter App
- **title**: Xem tab Giai dau — loading state
- **preconditions**: Provider o trang thai loading.
- **steps**:
  1. Chuyen sang tab "Giai dau"
- **testData**: `communityTournamentsProvider(clubId)` o trang thai `AsyncLoading`
- **expectedResult**: Hien thi `CircularProgressIndicator`
- **execution**: `status: "New"`

---

#### TC-FLUTTER-08: Xem danh sach tournament trong CLB — error state

- **id**: TC_FLUTTER_08
- **canonicalId**: TC-FLUTTER-08
- **module**: Flutter App
- **title**: Xem tab Giai dau — error state
- **preconditions**: Provider tra ve error.
- **steps**:
  1. Chuyen sang tab "Giai dau"
- **testData**: `communityTournamentsProvider(clubId)` tra ve `AsyncError`
- **expectedResult**: Hien thi icon cloud_off + text "Loi tai du lieu"
- **execution**: `status: "New"`

---

#### TC-FLUTTER-09: Profile — Xem "Giai dau cua toi" co du lieu

- **id**: TC_FLUTTER_09
- **canonicalId**: TC-FLUTTER-09
- **module**: Flutter App
- **title**: Profile — hien thi danh sach tournament cua toi
- **preconditions**: Da dang nhap. `myTournamentWorkspaceProvider` tra ve workspace co 3 organized + 2 participating.
- **steps**:
  1. Vao ProfileScreen
  2. Cho load du lieu
  3. Keo xuong "Giai dau cua toi"
- **testData**: `workspace.organizedTournaments.length = 3`, `workspace.participatingTournaments.length = 2`
- **expectedResult**: Hien thi toi da 4 tournament (lay tu organized + coOrganizer + participating). Moi tournament hien: ten, status, icon. Tap vao tournament -> `/intro/:id`. Long press -> show delete dialog.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-10: Profile — "Giai dau cua toi" rong

- **id**: TC_FLUTTER_10
- **canonicalId**: TC-FLUTTER-10
- **module**: Flutter App
- **title**: Profile — empty state "Giai dau cua toi"
- **preconditions**: Da dang nhap. Workspace rong.
- **steps**:
  1. Vao ProfileScreen
  2. Xem "Giai dau cua toi"
- **testData**: `TournamentWorkspace.empty`
- **expectedResult**: Text "Ban chua tao hoac tham gia giai nao." + button "Xem Dashboard" dan den `/dashboard`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-11: Profile — Long press delete tournament

- **id**: TC_FLUTTER_11
- **canonicalId**: TC-FLUTTER-11
- **module**: Flutter App
- **title**: Profile — long press tournament -> xoa thanh cong
- **preconditions**: Da dang nhap. co tournament trong organizedTournaments.
- **steps**:
  1. Long press vao tournament
  2. Dialog xac nhan xuat hien
  3. Nhan "Xoa"
- **testData**: `t.id = "tour-456"`, `tournamentActionProvider.notifier.deleteTournament("tour-456")` -> tra ve `true`
- **expectedResult**: Dialog confirm xuat hien voi tieu de "Xoa giai dau?". `deleteTournament("tour-456")` duoc goi. Snackbar "Da xoa giai dau". `myTournamentWorkspaceProvider` bi invalidate.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-12: Profile — Long press delete tournament (cancel)

- **id**: TC_FLUTTER_12
- **canonicalId**: TC-FLUTTER-12
- **module**: Flutter App
- **title**: Profile — long press -> huy xoa
- **preconditions**: Da dang nhap. co tournament trong organizedTournaments.
- **steps**:
  1. Long press vao tournament
  2. Nhan "Huy"
- **testData**: Dialog tra ve `false`
- **expectedResult**: Khong co snackbar. Khong co API call. Khong invalidate provider.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-13: Profile — Tai avatar thanh cong

- **id**: TC_FLUTTER_13
- **canonicalId**: TC-FLUTTER-13
- **module**: Flutter App
- **title**: Profile — upload avatar thanh cong
- **preconditions**: Da dang nhap. Mock ImagePicker tra ve file.
- **steps**:
  1. Tap vao avatar
  2. Chon nguon (camera/gallery)
  3. Cho upload hoan tat
- **testData**: `ImagePicker.pickImage()` tra ve fake file
- **expectedResult**: `userRepositoryProvider.uploadAvatar()` duoc goi. `userProfileProvider` bi invalidate. Snackbar "Anh dai dien da duoc cap nhat".
- **execution**: `status: "New"`

---

#### TC-FLUTTER-14: Profile — Tai avatar loi

- **id**: TC_FLUTTER_14
- **canonicalId**: TC-FLUTTER-14
- **module**: Flutter App
- **title**: Profile — upload avatar bi loi
- **preconditions**: Da dang nhap. Mock uploadAvatar() nem Exception.
- **steps**:
  1. Tap vao avatar
  2. Chon anh
- **testData**: `uploadAvatar()` throws Exception("Network error")
- **expectedResult**: Snackbar do hien "Loi: Network error". `_uploading` chuyen ve false.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-15: Profile — Xem ranking ELO

- **id**: TC_FLUTTER_15
- **canonicalId**: TC-FLUTTER-15
- **module**: Flutter App
- **title**: Profile — hien thi ranking ELO dashboard cards
- **preconditions**: Da dang nhap. `userRankingsProvider` tra ve 2 ranking object.
- **steps**:
  1. Vao ProfileScreen
  2. Quan sat phan ranking
- **testData**: `rankings = [Ranking(rank:1, eloPoints:1500, tierName:"Vang", ...), Ranking(rank:3, eloPoints:950, tierName:"Bac", ...)]`
- **expectedResult**: Hien thi 2 card ranking voi gradient color tuong ung tier (Vang=gold, Bac=silver). Moi card co: category name, rank, ELO, matches played, win/loss, win rate.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-16: Dashboard — Xem workspace overview

- **id**: TC_FLUTTER_16
- **canonicalId**: TC-FLUTTER-16
- **module**: Flutter App
- **title**: Dashboard — hien thi day du workspace sections
- **preconditions**: Da dang nhap. `myTournamentWorkspaceProvider` tra ve workspace day du.
- **steps**:
  1. Vao DashboardScreen
  2. Quan sat toan bo sections
- **testData**: `workspace: organizedTournaments=2, participatingTournaments=3, coOrganizerTournaments=1, refereeInvites=2, refereeMatches=3`
- **expectedResult**: Hien thi: _DashboardHeader (avatar, ELO, thong ke), _WorkspaceOverview (3 metric: Loi moi, Vai tro, Tran giao), _PendingInviteSection (neu co), _RoleSection (Chu giai, BTC, Trong tai, VDV), _OrganizerLiteSection (organized + coOrganizer), _AssignedMatchesSection, _TournamentSection, _QuickActions.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-17: Dashboard — Chua dang nhap

- **id**: TC_FLUTTER_17
- **canonicalId**: TC-FLUTTER-17
- **module**: Flutter App
- **title**: Dashboard — prompt login khi chua auth
- **preconditions**: Chua dang nhap. `authProvider.isAuthenticated == false`.
- **steps**:
  1. Vao DashboardScreen
- **testData**: `authState = AuthStatus.unauthenticated`
- **expectedResult**: Hien thi icon dashboard + text "Dang nhap de xem khu vuc cua ban" + button "Dang nhap" dan den `/login`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-18: Dashboard — OrganizerLiteSection

- **id**: TC_FLUTTER_18
- **canonicalId**: TC-FLUTTER-18
- **module**: Flutter App
- **title**: Dashboard — OrganizerLiteSection hien thi dung
- **preconditions**: Da dang nhap. `organizedTournaments` co 2 item.
- **steps**:
  1. Vao DashboardScreen
  2. Xem OrganizerLiteSection
- **testData**: `organizedTournaments = [Tournament(id:"t1", name:"Giai CN"), Tournament(id:"t2", name:"Giai Tennis")]`
- **expectedResult**: Section title "Organizer Lite". Hien thi toi da 3 tournament. Moi tournament co: icon, ten, role label ("Chu giai" hoac "Ban to chuc"), button "Mo" dan den `/organizer-lite/:id`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-19: Dashboard — RoleSection day du

- **id**: TC_FLUTTER_19
- **canonicalId**: TC-FLUTTER-19
- **module**: Flutter App
- **title**: Dashboard — RoleSection hien thi tat ca roles
- **preconditions**: Da dang nhap. Tat ca 4 loai role deu co tournament.
- **steps**:
  1. Vao DashboardScreen
  2. Xem RoleSection
- **testData**: `organizedTournaments=2, coOrganizerTournaments=1, refereeTournaments=3, participatingTournaments=5`
- **expectedResult**: 4 chip role: "Chu giai . 2", "Ban to chuc . 1", "Trong tai . 3", "Van dong vien . 5". Moi chip co icon va mau tuong ung.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-20: Dashboard — Pull-to-refresh

- **id**: TC_FLUTTER_20
- **canonicalId**: TC-FLUTTER-20
- **module**: Flutter App
- **title**: Dashboard — pull to refresh workspace
- **preconditions**: Da dang nhap. `myTournamentWorkspaceProvider.notifier.refresh()` duoc mock.
- **steps**:
  1. Vao DashboardScreen
  2. Keo xuong de refresh
- **testData**: `RefreshIndicator.onRefresh()` duoc goi
- **expectedResult**: `refresh()` duoc goi. UI cap nhat lai.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-21: ClubDetail — Tab bar day du 5 tabs

- **id**: TC_FLUTTER_21
- **canonicalId**: TC-FLUTTER-21
- **module**: Flutter App
- **title**: ClubDetailScreen — hien thi 5 tabs: Gioi thieu, Giai dau, Thanh vien, Anh, Xep hang
- **preconditions**: Da vao ClubDetailScreen. `communityDetailProvider` tra ve Community data.
- **steps**:
  1. Vao ClubDetailScreen
  2. Quan sat tab bar
- **testData**: `Community` object voi day du fields
- **expectedResult**: Tab bar co 5 tab: "Gioi thieu", "Giai dau", "Thanh vien", "Anh", "Xep hang". Tab mac dinh la "Gioi thieu".
- **execution**: `status: "New"`

---

#### TC-FLUTTER-22: ClubDetail — Join/Leave CLB

- **id**: TC_FLUTTER_22
- **canonicalId**: TC-FLUTTER-22
- **module**: Flutter App
- **title**: ClubDetailScreen — tham gia CLB thanh cong
- **preconditions**: Da dang nhap. Chua la member. `_myMembership == null`.
- **steps**:
  1. Vao ClubDetailScreen
  2. Nhan "Tham gia cau lac bo"
- **testData**: `communityRepositoryProvider.joinCommunity(clubId)` -> tra ve `true`
- **expectedResult**: Button hien "Dang xu ly...". Sau do chuyen sang "Da tham gia". Snackbar "Tham gia cau lac bo thanh cong!". `_fetchMembership()` duoc goi lai.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-23: ClubDetail — Chua auth click Join

- **id**: TC_FLUTTER_23
- **canonicalId**: TC-FLUTTER-23
- **module**: Flutter App
- **title**: ClubDetailScreen — chua dang nhap click Join -> chuyen Login
- **preconditions**: Chua dang nhap.
- **steps**:
  1. Vao ClubDetailScreen
  2. Nhan "Tham gia cau lac bo"
- **testData**: `authProvider.isAuthenticated == false`
- **expectedResult**: `context.push('/login')` duoc goi. Khong goi API join.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-24: TournamentWorkspace — visibleTournaments dedup

- **id**: TC_FLUTTER_24
- **canonicalId**: TC-FLUTTER-24
- **module**: Flutter App
- **title**: TournamentWorkspace.visibleTournaments — loai bo trung lap
- **preconditions**: Tournament co trong ca organized va participating.
- **steps**:
  1. Tao workspace voi tournament trung id
- **testData**: `organizedTournaments = [T(id:"t1")]`, `participatingTournaments = [T(id:"t1")]`
- **expectedResult**: `visibleTournaments.length == 1` (chi 1 instance, khong trung).
- **execution**: `status: "New"`

---

#### TC-FLUTTER-25: TournamentWorkspace — activeRoleCount

- **id**: TC_FLUTTER_25
- **canonicalId**: TC-FLUTTER-25
- **module**: Flutter App
- **title**: TournamentWorkspace.activeRoleCount — dem dung so role
- **preconditions**: Workspace co 3 loai role co tournament.
- **steps**:
  1. Tao workspace
- **testData**: `organizedTournaments=[T()]`, `refereeTournaments=[Invite()]`, `participatingTournaments=[T()]`, `coOrganizerTournaments=[]`
- **expectedResult**: `activeRoleCount == 3` (organized, referee, participating)
- **execution**: `status: "New"`

---

#### TC-FLUTTER-26: CommunityTournamentModel — fromJson parsing

- **id**: TC_FLUTTER_26
- **canonicalId**: TC-FLUTTER-26
- **module**: Flutter App
- **title**: CommunityTournamentModel.fromJson — parse day du fields
- **preconditions**: Co JSON response tu API.
- **steps**:
  1. Parse JSON -> CommunityTournamentModel
  2. Kiem tra tung field
- **testData**: `{ id: "t1", name: "Giai Test", sport: "badminton", format: "SINGLES", status: "DRAFT", maxParticipants: "16", _count: { participants: 3 }, startDate: "2026-08-01" }`
- **expectedResult**: `model.id == "t1"`, `model.name == "Giai Test"`, `model.sport == "badminton"`, `model.format == "SINGLES"`, `model.maxTeams == 16`, `model.teamCount == 3`, `model.startDate == "2026-08-01"`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-27: CommunityTournamentModel — fromJson fallback fields

- **id**: TC_FLUTTER_27
- **canonicalId**: TC-FLUTTER-27
- **module**: Flutter App
- **title**: CommunityTournamentModel.fromJson — xu ly thieu field
- **preconditions**: JSON thieu mot so field.
- **steps**:
  1. Parse JSON thieu field -> kiem tra default values
- **testData**: `{ id: "", name: "" }`
- **expectedResult**: `model.id == ""`, `model.name == ""`, `model.sport == ""`, `model.maxTeams == 16`, `model.teamCount == 0`, `model.status == "draft"`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-28: MyTournamentWorkspaceNotifier — refresh

- **id**: TC_FLUTTER_28
- **canonicalId**: TC-FLUTTER-28
- **module**: Flutter App
- **title**: MyTournamentWorkspaceNotifier.refresh() — cap nhat state
- **preconditions**: Da khoi tao notifier. State co du lieu cu.
- **steps**:
  1. Goi `notifier.refresh()`
- **testData**: `repository.getMyWorkspace()` tra ve workspace moi
- **expectedResult**: State chuyen tu `AsyncLoading` -> `AsyncData(workspaceMoi)`. State co workspace moi.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-29: AuthNotifier — login flow

- **id**: TC_FLUTTER_29
- **canonicalId**: TC-FLUTTER-29
- **module**: Flutter App
- **title**: AuthNotifier — login thanh cong
- **preconditions**: AuthState o trang thai `unauthenticated`.
- **steps**:
  1. Goi `authNotifier.login(accessToken, refreshToken, role)`
- **testData**: `login("token123", "refresh456", UserRole.admin)`
- **expectedResult**: State chuyen `authenticated`. `role == UserRole.admin`. `isAuthenticated == true`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-30: AuthNotifier — logout

- **id**: TC_FLUTTER_30
- **canonicalId**: TC-FLUTTER-30
- **module**: Flutter App
- **title**: AuthNotifier — signOut xoa state
- **preconditions**: Da authenticated.
- **steps**:
  1. Goi `authNotifier.signOut()`
- **testData**: `clearSessionUseCase.call()` OK
- **expectedResult**: State chuyen `unauthenticated`. `role == null`. `isAuthenticated == false`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-31: TournamentActionNotifier — delete tournament

- **id**: TC_FLUTTER_31
- **canonicalId**: TC-FLUTTER-31
- **module**: Flutter App
- **title**: TournamentActionNotifier.deleteTournament — thanh cong
- **preconditions**: Notifier da khoi tao.
- **steps**:
  1. Goi `notifier.deleteTournament("tour-123")`
- **testData**: `deleteTournamentUseCase.call("tour-123")` OK
- **expectedResult**: `state` chuyen `AsyncLoading` -> `AsyncValue(null)`. Tra ve `true`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-32: TournamentActionNotifier — delete that bai

- **id**: TC_FLUTTER_32
- **canonicalId**: TC-FLUTTER-32
- **module**: Flutter App
- **title**: TournamentActionNotifier.deleteTournament — that bai
- **preconditions**: Notifier da khoi tao.
- **steps**:
  1. Goi `notifier.deleteTournament("tour-123")`
- **testData**: `deleteTournamentUseCase.call("tour-123")` throws Exception
- **expectedResult**: Tra ve `false`. State co error.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-33: ClubDetail — Owner thay nut "Quan ly" va "Sua"

- **id**: TC_FLUTTER_33
- **canonicalId**: TC-FLUTTER-33
- **module**: Flutter App
- **title**: ClubDetailScreen — Owner/Admin thay nut QL va Sua trong AppBar
- **preconditions**: Da dang nhap. `_myMembership.role == "OWNER"`.
- **steps**:
  1. Vao ClubDetailScreen
  2. Quan sat AppBar actions
- **testData**: `_myMembership = CommunityMemberModel(role:"OWNER", status:"JOINED")`
- **expectedResult**: AppBar hien thi nut "QL" dan den `/club/:id/manage` va nut "Sua" dan den `/club/:id/edit`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-34: ClubDetail — Member khong thay QL/Sua

- **id**: TC_FLUTTER_34
- **canonicalId**: TC-FLUTTER-34
- **module**: Flutter App
- **title**: ClubDetailScreen — Member thuong khong thay QL/Sua buttons
- **preconditions**: Da dang nhap. `_myMembership.role == "MEMBER"`.
- **steps**:
  1. Vao ClubDetailScreen
  2. Quan sat AppBar
- **testData**: `_myMembership = CommunityMemberModel(role:"MEMBER", status:"JOINED")`
- **expectedResult**: AppBar khong co nut "QL" hoac "Sua".
- **execution**: `status: "New"`

---

#### TC-FLUTTER-35: Profile — Dang xuat

- **id**: TC_FLUTTER_35
- **canonicalId**: TC-FLUTTER-35
- **module**: Flutter App
- **title**: ProfileScreen — sign out thanh cong
- **preconditions**: Da dang nhap. Dang o tab "Cai dat & Tien ich".
- **steps**:
  1. Chuyen sang tab "Cai dat & Tien ich"
  2. Keo xuong cuoi
  3. Nhan "Dang xuat"
- **testData**: `authProvider.notifier.signOut()` OK
- **expectedResult**: `signOut()` duoc goi. `userProfileProvider` bi invalidate. `userRankingsProvider` bi invalidate. Chuyen ve `/home`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-36: Dashboard — TournamentSection hien thi 4 tournament

- **id**: TC_FLUTTER_36
- **canonicalId**: TC-FLUTTER-36
- **module**: Flutter App
- **title**: Dashboard — TournamentSection gioi han 4 tournament
- **preconditions**: `visibleTournaments` co 6 tournament.
- **steps**:
  1. Vao DashboardScreen
  2. Xem TournamentSection
- **testData**: `visibleTournaments = [T1, T2, T3, T4, T5, T6]`
- **expectedResult**: Chi hien thi 4 tournament. Moi tournament co: icon, ten, meta (sport + ngay), 2 buttons "Xem giai" va "Xem bracket".
- **execution**: `status: "New"`

---

#### TC-FLUTTER-37: Dashboard — Workspace loading state

- **id**: TC_FLUTTER_37
- **canonicalId**: TC-FLUTTER-37
- **module**: Flutter App
- **title**: Dashboard — hien thi loading khi workspace dang load
- **preconditions**: `myTournamentWorkspaceProvider` o trang thai loading.
- **steps**:
  1. Vao DashboardScreen
- **testData**: AsyncLoading
- **expectedResult**: `_DashboardLoadingCard` hien thi (CircularProgressIndicator trong card).
- **execution**: `status: "New"`

---

#### TC-FLUTTER-38: Dashboard — Workspace error state

- **id**: TC_FLUTTER_38
- **canonicalId**: TC-FLUTTER-38
- **module**: Flutter App
- **title**: Dashboard — hien thi error card khi workspace loi
- **preconditions**: `myTournamentWorkspaceProvider` tra ve error.
- **steps**:
  1. Vao DashboardScreen
- **testData**: `AsyncError("Network error")`
- **expectedResult**: `_DashboardErrorCard` hien thi: title "Khong the tai khu vuc cua ban", description, button "Tai lai" goi `refresh()`.
- **execution**: `status: "New"`

---

#### TC-FLUTTER-39: Tao Lite tournament — maxTeams border values

- **id**: TC_FLUTTER_39
- **canonicalId**: TC-FLUTTER-39
- **module**: Flutter App
- **title**: Tao Lite tournament — validation bien cua maxTeams (2, 128)
- **preconditions**: Da vao CreateClubTournamentScreen.
- **steps**:
  1. Nhap ten giai hop le
  2. Nhap maxTeams = 2 -> submit -> OK
  3. Nhap maxTeams = 128 -> submit -> OK
  4. Nhap maxTeams = 1 -> submit -> validation loi
  5. Nhap maxTeams = 129 -> submit -> validation loi
- **testData**: `{ maxTeams: [2, 128, 1, 129] }`
- **expectedResult**: 2 va 128 PASS validation. 1 va 129 FAIL: "Tu 2-128 doi".
- **execution**: `status: "New"`

---

#### TC-FLUTTER-40: Navigation routing — redirect logic

- **id**: TC_FLUTTER_40
- **canonicalId**: TC-FLUTTER-40
- **module**: Flutter App
- **title**: GoRouter redirect — chua auth thi redirect ve /home
- **preconditions**: Chua dang nhap. Co gang vao `/referee` hoac `/admin`.
- **steps**:
  1. `state.matchedLocation = "/referee/invites"`
- **testData**: `auth.status == AuthStatus.unauthenticated`
- **expectedResult**: Redirect den `/login`.
- **execution**: `status: "New"`

---

## D. JSON export format (tuong thich tournaments.json)

```json
{
  "schemaVersion": "1.0.0",
  "generatedAt": "2026-07-07T00:00:00.000000+00:00",
  "source": {
    "type": "flutter-test-plan",
    "path": "docs/flutter-test-plan.md"
  },
  "module": {
    "name": "flutter_app",
    "moduleCodes": ["FLUTTER"]
  },
  "summary": {
    "totalTestCases": 40,
    "moduleCodes": ["FLUTTER"]
  },
  "testCases": [
    {
      "id": "TC_FLUTTER_01",
      "canonicalId": "TC-FLUTTER-01",
      "module": {
        "code": "FLUTTER",
        "name": "Flutter App",
        "suite": "flutter_app"
      },
      "title": "...",
      "preconditions": "...",
      "steps": ["..."],
      "testData": {},
      "expectedResult": "...",
      "execution": { "status": "New" },
      "automation": {
        "enabled": true,
        "targetFolder": "flutter_app",
        "generatedSpec": "tests/flutter/"
      }
    }
  ]
}
```

---

## E. Cac test pattern can xay dung

### E.1. Mock helpers (`test/helpers/test_helpers.dart`)

```dart
// Fake classes can co:
// 1. FakeDioClient — mock HTTP responses
// 2. FakeTokenManager — in-memory token storage
// 3. FakeSharedPreferences — in-memory prefs
// 4. MockCommunityRepository — stub API calls
// 5. MockTournamentRepository — stub workspace calls
// 6. Test data factories — createSampleCommunity(), createSampleTournament(), etc.
```

### E.2. Widget test pattern

```dart
// 1. Setup ProviderScope with overridden providers
// 2. Mock all dependencies (DioClient, Repositories)
// 3. Pump widget
// 4. Verify loading state -> data/error state
// 5. Verify interactions (tap, long press, form input)
// 6. Verify API calls were made
// 7. Verify navigation (context.pop, context.push)
```

### E.3. Unit test pattern (Provider)

```dart
// 1. Create ProviderContainer with overrides
// 2. Call notifier method
// 3. Verify state transitions
// 4. Verify repository calls
```

---

## F. Checklist khi implement test

- [ ] Cai dat `mocktail` package
- [ ] Tao `test/helpers/test_helpers.dart` voi fake classes
- [ ] Tao `test/models/community_tournament_model_test.dart`
- [ ] Tao `test/models/tournament_workspace_test.dart`
- [ ] Tao `test/providers/community_provider_test.dart`
- [ ] Tao `test/providers/my_tournament_workspace_provider_test.dart`
- [ ] Tao `test/providers/tournament_action_notifier_test.dart`
- [ ] Tao `test/providers/auth_provider_test.dart`
- [ ] Tao `test/screens/create_club_tournament_screen_test.dart`
- [ ] Tao `test/screens/club_detail_screen_test.dart`
- [ ] Tao `test/screens/profile_screen_test.dart`
- [ ] Tao `test/screens/dashboard_screen_test.dart`
- [ ] Tao `test/repositories/api_community_repository_test.dart`
- [ ] Tao `test/repositories/api_tournament_repository_test.dart`
- [ ] Chay `flutter test` — tat ca Pass
