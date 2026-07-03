# APP PLAN

Cap nhat: 2026-07-02

## 1. Dinh huong san pham

App mobile khong phai web thu nho.

App chi tap trung vao 6 nhom gia tri:

1. Nguoi dung xem giai da dang ky, lich sap toi, nhanh dau, ket qua, thanh toan cua minh.
2. Trong tai/BTC mo nhanh man hinh cham diem va thao tac tai san.
3. Modal tinh diem theo tung mon phai ro, nhanh, dung nghiep vu.
4. Xu ly loi moi, xac nhan tham gia, xac nhan thanh toan, thong bao.
5. Tao cau lac bo va tao giai dau lite trong cau lac bo de danh nhanh.
6. Ho so ca nhan va lich su cua chinh minh.

App van phai phuc vu dong thoi 2 nhom giai dau:

1. Giai cong khai / giai lon toan he thong
- User xem, dang ky, theo doi, thanh toan, xem nhanh dau, live, ket qua
- Neu user la Trong tai/BTC cua chinh giai do thi van duoc mo modal tinh diem va thao tac theo quyen

2. Giai lite noi bo cau lac bo
- Dung de tao nhanh, danh nhanh, tinh diem nhanh, xem nhanh trong pham vi CLB

Khong dua vao app:

- Admin/moderation sau
- Cau hinh giai dau day du nhu web
- Tai chinh phuc tap cua BTC
- Form cau hinh bracket sau, seed sau, scheduling sau nhu web

## 2. Nguyen tac pham vi

- App uu tien toc do thao tac tai san.
- Moi man phai phuc vu nguoi dang di danh, dang bat tran, dang can check thong tin.
- Neu mot nghiep vu phai nhap qua nhieu field, nghiep vu do de web.
- Neu mot nghiep vu can thao tac nhanh tai san, nghiep vu do uu tien app.

## 3. Rule san pham bat buoc

### 3.1 Khu vuc "Cua toi"

Day la entry point chinh cua user da dang nhap.

Bat buoc co:

- Giai dang tham gia
- Vai tro cua toi
- Loi moi dang cho
- Tran duoc giao / tran sap toi
- CTA vao bracket / live / thong tin giai

Giai trong `Cua toi` gom ca:

- giai cong khai user da dang ky / dang co vai tro
- giai noi bo CLB user dang tham gia / dang co vai tro

### 3.2 UI cham diem

Khong de luon trong trang live viewer.

Mo hinh dung:

- Viewer xem trang live binh thuong
- Neu co quyen Trong tai/BTC thi co nut `Tinh diem`
- Bam vao mo modal/panel tinh diem theo mon
- Modal nay la noi thao tac chinh

Rule nay ap dung cho ca:

- giai cong khai toan he thong
- giai noi bo CLB

Bat buoc:

- Tennis modal rieng
- Pickleball modal rieng
- Cau long modal rieng
- Bong ban modal rieng
- Hinh phat theo schema tung mon
- Canh bao score bat thuong
- Cho phep override co ly do

### 3.3 Loi moi va xac nhan

App phai xu ly du:

- Loi moi trong tai
- Loi moi CLB
- Xac nhan tham gia giai
- Xac nhan thanh toan cua chinh user

Trong do `xac nhan tham gia giai` va `xac nhan thanh toan` chu yeu ap dung cho giai cong khai.

Khong can moderation workflow sau tren app.

### 3.4 Ho so ca nhan

Bat buoc co:

- Thong tin ca nhan cua minh
- Anh dai dien / ho ten / lien he
- ELO / tier / thong ke co ban
- Giai dang tham gia
- Giai da tham gia
- CLB dang tham gia
- Lich su tran gan day
- Lich su thanh toan cua minh

## 4. Dinh nghia "Giai Lite trong Cau Lac Bo"

Day la flow rat quan trong cua app.

Muc tieu:

- Nguoi trong CLB tao nhanh giai de danh choi
- It form
- It rao can
- Len nhanh
- Xem nhanh nhanh dau, live, ket qua
- Co the tinh diem nhanh va cap nhat ELO neu bat

### 4.1 Default nghiep vu

Mac dinh khi tao giai lite trong CLB:

- `tournamentType = CLUB`
- `visibility = PRIVATE`
- `entryFee = 0`
- khong can gallery
- khong can prize phuc tap
- khong can venue phuc tap
- khong can finance config
- khong can bracket config sau

### 4.2 Quyen truy cap

Mac dinh:

- Chi thanh vien CLB moi duoc xem day du giai lite
- Chi BTC / owner / admin CLB moi duoc tao giai lite
- Chi BTC hoac trong tai duoc giao moi duoc cham diem
- Thanh vien CLB co the vao xem nhanh dau, lich, ket qua

