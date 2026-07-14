# Test Cases - Flutter App: Auth, Payment, Notification Modules

---

## 1. AUTH MODULE

---

### TC-FLUTTER-AUTH-001: Hien thi man hinh Login mac dinh
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Mo man hinh LoginRegisterScreen (dang o che do login, `_isRegisterMode = false`)
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - Hien thi logo VNSPORT (Hero tag "vnsport_logo")
  - Tieu de "Dang nhap tai khoan"
  - Phu de "Truy cap de quan ly cac giai dau cua ban."
  - Truong nhap Email (icon email_outlined)
  - Truong nhap Mat khau (icon lock_outline, co toggle hien/an mat khau)
  - Lien ket "Quen mat khau?" ben phai truong password
  - Nut "Dang nhap" (mau xanh primary, full width)
  - Phan cach "hoac tiep tuc voi" + nut Google
  - Lien kết "Dang ky ngay" de chuyen sang che do register
  - Lien ket "Kham pha khong can dang nhap"
- **Edge cases**:
  - Kiem tra che do Dark/Light (mau sac thay doi)
  - Responsive layout man hinh nho

### TC-FLUTTER-AUTH-002: Hien thi man hinh Register mac dinh
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Nhan vao "Dang ky ngay" de chuyen sang che do register (`_isRegisterMode = true`)
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - Tieu de "Dang ky thanh vien" thay vi "Dang nhap tai khoan"
  - Phụ de "Gia nhap cong dong the thao VNSPORT."
  - Truong "Ho va ten" xuat hien phia tren (validator bat buoc)
  - Truong Email va Mat khau giong login
  - Nut "Dang ky" thay vi "Dang nhap"
  - An lien ket "Quen mat khau?"
  - Lien ket chuyen ve login: "Dang nhap ngay"
  - Van hien thi nut Google
  - Van hien thi "Kham pha khong can dang nhap"
- **Edge cases**: Chuyen qua lai giua 2 mode nhieu lan, kiem tra `_errorMessage` duoc reset

### TC-FLUTTER-AUTH-003: Login thanh cong voi email/password
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Form o che do login, chua dang nhap
- **Steps**:
  1. Nhap email hop le (vd: `test@example.com`)
  2. Nhap password hop le (>= 6 ky tu)
  3. Nhan nut "Dang nhap"
- **Expected**:
  - `_isLoading = true`, hien thi CircularProgressIndicator tren nut
  - Goi `authProvider.notifier.loginWithEmailPassword(email, password)`
  - Thanh cong (tra ve `true`)
  - `ref.invalidate(userProfileProvider)` duoc goi
  - `ref.invalidate(userRankingsProvider)` duoc goi
  - Dieu huong sang `/login-loading` bang `context.go("/login-loading")`
- **Edge cases**:
  - Email nhap hoa -- thuong duoc trim va lowercase (`email.trim().toLowerCase()`)
  - Password khoang trang 2 dau duoc giu nguyen (khong trim)

### TC-FLUTTER-AUTH-004: Login that bai voi email/password sai
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Form o che do login
- **Steps**:
  1. Nhap email bat ky
  2. Nhap password bat ky
  3. Nhan nut "Dang nhap"
- **Expected**:
  - Goi API login
  - API tra ve loi (throw exception)
  - `_isLoading = false`
  - `_errorMessage` duoc set tu `auth.errorMessage` hoac "Dang nhap that bai"
  - Hien thi error container co icon `error_outline_rounded` va text mau do
  - Khong chuyen trang
- **Edge cases**:
  - Error message tu backend chua "Exception: " prefix duoc loai bo boi `replaceFirst`
  - `_errorMessage` duoc set lai null khi submit lai

### TC-FLUTTER-AUTH-005: Register thanh cong
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Chuyen sang che do register
- **Steps**:
  1. Nhap "Ho va ten" hop le
  2. Nhap email hop le
  3. Nhap password >= 6 ky tu
  4. Nhan nut "Dang ky"
- **Expected**:
  - Goi `authProvider.notifier.registerWithEmailPassword(email, password, fullName)`
  - Thanh cong, chuyen sang `/login-loading`
  - User providers invalidated
- **Edge cases**:
  - `fullName.trim()` duoc gui len (khoang trang 2 dau duoc loai bo)
  - `email.trim().toLowerCase()` duoc gui len

### TC-FLUTTER-AUTH-006: Register that bai
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Che do register
- **Steps**:
  1. Nhap thong tin hop le
  2. Nhan "Dang ky"
- **Expected**:
  - API register throw exception
  - `_isLoading = false`
  - Hien thi error message: `auth.errorMessage` hoac "Dang ky that bai"
  - Khong chuyen trang
- **Edge cases**: Email da ton tai, password qua yeu, loi mang

### TC-FLUTTER-AUTH-007: Validation email khong hop le
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Form login hoac register
- **Steps**:
  1. Nhap email khong hop le (vd: "abc", "abc@", "@gmail.com", "a@b")
  2. Nhap password bat ky
  3. Nhan submit
- **Expected**:
  - `_formKey.currentState!.validate()` tra ve `false`
  - Khong goi `authProvider`
  - Hien thi error ben duoi truong email: "Dinh dang email khong hop le"
