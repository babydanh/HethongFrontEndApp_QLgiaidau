# APP ROLE + DASHBOARD EXECUTION PLAN

Cap nhat: 2026-07-02

## 0. Tien do thuc te

- Da xong dot dau cua Phase 1:
  - App da dung `GET /tournaments/workspace/me`.
  - Da co entity + provider cho workspace role/invite/match assignment.
  - Da sua man `Loi moi trong tai` sang luong API dung.
  - Da nang cap `/dashboard` thanh man `Cua toi` co loi moi, vai tro, tran duoc giao va giai cua toi.
- Chua xong phan sau cua Phase 1:
  - Chua co dedicated endpoint `matches/me/upcoming` cho player.
  - Chua co flow loi moi BTC/co-organizer accept/decline.
  - Chua tach role projection thong nhat tren backend.

## 1. Muc tieu

Dong bo app mobile voi nghiep vu thuc te cua he thong theo thu tu uu tien:

1. User nhin thay minh dang co vai tro gi.
2. User xu ly duoc loi moi va phan cong cua minh.
3. User xem duoc giai dang tham gia, tran sap toi, va cong viec can xu ly.
4. Trong tai/BTC vao dung man hinh thao tac ma khong phai tu tu duy tim.
5. Chi tiet giai dau va live score gan muc do hoan thien cua web.

## 2. Nguyen tac thuc thi

- UI app giu nhe, tap trung thao tac nhanh tren di dong.
- Khong dua full organizer web vao mobile.
- Role va permission phai ro o backend truoc khi mo rong UI.
- Moi flow moi phai co:
  - API ro rang
  - provider/notifier ro rang
  - route ro rang
  - state loading/empty/error/day du

## 3. Hien trang tom tat

### Da co

- Auth + profile + notifications co nen tang co ban.
- Live score va bracket da ton tai.
- Referee invite screen, club invites, dashboard screen da ton tai o muc co so.
- Notification bell va unread count da duoc noi voi provider.

### Con thieu lon

- Khong co "trung tam vai tro" cho user.
- Khong co man "Cua toi" dung nghia.
- Luong moi trong tai/BTC chua day du va chua ro quyen.
- Chua co dashboard nghiep vu cho giai dang tham gia.
- Chi tiet giai dau thieu division, prize, registration info, match grouping.
- Live viewer/referee chua sau bang web.

## 4. Kien truc du kien

### 4.1 Role model trong app

Can tach 3 lop role:

1. System role
- ADMIN
- MODERATOR
- PLAYER

2. Tournament role
- ORGANIZER_OWNER
- ORGANIZER_MANAGER
- REFEREE_INVITED
- REFEREE_ACCEPTED
- REFEREE_DECLINED
- PARTICIPANT

3. Community role
- CLUB_OWNER
- CLUB_ADMIN
- CLUB_MODERATOR
- CLUB_MEMBER
- CLUB_INVITED

Khong duoc dung 1 bien role don de dai dien tat ca.

### 4.2 Trung tam "Cua toi"

Man "Cua toi" can la trung tam nghiep vu cho mobile:

- Khoi "Loi moi dang cho"
  - Trong tai
  - CLB
  - Doi doi tac/thi dau doi

- Khoi "Vai tro cua toi"
  - Toi la BTC o giai nao
  - Toi la trong tai o giai nao
  - Toi dang la VDV o giai nao

- Khoi "Tran sap toi"
  - Tran sap danh
  - Tran duoc phan cong bat

- Khoi "Giai dang tham gia"
  - Co trang thai
  - Co nut vao chi tiet / live / bracket

## 5. Phase thuc thi

### Phase 1 - Role and Invite Foundation

Muc tieu:
- Chot nen tang role/invite ro rang o backend va app.

Backend can co:
- API lay loi moi cua toi.
- API chap nhan/tu choi loi moi trong tai.
- API lay role cua toi theo tung giai.
- API lay tran duoc phan cong cho toi.
- Guard backend cho phep chi referee duoc phan cong hoac BTC duoc sua diem.

App can co:
- Model cho invitation item.
- Model cho tournament role summary.
- Provider cho:
  - myInvitationsProvider
  - myTournamentRolesProvider
  - myAssignedMatchesProvider