Khong nen de mac dinh public cho ca he thong.

Neu can mo rong sau nay:

- Them che do chia se bang link moi
- Hoac che do public tuy chon

Nhung default van phai la noi bo CLB.

### 4.3 Form tao giai lite

Chi giu:

- Ten giai
- Mon
- Don / doi
- The thuc
- So doi toi da
- Co tinh ELO hay khong
- Mo ta ngan

Khong dua:

- prize detail
- gallery
- phan quyen staff sau
- payment config sau
- chia division sau

## 5. Role tren app

Role tren app can the hien theo nghiep vu thuc te:

1. Player
- xem thong tin giai
- dang ky / xac nhan / thanh toan
- xem bracket / lich / live

Player co the thuoc:

- giai cong khai
- giai noi bo CLB

2. Referee
- nhan loi moi
- vao tran duoc giao
- mo modal cham diem

Referee co the bat tran cho:

- giai cong khai
- giai noi bo CLB

3. Organizer Lite
- xem giai minh quan ly
- vao bracket / lich / doi / trong tai
- dieu phoi nhanh tren mobile

Organizer Lite duoc ap dung cho:

- BTC giai cong khai khi can thao tac tai san
- BTC giai noi bo CLB khi can dieu phoi nhanh

4. Club Owner/Admin/Moderator
- tao giai lite trong CLB
- quan ly so bo giai noi bo

Khong day admin he thong vao mobile scope chinh.

## 6. Phase thuc thi

### Phase A - Nen tang nguoi dung

Muc tieu:

- Khu `Cua toi`
- Workspace role/invite
- Giai cua toi / tran cua toi / loi moi

Bat buoc cover du:

- giai cong khai
- giai CLB

Trang thai:

- Da lam mot phan

### Phase B - Referee scoring mobile first

Muc tieu:

- Nut `Tinh diem`
- Modal tinh diem theo mon
- Hinh phat theo schema tung mon
- Role gate ro rang

Bat buoc dung cho ca giai cong khai va giai CLB.

Do uu tien:

- Rat cao

### Phase C - Club + Lite Tournament

Muc tieu:

- Tao CLB
- Tao giai lite trong CLB
- Mac dinh noi bo CLB
- Moi nguoi trong CLB vao xem bracket / live / ket qua

Do uu tien:

- Rat cao

### Phase D - Organizer Lite

Muc tieu:

- Hub giai quan ly tren mobile
- Xem nhanh bracket
- Xem lich
- Xem doi / VDV
- Xem trong tai va assignment

Hub nay khong chi cho giai CLB.

No phai ho tro ca:

- giai cong khai ma user dang la BTC / dong BTC
- giai noi bo CLB ma user dang quan ly

Trang thai:

- Da lam ban dau

### Phase E - Payment + Confirmation

Muc tieu:

- User check thanh toan cua minh
- Xac nhan dang ky / xac nhan ket qua thanh toan
- Khong dua finance dashboard sau cua BTC vao app

### Phase F - Profile cua toi

Muc tieu:

- Ho so ca nhan hoan chinh
- CLB / giai / lich su / elo / thanh toan

## 7. Thu tu lam tiep

1. Hoan thien modal cham diem theo mon
2. Hoan thien flow giai cong khai cho user: dang ky / thanh toan / theo doi
3. Khoa rule cho giai lite trong CLB
4. Hoan thien profile cua toi
5. Chi sau do moi mo rong organizer lite neu can

Ly do:

- Gia tri cao nhat cua app la thao tac tai san
- App phai phuc vu nguoi choi va trong tai truoc, bat ke ho dang o giai cong khai hay giai CLB
- Organizer tren mobile chi nen o muc dieu phoi nhe

## 8. Quy tac quyet dinh

Neu co xung dot giua web va app:

- Web giu nghiep vu cau hinh sau
- App giu nghiep vu thao tac nhanh

Neu co flow nao can hoi:

- flow nay co xay ra khi dang o san khong?
- co can bam nhanh trong 5-10 giay khong?

Neu co:

- uu tien app

Neu khong:

- de web

## 9. Definition of Done

App dung huong khi:

- User mo app thay du viec cua minh
- Trong tai vao tran va cham diem bang modal theo mon de dung o ca giai cong khai va giai CLB
- Thanh vien CLB tao nhanh giai noi bo va vao danh duoc
- User van xem, dang ky, thanh toan, theo doi duoc giai cong khai cua he thong
- Thanh vien CLB xem duoc nhanh dau / live / ket qua noi bo
- User xem duoc profile, lich su va thanh toan cua chinh minh