- **Edge cases**: Regex: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`

### TC-FLUTTER-AUTH-008: Validation password qua ngan
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Form login hoac register
- **Steps**:
  1. Nhap email hop le
  2. Nhap password < 6 ky tu (vd: "abc12")
  3. Nhan submit
- **Expected**:
  - validation tra ve false
  - Hien thi: "Mat khau phai tu 6 ky tu tro len"
  - Khong goi API

### TC-FLUTTER-AUTH-009: Validation truong trong
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Ca login va register mode
- **Steps**:
  1. De trong email -> submit -> "Vui long nhap email"
  2. De trong password -> submit -> "Vui long nhap mat khau"
  3. Register mode: de trong "Ho va ten" -> submit -> "Vui long nhap ho va ten"
- **Expected**: Tat ca validator tra ve false, khong goi API

### TC-FLUTTER-AUTH-010: Toggle hien/an password
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Form o che do login
- **Steps**:
  1. Nhap password vao truong
  2. Nhan vao icon `visibility_outlined` (con mat)
- **Expected**:
  - `_obscurePassword` tu `true` -> `false`
  - Password hien ra duoi dang plain text
  - Icon chuyen thanh `visibility_off_outlined`
  - Nhan lai -> password an, icon tro lai `visibility_outlined`
- **Edge cases**: Khong gay rebuild khong can thiet

### TC-FLUTTER-AUTH-011: Chuyen giua Login va Register mode
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Dang o login mode
- **Steps**:
  1. Nhan "Dang ky ngay"
- **Expected**:
  - `_isRegisterMode = true`
  - `_errorMessage = null`
  - Hien thi truong "Ho va ten"
  - An "Quen mat khau?"
  - Tieu de thay doi, nut thay doi
  - Nhan "Dang nhap ngay" -> tro lai login mode
- **Edge cases**: `AnimatedSwitcher` va `AnimatedSize` hoat dong muot

### TC-FLUTTER-AUTH-012: Kham pha khong can dang nhap
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Mo man hinh login
- **Steps**:
  1. Nhan vao "Kham pha khong can dang nhap"
- **Expected**: Dieu huong sang `/home`

### TC-FLUTTER-AUTH-013: Login Google thanh cong (mobile)
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Thiet bi mobile (khong phai web), da cai Google Sign-In
- **Steps**:
  1. Nhan nut "Google"
- **Expected**:
  - `_isLoading = true`
  - Goi `_initGoogleSignIn()` (init clientId)
  - Goi `GoogleSignIn.instance.attemptLightweightAuthentication()`
  - Neu lightweight null, goi `googleSignIn.authenticate()`
  - Lay `idToken` tu `googleUser.authentication`
  - Goi `authProvider.notifier.loginWithGoogle(idToken)`
  - Thanh cong: invalidate providers, dieu huong `/login-loading`
- **Edge cases**:
  - User huy Google Sign-In -> throw exception
  - `idToken == null` -> throw "Khong nhan duoc ID Token tu Google"
  - Google Sign-In chua init -> goi `_initGoogleSignIn`
  - `_gsiInitialized` chi init 1 lan (`static`)

### TC-FLUTTER-AUTH-014: Login Google that bai (mobile)
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Thiet bi mobile
- **Steps**:
  1. Nhan nut Google
  2. Chon tai khoan
  3. API Google login tra ve false
- **Expected**:
  - Hien thi error message tu `auth.errorMessage` hoac "Dang nhap Google that bai"
  - `_isLoading = false`
  - Khong chuyen trang

### TC-FLUTTER-AUTH-015: Google Sign-In event listener (authenticationEvents)
- **Module**: auth
- **Screen**: `features/auth/screens/login_register_screen.dart`
- **Preconditions**: Co Google Sign-In instance
- **Steps**:
  1. Khoi tao LoginRegisterScreen (initState)
- **Expected**:
  - Dang ky `GoogleSignIn.instance.authenticationEvents.listen()`
  - Khi nhan `GoogleSignInAuthenticationEventSignIn`: tu dong xu ly login
  - Lay idToken -> loginWithGoogle
  - Thanh cong: `/login-loading`
  - That bai: hien error
- **Edge cases**:
  - event khong phai `GoogleSignInAuthenticationEventSignIn` -> bo qua
  - idToken null -> throw exception
  - Trong web: goi `_initGoogleSignIn()` trong initState

### TC-FLUTTER-AUTH-016: Splash screen hien thi va animation
- **Module**: auth
- **Screen**: `features/auth/screens/splash_screen.dart`
- **Preconditions**: Mo app
- **Steps**:
  1. Quan sat man hinh SplashScreen
- **Expected**:
  - Background mau `bgDark`
  - Logo VNSPORT (Hero tag "vnsport_logo") fade in + scale tu 0.92 -> 1.0
  - Tagline "To chuc giai dau chuyen nghiep"
  - CircularProgressIndicator
  - Animation keo dai 1000ms
  - Sau 1500ms, goi `_initAuth()`
- **Edge cases**: Logo fail -> fallback text "VNSPORT"

### TC-FLUTTER-AUTH-017: Splash init() restore session thanh cong co JWT
- **Module**: auth
- **Screen**: `features/auth/screens/splash_screen.dart`
- **Preconditions**: Co JWT valid trong secure storage
- **Steps**:
  1. Mo app -> Splash
  2. `_initAuth()` -> `authProvider.notifier.init()`
- **Expected**:
  - `tokenManager.hasValidToken()` tra ve `true`
  - `tokenManager.getRole()` tra ve role
  - `state = AuthStatus.authenticated`, `role = restoredRole`, `tokenCode = "SESSION"`
  - `auth.isAuthenticated = true`
  - `auth.tournamentId` null -> dieu huong `/home`
  - `auth.tournamentId` co gia tri:
    - `role == admin` -> `/admin/tournament/{tournamentId}`
    - `role == referee` -> `/referee`
    - `role == viewer` -> `/viewer`
- **Edge cases**:
  - Role string khong khop enum -> fallback `UserRole.viewer`

### TC-FLUTTER-AUTH-018: Splash init() restore session tu saved invite token
- **Module**: auth
- **Screen**: `features/auth/screens/splash_screen.dart`
- **Preconditions**: Khong co JWT, co saved invite token
- **Steps**:
  1. Mo app -> Splash -> init()
- **Expected**:
  - `hasValidToken()` tra ve `false`
  - Goi `restoreSavedInviteTokenUseCase`
  - Co saved token -> goi `validateToken(savedToken)`
  - Token valid -> `isAuthenticated = true` -> dieu huong theo role
  - Token invalid -> `isAuthenticated = false` -> `/home`
- **Edge cases**: savedToken null hoac empty -> `/home`

### TC-FLUTTER-AUTH-019: Splash init() khong co session nao
- **Module**: auth
- **Screen**: `features/auth/screens/splash_screen.dart`
- **Preconditions**: Chua tung dang nhap, ko co JWT, ko co token
- **Steps**:
  1. Mo app -> Splash -> init()
- **Expected**: `isAuthenticated = false` -> dieu huong `/home`

### TC-FLUTTER-AUTH-020: Forgot password gui email thanh cong
- **Module**: auth
- **Screen**: `features/auth/screens/forgot_password_screen.dart`
- **Preconditions**: Mo man hinh ForgotPassword
- **Steps**:
  1. Nhap email hop le (vd: `test@example.com`)
  2. Nhan "Gui yeu cau"
- **Expected**:
  - `_submitting = true`, hien thi spinner
  - Goi `POST /auth/forgot-password` voi `{'email': email}`
  - API thanh cong (khong throw)
  - `_sent = true`
  - Hien thi man hinh xac nhan: icon `mark_email_read_rounded` + "Email da duoc gui!" + "Vui long kiem tra hop thu..."
  - Nut "Quay lai dang nhap" -> dieu huong `/login`
- **Edge cases**: `_sent` state duy tri dung

### TC-FLUTTER-AUTH-021: Forgot password gui email that bai
- **Module**: auth
- **Screen**: `features/auth/screens/forgot_password_screen.dart`
- **Preconditions**: Mo man hinh ForgotPassword
- **Steps**:
  1. Nhap email
  2. Nhan "Gui yeu cau"
- **Expected**:
  - API throw exception
  - Hien thi SnackBar: "Loi: {error}"
  - `_submitting = false`
  - Khong chuyen sang man hinh `_buildSent()`
- **Edge cases**: Loi mang, email khong ton tai, server error

### TC-FLUTTER-AUTH-022: Forgot password validation
- **Module**: auth
- **Screen**: `features/auth/screens/forgot_password_screen.dart`
- **Preconditions**: Mo man hinh ForgotPassword
- **Steps**:
  1. De trong email -> nhan submit
  2. Nhap email khong co '@' -> nhan submit
- **Expected**:
  - `_submit()` tra ve ngay (khong goi API)
  - `_submitting` khong thay doi
- **Edge cases**: Chi kiem tra `email.isEmpty` va `!email.contains('@')` (kha loong leo)

### TC-FLUTTER-AUTH-023: Login loading screen hien thi thong tin nguoi dung
- **Module**: auth
- **Screen**: `features/auth/screens/login_loading_screen.dart`
- **Preconditions**: Sau khi login thanh cong, chuyen sang `/login-loading`
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - Header `VnsportHeaderPainter` (isLoggedIn: true)
  - Logo VNSPORT (Hero tag)
  - Hien thi `userProfileAsync.when()`:
    - `data`: "CHAO MUNG QUAY TRO LAI" + ten nguoi dung (`profile.fullName` hoac "Nguoi dung")
    - `loading`: CircularProgressIndicator
    - `error`: "Dang nhap thanh cong!"
  - Spinner ben duoi
  - Sau 2200ms -> tu dong chuyen sang `/home`
- **Edge cases**:
  - Timer chi chay 1 lan, `mounted` check truoc khi goi

### TC-FLUTTER-AUTH-024: validateToken() thanh cong
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: AuthNotifier chua xac thuc
- **Steps**:
  1. Goi `validateToken("ADM-XXXX")`
- **Expected**:
  - `state.status = AuthStatus.validating`
  - Goi `validateInviteTokenUseCase` voi tokenCode
  - Token tra ve hop le voi role hop le (admin/referee/viewer)
  - `state = AuthStatus.authenticated`, set role, tournamentId, tokenCode
  - Goi `saveInviteTokenUseCase` de luu token
  - Goi `savedTournamentsProvider.notifier.saveTournament()`
  - `_startTokenListener()` duoc goi
  - Tra ve `true`
- **Edge cases**:
  - Token "ADM-XXX" -> role admin
  - Token "REF-XXX" -> role referee
  - Token "VWR-XXX" -> role viewer

### TC-FLUTTER-AUTH-025: validateToken() that bai - token null
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `validateToken("INVALID")`
- **Expected**:
  - API tra ve `null`
  - `state = AuthStatus.invalid`, `errorMessage = 'Token khong hop le hoac da het han'`
  - Tra ve `false`

### TC-FLUTTER-AUTH-026: validateToken() that bai - role khong xac dinh
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `validateToken("XXX-YYYY")` (token ton tai nhung role = "unknown")
- **Expected**:
  - Token tra ve hop le nhung role khong khop 'admin'/'referee'/'viewer'
  - `switch` roi vao `_ => null`
  - `state = AuthStatus.invalid`, `errorMessage = 'Vai tro khong xac dinh'`
  - Tra ve `false`

### TC-FLUTTER-AUTH-027: validateToken() that bai - exception
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `validateToken("ERROR-TOKEN")` (API throw exception)
- **Expected**:
  - `catch` block bat loi
  - `state = AuthStatus.invalid`, `errorMessage = 'Loi xac thuc: {error}'`
  - Tra ve `false`

### TC-FLUTTER-AUTH-028: loginLocally()
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: Vua tao giai dau xong (backend da tao token)
- **Steps**: Goi `loginLocally(tokenCode: "ADM-XXX", role: UserRole.admin, tournamentId: "t123")`
- **Expected**:
  - `saveInviteTokenUseCase` goi luu token
  - `savedTournamentsProvider` goi save
  - `state = AuthStatus.authenticated`, role = admin, tournamentId = "t123", tokenCode = "ADM-XXX"
  - `_startTokenListener` duoc goi
  - Khong goi API validate

### TC-FLUTTER-AUTH-029: loginWithEmailPassword() xu ly session
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `loginWithEmailPassword("test@test.com", "password123")`
- **Expected**:
  - `state.status = AuthStatus.validating`
  - Goi `loginWithEmailUseCase`
  - Goi `_mapSessionRole()` de xac dinh role tu `session.roles`
  - Goi `_saveJwtSession()` de luu accessToken + refreshToken
  - `state = AuthStatus.authenticated`, `tokenCode = "SESSION"`
  - Tra ve `true`
- **Edge cases**: 
  - roles chua "ADMIN" hoac "admin" -> admin
  - roles chua "REFEREE"/"referee" -> referee
  - roles khong chua cac role tren -> viewer
  - Roles la ["ADMIN", "referee"] -> admin (uutien ADMIN)

### TC-FLUTTER-AUTH-030: loginWithGoogle() xu ly session
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `loginWithGoogle("google-id-token")`
- **Expected**:
  - Goi `loginWithGoogleUseCase` voi idToken
  - `_mapSessionRole`, `_saveJwtSession`
  - `state = AuthStatus.authenticated`, `tokenCode = "SESSION"`
  - Tra ve `true`

### TC-FLUTTER-AUTH-031: registerWithEmailPassword() xu ly session
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Steps**: Goi `registerWithEmailPassword("test@test.com", "pass123", "Nguyen Van A")`
- **Expected**:
  - Goi `registerWithEmailUseCase` voi email, password, fullName
  - `_mapSessionRole`, `_saveJwtSession`
  - `state = AuthStatus.authenticated`, `tokenCode = "SESSION"`
  - Tra ve `true`

### TC-FLUTTER-AUTH-032: signOut() xoa session
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: Dang o trang thai authenticated
- **Steps**: Goi `signOut(reason: "Ly do bat ky")`
- **Expected**:
  - `_tokenSubscription?.cancel()`
  - `_tokenSubscription = null`
  - `clearSessionUseCase` duoc goi
  - `state = AuthStatus.unauthenticated`, `errorMessage = "Ly do bat ky"`
- **Edge cases**: Goi signOut() khong co reason -> `state.errorMessage = null`

### TC-FLUTTER-AUTH-033: _startTokenListener() phat hien token bi vo hieu hoa
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: `validateToken()` thanh cong, `tokenCode != "SESSION"`
- **Steps**:
  1. Token bi xoa / vo hieu hoa tu backend
- **Expected**:
  - `tokenRepositoryProvider.watchToken(tokenCode)` emit `null`
  - `_startTokenListener` kiem tra: token == null && state.isAuthenticated == true
  - Tu dong goi `signOut(reason: 'Phien dang nhap da het han hoac ma truy cap da duoc doi.')`

### TC-FLUTTER-AUTH-034: _startTokenListener() khong lang nghe SESSION token
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: `tokenCode == "SESSION"` (email/google login)
- **Steps**:
  1. Login email thanh cong -> `tokenCode = "SESSION"`
- **Expected**:
  - `_startTokenListener` tra ve ngay (`if (tokenCode == 'SESSION') return;`)
  - Khong subscribe `watchToken`
  - Khong co auto logout khi session bi thu hoi

### TC-FLUTTER-AUTH-035: AuthState cac getter
- **Module**: auth
- **Provider**: `providers/auth_provider.dart`
- **Preconditions**: Tao AuthState voi cac status khac nhau
- **Steps**:
  1. `AuthStatus.authenticated`, role = admin -> `isAuthenticated=true`, `isAdmin=true`, `canScore=true`
  2. `AuthStatus.authenticated`, role = referee -> `isReferee=true`, `canScore=true`
  3. `AuthStatus.authenticated`, role = viewer -> `isViewer=true`, `canScore=false`
  4. `AuthStatus.unauthenticated` -> `isAuthenticated=false`, `canScore=false`
  5. `AuthStatus.invalid` -> `isAuthenticated=false`
  6. `AuthStatus.validating` -> `isAuthenticated=false`
- **Edge cases**: `isAuthenticated` chi dung khi `status == AuthStatus.authenticated`

### TC-FLUTTER-AUTH-036: Token input sheet - submit token thanh cong
- **Module**: auth
- **Screen**: `features/home/widgets/token_input_sheet.dart`
- **Preconditions**: Mo bottom sheet TokenInputSheet
- **Steps**:
  1. Nhap token hop le (vd: "ADM-XXXX")
  2. Nhan "Xac nhan"
- **Expected**:
  - `_tokenController.text.trim().toUpperCase()` -> "ADM-XXXX"
  - Goi `authProvider.notifier.validateToken(token)`
  - Thanh cong:
    - `ref.invalidate(userProfileProvider, userRankingsProvider)`
    - `Navigator.pop(context)` dong sheet
    - `context.go(route)` den trang phu hop
    - `route = NavigationHelper.getTournamentRoute(role, tournamentId)`
- **Edge cases**: Nhap thuong "adm-xxxx" -> uppercase thanh "ADM-XXXX"

### TC-FLUTTER-AUTH-037: Token input sheet - submit token that bai
- **Module**: auth
- **Screen**: `features/home/widgets/token_input_sheet.dart`
- **Preconditions**: Mo bottom sheet
- **Steps**:
  1. Nhap token khong hop le
  2. Nhan "Xac nhan"
- **Expected**:
  - `validateToken()` tra ve `false`
  - `_tokenError` hien thi tu `auth.errorMessage` hoac "Ma khong hop le"
  - Input field bi shake animation
  - Hien thi error icon + text
  - Khong dong sheet, khong chuyen trang
  - `_isSubmittingToken = false`

### TC-FLUTTER-AUTH-038: Token input sheet - empty token
- **Module**: auth
- **Screen**: `features/home/widgets/token_input_sheet.dart`
- **Steps**:
  1. De trong truong token
  2. Nhan "Xac nhan"
- **Expected**:
  - Validation tra ve ngay: `_tokenError = 'Vui long nhap ma token'`
  - Khong goi `validateToken()`

### TC-FLUTTER-AUTH-039: Token input sheet - clear error khi thay doi input
- **Module**: auth
- **Screen**: `features/home/widgets/token_input_sheet.dart`
- **Preconditions**: Co `_tokenError` dang hien thi
- **Steps**:
  1. Nhap ky tu vao truong token (onChanged)
- **Expected**:
  - `_tokenError` duoc set ve `null`
  - Error widget bien mat

### TC-FLUTTER-AUTH-040: Token input sheet - onSubmitted xu ly
- **Module**: auth
- **Screen**: `features/home/widgets/token_input_sheet.dart`
- **Steps**:
  1. Nhap token
  2. Nhan Enter/Return tren ban phim
- **Expected**:
  - `onSubmitted` duoc goi
  - `_isSubmittingToken = true`
  - Goi `_submitToken()`
  - Sau khi hoan tat, neu `_tokenError != null` -> `_isSubmittingToken = false`
- **Edge cases**: Dung `.then()` de set lai loading -> can dam bao mounted truoc khi setState

---

## 2. PAYMENT MODULE

---

### TC-FLUTTER-PAYMENT-001: Checkout screen hien thi thong tin
- **Module**: payment
- **Screen**: `features/payment/screens/checkout_screen.dart`
- **Preconditions**: Mo CheckoutScreen voi `tournamentId`, `participantId`, `amount`, `tournamentName`
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - AppBar: "Thanh toan"
  - Card hien thi so tien (dinh dang VND, `NumberFormat('#,###', 'vi_VN')`)
  - Hien thi "LE PHI THAM GIA"
  - Hien thi `tournamentName` (neu co)
  - Danh sach 4 cong thanh toan: PayOS, VNPAY, MoMo, Chuyen khoan
  - Gateway mac dinh: PAYOS duoc chon (highlight)
  - Dieu khoan: "BANG CACH NHAN THANH TOAN, BAN DONG Y VOI DIEU KHOAN CUA CHUNG TOI"
  - Nut "Thanh toan {amount}đ"
- **Edge cases**: `tournamentName = null` -> khong hien section tournament name

### TC-FLUTTER-PAYMENT-002: Checkout - chon gateway khac
- **Module**: payment
- **Screen**: `features/payment/screens/checkout_screen.dart`
- **Preconditions**: Mo man hinh checkout
- **Steps**:
  1. Nhan vao gateway "MoMo" (hoac bat ky gateway nao khac PAYOS)
- **Expected**:
  - `_selectedGateway` thay doi
  - Gateway duoc chon co border mau + shadow
  - Nut radio tron duoc chon
- **Edge cases**: Chon tung gateway, kiem tra id dung: PAYOS, VNPAY, MOMO, TRANSFER

### TC-FLUTTER-PAYMENT-003: Checkout - thanh toan PAYOS thanh cong
- **Module**: payment
- **Screen**: `features/payment/screens/checkout_screen.dart`
- **Preconditions**: Gateway = PAYOS
- **Steps**:
  1. Nhan "Thanh toan"
- **Expected**:
  - `_isSubmitting = true`, hien spinner
  - Goi `paymentRepositoryProvider.createPaymentLink()` voi `CreatePaymentDto`
  - API tra ve `paymentId` va `paymentUrl` (khong null, khong rong)
  - `launchUrl(uri, mode: LaunchMode.externalApplication)` mo trinh duyet
  - Dieu huong sang `/payment/payos-verify` voi extra: paymentId, amount, tournamentId, tournamentName
- **Edge cases**: `result['paymentUrl']` rong -> SnackBar "Khong nhan duoc lien ket thanh toan tu PayOS"

### TC-FLUTTER-PAYMENT-004: Checkout - thanh toan VNPAY/MoMo/TRANSFER
- **Module**: payment
- **Screen**: `features/payment/screens/checkout_screen.dart`
- **Preconditions**: Gateway khac PAYOS
- **Steps**:
  1. Chon gateway VNPAY (hoac MOMO, TRANSFER)
  2. Nhan "Thanh toan"
- **Expected**:
  - `paymentRepositoryProvider.createPaymentLink()` goi voi gateway tuong ung
  - Dieu huong sang `/payment/mock-gateway` voi extra: paymentId, gateway, amount, tournamentId
  - Khong mo trinh duyet

### TC-FLUTTER-PAYMENT-005: Checkout - createPaymentLink that bai
- **Module**: payment
- **Screen**: `features/payment/screens/checkout_screen.dart`
- **Steps**:
  1. Nhan "Thanh toan"
- **Expected**:
  - `result == null` -> SnackBar "Khong the tao lien ket thanh toan"
  - `throw exception` -> SnackBar "Loi: {error}"
  - `_isSubmitting = false`

### TC-FLUTTER-PAYMENT-006: Mock gateway - hien thi man hinh
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Preconditions**: Mo MockGatewayScreen voi extra: gateway, amount, paymentId
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - AppBar: "Xac thuc {label}" (VNPAY/MoMo/Chuyen khoan ngan hang)
  - Icon shield voi mau cua gateway
  - So tien hien thi
  - 6 o nhap OTP (moi o 1 ky tu so)
  - Timer dem nguoc 180 giay (03:00)
  - Nut "Xac nhan thanh toan" (disabled khi chua nhap du 6 so)
  - Lien ket "Huy"
- **Edge cases**:
  - Mau VNPAY (0xFF1565C0), MOMO (0xFFD81B60), TRANSFER (0xFF059669)

### TC-FLUTTER-PAYMENT-007: Mock gateway - nhap OTP tu dong chuyen focus
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Steps**:
  1. Nhap so vao o OTP thu 1
- **Expected**:
  - `_onOtpChange(0, "5")`: chi cho phep 1 ky tu, chi cho phep so
  - Tu dong focus sang o thu 2 (`_otpFocusNodes[1].requestFocus()`)
  - Tiep tuc nhap -> focus chuyen dan den o cuoi cung
- **Edge cases**:
  - Nhap ky tu khong phai so -> bi chan (`if (!RegExp(r'^\d$').hasMatch(value)) return;`)
  - Paste nhieu ky tu -> `value.substring(0, 1)` giu lai ky tu dau

### TC-FLUTTER-PAYMENT-008: Mock gateway - verify OTP thanh cong
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Preconditions**: Da nhap du 6 so OTP
- **Steps**:
  1. Nhan "Xac nhan thanh toan"
- **Expected**:
  - `_isSubmitting = true`
  - OTP = 6 so ghep lai
  - `otp.length < 6` -> return (khong cho submit neu thieu so)
  - Goi `paymentRepositoryProvider.mockVerify(paymentId)`
  - `success == true` -> dieu huong `/payment/result` voi `{status: 'success', tournamentId, amount}`
- **Edge cases**: So tien truyen di la `extra?['amount']`

### TC-FLUTTER-PAYMENT-009: Mock gateway - verify OTP that bai
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Steps**:
  1. Nhap sai OTP
  2. Nhan "Xac nhan thanh toan"
- **Expected**:
  - `mockVerify()` tra ve `false`
  - SnackBar: "Ma OTP khong hop le!"
  - `_isSubmitting = false` (finaly block)
  - Khong chuyen trang

### TC-FLUTTER-PAYMENT-010: Mock gateway - timer het han
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Preconditions**: Mo man hinh, timer bat dau tu 180
- **Steps**:
  1. Doi cho timer chay ve 00:00
- **Expected**:
  - `_timeLeft` giam dan ve 0
  - Khi `_timeLeft <= 0`: `_timer.cancel()`, `_isExpired = true`
  - Hien thi "Ma da het han" mau do thay vi thoi gian
  - Nut "Xac nhan thanh toan" disabled
- **Edge cases**: Timer`cancel` khi `_timeLeft <= 0` de tranh memory leak

### TC-FLUTTER-PAYMENT-011: Mock gateway - huy
- **Module**: payment
- **Screen**: `features/payment/screens/mock_gateway_screen.dart`
- **Steps**:
  1. Nhan "Huy"
- **Expected**: `context.pop()` quay lai man hinh truoc

### TC-FLUTTER-PAYMENT-012: PayOS verify screen hien thi
- **Module**: payment
- **Screen**: `features/payment/screens/payos_verify_screen.dart`
- **Preconditions**: Mo PayOSVerifyScreen voi paymentId, amount, tournamentId, tournamentName
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - AppBar: "Xac nhan thanh toan" (khong co back button, `automaticallyImplyLeading: false`)
  - Icon receipt (mau PayOS #FF5622)
  - "Thanh toan qua PayOS"
  - Huong dan: "Vui long hoan thanh giao dich chuyen khoan tren trinh duyet web vua mo."
  - Thong tin: So tien + "Dang cho thanh toan..." (co spinner)
  - Nut "Toi da thanh toan"
  - Nut "Huy va quay ve trang chu"
- **Edge cases**: `tournamentName` co the null

### TC-FLUTTER-PAYMENT-013: PayOS verify - tu dong poll moi 5 giay
- **Module**: payment
- **Screen**: `features/payment/screens/payos_verify_screen.dart`
- **Preconditions**: Mo man hinh
- **Steps**:
  1. Quan sat (khong can thao tac)
- **Expected**:
  - `_autoCheckTimer` chay `Timer.periodic(Duration(seconds: 5))`
  - Moi lan goi `_verifyPaymentStatus(silent: true)` (khong show loading)
  - Toi da 12 lan (60 giay), sau do `_autoCheckTimer.cancel()`
  - `_checkAttempts` tang dan
- **Edge cases**: `payment.isCompleted` -> dieu huong `/payment/result` voi status success, cancel timer
- **Edge cases**: `payment.isFailed` -> dieu huong `/payment/result` voi status fail, cancel timer

### TC-FLUTTER-PAYMENT-014: PayOS verify - nhan "Toi da thanh toan" thanh cong
- **Module**: payment
- **Screen**: `features/payment/screens/payos_verify_screen.dart`
- **Steps**:
  1. Nhan "Toi da thanh toan"
- **Expected**:
  - `_isChecking = true`
  - Goi `paymentRepositoryProvider.getPaymentById(widget.paymentId)`
  - `payment.isCompleted == true` -> dieu huong `/payment/result` voi status success
- **Edge cases**: payment null -> SnackBar "He thong chua nhan duoc thanh toan..."

### TC-FLUTTER-PAYMENT-015: PayOS verify - that bai
- **Module**: payment
- **Screen**: `features/payment/screens/payos_verify_screen.dart`
- **Steps**:
  1. Nhan "Toi da thanh toan"
- **Expected**:
  - `payment.isFailed == true` -> `/payment/result` status fail
  - `throw exception` -> SnackBar "Co loi xay ra: {error}"
  - `_isChecking = false`

### TC-FLUTTER-PAYMENT-016: PayOS verify - huy quay ve
- **Module**: payment
- **Screen**: `features/payment/screens/payos_verify_screen.dart`
- **Steps**:
  1. Nhan "Huy va quay ve trang chu"
- **Expected**:
  - `_autoCheckTimer?.cancel()`
  - `context.pushReplacement('/home')`

### TC-FLUTTER-PAYMENT-017: Payment result screen - thanh cong
- **Module**: payment
- **Screen**: `features/payment/screens/payment_result_screen.dart`
- **Preconditions**: Mo PaymentResultScreen voi extra: `{status: 'success', tournamentId: 't123', amount: 100000}`
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - Icon `check_circle_rounded` mau xanh (success), animation scale elasticOut
  - "Thanh toan thanh cong!"
  - "Ban da thanh toan 100,000đ"
  - "Chuc ban thi dau tot!" (success message)
  - Nut "Quay lai giai dau" -> `/intro/t123`
  - Nut "Ve trang chu" -> `/home`
- **Edge cases**: `tournamentId` rong -> nut "Quay lai giai dau" ve `/home`

### TC-FLUTTER-PAYMENT-018: Payment result screen - that bai
- **Module**: payment
- **Screen**: `features/payment/screens/payment_result_screen.dart`
- **Preconditions**: extra: `{status: 'fail', tournamentId: '', amount: 100000}`
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - Icon `cancel_rounded` mau do
  - "Thanh toan that bai"
  - "Giao dich khong the hoan tat. Vui long thu lai!"
  - Khong hien "Chuc ban thi dau tot!"
  - Nut "Quay lai giai dau" -> `/home` (vi tournamentId rong)
  - Nut "Ve trang chu" -> `/home`
- **Edge cases**: `extra == null` -> `isSuccess = false`, `tournamentId = ''`, `amount = 0`

### TC-FLUTTER-PAYMENT-019: Payments screen - lich su thanh toan
- **Module**: payment
- **Screen**: `features/payment/screens/payments_screen.dart`
- **Preconditions**: Da co cac giao dich thanh toan
- **Steps**:
  1. Mo PaymentsScreen
- **Expected**:
  - AppBar: "Lich su thanh toan"
  - Hien thi `myPaymentsProvider` (FutureProvider)
  - Stats header: "Tong giao dich: {n} giao dich"
  - Neu co pending payments -> badge "X cho"
  - Danh sach payment cards: icon status, tournament name, gateway, date
  - Moi card hien thi: icon theo status (check/xam/dong ho/that bai), so tien, status label
  - `RefreshIndicator` keo de refresh
- **Edge cases**: `payments.isEmpty` -> hien thi empty state voi icon `receipt_long_rounded`, text "Chua co giao dich nao"

### TC-FLUTTER-PAYMENT-020: Payments screen - hien thi cac status khac nhau
- **Module**: payment
- **Screen**: `features/payment/screens/payments_screen.dart`
- **Preconditions**: Co payment voi cac status khac nhau
- **Steps**:
  1. Quan sat payment cards
- **Expected**:
  - `isCompleted`: icon `check_circle_rounded`, mau success
  - `isPending`: icon `access_time_rounded`, mau warning
  - `isFailed`: icon `cancel_rounded`, mau error
  - Khong phai cac status tren: icon `replay_rounded`, mau textMuted
  - `transactionReference != null` -> hien thi "Ma GD: {reference}"
- **Edge cases**: `payment.tournamentName = null` -> fallback "Thanh toan giai dau"

### TC-FLUTTER-PAYMENT-021: Payments screen - refresh
- **Module**: payment
- **Screen**: `features/payment/screens/payments_screen.dart`
- **Steps**:
  1. Keo xuong de refresh
- **Expected**:
  - `ref.refresh(myPaymentsProvider)` duoc goi
  - `RefreshIndicator` hien thi spinner
  - Danh sach duoc cap nhat

---

## 3. NOTIFICATION MODULE

---

### TC-FLUTTER-NOTIFICATION-001: Notification screen - hien thi danh sach
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: Co notifications tu API
- **Steps**:
  1. Mo NotificationScreen
- **Expected**:
  - AppBar: "Thong bao", co back button
  - `notificationStateProvider` duoc watch
  - `loadPage(1)` duoc goi tu `Future.microtask`
  - Danh sach notifications duoc nhom theo ngay: "Hom nay", "Hom qua", "Tuan nay", hoac ngay cu the
  - Moi card co: icon theo type, title (bold neu chua doc), body (toi da 2 dong), `timeAgo`
  - Unread badge: cham tron xanh (8x8) ben phai title
  - Neu co notification chua doc -> hien nut "Doc tat ca" o AppBar
- **Edge cases**: `notifications.isEmpty && currentPage == 0` -> hien CircularProgressIndicator (loading lan dau)
- **Edge cases**: `notifications.isEmpty && currentPage > 0` -> empty state

### TC-FLUTTER-NOTIFICATION-002: Notification screen - empty state
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: API tra ve danh sach rong
- **Steps**:
  1. Mo NotificationScreen
- **Expected**:
  - Icon `notifications_none_rounded`
  - "Chua co thong bao nao"
  - "Cac thong bao se hien thi tai day"

### TC-FLUTTER-NOTIFICATION-003: Notification grouping theo thoi gian
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: Co notifications voi cac createdAt khac nhau
- **Steps**:
  1. Quan sat man hinh
- **Expected**:
  - `diff.inDays == 0` -> nhom "Hom nay"
  - `diff.inDays == 1` -> nhom "Hom qua"
  - `diff.inDays < 7` -> nhom "Tuan nay"
  - `diff.inDays >= 7` -> nhom "dd/mm/yyyy"
  - Section header hien phia tren moi nhom

### TC-FLUTTER-NOTIFICATION-004: Notification - danh dau da doc khi tap
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: Co notification chua doc
- **Steps**:
  1. Nhan vao notification chua doc
- **Expected**:
  - Goi `notificationStateProvider.notifier.markAsRead(notif.id)`
  - `notif.isRead` chuyen thanh `true`
  - Title chuyen tu fontWeight.w700 -> w500
  - Cham tron bien mat
  - `unreadCountProvider` duoc invalidate
  - Neu `notif.redirectUrl` khong rong -> `context.go(notif.redirectUrl)`

### TC-FLUTTER-NOTIFICATION-005: Notification - redirect URL
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: Co notification voi redirectUrl hop le
- **Steps**:
  1. Nhan vao notification co redirectUrl
- **Expected**:
  - `redirectUrl != null && redirectUrl!.isNotEmpty` -> `context.go(redirectUrl!)`
- **Edge cases**:
  - `redirectUrl = null` hoac rong -> chi danh dau da doc, khong chuyen trang (khong goi `context.go`)

### TC-FLUTTER-NOTIFICATION-006: Notification - doc tat ca
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: Co nhieu notification chua doc
- **Steps**:
  1. Nhan "Doc tat ca" o AppBar
- **Expected**:
  - Goi `notificationStateProvider.notifier.markAllAsRead()`
  - Tat ca notification `isRead = true` (cap nhat state local)
  - `unreadCountProvider` invalidated
  - Tat ca cham tron bien mat, titles ve fontWeight.w500
- **Edge cases**: Khong co notification chua doc -> an nut "Doc tat ca"

### TC-FLUTTER-NOTIFICATION-007: Notification - pagination (load more)
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Preconditions**: API co nhieu hon 20 notifications
- **Steps**:
  1. Mo NotificationScreen
  2. Cuon xuong cuoi danh sach
- **Expected**:
  - `_scrollController.position.pixels >= maxScrollExtent - 200` -> trigger load more
  - `hasMore == true` va `_isLoadingMore == false` -> goi `loadPage(currentPage + 1)`
  - Hien thi spinner o cuoi danh sach
  - `_isLoadingMore = true`, sau do `false` khi hoan tat
  - Notifications moi duoc append vao danh sach
  - `state.currentPage` tang len
- **Edge cases**: `hasMore == false` -> khong load them
- **Edge cases**: Scroll listener dispose dung cach (`removeListener` + `dispose`)

### TC-FLUTTER-NOTIFICATION-008: Notification - pull to refresh
- **Module**: notification
- **Screen**: `features/notification/screens/notification_screen.dart`
- **Steps**:
  1. Keo xuong de refresh
- **Expected**:
  - `RefreshIndicator.onRefresh` -> goi `loadPage(1)`
  - Danh sach duoc reset va load lai tu trang 1
  - `state = NotificationState(notifications: newItems, currentPage: 1, hasMore: items.length >= 20)`

### TC-FLUTTER-NOTIFICATION-009: Notification provider - addNotification (socket realtime)
- **Module**: notification
- **Provider**: `providers/notification_provider.dart`
- **Steps**:
  1. Goi `addNotification(newNotif)`
- **Expected**:
  - `state.notifications` = `[newNotif, ...state.notifications]`
  - Notification moi duoc chen vao dau danh sach
  - Khong goi API

### TC-FLUTTER-NOTIFICATION-010: Notification provider - markAsRead
- **Module**: notification
- **Provider**: `providers/notification_provider.dart`
- **Steps**:
  1. Goi `markAsRead("notif-123")`
- **Expected**:
  - Goi `repo.markAsRead("notif-123")`
  - `state.notifications` duoc map: `id == "notif-123"` -> `isRead = true`
  - Cac notification khac giu nguyen
  - `ref.invalidate(unreadCountProvider)`

### TC-FLUTTER-NOTIFICATION-011: Notification provider - markAllAsRead
- **Module**: notification
- **Provider**: `providers/notification_provider.dart`
- **Steps**:
  1. Goi `markAllAsRead()`
- **Expected**:
  - Goi `repo.markAllAsRead()`
  - Tat ca notification trong state `isRead = true`
  - `ref.invalidate(unreadCountProvider)`

### TC-FLUTTER-NOTIFICATION-012: Notification provider - loadPage page > 1 (append)
- **Module**: notification
- **Provider**: `providers/notification_provider.dart`
- **Preconditions**: Da load page 1
- **Steps**:
  1. Goi `loadPage(2)`
- **Expected**:
  - Goi `repo.getMyNotifications(page: 2, limit: 20)`
  - `page != 1` -> append: `[...state.notifications, ...items]`
  - `state.currentPage = 2`
  - `state.hasMore = items.length >= 20`

### TC-FLUTTER-NOTIFICATION-013: Notification provider - loadPage page 1 (reset)
- **Module**: notification
- **Provider**: `providers/notification_provider.dart`
- **Steps**:
  1. Goi `loadPage(1)`
- **Expected**:
  - `page == 1` -> `state = NotificationState(notifications: items, currentPage: 1, hasMore: items.length >= 20)`
  - Reset danh sach (khong append)

### TC-FLUTTER-NOTIFICATION-014: AppNotification entity - fromJson
- **Module**: notification
- **Entity**: `domain/entities/app_notification.dart`
- **Steps**:
  1. Parse JSON `{'id': '1', 'type': 'MATCH', 'title': 'Test', 'content': 'Body text', 'isRead': true, 'createdAt': '2026-07-07T10:00:00Z'}`
- **Expected**:
  - `id = '1'`, `type = 'MATCH'`, `title = 'Test'`, `body = 'Body text'` (fallback tu content)
  - `isRead = true` (fallback tu is_read)
  - `createdAt` parse thanh cong
- **Edge cases**: `json['content']` fallback, `json['body']` fallback
- **Edge cases**: `json['isRead']` fallback `json['is_read']`
- **Edge cases**: `createdAt` parse fail -> `DateTime.now()`

### TC-FLUTTER-NOTIFICATION-015: AppNotification - icon va color theo type
- **Module**: notification
- **Entity**: `domain/entities/app_notification.dart`
- **Steps**:
  1. Kiem tra icon va color cho tung loai notification
- **Expected**:
  - `TOURNAMENT` / `TOURNAMENT_REGISTER_*` / `TOURNAMENT_PARTICIPANT_NEW` / `TOURNAMENT_WITHDRAWN` / `TOURNAMENT_KICKED` -> `Icons.emoji_events_rounded`, mau `0xFFF59E0B`
  - `MATCH` / `MATCH_SCHEDULED` / `MATCH_COMPLETED` -> `Icons.sports_tennis_rounded`, mau `0xFF2979FF`
  - `PAYMENT` / `PAYOUT_APPROVED` / `PAYOUT_REJECTED` -> `Icons.payments_rounded`, mau `0xFF10B981`
  - `CHAT` -> `Icons.chat_rounded`, mau `0xFF8B5CF6`
  - `REMINDER` -> `Icons.notifications_rounded`, mau `0xFF64748B`
  - `unknown` -> `Icons.notifications_outlined`, mau `0xFF64748B`

### TC-FLUTTER-NOTIFICATION-016: AppNotification - timeAgo format
- **Module**: notification
- **Entity**: `domain/entities/app_notification.dart`
- **Steps**:
  1. Kiem tra `timeAgo` cho cac khoang thoi gian khac nhau
- **Expected**:
  - `diff.inMinutes < 1` -> "Vua xong"
  - `diff.inMinutes >= 1 && < 60` -> "X phut truoc"
  - `diff.inHours >= 1 && < 24` -> "X gio truoc"
  - `diff.inDays >= 1 && < 7` -> "X ngay truoc"
  - `diff.inDays >= 7` -> "dd/mm/yyyy"