File du kien:
- backend-api_qlgiaidau/src/modules/notifications/*
- backend-api_qlgiaidau/src/modules/matches/*
- backend-api_qlgiaidau/src/modules/tournaments/*
- app_quanly_giaidau/lib/domain/entities/*
- app_quanly_giaidau/lib/data/repositories/api/*
- app_quanly_giaidau/lib/providers/*

Rui ro:
- Hien tai web docs cho thay referee chua la system role day du.
- Can tranh tron system role voi assignment role.

### Phase 2 - Man "Cua toi"

Muc tieu:
- Tao mot man duy nhat de user thay duoc viec cua minh.

Noi dung:
- Header ca nhan ngan gon
- Loi moi dang cho
- Vai tro cua toi
- Tran sap toi
- Giai dang tham gia

File du kien:
- app_quanly_giaidau/lib/features/dashboard/screens/dashboard_screen.dart
- app_quanly_giaidau/lib/features/dashboard/widgets/*
- app_quanly_giaidau/lib/providers/query_providers.dart

Ket qua mong doi:
- Dashboard khong chi hien ELO va quick actions.
- Dashboard tro thanh entry point cho nghiep vu.

### Phase 3 - Luong trong tai day du

Muc tieu:
- Moi trong tai -> chap nhan/tu choi -> vao man tran duoc giao.

UI can co:
- Card loi moi trong tai voi:
  - Ten giai
  - So tran du kien
  - Thoi gian/ghi chu
  - Nut Dong y / Tu choi

- Man "Tran duoc phan cong"
  - Loc theo status
  - Nut "Nhap diem"

- Badge quyen tren live:
  - Chi xem
  - Trong tai
  - BTC

File du kien:
- app_quanly_giaidau/lib/features/referee/screens/referee_invites_screen.dart
- app_quanly_giaidau/lib/features/live/screens/live_match_screen.dart
- app_quanly_giaidau/lib/features/match/screens/*
- app_quanly_giaidau/lib/core/router/app_router.dart

### Phase 4 - Mobile Organizer Workspace lite

Muc tieu:
- Cho BTC thao tac nhe tren mobile, khong sao chep full web.

Scope:
- Danh sach giai toi quan ly
- Muc tieu nhanh:
  - Xem bracket
  - Xem lich
  - Xem participant
  - Xem referee assignments

Khong dua vao mobile trong phase nay:
- Form cau hinh giai phuc tap
- Finance tab day du
- Admin moderation

### Phase 5 - Chi tiet giai dau ngang web muc quan trong

Bat buoc them:
- Division filter
- Prize tab
- Tong quan tach rieng
- Registration info:
  - phi
  - slots
  - thoi gian dang ky
  - contact
  - BTC info
- Matches grouping theo stage
- Seed / san / gio thi dau

File du kien:
- app_quanly_giaidau/lib/features/tournament/screens/tournament_intro_screen.dart
- app_quanly_giaidau/lib/features/tournament/widgets/*

### Phase 6 - Live + score nghiep vu

Muc tieu:
- Live mobile dung nghiep vu hon.

Bat buoc:
- viewerCount
- badge che do chi xem
- tennis score format 0/15/30/40/A/deuce
- panel badminton rieng
- panel bong ban rieng
- score warning
- override reason
- ELO/tier trong score card

### Phase 7 - Ho so va theo doi ban than

Bat buoc:
- CLB dang tham gia
- Giai da tham gia
- Giai dang tham gia
- Tran gan day
- Profile cong khai
- Link xem profile cong khai tu profile cua minh

## 6. Thu tu code de khong bi tac nghen

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 5
5. Phase 6
6. Phase 7
7. Phase 4

Ly do:
- Neu chua ro role/invite thi khong nen lap man UI sau.
- Dashboard va referee flow la diem gia tri cao nhat cho app.
- Organizer mobile workspace nen lam sau khi da co "Cua toi" va role summary.

## 7. Definition of Done cho tung phase

### Phase 1 done khi
- Co API va provider cho invite + role summary.
- Co test tay ro:
  - user nhan loi moi
  - user chap nhan
  - role summary thay doi dung

### Phase 2 done khi
- Dashboard hien du:
  - loi moi
  - vai tro
  - tran sap toi
  - giai dang tham gia

### Phase 3 done khi
- Trong tai vao app thay duoc:
  - loi moi
  - man assignment
  - vao dung tran
  - nguoi khong duoc giao khong thao tac duoc

## 8. Cong viec code truoc ngay

Block code dau tien de mo duong:

1. Chuan hoa provider va entity cho dashboard role summary.
2. Nang dashboard screen thanh man "Cua toi".
3. Chuan hoa referee invite screen thanh card xu ly loi moi that.
4. Them section "tran duoc phan cong" va "giai dang tham gia".

## 9. Ghi chu ve tai lieu

Trong app docs hien khong co day du bo:
- docs/SPEC.md
- docs/PLAN.md
- docs/DATABASE_SCHEMA.md

Nen tam thoi su dung cac file thay the:
- CURRENT_STATUS.md
- endpoint_url.md
- lack_api.md
- PROJECT_OVERVIEW.md
- ARCHITECTURE.md
