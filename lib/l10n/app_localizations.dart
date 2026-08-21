import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @club_favorite.
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích'**
  String get club_favorite;

  /// No description provided for @club_unfavorite.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ yêu thích'**
  String get club_unfavorite;

  /// No description provided for @club_follow.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi'**
  String get club_follow;

  /// No description provided for @club_unfollow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ theo dõi'**
  String get club_unfollow;

  /// No description provided for @club_unfollowSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ theo dõi CLB'**
  String get club_unfollowSuccess;

  /// No description provided for @club_followSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã theo dõi CLB'**
  String get club_followSuccess;

  /// No description provided for @club_actionError.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra, vui lòng thử lại'**
  String get club_actionError;

  /// No description provided for @club_unfavoriteSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ yêu thích CLB'**
  String get club_unfavoriteSuccess;

  /// No description provided for @club_favoriteSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm vào CLB yêu thích'**
  String get club_favoriteSuccess;

  /// No description provided for @navExplore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get navExplore;

  /// No description provided for @navTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get navTournaments;

  /// No description provided for @navRankings.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng'**
  String get navRankings;

  /// No description provided for @navSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// No description provided for @navClubs.
  ///
  /// In vi, this message translates to:
  /// **'CLB'**
  String get navClubs;

  /// No description provided for @loginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập tài khoản'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành viên'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordLabel;

  /// No description provided for @fullNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fullNameLabel;

  /// No description provided for @loginButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get registerButton;

  /// No description provided for @orContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'hoặc tiếp tục với'**
  String get orContinueWith;

  /// No description provided for @loginRegister_googleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Google'**
  String get loginRegister_googleLabel;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản?'**
  String get hasAccount;

  /// No description provided for @registerNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký ngay'**
  String get registerNow;

  /// No description provided for @loginNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get loginNow;

  /// No description provided for @exploreWithoutLogin.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá không cần đăng nhập'**
  String get exploreWithoutLogin;

  /// No description provided for @profileTabInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get profileTabInfo;

  /// No description provided for @profileTabSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get profileTabSettings;

  /// No description provided for @settingsAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản & Thiết lập'**
  String get settingsAccountTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @settingsProfileTab.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get settingsProfileTab;

  /// No description provided for @settingsBankTab.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get settingsBankTab;

  /// No description provided for @settingsSecurityTab.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get settingsSecurityTab;

  /// No description provided for @settingsSystemTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn hệ thống'**
  String get settingsSystemTitle;

  /// No description provided for @settingsDashboard.
  ///
  /// In vi, this message translates to:
  /// **'Dashboard'**
  String get settingsDashboard;

  /// No description provided for @settingsEditProfile.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa hồ sơ'**
  String get settingsEditProfile;

  /// No description provided for @settingsPaymentHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thanh toán'**
  String get settingsPaymentHistory;

  /// No description provided for @settingsSeries.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi giải đấu'**
  String get settingsSeries;

  /// No description provided for @settingsClubInvites.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời CLB'**
  String get settingsClubInvites;

  /// No description provided for @settingsChangePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get settingsChangePassword;

  /// No description provided for @settingsEloHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử ELO'**
  String get settingsEloHistory;

  /// No description provided for @settingsNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get settingsNotifications;

  /// No description provided for @settingsDarkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ tối'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @settingsLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get settingsLogout;

  /// No description provided for @changePassword_title.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get changePassword_title;

  /// No description provided for @changePassword_currentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get changePassword_currentLabel;

  /// No description provided for @changePassword_currentHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu hiện tại'**
  String get changePassword_currentHint;

  /// No description provided for @changePassword_currentRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu hiện tại'**
  String get changePassword_currentRequired;

  /// No description provided for @changePassword_newLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get changePassword_newLabel;

  /// No description provided for @changePassword_newHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu mới'**
  String get changePassword_newHint;

  /// No description provided for @changePassword_newRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu mới'**
  String get changePassword_newRequired;

  /// No description provided for @changePassword_minLength.
  ///
  /// In vi, this message translates to:
  /// **'Có ít nhất 6 ký tự'**
  String get changePassword_minLength;

  /// No description provided for @changePassword_uppercase.
  ///
  /// In vi, this message translates to:
  /// **'Có ít nhất 1 chữ hoa'**
  String get changePassword_uppercase;

  /// No description provided for @changePassword_number.
  ///
  /// In vi, this message translates to:
  /// **'Có ít nhất 1 chữ số'**
  String get changePassword_number;

  /// No description provided for @changePassword_confirmLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get changePassword_confirmLabel;

  /// No description provided for @changePassword_confirmHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới'**
  String get changePassword_confirmHint;

  /// No description provided for @changePassword_confirmRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng xác nhận mật khẩu mới'**
  String get changePassword_confirmRequired;

  /// No description provided for @changePassword_mismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get changePassword_mismatch;

  /// No description provided for @changePassword_success.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công'**
  String get changePassword_success;

  /// No description provided for @changePassword_errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đổi mật khẩu. Vui lòng thử lại.'**
  String get changePassword_errorGeneric;

  /// No description provided for @changePassword_button.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get changePassword_button;

  /// No description provided for @changePassword_help.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự, bao gồm chữ hoa và chữ số để bảo mật tài khoản của bạn.'**
  String get changePassword_help;

  /// No description provided for @languageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @infoMyTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu của tôi'**
  String get infoMyTournaments;

  /// No description provided for @infoMyClubs.
  ///
  /// In vi, this message translates to:
  /// **'Câu lạc bộ của tôi & đã tham gia'**
  String get infoMyClubs;

  /// No description provided for @infoFollowedTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đang theo dõi'**
  String get infoFollowedTournaments;

  /// No description provided for @infoPersonalInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get infoPersonalInfo;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profileTitle;

  /// No description provided for @infoEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get infoEdit;

  /// No description provided for @infoWin.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get infoWin;

  /// No description provided for @infoLoss.
  ///
  /// In vi, this message translates to:
  /// **'Thua'**
  String get infoLoss;

  /// No description provided for @infoWinRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ thắng'**
  String get infoWinRate;

  /// No description provided for @infoPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get infoPhone;

  /// No description provided for @infoDob.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get infoDob;

  /// No description provided for @infoGender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get infoGender;

  /// No description provided for @infoAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get infoAddress;

  /// No description provided for @infoProvince.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/Thành phố'**
  String get infoProvince;

  /// No description provided for @infoEmailVerified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get infoEmailVerified;

  /// No description provided for @infoEmailUnverified.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác thực'**
  String get infoEmailUnverified;

  /// No description provided for @infoAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get infoAll;

  /// No description provided for @infoUnranked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp hạng'**
  String get infoUnranked;

  /// No description provided for @infoPlayer.
  ///
  /// In vi, this message translates to:
  /// **'Vận động viên'**
  String get infoPlayer;

  /// No description provided for @infoAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên'**
  String get infoAdmin;

  /// No description provided for @infoOrganizer.
  ///
  /// In vi, this message translates to:
  /// **'Ban tổ chức'**
  String get infoOrganizer;

  /// No description provided for @infoReferee.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tài'**
  String get infoReferee;

  /// No description provided for @infoLeader.
  ///
  /// In vi, this message translates to:
  /// **'Trưởng nhóm'**
  String get infoLeader;

  /// No description provided for @infoCoach.
  ///
  /// In vi, this message translates to:
  /// **'Huấn luyện viên'**
  String get infoCoach;

  /// No description provided for @infoJoinedAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia từ'**
  String get infoJoinedAt;

  /// No description provided for @infoNoData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu'**
  String get infoNoData;

  /// No description provided for @infoRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get infoRetry;

  /// No description provided for @infoMyTournamentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo hoặc tham gia giải nào.'**
  String get infoMyTournamentsEmpty;

  /// No description provided for @infoMyClubsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo hoặc tham gia câu lạc bộ nào.'**
  String get infoMyClubsEmpty;

  /// No description provided for @infoCreateClub.
  ///
  /// In vi, this message translates to:
  /// **'Tạo CLB mới'**
  String get infoCreateClub;

  /// No description provided for @infoFollowedEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa theo dõi giải nào.'**
  String get infoFollowedEmpty;

  /// No description provided for @profileLoginGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào!'**
  String get profileLoginGreeting;

  /// No description provided for @profileLoginDescription.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem hồ sơ, theo dõi giải đấu và kết nối với cộng đồng thể thao.'**
  String get profileLoginDescription;

  /// No description provided for @profileLoginButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get profileLoginButton;

  /// No description provided for @profileChangeCover.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ảnh bìa'**
  String get profileChangeCover;

  /// No description provided for @profileChangeAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ảnh đại diện'**
  String get profileChangeAvatar;

  /// No description provided for @profileTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh mới'**
  String get profileTakePhoto;

  /// No description provided for @profileChooseFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get profileChooseFromGallery;

  /// No description provided for @profileCameraPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa cấp quyền camera cho Sporto.'**
  String get profileCameraPermissionDenied;

  /// No description provided for @profileGalleryPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa cấp quyền thư viện ảnh cho Sporto.'**
  String get profileGalleryPermissionDenied;

  /// No description provided for @profileImagePickerError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở camera hoặc thư viện ảnh.'**
  String get profileImagePickerError;

  /// No description provided for @profileCoverUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa đã được cập nhật'**
  String get profileCoverUpdated;

  /// No description provided for @profileAvatarUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh đại diện đã được cập nhật'**
  String get profileAvatarUpdated;

  /// No description provided for @publicProfileTabOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get publicProfileTabOverview;

  /// No description provided for @publicProfileTabMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get publicProfileTabMatches;

  /// No description provided for @publicProfileTabAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Danh hiệu'**
  String get publicProfileTabAchievements;

  /// No description provided for @publicProfileTabElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO'**
  String get publicProfileTabElo;

  /// No description provided for @publicProfileShareSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ Vận động viên'**
  String get publicProfileShareSubtitle;

  /// No description provided for @publicProfileShareBadge.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ VĐV & ELO'**
  String get publicProfileShareBadge;

  /// No description provided for @publicProfileClubTitles.
  ///
  /// In vi, this message translates to:
  /// **'DANH HIỆU CLB'**
  String get publicProfileClubTitles;

  /// No description provided for @publicProfileTagUnit.
  ///
  /// In vi, this message translates to:
  /// **'nhãn'**
  String get publicProfileTagUnit;

  /// No description provided for @publicProfileRankBySport.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng theo bộ môn'**
  String get publicProfileRankBySport;

  /// No description provided for @publicProfileEloChart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ ELO'**
  String get publicProfileEloChart;

  /// No description provided for @publicProfileDetailedStats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê chi tiết'**
  String get publicProfileDetailedStats;

  /// No description provided for @publicProfileMatchesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được lịch sử trận đấu'**
  String get publicProfileMatchesLoadError;

  /// No description provided for @publicProfileNoPublicMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu công khai'**
  String get publicProfileNoPublicMatches;

  /// No description provided for @publicProfileTournamentFallback.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get publicProfileTournamentFallback;

  /// No description provided for @publicProfileMatchCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get publicProfileMatchCompleted;

  /// No description provided for @publicProfileMatchUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Chưa diễn ra'**
  String get publicProfileMatchUpcoming;

  /// No description provided for @publicProfileNoUserData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu người dùng'**
  String get publicProfileNoUserData;

  /// No description provided for @publicProfileDetailedHistory.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch sử chi tiết'**
  String get publicProfileDetailedHistory;

  /// No description provided for @publicProfileAchievementsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích nổi bật'**
  String get publicProfileAchievementsTitle;

  /// No description provided for @publicProfileNoAchievements.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành tích nào'**
  String get publicProfileNoAchievements;

  /// No description provided for @publicProfileChampion.
  ///
  /// In vi, this message translates to:
  /// **'Quán quân'**
  String get publicProfileChampion;

  /// No description provided for @publicProfileRunnerUp.
  ///
  /// In vi, this message translates to:
  /// **'Á quân'**
  String get publicProfileRunnerUp;

  /// No description provided for @publicProfileThirdPlace.
  ///
  /// In vi, this message translates to:
  /// **'Hạng ba'**
  String get publicProfileThirdPlace;

  /// No description provided for @publicProfileCategoryUnit.
  ///
  /// In vi, this message translates to:
  /// **'bộ môn'**
  String get publicProfileCategoryUnit;

  /// No description provided for @publicProfileTotalElo.
  ///
  /// In vi, this message translates to:
  /// **'Tổng ELO'**
  String get publicProfileTotalElo;

  /// No description provided for @publicProfileAverageElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO TB'**
  String get publicProfileAverageElo;

  /// No description provided for @publicProfileTotalMatches.
  ///
  /// In vi, this message translates to:
  /// **'Tổng trận'**
  String get publicProfileTotalMatches;

  /// No description provided for @publicProfileMatchesShort.
  ///
  /// In vi, this message translates to:
  /// **'Trận'**
  String get publicProfileMatchesShort;

  /// No description provided for @publicProfileWinRateShort.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ'**
  String get publicProfileWinRateShort;

  /// No description provided for @publicProfileNoRankData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu xếp hạng'**
  String get publicProfileNoRankData;

  /// No description provided for @publicProfileLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin'**
  String get publicProfileLoadError;

  /// No description provided for @publicProfileHomeButton.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get publicProfileHomeButton;

  /// No description provided for @publicProfileUserFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get publicProfileUserFallback;

  /// No description provided for @userProfileClubOwnerRole.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhiệm CLB'**
  String get userProfileClubOwnerRole;

  /// No description provided for @userProfileClubAdminRole.
  ///
  /// In vi, this message translates to:
  /// **'Ban quản trị'**
  String get userProfileClubAdminRole;

  /// No description provided for @userProfileClubMemberRole.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên CLB'**
  String get userProfileClubMemberRole;

  /// No description provided for @userProfileEloStarting.
  ///
  /// In vi, this message translates to:
  /// **'Điểm ELO khởi điểm'**
  String get userProfileEloStarting;

  /// No description provided for @userProfileClubTagsTitle.
  ///
  /// In vi, this message translates to:
  /// **'DANH HIỆU CLB'**
  String get userProfileClubTagsTitle;

  /// No description provided for @userProfileEditTag.
  ///
  /// In vi, this message translates to:
  /// **'Sửa nhãn'**
  String get userProfileEditTag;

  /// No description provided for @userProfileAssignTag.
  ///
  /// In vi, this message translates to:
  /// **'+ Gán nhãn'**
  String get userProfileAssignTag;

  /// No description provided for @userProfileNoClubTags.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có danh hiệu trong CLB'**
  String get userProfileNoClubTags;

  /// No description provided for @userProfileOpeningChat.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở...'**
  String get userProfileOpeningChat;

  /// No description provided for @userProfileMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin'**
  String get userProfileMessage;

  /// No description provided for @userProfileViewProfile.
  ///
  /// In vi, this message translates to:
  /// **'Xem hồ sơ'**
  String get userProfileViewProfile;

  /// No description provided for @userProfileLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải hồ sơ...'**
  String get userProfileLoading;

  /// No description provided for @userProfileLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hồ sơ người dùng'**
  String get userProfileLoadError;

  /// No description provided for @userProfileNoTop100.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có hạng trong Top 100. Tham gia giải đấu để được xếp hạng!'**
  String get userProfileNoTop100;

  /// No description provided for @userProfileOpenChatError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở cuộc trò chuyện: {error}'**
  String userProfileOpenChatError(Object error);

  /// No description provided for @userProfileOpenTagError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi mở gán danh hiệu: {error}'**
  String userProfileOpenTagError(Object error);

  /// No description provided for @userProfileElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO'**
  String get userProfileElo;

  /// No description provided for @userProfileTotalMatches.
  ///
  /// In vi, this message translates to:
  /// **'Tổng trận'**
  String get userProfileTotalMatches;

  /// No description provided for @userProfileWins.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get userProfileWins;

  /// No description provided for @userProfileLosses.
  ///
  /// In vi, this message translates to:
  /// **'Thua'**
  String get userProfileLosses;

  /// No description provided for @userProfileWinRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ thắng'**
  String get userProfileWinRate;

  /// No description provided for @userProfileRankFallback.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng'**
  String get userProfileRankFallback;

  /// No description provided for @vietnam.
  ///
  /// In vi, this message translates to:
  /// **'Việt Nam'**
  String get vietnam;

  /// No description provided for @freePrice.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get freePrice;

  /// No description provided for @viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get viewAll;

  /// No description provided for @featuredTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu nổi bật'**
  String get featuredTournaments;

  /// No description provided for @liveMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu đang diễn ra'**
  String get liveMatches;

  /// No description provided for @noLiveMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu nào đang diễn ra'**
  String get noLiveMatches;

  /// No description provided for @upcomingMatches.
  ///
  /// In vi, this message translates to:
  /// **'Lịch thi đấu sắp diễn ra'**
  String get upcomingMatches;

  /// No description provided for @noUpcomingMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch thi đấu sắp diễn ra'**
  String get noUpcomingMatches;

  /// No description provided for @clubCommunity.
  ///
  /// In vi, this message translates to:
  /// **'Cộng đồng câu lạc bộ'**
  String get clubCommunity;

  /// No description provided for @noClubs.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có câu lạc bộ nào'**
  String get noClubs;

  /// No description provided for @sportsHeader.
  ///
  /// In vi, this message translates to:
  /// **'THỂ THAO'**
  String get sportsHeader;

  /// No description provided for @filterSport.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get filterSport;

  /// No description provided for @filterStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get filterStatus;

  /// No description provided for @filterContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get filterContent;

  /// No description provided for @filterFormat.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức'**
  String get filterFormat;

  /// No description provided for @filterScoring.
  ///
  /// In vi, this message translates to:
  /// **'Tính điểm'**
  String get filterScoring;

  /// No description provided for @filterLocation.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get filterLocation;

  /// No description provided for @filterDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày thi đấu'**
  String get filterDate;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @filterReset.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get filterApply;

  /// No description provided for @singlesMale.
  ///
  /// In vi, this message translates to:
  /// **'Đơn nam'**
  String get singlesMale;

  /// No description provided for @singlesFemale.
  ///
  /// In vi, this message translates to:
  /// **'Đơn nữ'**
  String get singlesFemale;

  /// No description provided for @doublesMale.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam'**
  String get doublesMale;

  /// No description provided for @doublesFemale.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nữ'**
  String get doublesFemale;

  /// No description provided for @doublesMixed.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam nữ'**
  String get doublesMixed;

  /// No description provided for @eliminationSingle.
  ///
  /// In vi, this message translates to:
  /// **'Loại trực tiếp'**
  String get eliminationSingle;

  /// No description provided for @eliminationDouble.
  ///
  /// In vi, this message translates to:
  /// **'Nhánh thắng/thua'**
  String get eliminationDouble;

  /// No description provided for @roundRobin.
  ///
  /// In vi, this message translates to:
  /// **'Vòng tròn'**
  String get roundRobin;

  /// No description provided for @groupStage.
  ///
  /// In vi, this message translates to:
  /// **'Vòng bảng'**
  String get groupStage;

  /// No description provided for @rankedELO.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng ELO'**
  String get rankedELO;

  /// No description provided for @unranked.
  ///
  /// In vi, this message translates to:
  /// **'Phong trào'**
  String get unranked;

  /// No description provided for @tournamentLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải giải đấu...'**
  String get tournamentLoading;

  /// No description provided for @tournamentLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được giải đấu'**
  String get tournamentLoadError;

  /// No description provided for @tournamentNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu không tồn tại'**
  String get tournamentNotFound;

  /// No description provided for @unnamed.
  ///
  /// In vi, this message translates to:
  /// **'(Chưa có tên)'**
  String get unnamed;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @registrationClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng đăng ký'**
  String get registrationClosed;

  /// No description provided for @unfollow.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ theo dõi'**
  String get unfollow;

  /// No description provided for @follow.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi'**
  String get follow;

  /// No description provided for @followedTournament.
  ///
  /// In vi, this message translates to:
  /// **'Đã theo dõi giải đấu'**
  String get followedTournament;

  /// No description provided for @unfollowedTournament.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ theo dõi giải đấu'**
  String get unfollowedTournament;

  /// No description provided for @followError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật theo dõi'**
  String get followError;

  /// No description provided for @liteTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nhanh (Lite)'**
  String get liteTournament;

  /// No description provided for @advancedTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nâng Cao'**
  String get advancedTournament;

  /// No description provided for @noParticipants.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có người tham gia'**
  String get noParticipants;

  /// No description provided for @joined.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia'**
  String get joined;

  /// No description provided for @teamsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu đội'**
  String get teamsLoadError;

  /// No description provided for @notUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get notUpdated;

  /// No description provided for @locationNotUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật địa điểm'**
  String get locationNotUpdated;

  /// No description provided for @teamsUnit.
  ///
  /// In vi, this message translates to:
  /// **'đội'**
  String get teamsUnit;

  /// No description provided for @tabAbout.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get tabAbout;

  /// No description provided for @tabTeams.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách đội'**
  String get tabTeams;

  /// No description provided for @tabBracket.
  ///
  /// In vi, this message translates to:
  /// **'Bảng thi đấu'**
  String get tabBracket;

  /// No description provided for @tabGallery.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get tabGallery;

  /// No description provided for @deleteTournamentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giải đấu?'**
  String get deleteTournamentTitle;

  /// No description provided for @deleteTournamentContent.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này không thể hoàn tác.'**
  String get deleteTournamentContent;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @deleteTournament.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giải đấu'**
  String get deleteTournament;

  /// No description provided for @tournamentDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa giải đấu thành công'**
  String get tournamentDeleted;

  /// No description provided for @deleteError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi xóa'**
  String get deleteError;

  /// No description provided for @selectFeature.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một chức năng bên trái'**
  String get selectFeature;

  /// No description provided for @playersPerTeam.
  ///
  /// In vi, this message translates to:
  /// **'Người/Đội'**
  String get playersPerTeam;

  /// No description provided for @managementTitle.
  ///
  /// In vi, this message translates to:
  /// **'QUẢN LÝ'**
  String get managementTitle;

  /// No description provided for @manageTokens.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý Mã truy cập (Token)'**
  String get manageTokens;

  /// No description provided for @manageTokensSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem QR Code, Refresh Token, Số người online'**
  String get manageTokensSubtitle;

  /// No description provided for @manageTeams.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đội / VĐV'**
  String get manageTeams;

  /// No description provided for @manageTeamsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm, sửa, import danh sách'**
  String get manageTeamsSubtitle;

  /// No description provided for @manageDraw.
  ///
  /// In vi, this message translates to:
  /// **'Bốc thăm & Phân bảng'**
  String get manageDraw;

  /// No description provided for @manageDrawSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự động hoặc thủ công'**
  String get manageDrawSubtitle;

  /// No description provided for @viewBracket.
  ///
  /// In vi, this message translates to:
  /// **'Xem Bracket'**
  String get viewBracket;

  /// No description provided for @viewBracketSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ thi đấu & kết quả'**
  String get viewBracketSubtitle;

  /// No description provided for @endTournament.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc giải đấu'**
  String get endTournament;

  /// No description provided for @endTournamentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khóa kết quả và trao giải'**
  String get endTournamentSubtitle;

  /// No description provided for @confirmEndTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận kết thúc'**
  String get confirmEndTitle;

  /// No description provided for @confirmEndContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn kết thúc giải đấu? Thao tác này sẽ khóa toàn bộ các trận đấu.'**
  String get confirmEndContent;

  /// No description provided for @confirmEndButton.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận kết thúc'**
  String get confirmEndButton;

  /// No description provided for @continueButton.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueButton;

  /// No description provided for @tournamentEnded.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đã kết thúc thành công!'**
  String get tournamentEnded;

  /// No description provided for @endError.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra khi kết thúc giải đấu.'**
  String get endError;

  /// No description provided for @exportData.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu giải đấu'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất toàn bộ kết quả ra Excel'**
  String get exportDataSubtitle;

  /// No description provided for @exportingExcel.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo file Excel...'**
  String get exportingExcel;

  /// No description provided for @exportSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu thành công!'**
  String get exportSuccess;

  /// No description provided for @errorPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get errorPrefix;

  /// No description provided for @tokenManagement.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý Mã Truy Cập'**
  String get tokenManagement;

  /// No description provided for @tokenError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get tokenError;

  /// No description provided for @online.
  ///
  /// In vi, this message translates to:
  /// **'online'**
  String get online;

  /// No description provided for @refreshToken.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới mã'**
  String get refreshToken;

  /// No description provided for @confirmRefreshTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận làm mới'**
  String get confirmRefreshTitle;

  /// No description provided for @confirmRefreshContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn làm mới mã'**
  String get confirmRefreshContent;

  /// No description provided for @confirmRefreshNote.
  ///
  /// In vi, this message translates to:
  /// **'Những người đang truy cập bằng mã cũ sẽ bị đăng xuất khỏi giải ngay lập tức!'**
  String get confirmRefreshNote;

  /// No description provided for @confirmRefreshButton.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý Làm mới'**
  String get confirmRefreshButton;

  /// No description provided for @tokenRefreshed.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo mã mới thành công!'**
  String get tokenRefreshed;

  /// No description provided for @qrCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'QR Code -'**
  String get qrCodeTitle;

  /// No description provided for @qrCodeValue.
  ///
  /// In vi, this message translates to:
  /// **'Mã:'**
  String get qrCodeValue;

  /// No description provided for @qrCodeInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã này để truy cập trực tiếp vào giải đấu.'**
  String get qrCodeInstruction;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @sectionOrganizer.
  ///
  /// In vi, this message translates to:
  /// **'BAN TỔ CHỨC'**
  String get sectionOrganizer;

  /// No description provided for @organizerName.
  ///
  /// In vi, this message translates to:
  /// **'Ban Tổ Chức'**
  String get organizerName;

  /// No description provided for @newlyCreated.
  ///
  /// In vi, this message translates to:
  /// **'Mới Tạo'**
  String get newlyCreated;

  /// No description provided for @tournamentFounder.
  ///
  /// In vi, this message translates to:
  /// **'Người sáng lập giải đấu'**
  String get tournamentFounder;

  /// No description provided for @sectionAboutTournament.
  ///
  /// In vi, this message translates to:
  /// **'GIỚI THIỆU GIẢI ĐẤU'**
  String get sectionAboutTournament;

  /// No description provided for @sectionTournamentInfo.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN GIẢI ĐẤU'**
  String get sectionTournamentInfo;

  /// No description provided for @sportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get sportLabel;

  /// No description provided for @formatLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức'**
  String get formatLabel;

  /// No description provided for @bracketTypeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung thi đấu'**
  String get bracketTypeLabel;

  /// No description provided for @maxTeamsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số đội tối đa'**
  String get maxTeamsLabel;

  /// No description provided for @sectionPrize.
  ///
  /// In vi, this message translates to:
  /// **'GIẢI THƯỞNG'**
  String get sectionPrize;

  /// No description provided for @sectionContact.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN LIÊN HỆ'**
  String get sectionContact;

  /// No description provided for @sectionRegistration.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN ĐĂNG KÝ'**
  String get sectionRegistration;

  /// No description provided for @entryFeeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phí tham gia'**
  String get entryFeeLabel;

  /// No description provided for @vnd.
  ///
  /// In vi, this message translates to:
  /// **'VNĐ'**
  String get vnd;

  /// No description provided for @maxQuantityLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng tối đa'**
  String get maxQuantityLabel;

  /// No description provided for @registrationOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở đăng ký'**
  String get registrationOpen;

  /// No description provided for @registrationClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng đăng ký'**
  String get registrationClose;

  /// No description provided for @registeredSlots.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký:'**
  String get registeredSlots;

  /// No description provided for @registrationEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc đăng ký'**
  String get registrationEnded;

  /// No description provided for @noTeamsJoined.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đội tham gia'**
  String get noTeamsJoined;

  /// No description provided for @otherDivision.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get otherDivision;

  /// No description provided for @noTeamsFound.
  ///
  /// In vi, this message translates to:
  /// **'Không có đội nào'**
  String get noTeamsFound;

  /// No description provided for @noGalleryImages.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh gallery'**
  String get noGalleryImages;

  /// No description provided for @sporto.
  ///
  /// In vi, this message translates to:
  /// **'Sporto'**
  String get sporto;

  /// No description provided for @registrationClosedTag.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ ĐÓNG ĐĂNG KÝ'**
  String get registrationClosedTag;

  /// No description provided for @registrationOpenTag.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG MỞ ĐĂNG KÝ'**
  String get registrationOpenTag;

  /// No description provided for @roundRobinTag.
  ///
  /// In vi, this message translates to:
  /// **'VÒNG TRÒN'**
  String get roundRobinTag;

  /// No description provided for @liveTag.
  ///
  /// In vi, this message translates to:
  /// **'TRỰC TIẾP'**
  String get liveTag;

  /// No description provided for @resultTag.
  ///
  /// In vi, this message translates to:
  /// **'KẾT QUẢ'**
  String get resultTag;

  /// No description provided for @cancelledTag.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ HỦY'**
  String get cancelledTag;

  /// No description provided for @seedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạt giống'**
  String get seedLabel;

  /// No description provided for @eloLabel.
  ///
  /// In vi, this message translates to:
  /// **'Elo:'**
  String get eloLabel;

  /// No description provided for @doublesMemberList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách 2 vận động viên:'**
  String get doublesMemberList;

  /// No description provided for @memberNamesLabel.
  ///
  /// In vi, this message translates to:
  /// **'VĐV:'**
  String get memberNamesLabel;

  /// No description provided for @captainRole.
  ///
  /// In vi, this message translates to:
  /// **'Trưởng nhóm'**
  String get captainRole;

  /// No description provided for @memberRole.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get memberRole;

  /// No description provided for @leaderboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get leaderboardTitle;

  /// No description provided for @noStandings.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu thi đấu'**
  String get noStandings;

  /// No description provided for @rankHeader.
  ///
  /// In vi, this message translates to:
  /// **'#'**
  String get rankHeader;

  /// No description provided for @teamHeader.
  ///
  /// In vi, this message translates to:
  /// **'ĐỘI'**
  String get teamHeader;

  /// No description provided for @playedHeader.
  ///
  /// In vi, this message translates to:
  /// **'P'**
  String get playedHeader;

  /// No description provided for @wonHeader.
  ///
  /// In vi, this message translates to:
  /// **'W'**
  String get wonHeader;

  /// No description provided for @drawnHeader.
  ///
  /// In vi, this message translates to:
  /// **'D'**
  String get drawnHeader;

  /// No description provided for @lostHeader.
  ///
  /// In vi, this message translates to:
  /// **'L'**
  String get lostHeader;

  /// No description provided for @gdHeader.
  ///
  /// In vi, this message translates to:
  /// **'GD'**
  String get gdHeader;

  /// No description provided for @ptsHeader.
  ///
  /// In vi, this message translates to:
  /// **'PTS'**
  String get ptsHeader;

  /// No description provided for @totalTeamsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng đội'**
  String get totalTeamsLabel;

  /// No description provided for @totalMatchesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get totalMatchesLabel;

  /// No description provided for @completedMatchesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get completedMatchesLabel;

  /// No description provided for @liveMatchesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get liveMatchesLabel;

  /// No description provided for @matchesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get matchesTitle;

  /// No description provided for @matchesSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo tên VĐV / CLB...'**
  String get matchesSearchHint;

  /// No description provided for @matchesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách trận đấu. Hãy thử lại.'**
  String get matchesLoadError;

  /// No description provided for @matchesFilterJustEnded.
  ///
  /// In vi, this message translates to:
  /// **'Vừa kết thúc'**
  String get matchesFilterJustEnded;

  /// No description provided for @matchesFilterOngoing.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get matchesFilterOngoing;

  /// No description provided for @matchesFilterRegistration.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get matchesFilterRegistration;

  /// No description provided for @matchesFilterScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get matchesFilterScheduled;

  /// No description provided for @matchesFilterEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get matchesFilterEnded;

  /// No description provided for @matchesFilterSport.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get matchesFilterSport;

  /// No description provided for @matchesFilterDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get matchesFilterDate;

  /// No description provided for @matchesFilterLocation.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get matchesFilterLocation;

  /// No description provided for @matchesPickSport.
  ///
  /// In vi, this message translates to:
  /// **'Chọn môn thể thao'**
  String get matchesPickSport;

  /// No description provided for @matchesFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get matchesFilterAll;

  /// No description provided for @matchesEnterLocation.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa điểm'**
  String get matchesEnterLocation;

  /// No description provided for @matchesLocationHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên địa điểm, sân...'**
  String get matchesLocationHint;

  /// No description provided for @matchesCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get matchesCancel;

  /// No description provided for @matchesApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get matchesApply;

  /// No description provided for @matchesOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get matchesOther;

  /// No description provided for @matchesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} trận'**
  String matchesCount(Object count);

  /// No description provided for @matchesNoMatchesFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trận đấu'**
  String get matchesNoMatchesFound;

  /// No description provided for @matchesTryChangeFilter.
  ///
  /// In vi, this message translates to:
  /// **'Thử thay đổi bộ lọc hoặc tìm kiếm khác'**
  String get matchesTryChangeFilter;

  /// No description provided for @matchesRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get matchesRetry;

  /// No description provided for @matchesStatusAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get matchesStatusAll;

  /// No description provided for @matchesStatusScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get matchesStatusScheduled;

  /// No description provided for @matchesStatusLive.
  ///
  /// In vi, this message translates to:
  /// **'Đang thi đấu'**
  String get matchesStatusLive;

  /// No description provided for @matchesStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get matchesStatusCompleted;

  /// No description provided for @matchesStatusWalkover.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ cuộc'**
  String get matchesStatusWalkover;

  /// No description provided for @matchLiveCheerError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể gửi cổ vũ. Vui lòng thử lại.'**
  String get matchLiveCheerError;

  /// No description provided for @matchLiveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trực tiếp'**
  String get matchLiveTitle;

  /// No description provided for @liveMatchesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu trực tiếp'**
  String get liveMatchesTitle;

  /// No description provided for @liveMatchesRemainingStat.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get liveMatchesRemainingStat;

  /// No description provided for @liveMatchesNoMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu'**
  String get liveMatchesNoMatches;

  /// No description provided for @liveMatchesNoMatchesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chờ ban tổ chức bốc thăm và xếp lịch\nCác trận đấu sẽ xuất hiện tại đây'**
  String get liveMatchesNoMatchesDescription;

  /// No description provided for @liveMatchesFilteredEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có trận đấu nào phù hợp bộ lọc'**
  String get liveMatchesFilteredEmpty;

  /// No description provided for @contactWebsite.
  ///
  /// In vi, this message translates to:
  /// **'Website'**
  String get contactWebsite;

  /// No description provided for @contactPhone.
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get contactEmail;

  /// No description provided for @contactZalo.
  ///
  /// In vi, this message translates to:
  /// **'Zalo'**
  String get contactZalo;

  /// No description provided for @contactFacebook.
  ///
  /// In vi, this message translates to:
  /// **'Facebook'**
  String get contactFacebook;

  /// No description provided for @imageZoomHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để phóng to'**
  String get imageZoomHint;

  /// No description provided for @liveMatchesReload.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại'**
  String get liveMatchesReload;

  /// No description provided for @liveMatchMaxScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tối đa: {score}'**
  String liveMatchMaxScore(Object score);

  /// No description provided for @liveMatchCompletedStatus.
  ///
  /// In vi, this message translates to:
  /// **'HOÀN THÀNH'**
  String get liveMatchCompletedStatus;

  /// No description provided for @liveMatchScheduledStatus.
  ///
  /// In vi, this message translates to:
  /// **'SẮP DIỄN RA'**
  String get liveMatchScheduledStatus;

  /// No description provided for @matchDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi Tiết Trận Đấu'**
  String get matchDetailTitle;

  /// No description provided for @matchRefereeDesk.
  ///
  /// In vi, this message translates to:
  /// **'Bàn Trọng Tài'**
  String get matchRefereeDesk;

  /// No description provided for @matchScoringButton.
  ///
  /// In vi, this message translates to:
  /// **'Tính điểm'**
  String get matchScoringButton;

  /// No description provided for @matchNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trận đấu'**
  String get matchNotFound;

  /// No description provided for @matchLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu trận đấu.'**
  String get matchLoadError;

  /// No description provided for @matchBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get matchBack;

  /// No description provided for @matchMatchInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin trận đấu'**
  String get matchMatchInfo;

  /// No description provided for @matchAppliedRules.
  ///
  /// In vi, this message translates to:
  /// **'Luật giải đang áp dụng'**
  String get matchAppliedRules;

  /// No description provided for @matchRulesDesc.
  ///
  /// In vi, this message translates to:
  /// **'Các thông số được lấy từ cấu hình của ban tổ chức. App chỉ mở bảng chấm điểm theo luật này.'**
  String get matchRulesDesc;

  /// No description provided for @matchSport.
  ///
  /// In vi, this message translates to:
  /// **'Môn'**
  String get matchSport;

  /// No description provided for @matchWin.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get matchWin;

  /// No description provided for @matchSetThreshold.
  ///
  /// In vi, this message translates to:
  /// **'Mốc set'**
  String get matchSetThreshold;

  /// No description provided for @matchWinByTwo.
  ///
  /// In vi, this message translates to:
  /// **'Cách biệt 2'**
  String get matchWinByTwo;

  /// No description provided for @matchNoWinByTwo.
  ///
  /// In vi, this message translates to:
  /// **'Không cách biệt 2'**
  String get matchNoWinByTwo;

  /// No description provided for @matchRefereeNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên trọng tài hoặc ghi chú nhanh'**
  String get matchRefereeNameHint;

  /// No description provided for @matchRefereeOptionalHint.
  ///
  /// In vi, this message translates to:
  /// **'Không bắt buộc. Chỉ hiển thị trong app nếu có.'**
  String get matchRefereeOptionalHint;

  /// No description provided for @matchStartMatch.
  ///
  /// In vi, this message translates to:
  /// **'BẮT ĐẦU TRẬN ĐẤU'**
  String get matchStartMatch;

  /// No description provided for @matchSetupConfig.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình Trận đấu'**
  String get matchSetupConfig;

  /// No description provided for @matchAppliedConfig.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình giải đang áp dụng'**
  String get matchAppliedConfig;

  /// No description provided for @matchConfigDetail.
  ///
  /// In vi, this message translates to:
  /// **'Màn setup đang lấy mặc định từ cấu hình giải đấu. Bạn có thể chỉnh ở cấp trận nếu cần.'**
  String get matchConfigDetail;

  /// No description provided for @matchConfigFallback.
  ///
  /// In vi, this message translates to:
  /// **'Giải chưa có sportRules chi tiết, hệ thống đang dùng cấu hình mặc định theo môn.'**
  String get matchConfigFallback;

  /// No description provided for @matchFormat.
  ///
  /// In vi, this message translates to:
  /// **'Format'**
  String get matchFormat;

  /// No description provided for @matchTimeLimit.
  ///
  /// In vi, this message translates to:
  /// **'Giới hạn thời gian (phút, tuỳ chọn)'**
  String get matchTimeLimit;

  /// No description provided for @matchTimeLimitHint.
  ///
  /// In vi, this message translates to:
  /// **'Nếu để trống, trận sẽ không giới hạn thời gian ở cấp trận.'**
  String get matchTimeLimitHint;

  /// No description provided for @matchRefereeNameOptional.
  ///
  /// In vi, this message translates to:
  /// **'Tên trọng tài (Tùy chọn)'**
  String get matchRefereeNameOptional;

  /// No description provided for @matchWinByTwoRule.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng luật cách biệt 2 điểm'**
  String get matchWinByTwoRule;

  /// No description provided for @matchMaxScore.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa:'**
  String get matchMaxScore;

  /// No description provided for @matchBlowWhistle.
  ///
  /// In vi, this message translates to:
  /// **'THỔI CÒI'**
  String get matchBlowWhistle;

  /// No description provided for @matchEndMatch.
  ///
  /// In vi, this message translates to:
  /// **'KẾT THÚC'**
  String get matchEndMatch;

  /// No description provided for @matchConfirmEndTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận kết thúc trận đấu'**
  String get matchConfirmEndTitle;

  /// No description provided for @matchConfirmEndContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn kết thúc trận đấu này và chốt kết quả tỉ số?'**
  String get matchConfirmEndContent;

  /// No description provided for @matchCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get matchCancel;

  /// No description provided for @matchConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get matchConfirm;

  /// No description provided for @matchRefereeDeskNotStarted.
  ///
  /// In vi, this message translates to:
  /// **'BÀN TRỌNG TÀI - CHƯA BẮT ĐẦU'**
  String get matchRefereeDeskNotStarted;

  /// No description provided for @matchRefereeDeskOngoing.
  ///
  /// In vi, this message translates to:
  /// **'BÀN TRỌNG TÀI - ĐANG THI ĐẤU'**
  String get matchRefereeDeskOngoing;

  /// No description provided for @matchStartHint.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút để bắt đầu trận đấu & mở bàn chấm điểm'**
  String get matchStartHint;

  /// No description provided for @matchScoringHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở bàn chấm điểm để ghi nhận tỉ số & thẻ phạt'**
  String get matchScoringHint;

  /// No description provided for @matchOpenScoreboard.
  ///
  /// In vi, this message translates to:
  /// **'MỞ BẢNG CHẤM ĐIỂM'**
  String get matchOpenScoreboard;

  /// No description provided for @matchUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'SẮP ĐẤU'**
  String get matchUpcoming;

  /// No description provided for @matchTabScore.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ số & Diễn biến'**
  String get matchTabScore;

  /// No description provided for @matchTabChat.
  ///
  /// In vi, this message translates to:
  /// **'Phòng thảo luận'**
  String get matchTabChat;

  /// No description provided for @matchSetsWon.
  ///
  /// In vi, this message translates to:
  /// **'SET THẮNG:'**
  String get matchSetsWon;

  /// No description provided for @matchSetScores.
  ///
  /// In vi, this message translates to:
  /// **'TỈ SỐ CÁC SET'**
  String get matchSetScores;

  /// No description provided for @matchDetailInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin trận đấu chi tiết'**
  String get matchDetailInfo;

  /// No description provided for @matchTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get matchTournament;

  /// No description provided for @matchMainReferee.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tài chính'**
  String get matchMainReferee;

  /// No description provided for @matchNotDetermined.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get matchNotDetermined;

  /// No description provided for @matchScheduledTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian xếp lịch'**
  String get matchScheduledTime;

  /// No description provided for @matchNotScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp lịch'**
  String get matchNotScheduled;

  /// No description provided for @matchEnded.
  ///
  /// In vi, this message translates to:
  /// **'TRẬN ĐẤU ĐÃ KẾT THÚC'**
  String get matchEnded;

  /// No description provided for @matchWinner.
  ///
  /// In vi, this message translates to:
  /// **'Thắng:'**
  String get matchWinner;

  /// No description provided for @matchEditResultAdmin.
  ///
  /// In vi, this message translates to:
  /// **'SỬA KẾT QUẢ (ADMIN)'**
  String get matchEditResultAdmin;

  /// No description provided for @matchGoHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get matchGoHome;

  /// No description provided for @matchAdminEditResult.
  ///
  /// In vi, this message translates to:
  /// **'Admin: Sửa Kết Quả'**
  String get matchAdminEditResult;

  /// No description provided for @matchAdminEditWarning.
  ///
  /// In vi, this message translates to:
  /// **'Việc thay đổi kết quả sẽ ghi đè dữ liệu và tự động cập nhật nhánh đấu tiếp theo.'**
  String get matchAdminEditWarning;

  /// No description provided for @matchWinnerTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội chiến thắng:'**
  String get matchWinnerTeam;

  /// No description provided for @matchSaveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu Thay Đổi'**
  String get matchSaveChanges;

  /// No description provided for @matchResultUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật kết quả trận đấu!'**
  String get matchResultUpdated;

  /// No description provided for @matchNoDiscussions.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thảo luận'**
  String get matchNoDiscussions;

  /// No description provided for @matchBeFirstToShare.
  ///
  /// In vi, this message translates to:
  /// **'Hãy là người đầu tiên chia sẻ cảm nghĩ!'**
  String get matchBeFirstToShare;

  /// No description provided for @matchChatHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập bình luận...'**
  String get matchChatHint;

  /// No description provided for @matchChatLoginHint.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để bình luận'**
  String get matchChatLoginHint;

  /// No description provided for @matchLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get matchLogin;

  /// No description provided for @matchForceWinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xử thắng nhanh'**
  String get matchForceWinTitle;

  /// No description provided for @matchForceWinContent.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xử thắng cho một đội (đối thủ bỏ cuộc hoặc phạm quy)?'**
  String get matchForceWinContent;

  /// No description provided for @matchWhichTeamFoul.
  ///
  /// In vi, this message translates to:
  /// **'Đội nào bị phạt?'**
  String get matchWhichTeamFoul;

  /// No description provided for @matchCommentError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi bình luận. Vui lòng thử lại!'**
  String get matchCommentError;

  /// No description provided for @matchScoreUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật điểm trận đấu. Vui lòng thử lại.'**
  String get matchScoreUpdateError;

  /// No description provided for @matchRecordedPenalty.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận {name}.'**
  String matchRecordedPenalty(Object name);

  /// No description provided for @matchCourtLabel.
  ///
  /// In vi, this message translates to:
  /// **'Sân trung tâm'**
  String get matchCourtLabel;

  /// No description provided for @matchVsLabel.
  ///
  /// In vi, this message translates to:
  /// **'VS'**
  String get matchVsLabel;

  /// No description provided for @matchSetLabel.
  ///
  /// In vi, this message translates to:
  /// **'SET'**
  String get matchSetLabel;

  /// No description provided for @matchViewer.
  ///
  /// In vi, this message translates to:
  /// **'Người xem'**
  String get matchViewer;

  /// No description provided for @matchCamLabel.
  ///
  /// In vi, this message translates to:
  /// **'CAM 1 (SÂN CHÍNH)'**
  String get matchCamLabel;

  /// No description provided for @matchTiebreak.
  ///
  /// In vi, this message translates to:
  /// **'Tiebreak'**
  String get matchTiebreak;

  /// No description provided for @matchGameLabel.
  ///
  /// In vi, this message translates to:
  /// **'GAME'**
  String get matchGameLabel;

  /// No description provided for @matchLiveStatus.
  ///
  /// In vi, this message translates to:
  /// **'LIVE'**
  String get matchLiveStatus;

  /// No description provided for @matchCompletedStatus.
  ///
  /// In vi, this message translates to:
  /// **'KẾT THÚC'**
  String get matchCompletedStatus;

  /// No description provided for @matchCurrentSet.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp'**
  String get matchCurrentSet;

  /// No description provided for @matchCurrentTennisSet.
  ///
  /// In vi, this message translates to:
  /// **'Set'**
  String get matchCurrentTennisSet;

  /// No description provided for @matchOverrideLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại lệ'**
  String get matchOverrideLabel;

  /// No description provided for @matchOverrideOn.
  ///
  /// In vi, this message translates to:
  /// **'Ngoại lệ: BẬT'**
  String get matchOverrideOn;

  /// No description provided for @matchOverrideHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do ngoại lệ bắt buộc...'**
  String get matchOverrideHint;

  /// No description provided for @matchPenaltyPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Phạt: '**
  String get matchPenaltyPrefix;

  /// No description provided for @matchRecordPenalty.
  ///
  /// In vi, this message translates to:
  /// **'Ghi phạt'**
  String get matchRecordPenalty;

  /// No description provided for @matchForceWin.
  ///
  /// In vi, this message translates to:
  /// **'Xử thắng'**
  String get matchForceWin;

  /// No description provided for @matchFinishSet.
  ///
  /// In vi, this message translates to:
  /// **'CHỐT SET'**
  String get matchFinishSet;

  /// No description provided for @matchFinishSetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Chốt set'**
  String get matchFinishSetConfirm;

  /// No description provided for @matchSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get matchSaving;

  /// No description provided for @matchSaveMatch.
  ///
  /// In vi, this message translates to:
  /// **'CHỐT TRẬN ĐẤU'**
  String get matchSaveMatch;

  /// No description provided for @matchSaveResult.
  ///
  /// In vi, this message translates to:
  /// **'Chốt kết quả'**
  String get matchSaveResult;

  /// No description provided for @matchConfirmFinishSet.
  ///
  /// In vi, this message translates to:
  /// **'Chốt set'**
  String get matchConfirmFinishSet;

  /// No description provided for @matchRuleWinByTwo.
  ///
  /// In vi, this message translates to:
  /// **'Thắng cách 2'**
  String get matchRuleWinByTwo;

  /// No description provided for @matchCeilingScore.
  ///
  /// In vi, this message translates to:
  /// **'Trần điểm {max}'**
  String matchCeilingScore(Object max);

  /// No description provided for @matchRound.
  ///
  /// In vi, this message translates to:
  /// **'Vòng {round}'**
  String matchRound(Object round);

  /// No description provided for @matchCourt.
  ///
  /// In vi, this message translates to:
  /// **'Sân: {court}'**
  String matchCourt(Object court);

  /// No description provided for @matchScoringModel.
  ///
  /// In vi, this message translates to:
  /// **'Chấm theo game tennis'**
  String get matchScoringModel;

  /// No description provided for @matchScoringSideout.
  ///
  /// In vi, this message translates to:
  /// **'Pickleball side-out'**
  String get matchScoringSideout;

  /// No description provided for @matchScoringRally.
  ///
  /// In vi, this message translates to:
  /// **'Rally point'**
  String get matchScoringRally;

  /// No description provided for @matchWinSets.
  ///
  /// In vi, this message translates to:
  /// **'Thắng {sets} set'**
  String matchWinSets(Object sets);

  /// No description provided for @matchPointsPerSet.
  ///
  /// In vi, this message translates to:
  /// **'{points} điểm/set'**
  String matchPointsPerSet(Object points);

  /// No description provided for @matchGamesPerSet.
  ///
  /// In vi, this message translates to:
  /// **'{games} game/set'**
  String matchGamesPerSet(Object games);

  /// No description provided for @rallyPointsPerSet.
  ///
  /// In vi, this message translates to:
  /// **'{points} điểm/set'**
  String rallyPointsPerSet(Object points);

  /// No description provided for @rallyBestOf.
  ///
  /// In vi, this message translates to:
  /// **'BO{bestOf}'**
  String rallyBestOf(Object bestOf);

  /// No description provided for @rallyOneSet.
  ///
  /// In vi, this message translates to:
  /// **'1 set'**
  String get rallyOneSet;

  /// No description provided for @rallyWinByTwo.
  ///
  /// In vi, this message translates to:
  /// **'Thắng cách 2'**
  String get rallyWinByTwo;

  /// No description provided for @rallyNearSetPoint.
  ///
  /// In vi, this message translates to:
  /// **'Đang gần điểm chốt set'**
  String get rallyNearSetPoint;

  /// No description provided for @rallyRemainingPoints.
  ///
  /// In vi, this message translates to:
  /// **'Còn {points} điểm tới mốc set'**
  String rallyRemainingPoints(Object points);

  /// No description provided for @rallyReachedThreshold.
  ///
  /// In vi, this message translates to:
  /// **'Đã chạm mốc set'**
  String get rallyReachedThreshold;

  /// No description provided for @pickleballServingTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội giao bóng: {name}'**
  String pickleballServingTeam(Object name);

  /// No description provided for @pickleballServerNumber.
  ///
  /// In vi, this message translates to:
  /// **'Lượt #{number}'**
  String pickleballServerNumber(Object number);

  /// No description provided for @pickleballServing.
  ///
  /// In vi, this message translates to:
  /// **'Đang giao · có quyền ghi điểm'**
  String get pickleballServing;

  /// No description provided for @pickleballReceiving.
  ///
  /// In vi, this message translates to:
  /// **'Đang đỡ · chưa được ghi điểm'**
  String get pickleballReceiving;

  /// No description provided for @pickleballSwitchServer.
  ///
  /// In vi, this message translates to:
  /// **'Đổi lượt giao'**
  String get pickleballSwitchServer;

  /// No description provided for @pickleballLoseServe.
  ///
  /// In vi, this message translates to:
  /// **'Mất quyền giao'**
  String get pickleballLoseServe;

  /// No description provided for @pickleballTeam1.
  ///
  /// In vi, this message translates to:
  /// **'Đội 1'**
  String get pickleballTeam1;

  /// No description provided for @pickleballTeam2.
  ///
  /// In vi, this message translates to:
  /// **'Đội 2'**
  String get pickleballTeam2;

  /// No description provided for @tennisTiebreakInfo.
  ///
  /// In vi, this message translates to:
  /// **'TIEBREAK · Mỗi pha bóng được 1 điểm, chạm {points} và cách 2 để thắng set'**
  String tennisTiebreakInfo(Object points);

  /// No description provided for @tennisPointsLabel.
  ///
  /// In vi, this message translates to:
  /// **'15 • 30 • 40'**
  String get tennisPointsLabel;

  /// No description provided for @tennisTiebreakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiebreak'**
  String get tennisTiebreakLabel;

  /// No description provided for @tennisGamePointsInfo.
  ///
  /// In vi, this message translates to:
  /// **'Điểm game'**
  String get tennisGamePointsInfo;

  /// No description provided for @tennisFormatSets.
  ///
  /// In vi, this message translates to:
  /// **'Thắng {sets} set'**
  String tennisFormatSets(Object sets);

  /// No description provided for @tennisDeuce.
  ///
  /// In vi, this message translates to:
  /// **'Deuce'**
  String get tennisDeuce;

  /// No description provided for @tennisGameLabel.
  ///
  /// In vi, this message translates to:
  /// **'GAME'**
  String get tennisGameLabel;

  /// No description provided for @tennisCurrentPoint.
  ///
  /// In vi, this message translates to:
  /// **'Pha hiện tại: {points}'**
  String tennisCurrentPoint(Object points);

  /// No description provided for @tennisTiebreakHint.
  ///
  /// In vi, this message translates to:
  /// **'Set đang vào tiebreak, điểm hiển thị theo số thực.'**
  String get tennisTiebreakHint;

  /// No description provided for @tennisGameHint.
  ///
  /// In vi, this message translates to:
  /// **'Chấm theo game tennis của giải, hệ thống tự xử lý deuce và advantage.'**
  String get tennisGameHint;

  /// No description provided for @tennisInfoSet.
  ///
  /// In vi, this message translates to:
  /// **'Set'**
  String get tennisInfoSet;

  /// No description provided for @tennisInfoFormat.
  ///
  /// In vi, this message translates to:
  /// **'Format'**
  String get tennisInfoFormat;

  /// No description provided for @tennisInfoStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get tennisInfoStatus;

  /// No description provided for @matchChatInitError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối phòng chat. Vui lòng thử lại.'**
  String get matchChatInitError;

  /// No description provided for @matchChatRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get matchChatRetry;

  /// No description provided for @matchChatSendError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi tin nhắn. Vui lòng thử lại.'**
  String get matchChatSendError;

  /// No description provided for @matchChatNoMessages.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn'**
  String get matchChatNoMessages;

  /// No description provided for @matchChatUserPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get matchChatUserPlaceholder;

  /// No description provided for @matchChatMessageHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tin nhắn...'**
  String get matchChatMessageHint;

  /// No description provided for @matchChatLoginRequired.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tham gia'**
  String get matchChatLoginRequired;

  /// No description provided for @matchChatPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Camera trực tiếp'**
  String get matchChatPlaceholder;

  /// No description provided for @matchChatConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối camera sân đấu...'**
  String get matchChatConnecting;

  /// No description provided for @teamScoreCardError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: Bạn không có quyền sửa điểm.'**
  String get teamScoreCardError;

  /// No description provided for @registerSubmitApproval.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu tham gia'**
  String get registerSubmitApproval;

  /// No description provided for @registerSubmitConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đăng ký'**
  String get registerSubmitConfirm;

  /// No description provided for @registerSuccessWaitlisted.
  ///
  /// In vi, this message translates to:
  /// **'Đã vào danh sách chờ'**
  String get registerSuccessWaitlisted;

  /// No description provided for @registerApprovalSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu thành công!'**
  String get registerApprovalSuccess;

  /// No description provided for @registerSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công!'**
  String get registerSuccess;

  /// No description provided for @registerDivMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get registerDivMale;

  /// No description provided for @registerDivFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get registerDivFemale;

  /// No description provided for @registerDivMixed.
  ///
  /// In vi, this message translates to:
  /// **'Nam nữ'**
  String get registerDivMixed;

  /// No description provided for @registerTypeSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đơn'**
  String get registerTypeSingles;

  /// No description provided for @registerTypeDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi'**
  String get registerTypeDoubles;

  /// No description provided for @registerTypeMixedDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam nữ'**
  String get registerTypeMixedDoubles;

  /// No description provided for @registerTypeDefault.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get registerTypeDefault;

  /// No description provided for @registerEloRange.
  ///
  /// In vi, this message translates to:
  /// **'ELO {min}-{max}'**
  String registerEloRange(Object min, Object max);

  /// No description provided for @registerMaxTeams.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa {max} đội'**
  String registerMaxTeams(Object max);

  /// No description provided for @registerFree.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get registerFree;

  /// No description provided for @registerGenderErrorMale.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này chỉ dành cho Nam'**
  String get registerGenderErrorMale;

  /// No description provided for @registerGenderErrorFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung này chỉ dành cho Nữ'**
  String get registerGenderErrorFemale;

  /// No description provided for @registerEloTooLow.
  ///
  /// In vi, this message translates to:
  /// **'ELO của bạn ({elo}) thấp hơn yêu cầu tối thiểu ({min})'**
  String registerEloTooLow(Object elo, Object min);

  /// No description provided for @registerEloTooHigh.
  ///
  /// In vi, this message translates to:
  /// **'ELO của bạn ({elo}) cao hơn yêu cầu tối đa ({max})'**
  String registerEloTooHigh(Object elo, Object max);

  /// No description provided for @registerEloCheckError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kiểm tra ELO. Vui lòng thử lại trước khi đăng ký.'**
  String get registerEloCheckError;

  /// No description provided for @registerInviteInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời không hợp lệ hoặc đã hết hạn'**
  String get registerInviteInvalid;

  /// No description provided for @registerInviteTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời phải có ít nhất 6 ký tự'**
  String get registerInviteTooShort;

  /// No description provided for @registerAlreadyRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đăng ký giải đấu này rồi.'**
  String get registerAlreadyRegistered;

  /// No description provided for @registerProfileIncomplete.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng hoàn thiện hồ sơ trước khi đăng ký'**
  String get registerProfileIncomplete;

  /// No description provided for @registerSelectDivision.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn nội dung thi đấu.'**
  String get registerSelectDivision;

  /// No description provided for @registerDefaultDivision.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung chính'**
  String get registerDefaultDivision;

  /// No description provided for @registerPrivateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu riêng tư'**
  String get registerPrivateTitle;

  /// No description provided for @registerPrivateDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã mời để tham gia giải đấu này'**
  String get registerPrivateDesc;

  /// No description provided for @registerInviteHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời'**
  String get registerInviteHint;

  /// No description provided for @registerInviteValidating.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra...'**
  String get registerInviteValidating;

  /// No description provided for @registerInviteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mã mời'**
  String get registerInviteConfirm;

  /// No description provided for @registerRegClosed.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đã đóng đăng ký'**
  String get registerRegClosed;

  /// No description provided for @registerRegClosedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ban tổ chức hiện đã ngắt nhận hồ sơ đăng ký mới cho giải đấu này.'**
  String get registerRegClosedDesc;

  /// No description provided for @registerProfileIncompleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ chưa hoàn thiện'**
  String get registerProfileIncompleteTitle;

  /// No description provided for @registerProfileIncompleteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần cập nhật đầy đủ Họ tên, Số điện thoại và Giới tính trong hồ sơ cá nhân trước khi đăng ký.'**
  String get registerProfileIncompleteDesc;

  /// No description provided for @registerUpdateProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật hồ sơ ngay'**
  String get registerUpdateProfile;

  /// No description provided for @registerInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN'**
  String get registerInfoTitle;

  /// No description provided for @registerPlayerName.
  ///
  /// In vi, this message translates to:
  /// **'Tên thi đấu'**
  String get registerPlayerName;

  /// No description provided for @registerNameNotUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get registerNameNotUpdated;

  /// No description provided for @registerNameFromAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tên sẽ được lấy từ tài khoản của bạn'**
  String get registerNameFromAccount;

  /// No description provided for @registerTeamNameNext.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội và đồng đội sẽ được chọn ở bước tiếp theo.'**
  String get registerTeamNameNext;

  /// No description provided for @registerContentTitle.
  ///
  /// In vi, this message translates to:
  /// **'NỘI DUNG'**
  String get registerContentTitle;

  /// No description provided for @registerScheduleTitle.
  ///
  /// In vi, this message translates to:
  /// **'QUYỀN LỢI & QUY ĐỊNH THAM GIA'**
  String get registerScheduleTitle;

  /// No description provided for @registerScheduleTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian thi đấu'**
  String get registerScheduleTime;

  /// No description provided for @registerLocationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm thi đấu'**
  String get registerLocationTitle;

  /// No description provided for @registerNotScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp lịch'**
  String get registerNotScheduled;

  /// No description provided for @registerSupportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ VĐV'**
  String get registerSupportTitle;

  /// No description provided for @registerEloSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Xếp lịch & ELO'**
  String get registerEloSchedule;

  /// No description provided for @registerEloScheduleDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ thi đấu công khai, tích lũy điểm ELO tự động sau giải'**
  String get registerEloScheduleDesc;

  /// No description provided for @registerSupportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ hoàn hủy lệ phí & thắc mắc trực tiếp với Ban tổ chức'**
  String get registerSupportDesc;

  /// No description provided for @registerDeadline.
  ///
  /// In vi, this message translates to:
  /// **'HẠN ĐĂNG KÝ CÒN LẠI'**
  String get registerDeadline;

  /// No description provided for @registerDeadlineExpired.
  ///
  /// In vi, this message translates to:
  /// **'Hạn đăng ký giải đấu đã kết thúc'**
  String get registerDeadlineExpired;

  /// No description provided for @registerOpenTag.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG MỞ'**
  String get registerOpenTag;

  /// No description provided for @registerRegLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get registerRegLabel;

  /// No description provided for @registerDays.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get registerDays;

  /// No description provided for @registerHours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ'**
  String get registerHours;

  /// No description provided for @registerMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get registerMinutes;

  /// No description provided for @registerSeconds.
  ///
  /// In vi, this message translates to:
  /// **'Giây'**
  String get registerSeconds;

  /// No description provided for @registerViewDetail.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get registerViewDetail;

  /// No description provided for @registerViewDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết giải đấu'**
  String get registerViewDetailTitle;

  /// No description provided for @registerWithdraw.
  ///
  /// In vi, this message translates to:
  /// **'Rút lui khỏi giải'**
  String get registerWithdraw;

  /// No description provided for @registerFeePending.
  ///
  /// In vi, this message translates to:
  /// **'Phí tham gia {fee} chưa thanh toán'**
  String registerFeePending(Object fee);

  /// No description provided for @registerNoPaymentWaitlisted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cần thanh toán cho đến khi có suất chính thức'**
  String get registerNoPaymentWaitlisted;

  /// No description provided for @registerStatusPendingPartner.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ đồng đội tham gia'**
  String get registerStatusPendingPartner;

  /// No description provided for @registerStatusPendingApproval.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ Ban tổ chức duyệt'**
  String get registerStatusPendingApproval;

  /// No description provided for @registerStatusWaitlisted.
  ///
  /// In vi, this message translates to:
  /// **'Đang ở danh sách chờ'**
  String get registerStatusWaitlisted;

  /// No description provided for @registerStatusCompletePaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký và thanh toán'**
  String get registerStatusCompletePaid;

  /// No description provided for @registerStatusCompleteUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký, chưa thanh toán'**
  String get registerStatusCompleteUnpaid;

  /// No description provided for @registerStatusDefault.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đăng ký giải đấu này'**
  String get registerStatusDefault;

  /// No description provided for @registerLoginPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đăng nhập để tham gia'**
  String get registerLoginPrompt;

  /// No description provided for @registerLoginButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get registerLoginButton;

  /// No description provided for @registerRegClosedButton.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đã đóng đăng ký'**
  String get registerRegClosedButton;

  /// No description provided for @registerSubmitFee.
  ///
  /// In vi, this message translates to:
  /// **'{label} • {fee}'**
  String registerSubmitFee(Object label, Object fee);

  /// No description provided for @registerSubmitFree.
  ///
  /// In vi, this message translates to:
  /// **'{label} (Miễn phí)'**
  String registerSubmitFree(Object label);

  /// No description provided for @registerTournamentNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giải'**
  String get registerTournamentNotFound;

  /// No description provided for @registerFeeUnit.
  ///
  /// In vi, this message translates to:
  /// **'đ'**
  String get registerFeeUnit;

  /// No description provided for @doublesRegTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký đôi'**
  String get doublesRegTitle;

  /// No description provided for @doublesRegStep1.
  ///
  /// In vi, this message translates to:
  /// **'BƯỚC 1'**
  String get doublesRegStep1;

  /// No description provided for @doublesRegStep2.
  ///
  /// In vi, this message translates to:
  /// **'BƯỚC 2'**
  String get doublesRegStep2;

  /// No description provided for @doublesRegStep3.
  ///
  /// In vi, this message translates to:
  /// **'BƯỚC 3'**
  String get doublesRegStep3;

  /// No description provided for @doublesRegCreateTeam.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đội'**
  String get doublesRegCreateTeam;

  /// No description provided for @doublesRegTeamName.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội'**
  String get doublesRegTeamName;

  /// No description provided for @doublesRegTeamNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên đội của bạn'**
  String get doublesRegTeamNameHint;

  /// No description provided for @doublesRegSearchPartner.
  ///
  /// In vi, this message translates to:
  /// **'TÌM ĐỒNG ĐỘI'**
  String get doublesRegSearchPartner;

  /// No description provided for @doublesRegInviteLater.
  ///
  /// In vi, this message translates to:
  /// **'Mời sau'**
  String get doublesRegInviteLater;

  /// No description provided for @doublesRegPartnerHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email hoặc SĐT đồng đội'**
  String get doublesRegPartnerHint;

  /// No description provided for @doublesRegSubmitNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp theo'**
  String get doublesRegSubmitNext;

  /// No description provided for @doublesRegProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get doublesRegProcessing;

  /// No description provided for @doublesRegInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời đồng đội'**
  String get doublesRegInviteTitle;

  /// No description provided for @doublesRegInviteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ mã mời hoặc link này cho đồng đội của bạn'**
  String get doublesRegInviteDesc;

  /// No description provided for @doublesRegInviteLink.
  ///
  /// In vi, this message translates to:
  /// **'Link mời:'**
  String get doublesRegInviteLink;

  /// No description provided for @doublesRegCopyLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link mời'**
  String get doublesRegCopyLink;

  /// No description provided for @doublesRegCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get doublesRegCopied;

  /// No description provided for @doublesRegWaiting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ đồng đội tham gia...'**
  String get doublesRegWaiting;

  /// No description provided for @doublesRegContinueLater.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục sau'**
  String get doublesRegContinueLater;

  /// No description provided for @doublesRegSpotReserved.
  ///
  /// In vi, this message translates to:
  /// **'Giữ chỗ trong {time}'**
  String doublesRegSpotReserved(Object time);

  /// No description provided for @doublesRegCompleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get doublesRegCompleteTitle;

  /// No description provided for @doublesRegYourTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội của bạn: {name}'**
  String doublesRegYourTeam(Object name);

  /// No description provided for @doublesRegWithPartner.
  ///
  /// In vi, this message translates to:
  /// **'Cùng: {name}'**
  String doublesRegWithPartner(Object name);

  /// No description provided for @doublesRegEntryFee.
  ///
  /// In vi, this message translates to:
  /// **'Phí tham gia: {fee}'**
  String doublesRegEntryFee(Object fee);

  /// No description provided for @doublesRegWaitlistInfo.
  ///
  /// In vi, this message translates to:
  /// **'Đội đang ở danh sách chờ. Bạn chưa cần thanh toán cho đến khi có suất chính thức.'**
  String get doublesRegWaitlistInfo;

  /// No description provided for @doublesRegProceedPayment.
  ///
  /// In vi, this message translates to:
  /// **'Tiến hành thanh toán'**
  String get doublesRegProceedPayment;

  /// No description provided for @doublesRegComplete.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get doublesRegComplete;

  /// No description provided for @doublesRegSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công!'**
  String get doublesRegSuccess;

  /// No description provided for @doublesRegViewDetail.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get doublesRegViewDetail;

  /// No description provided for @doublesRegTeamNameTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội tối thiểu 3 ký tự'**
  String get doublesRegTeamNameTooShort;

  /// No description provided for @doublesRegPartnerTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết thời gian chờ đồng đội. Bạn có thể tiếp tục sau.'**
  String get doublesRegPartnerTimeout;

  /// No description provided for @doublesRegCreateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo đội đăng ký. Vui lòng thử lại.'**
  String get doublesRegCreateError;

  /// No description provided for @joinTeamTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia đội'**
  String get joinTeamTitle;

  /// No description provided for @joinTeamLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để tham gia đội'**
  String get joinTeamLogin;

  /// No description provided for @joinTeamSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia đội thành công!'**
  String get joinTeamSuccess;

  /// No description provided for @joinTeamInvitation.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời tham gia đội'**
  String get joinTeamInvitation;

  /// No description provided for @joinTeamDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được mời vào một đội đánh đôi'**
  String get joinTeamDesc;

  /// No description provided for @joinTeamConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận tham gia'**
  String get joinTeamConfirm;

  /// No description provided for @joinTeamProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get joinTeamProcessing;

  /// No description provided for @joinTeamViewTournament.
  ///
  /// In vi, this message translates to:
  /// **'Xem giải đấu'**
  String get joinTeamViewTournament;

  /// No description provided for @joinTeamError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tham gia đội.'**
  String get joinTeamError;

  /// No description provided for @registerError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đăng ký. Vui lòng thử lại.'**
  String get registerError;

  /// No description provided for @registerDivisionLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải nội dung thi đấu. Hãy thử lại.'**
  String get registerDivisionLoadError;

  /// No description provided for @registerTermsTitle.
  ///
  /// In vi, this message translates to:
  /// **'QUYỀN LỢI & QUY ĐỊNH THAM GIA'**
  String get registerTermsTitle;

  /// No description provided for @checkout_invalidDivision.
  ///
  /// In vi, this message translates to:
  /// **'Mã nội dung không hợp lệ'**
  String get checkout_invalidDivision;

  /// No description provided for @checkout_freeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận đăng ký miễn phí thành công'**
  String get checkout_freeConfirm;

  /// No description provided for @checkout_cannotOpenPayOS.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở liên kết PayOS'**
  String get checkout_cannotOpenPayOS;

  /// No description provided for @checkout_noPaymentLink.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống chưa tạo được link thanh toán'**
  String get checkout_noPaymentLink;

  /// No description provided for @checkout_createGatewayError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo liên kết thanh toán'**
  String get checkout_createGatewayError;

  /// No description provided for @checkout_createPaymentError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khởi tạo thanh toán'**
  String get checkout_createPaymentError;

  /// No description provided for @checkout_title.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán lệ phí'**
  String get checkout_title;

  /// No description provided for @checkout_freeBadge.
  ///
  /// In vi, this message translates to:
  /// **'MIỄN PHÍ'**
  String get checkout_freeBadge;

  /// No description provided for @checkout_entryFeeLabel.
  ///
  /// In vi, this message translates to:
  /// **'LỆ PHÍ THAM GIA'**
  String get checkout_entryFeeLabel;

  /// No description provided for @checkout_paymentMethodLabel.
  ///
  /// In vi, this message translates to:
  /// **'PHƯƠNG THỨC THANH TOÁN'**
  String get checkout_paymentMethodLabel;

  /// No description provided for @checkout_payOSLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cổng PayOS (QR Code / Ngân hàng)'**
  String get checkout_payOSLabel;

  /// No description provided for @checkout_payOSDescription.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã VietQR tự động khớp đơn và kích hoạt ngay'**
  String get checkout_payOSDescription;

  /// No description provided for @checkout_confirmInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng kiểm tra lại thông tin giải đấu và số tiền trước khi tiến hành thanh toán.'**
  String get checkout_confirmInstruction;

  /// No description provided for @checkout_freeConfirmButton.
  ///
  /// In vi, this message translates to:
  /// **'XÁC NHẬN THAM GIA MIỄN PHÍ'**
  String get checkout_freeConfirmButton;

  /// No description provided for @checkout_payButton.
  ///
  /// In vi, this message translates to:
  /// **'THANH TOÁN {amount}đ'**
  String checkout_payButton(Object amount);

  /// No description provided for @paymentResult_successTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công'**
  String get paymentResult_successTitle;

  /// No description provided for @paymentResult_failedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thất bại'**
  String get paymentResult_failedTitle;

  /// No description provided for @paymentResult_pendingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý thanh toán'**
  String get paymentResult_pendingTitle;

  /// No description provided for @paymentResult_amountLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tiền'**
  String get paymentResult_amountLabel;

  /// No description provided for @paymentResult_orderCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã đơn hàng'**
  String get paymentResult_orderCodeLabel;

  /// No description provided for @paymentResult_transactionIdLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch'**
  String get paymentResult_transactionIdLabel;

  /// No description provided for @paymentResult_backToTournament.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại giải đấu'**
  String get paymentResult_backToTournament;

  /// No description provided for @paymentResult_backToHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get paymentResult_backToHome;

  /// No description provided for @paymentResult_failedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác thanh toán bị hủy hoặc không thành công.'**
  String get paymentResult_failedMessage;

  /// No description provided for @paymentResult_successMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chúc bạn thi đấu tốt!'**
  String get paymentResult_successMessage;

  /// No description provided for @payments_title.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thanh toán'**
  String get payments_title;

  /// No description provided for @payments_noHistory.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử thanh toán'**
  String get payments_noHistory;

  /// No description provided for @payments_statusSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get payments_statusSuccess;

  /// No description provided for @payments_statusPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get payments_statusPending;

  /// No description provided for @payments_statusFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get payments_statusFailed;

  /// No description provided for @payments_refreshTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get payments_refreshTooltip;

  /// No description provided for @payments_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải lịch sử thanh toán:'**
  String get payments_loadError;

  /// No description provided for @payments_totalTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giao dịch'**
  String get payments_totalTransactions;

  /// No description provided for @payments_transactionCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giao dịch'**
  String payments_transactionCount(Object count);

  /// No description provided for @payments_pendingCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} chờ xử lý'**
  String payments_pendingCount(Object count);

  /// No description provided for @payments_filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get payments_filterAll;

  /// No description provided for @payments_filterCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get payments_filterCompleted;

  /// No description provided for @payments_filterPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get payments_filterPending;

  /// No description provided for @payments_filterFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get payments_filterFailed;

  /// No description provided for @payments_emptyAll.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử thanh toán'**
  String get payments_emptyAll;

  /// No description provided for @payments_emptyFiltered.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giao dịch'**
  String get payments_emptyFiltered;

  /// No description provided for @payments_emptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các giao dịch của bạn sẽ hiển thị ở đây'**
  String get payments_emptySubtitle;

  /// No description provided for @payments_defaultTournamentName.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu không xác định'**
  String get payments_defaultTournamentName;

  /// No description provided for @payments_transactionRef.
  ///
  /// In vi, this message translates to:
  /// **'Mã GD: {ref}'**
  String payments_transactionRef(Object ref);

  /// No description provided for @payments_retryCta.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán ngay'**
  String get payments_retryCta;

  /// No description provided for @payments_detailTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get payments_detailTournament;

  /// No description provided for @payments_detailUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Không xác định'**
  String get payments_detailUnknown;

  /// No description provided for @payments_detailTeamName.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội / VĐV'**
  String get payments_detailTeamName;

  /// No description provided for @payments_detailGateway.
  ///
  /// In vi, this message translates to:
  /// **'Cổng thanh toán'**
  String get payments_detailGateway;

  /// No description provided for @payments_detailTransactionId.
  ///
  /// In vi, this message translates to:
  /// **'Mã giao dịch'**
  String get payments_detailTransactionId;

  /// No description provided for @payments_copied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã giao dịch'**
  String get payments_copied;

  /// No description provided for @payments_retryPendingInfo.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đang chờ xử lý. Bạn có thể kiểm tra lại hoặc thực hiện lại thanh toán.'**
  String get payments_retryPendingInfo;

  /// No description provided for @payments_retryFailedInfo.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch không thành công. Bạn có thể mở lại trang thanh toán để hoàn tất.'**
  String get payments_retryFailedInfo;

  /// No description provided for @payments_refreshStatus.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật trạng thái'**
  String get payments_refreshStatus;

  /// No description provided for @payments_processing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get payments_processing;

  /// No description provided for @payments_payNow.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán ngay'**
  String get payments_payNow;

  /// No description provided for @payments_successInfo.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch này đã thành công hoàn tất.'**
  String get payments_successInfo;

  /// No description provided for @forgotPassword_title.
  ///
  /// In vi, this message translates to:
  /// **'Quên Mật Khẩu'**
  String get forgotPassword_title;

  /// No description provided for @forgotPassword_headerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại mật khẩu'**
  String get forgotPassword_headerTitle;

  /// No description provided for @forgotPassword_description.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ email liên kết với tài khoản của bạn để nhận liên kết khôi phục mật khẩu.'**
  String get forgotPassword_description;

  /// No description provided for @forgotPassword_emailTip.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống sẽ gửi một mã hoặc đường dẫn xác thực tới email của bạn. Vui lòng kiểm tra kỹ cả hộp thư Hòm thư rác (Spam).'**
  String get forgotPassword_emailTip;

  /// No description provided for @forgotPassword_emailHint.
  ///
  /// In vi, this message translates to:
  /// **'nhap@email.com'**
  String get forgotPassword_emailHint;

  /// No description provided for @forgotPassword_emailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập địa chỉ email'**
  String get forgotPassword_emailRequired;

  /// No description provided for @forgotPassword_emailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get forgotPassword_emailInvalid;

  /// No description provided for @forgotPassword_submitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi...'**
  String get forgotPassword_submitting;

  /// No description provided for @forgotPassword_submitButton.
  ///
  /// In vi, this message translates to:
  /// **'Gửi Yêu Cầu Khôi Phục'**
  String get forgotPassword_submitButton;

  /// No description provided for @forgotPassword_backToLogin.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại Đăng nhập'**
  String get forgotPassword_backToLogin;

  /// No description provided for @forgotPassword_sentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đã Gửi Email Khôi Phục'**
  String get forgotPassword_sentTitle;

  /// No description provided for @forgotPassword_checkEmail.
  ///
  /// In vi, this message translates to:
  /// **'Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu tới '**
  String get forgotPassword_checkEmail;

  /// No description provided for @forgotPassword_checkEmailSuffix.
  ///
  /// In vi, this message translates to:
  /// **'. Vui lòng kiểm tra hộp thư của bạn.'**
  String get forgotPassword_checkEmailSuffix;

  /// No description provided for @forgotPassword_resendTimer.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại sau {seconds}s'**
  String forgotPassword_resendTimer(Object seconds);

  /// No description provided for @forgotPassword_canResend.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể yêu cầu gửi lại email bây giờ'**
  String get forgotPassword_canResend;

  /// No description provided for @forgotPassword_resendButtonTimer.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại ({seconds}s)'**
  String forgotPassword_resendButtonTimer(Object seconds);

  /// No description provided for @forgotPassword_resendButton.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại email khôi phục'**
  String get forgotPassword_resendButton;

  /// No description provided for @forgotPassword_backToLoginButton.
  ///
  /// In vi, this message translates to:
  /// **'Trở về Đăng nhập'**
  String get forgotPassword_backToLoginButton;

  /// No description provided for @forgotPassword_sentSuccessMessage.
  ///
  /// In vi, this message translates to:
  /// **'Email khôi phục mật khẩu đã được gửi!'**
  String get forgotPassword_sentSuccessMessage;

  /// No description provided for @forgotPassword_errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi email khôi phục mật khẩu'**
  String get forgotPassword_errorGeneric;

  /// No description provided for @notification_markAllReadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đánh dấu tất cả là đã đọc.'**
  String get notification_markAllReadError;

  /// No description provided for @notification_inviteAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấp nhận lời mời!'**
  String get notification_inviteAccepted;

  /// No description provided for @notification_inviteDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời.'**
  String get notification_inviteDeclined;

  /// No description provided for @notification_acceptError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi chấp nhận lời mời.'**
  String get notification_acceptError;

  /// No description provided for @notification_declineError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi từ chối lời mời.'**
  String get notification_declineError;

  /// No description provided for @notification_title.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notification_title;

  /// No description provided for @notification_readAll.
  ///
  /// In vi, this message translates to:
  /// **'Đọc tất cả'**
  String get notification_readAll;

  /// No description provided for @notification_all.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get notification_all;

  /// No description provided for @notification_unread.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đọc'**
  String get notification_unread;

  /// No description provided for @notification_emptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào'**
  String get notification_emptyTitle;

  /// No description provided for @notification_emptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các cập nhật giải đấu và hệ thống sẽ hiển thị tại đây'**
  String get notification_emptySubtitle;

  /// No description provided for @notification_filteredEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đọc hết tất cả thông báo!'**
  String get notification_filteredEmptyTitle;

  /// No description provided for @notification_viewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả thông báo'**
  String get notification_viewAll;

  /// No description provided for @notification_today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get notification_today;

  /// No description provided for @notification_yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get notification_yesterday;

  /// No description provided for @notification_thisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get notification_thisWeek;

  /// No description provided for @notification_roleBtc.
  ///
  /// In vi, this message translates to:
  /// **'BTC'**
  String get notification_roleBtc;

  /// No description provided for @notification_roleReferee.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tài'**
  String get notification_roleReferee;

  /// No description provided for @notification_rolePlayer.
  ///
  /// In vi, this message translates to:
  /// **'Vận động viên'**
  String get notification_rolePlayer;

  /// No description provided for @notification_updateStatusError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi cập nhật trạng thái thông báo.'**
  String get notification_updateStatusError;

  /// No description provided for @notification_decline.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get notification_decline;

  /// No description provided for @notification_accept.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận'**
  String get notification_accept;

  /// No description provided for @notification_inviteHandled.
  ///
  /// In vi, this message translates to:
  /// **'Đã phản hồi lời mời'**
  String get notification_inviteHandled;

  /// No description provided for @payments_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get payments_close;

  /// No description provided for @payments_createLinkError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo liên kết thanh toán.'**
  String get payments_createLinkError;

  /// No description provided for @loginRegister_forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get loginRegister_forgotPassword;

  /// No description provided for @loginRegister_appleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Apple'**
  String get loginRegister_appleLabel;

  /// No description provided for @loginRegister_googleSignInButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google'**
  String get loginRegister_googleSignInButton;

  /// No description provided for @loginRegister_appleSignInButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Apple'**
  String get loginRegister_appleSignInButton;

  /// No description provided for @loginRegister_googleTokenMissing.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được ID Token từ Google'**
  String get loginRegister_googleTokenMissing;

  /// No description provided for @loginRegister_appleTokenMissing.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được ID Token từ Apple'**
  String get loginRegister_appleTokenMissing;

  /// No description provided for @loginRegister_loginNowAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập ngay'**
  String get loginRegister_loginNowAction;

  /// No description provided for @resetPassword_minLengthError.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự'**
  String get resetPassword_minLengthError;

  /// No description provided for @resetPassword_mismatchError.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get resetPassword_mismatchError;

  /// No description provided for @resetPassword_errorGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đặt lại mật khẩu. Vui lòng thử lại.'**
  String get resetPassword_errorGeneric;

  /// No description provided for @resetPassword_title.
  ///
  /// In vi, this message translates to:
  /// **'Đặt Lại Mật Khẩu'**
  String get resetPassword_title;

  /// No description provided for @resetPassword_successTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu thành công!'**
  String get resetPassword_successTitle;

  /// No description provided for @resetPassword_createNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mật khẩu mới'**
  String get resetPassword_createNewPassword;

  /// No description provided for @resetPassword_newPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get resetPassword_newPasswordLabel;

  /// No description provided for @resetPassword_confirmPasswordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu mới'**
  String get resetPassword_confirmPasswordLabel;

  /// No description provided for @resetPassword_submitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get resetPassword_submitting;

  /// No description provided for @resetPassword_resetButton.
  ///
  /// In vi, this message translates to:
  /// **'Đặt Lại Mật Khẩu'**
  String get resetPassword_resetButton;

  /// No description provided for @loginLoading_defaultUserName.
  ///
  /// In vi, this message translates to:
  /// **'Vận động viên'**
  String get loginLoading_defaultUserName;

  /// No description provided for @loginLoading_welcomeBack.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng quay trở lại!'**
  String get loginLoading_welcomeBack;

  /// No description provided for @loginLoading_loginSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công!'**
  String get loginLoading_loginSuccess;

  /// No description provided for @loginRegister_registerFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký không thành công'**
  String get loginRegister_registerFailed;

  /// No description provided for @loginRegister_loginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập không thành công'**
  String get loginRegister_loginFailed;

  /// No description provided for @loginRegister_googleLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Google thất bại'**
  String get loginRegister_googleLoginFailed;

  /// No description provided for @loginRegister_googleLoginError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi đăng nhập bằng Google'**
  String get loginRegister_googleLoginError;

  /// No description provided for @loginRegister_appleLoginFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Apple thất bại'**
  String get loginRegister_appleLoginFailed;

  /// No description provided for @loginRegister_appleLoginError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi đăng nhập bằng Apple'**
  String get loginRegister_appleLoginError;

  /// No description provided for @loginRegister_registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới để tham gia và tổ chức các giải đấu chuyên nghiệp'**
  String get loginRegister_registerSubtitle;

  /// No description provided for @loginRegister_loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập tài khoản của bạn để trải nghiệm dịch vụ'**
  String get loginRegister_loginSubtitle;

  /// No description provided for @loginRegister_fullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nguyễn Văn A'**
  String get loginRegister_fullNameHint;

  /// No description provided for @loginRegister_fullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get loginRegister_fullNameRequired;

  /// No description provided for @loginRegister_emailHint.
  ///
  /// In vi, this message translates to:
  /// **'example@email.com'**
  String get loginRegister_emailHint;

  /// No description provided for @loginRegister_emailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get loginRegister_emailRequired;

  /// No description provided for @loginRegister_emailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ email không hợp lệ'**
  String get loginRegister_emailInvalid;

  /// No description provided for @loginRegister_passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'••••••••'**
  String get loginRegister_passwordHint;

  /// No description provided for @loginRegister_passwordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get loginRegister_passwordRequired;

  /// No description provided for @loginRegister_passwordMinLength.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối thiểu 6 ký tự'**
  String get loginRegister_passwordMinLength;

  /// No description provided for @paymentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử thanh toán'**
  String get paymentsTitle;

  /// No description provided for @paymentsRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get paymentsRefresh;

  /// No description provided for @paymentsTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng giao dịch'**
  String get paymentsTotal;

  /// No description provided for @paymentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giao dịch nào'**
  String get paymentsEmpty;

  /// No description provided for @paymentsFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get paymentsFilterAll;

  /// No description provided for @paymentsFilterSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get paymentsFilterSuccess;

  /// No description provided for @paymentsFilterPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý'**
  String get paymentsFilterPending;

  /// No description provided for @paymentsFilterFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get paymentsFilterFailed;

  /// No description provided for @paymentsRefunded.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tiền'**
  String get paymentsRefunded;

  /// No description provided for @checkoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận thanh toán'**
  String get checkoutTitle;

  /// No description provided for @checkoutFee.
  ///
  /// In vi, this message translates to:
  /// **'LỆ PHÍ THAM GIA'**
  String get checkoutFee;

  /// No description provided for @checkoutFree.
  ///
  /// In vi, this message translates to:
  /// **'MIỄN PHÍ'**
  String get checkoutFree;

  /// No description provided for @checkoutPaymentMethod.
  ///
  /// In vi, this message translates to:
  /// **'PHƯƠNG THỨC THANH TOÁN'**
  String get checkoutPaymentMethod;

  /// No description provided for @checkoutPayos.
  ///
  /// In vi, this message translates to:
  /// **'QR thanh toán PayOS'**
  String get checkoutPayos;

  /// No description provided for @checkoutSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công!'**
  String get checkoutSuccess;

  /// No description provided for @checkoutFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thất bại'**
  String get checkoutFailed;

  /// No description provided for @checkoutBackToTournament.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại giải đấu'**
  String get checkoutBackToTournament;

  /// No description provided for @checkoutBackToHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get checkoutBackToHome;

  /// No description provided for @dashboard_title.
  ///
  /// In vi, this message translates to:
  /// **'Của tôi'**
  String get dashboard_title;

  /// No description provided for @dashboard_loginPrompt.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem khu vực của bạn'**
  String get dashboard_loginPrompt;

  /// No description provided for @dashboard_user.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get dashboard_user;

  /// No description provided for @dashboard_invites.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời'**
  String get dashboard_invites;

  /// No description provided for @dashboard_roles.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò'**
  String get dashboard_roles;

  /// No description provided for @dashboard_refereeMatchesCount.
  ///
  /// In vi, this message translates to:
  /// **'Trận giao'**
  String get dashboard_refereeMatchesCount;

  /// No description provided for @dashboard_pendingInvitesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời cần xử lý'**
  String get dashboard_pendingInvitesTitle;

  /// No description provided for @dashboard_openList.
  ///
  /// In vi, this message translates to:
  /// **'Mở danh sách'**
  String get dashboard_openList;

  /// No description provided for @dashboard_refereeInviteFallback.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời trọng tài'**
  String get dashboard_refereeInviteFallback;

  /// No description provided for @dashboard_inviteDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mời'**
  String get dashboard_inviteDate;

  /// No description provided for @dashboard_updateInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật'**
  String get dashboard_updateInProgress;

  /// No description provided for @dashboard_myRoles.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò của tôi'**
  String get dashboard_myRoles;

  /// No description provided for @dashboard_organizer.
  ///
  /// In vi, this message translates to:
  /// **'Chủ giải'**
  String get dashboard_organizer;

  /// No description provided for @dashboard_coOrganizer.
  ///
  /// In vi, this message translates to:
  /// **'Ban tổ chức'**
  String get dashboard_coOrganizer;

  /// No description provided for @dashboard_noRolesDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có vai trò nào trong giải đấu.'**
  String get dashboard_noRolesDesc;

  /// No description provided for @dashboard_assignedMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận được phân công'**
  String get dashboard_assignedMatches;

  /// No description provided for @dashboard_viewInvites.
  ///
  /// In vi, this message translates to:
  /// **'Xem lời mời'**
  String get dashboard_viewInvites;

  /// No description provided for @dashboard_noAssignedMatches.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có trận nào được phân công.'**
  String get dashboard_noAssignedMatches;

  /// No description provided for @dashboard_roundLabel.
  ///
  /// In vi, this message translates to:
  /// **'Vòng {round}'**
  String dashboard_roundLabel(Object round);

  /// No description provided for @dashboard_waitingSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Chờ sắp lịch'**
  String get dashboard_waitingSchedule;

  /// No description provided for @dashboard_myTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu của tôi ({count})'**
  String dashboard_myTournaments(Object count);

  /// No description provided for @dashboard_tournamentCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} giải'**
  String dashboard_tournamentCount(Object count);

  /// No description provided for @dashboard_searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm giải đấu...'**
  String get dashboard_searchHint;

  /// No description provided for @dashboard_noSearchResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giải đấu phù hợp'**
  String get dashboard_noSearchResults;

  /// No description provided for @dashboard_noTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo hoặc tham gia giải đấu nào'**
  String get dashboard_noTournaments;

  /// No description provided for @dashboard_collapse.
  ///
  /// In vi, this message translates to:
  /// **'Thu gọn'**
  String get dashboard_collapse;

  /// No description provided for @dashboard_showMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm ({count} giải khác)'**
  String dashboard_showMore(Object count);

  /// No description provided for @dashboard_quickActions.
  ///
  /// In vi, this message translates to:
  /// **'Tiện ích nhanh'**
  String get dashboard_quickActions;

  /// No description provided for @dashboard_createLite.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải nhanh (Lite)'**
  String get dashboard_createLite;

  /// No description provided for @dashboard_createLiteSub.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh trong câu lạc bộ của bạn'**
  String get dashboard_createLiteSub;

  /// No description provided for @dashboard_notificationsSub.
  ///
  /// In vi, this message translates to:
  /// **'Xem mời giải, cập nhật và nhắc việc'**
  String get dashboard_notificationsSub;

  /// No description provided for @dashboard_clubInvites.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời câu lạc bộ'**
  String get dashboard_clubInvites;

  /// No description provided for @dashboard_clubInvitesSub.
  ///
  /// In vi, this message translates to:
  /// **'Nhận và phản hồi lời mời CLB'**
  String get dashboard_clubInvitesSub;

  /// No description provided for @dashboard_profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ cá nhân'**
  String get dashboard_profile;

  /// No description provided for @dashboard_profileSub.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin và hồ sơ công khai'**
  String get dashboard_profileSub;

  /// No description provided for @dashboard_needClubTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cần có câu lạc bộ'**
  String get dashboard_needClubTitle;

  /// No description provided for @dashboard_needClubContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần tạo hoặc tham gia câu lạc bộ trước khi tạo giải nhanh (Lite).'**
  String get dashboard_needClubContent;

  /// No description provided for @dashboard_later.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get dashboard_later;

  /// No description provided for @dashboard_createClubBtn.
  ///
  /// In vi, this message translates to:
  /// **'Tạo câu lạc bộ'**
  String get dashboard_createClubBtn;

  /// No description provided for @dashboard_selectClub.
  ///
  /// In vi, this message translates to:
  /// **'Chọn câu lạc bộ tạo giải'**
  String get dashboard_selectClub;

  /// No description provided for @dashboard_registered.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký'**
  String get dashboard_registered;

  /// No description provided for @dashboard_manageAdvancedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải Nâng Cao'**
  String get dashboard_manageAdvancedTitle;

  /// No description provided for @dashboard_manageAdvancedContent.
  ///
  /// In vi, this message translates to:
  /// **'App hiện chỉ hỗ trợ quản lý giải nhanh (Lite). Giải Nâng Cao vui lòng quản lý trên web.'**
  String get dashboard_manageAdvancedContent;

  /// No description provided for @dashboard_gotIt.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get dashboard_gotIt;

  /// No description provided for @dashboard_liteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giải nhanh (Lite) • Quản lý trên app'**
  String get dashboard_liteDesc;

  /// No description provided for @dashboard_advancedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giải nâng cao • Quản lý đầy đủ'**
  String get dashboard_advancedDesc;

  /// No description provided for @dashboard_loadErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải khu vực của bạn'**
  String get dashboard_loadErrorTitle;

  /// No description provided for @dashboard_loadErrorDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hãy thử tải lại để đồng bộ lời mời, vai trò và các trận được giao.'**
  String get dashboard_loadErrorDesc;

  /// No description provided for @dashboard_retry.
  ///
  /// In vi, this message translates to:
  /// **'Tải lại'**
  String get dashboard_retry;

  /// No description provided for @organizer_title.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý nhanh'**
  String get organizer_title;

  /// No description provided for @organizer_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải giải đấu: {error}'**
  String organizer_loadError(Object error);

  /// No description provided for @organizer_notFound.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu không tồn tại'**
  String get organizer_notFound;

  /// No description provided for @organizer_tabOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get organizer_tabOverview;

  /// No description provided for @organizer_tabTeams.
  ///
  /// In vi, this message translates to:
  /// **'Đội / VĐV'**
  String get organizer_tabTeams;

  /// No description provided for @organizer_tabSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch đấu'**
  String get organizer_tabSchedule;

  /// No description provided for @organizer_tabFinance.
  ///
  /// In vi, this message translates to:
  /// **'Tài chính'**
  String get organizer_tabFinance;

  /// No description provided for @organizer_tabPermissions.
  ///
  /// In vi, this message translates to:
  /// **'Phân quyền'**
  String get organizer_tabPermissions;

  /// No description provided for @organizer_noDate.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chốt ngày'**
  String get organizer_noDate;

  /// No description provided for @organizer_tournamentPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang giải'**
  String get organizer_tournamentPage;

  /// No description provided for @organizer_metricLive.
  ///
  /// In vi, this message translates to:
  /// **'Đang live'**
  String get organizer_metricLive;

  /// No description provided for @organizer_openBracket.
  ///
  /// In vi, this message translates to:
  /// **'Mở sơ đồ thi đấu'**
  String get organizer_openBracket;

  /// No description provided for @organizer_openBracketSub.
  ///
  /// In vi, this message translates to:
  /// **'Xem bracket hiện tại để kiểm tra nhánh và kết quả'**
  String get organizer_openBracketSub;

  /// No description provided for @organizer_viewLive.
  ///
  /// In vi, this message translates to:
  /// **'Xem trận đang diễn ra'**
  String get organizer_viewLive;

  /// No description provided for @organizer_viewLiveSub.
  ///
  /// In vi, this message translates to:
  /// **'Đi vào màn live để theo dõi và điều phối nhanh'**
  String get organizer_viewLiveSub;

  /// No description provided for @organizer_viewPublic.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang giải công khai'**
  String get organizer_viewPublic;

  /// No description provided for @organizer_viewPublicSub.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra giao diện người xem và thông tin hiển thị'**
  String get organizer_viewPublicSub;

  /// No description provided for @organizer_teamsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách đội: {error}'**
  String organizer_teamsLoadError(Object error);

  /// No description provided for @organizer_noTeams.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đội hoặc VĐV nào trong giải.'**
  String get organizer_noTeams;

  /// No description provided for @organizer_noMembers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên'**
  String get organizer_noMembers;

  /// No description provided for @organizer_matchesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải lịch đấu: {error}'**
  String organizer_matchesLoadError(Object error);

  /// No description provided for @organizer_noMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu nào được tạo.'**
  String get organizer_noMatches;

  /// No description provided for @organizer_noTime.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp giờ'**
  String get organizer_noTime;

  /// No description provided for @organizer_matchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vòng {round} • Trận {matchNumber}'**
  String organizer_matchTitle(Object round, Object matchNumber);

  /// No description provided for @organizer_refereesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách trọng tài.\n{error}'**
  String organizer_refereesLoadError(Object error);

  /// No description provided for @organizer_noReferees.
  ///
  /// In vi, this message translates to:
  /// **'Giải này chưa có trọng tài nào được gắn.'**
  String get organizer_noReferees;

  /// No description provided for @organizer_refereeAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get organizer_refereeAccepted;

  /// No description provided for @organizer_refereeInvited.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời'**
  String get organizer_refereeInvited;

  /// No description provided for @organizer_refereeAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Đã giao trận'**
  String get organizer_refereeAssigned;

  /// No description provided for @organizer_noEmail.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có email'**
  String get organizer_noEmail;

  /// No description provided for @organizer_matchCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} trận'**
  String organizer_matchCount(Object count);

  /// No description provided for @organizer_liveCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} đang live'**
  String organizer_liveCount(Object count);

  /// No description provided for @organizer_openAssignedMatch.
  ///
  /// In vi, this message translates to:
  /// **'Mở trận đã giao'**
  String get organizer_openAssignedMatch;

  /// No description provided for @organizer_openNearestMatch.
  ///
  /// In vi, this message translates to:
  /// **'Mở trận gần nhất'**
  String get organizer_openNearestMatch;

  /// No description provided for @organizer_refereeDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối'**
  String get organizer_refereeDeclined;

  /// No description provided for @organizer_statusOngoing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đấu'**
  String get organizer_statusOngoing;

  /// No description provided for @organizer_statusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get organizer_statusCompleted;

  /// No description provided for @organizer_statusScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Sắp đấu'**
  String get organizer_statusScheduled;

  /// No description provided for @organizer_financeTotalRevenue.
  ///
  /// In vi, this message translates to:
  /// **'Tổng doanh thu'**
  String get organizer_financeTotalRevenue;

  /// No description provided for @organizer_financeRegisteredTeams.
  ///
  /// In vi, this message translates to:
  /// **'Số đội đã đăng ký'**
  String get organizer_financeRegisteredTeams;

  /// No description provided for @organizer_financeMaxRevenue.
  ///
  /// In vi, this message translates to:
  /// **'Doanh thu tối đa'**
  String get organizer_financeMaxRevenue;

  /// No description provided for @organizer_financeFreeTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu miễn phí'**
  String get organizer_financeFreeTournament;

  /// No description provided for @organizer_financeNoFee.
  ///
  /// In vi, this message translates to:
  /// **'Không thu phí tham gia'**
  String get organizer_financeNoFee;

  /// No description provided for @organizer_financeDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'CHI TIẾT DOANH THU'**
  String get organizer_financeDetailTitle;

  /// No description provided for @organizer_financeFeePerTeam.
  ///
  /// In vi, this message translates to:
  /// **'Phí tham gia mỗi đội'**
  String get organizer_financeFeePerTeam;

  /// No description provided for @organizer_financeRegisteredTeamsDetail.
  ///
  /// In vi, this message translates to:
  /// **'Đội đã đăng ký'**
  String get organizer_financeRegisteredTeamsDetail;

  /// No description provided for @organizer_financeRemainingSlots.
  ///
  /// In vi, this message translates to:
  /// **'Còn trống'**
  String get organizer_financeRemainingSlots;

  /// No description provided for @organizer_financePaymentInfo.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN THANH TOÁN'**
  String get organizer_financePaymentInfo;

  /// No description provided for @organizer_financePaymentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý thanh toán chi tiết và đối soát trên trang web để có trải nghiệm tốt nhất.'**
  String get organizer_financePaymentDesc;

  /// No description provided for @organizer_financeViewWeb.
  ///
  /// In vi, this message translates to:
  /// **'Xem trên web'**
  String get organizer_financeViewWeb;

  /// No description provided for @organizer_financeWebError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở trang quản lý trên web'**
  String get organizer_financeWebError;

  /// No description provided for @organizer_permissionsCreator.
  ///
  /// In vi, this message translates to:
  /// **'NGƯỜI TẠO GIẢI'**
  String get organizer_permissionsCreator;

  /// No description provided for @organizer_permissionsUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get organizer_permissionsUnknown;

  /// No description provided for @organizer_permissionsRoles.
  ///
  /// In vi, this message translates to:
  /// **'VAI TRÒ & TRUY CẬP'**
  String get organizer_permissionsRoles;

  /// No description provided for @organizer_permissionsAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Admin'**
  String get organizer_permissionsAdmin;

  /// No description provided for @organizer_permissionsAdminDesc.
  ///
  /// In vi, this message translates to:
  /// **'Toàn quyền quản lý giải đấu'**
  String get organizer_permissionsAdminDesc;

  /// No description provided for @organizer_permissionsRefereeDesc.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật tỷ số, quản lý trận đấu'**
  String get organizer_permissionsRefereeDesc;

  /// No description provided for @organizer_permissionsViewer.
  ///
  /// In vi, this message translates to:
  /// **'Người xem'**
  String get organizer_permissionsViewer;

  /// No description provided for @organizer_permissionsViewerDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xem kết quả và bảng xếp hạng'**
  String get organizer_permissionsViewerDesc;

  /// No description provided for @organizer_permissionsTokenAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Mã Admin'**
  String get organizer_permissionsTokenAdmin;

  /// No description provided for @organizer_permissionsTokenReferee.
  ///
  /// In vi, this message translates to:
  /// **'Mã Trọng tài'**
  String get organizer_permissionsTokenReferee;

  /// No description provided for @organizer_permissionsTokenViewer.
  ///
  /// In vi, this message translates to:
  /// **'Mã Xem'**
  String get organizer_permissionsTokenViewer;

  /// No description provided for @organizer_permissionsVisibility.
  ///
  /// In vi, this message translates to:
  /// **'CÀI ĐẶT HIỂN THỊ'**
  String get organizer_permissionsVisibility;

  /// No description provided for @organizer_permissionsDisplay.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị'**
  String get organizer_permissionsDisplay;

  /// No description provided for @organizer_permissionsPublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai — Ai cũng có thể xem'**
  String get organizer_permissionsPublic;

  /// No description provided for @organizer_permissionsPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư — Chỉ người có mã mới xem được'**
  String get organizer_permissionsPrivate;

  /// No description provided for @organizer_permissionsInfoNote.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ mã tương ứng để cấp quyền truy cập cho từng vai trò. Mỗi mã chỉ dùng 1 lần.'**
  String get organizer_permissionsInfoNote;

  /// No description provided for @organizer_tokenCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {label}'**
  String organizer_tokenCopied(Object label);

  /// No description provided for @lite_loadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu giải Lite. Kiểm tra mạng hoặc thử lại.'**
  String get lite_loadFailed;

  /// No description provided for @lite_managementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải'**
  String get lite_managementTitle;

  /// No description provided for @lite_participantsTab.
  ///
  /// In vi, this message translates to:
  /// **'Người tham gia'**
  String get lite_participantsTab;

  /// No description provided for @lite_bracketAndMatches.
  ///
  /// In vi, this message translates to:
  /// **'Bracket & trận đấu'**
  String get lite_bracketAndMatches;

  /// No description provided for @lite_tournamentInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin giải đấu'**
  String get lite_tournamentInfo;

  /// No description provided for @lite_bracketFormat.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức bảng đấu'**
  String get lite_bracketFormat;

  /// No description provided for @lite_participants.
  ///
  /// In vi, this message translates to:
  /// **'Người tham gia'**
  String get lite_participants;

  /// No description provided for @lite_created.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo'**
  String get lite_created;

  /// No description provided for @lite_notCreated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tạo'**
  String get lite_notCreated;

  /// No description provided for @lite_inviteCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời tham gia'**
  String get lite_inviteCodeTitle;

  /// No description provided for @lite_qrCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR'**
  String get lite_qrCodeTitle;

  /// No description provided for @lite_stepPairing.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp'**
  String get lite_stepPairing;

  /// No description provided for @lite_stepFollowMatches.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi trận'**
  String get lite_stepFollowMatches;

  /// No description provided for @lite_progressTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ giải Lite'**
  String get lite_progressTitle;

  /// No description provided for @lite_doubles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đôi'**
  String get lite_doubles;

  /// No description provided for @lite_singles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đơn'**
  String get lite_singles;

  /// No description provided for @lite_inviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời'**
  String get lite_inviteCode;

  /// No description provided for @lite_inviteCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã mời'**
  String get lite_inviteCopied;

  /// No description provided for @lite_copy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get lite_copy;

  /// No description provided for @lite_qrInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR để tham gia giải'**
  String get lite_qrInstruction;

  /// No description provided for @lite_creating.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo...'**
  String get lite_creating;

  /// No description provided for @lite_create.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get lite_create;

  /// No description provided for @lite_createMockPlayers.
  ///
  /// In vi, this message translates to:
  /// **'Tạo VĐV ảo'**
  String get lite_createMockPlayers;

  /// No description provided for @lite_quantity.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng'**
  String get lite_quantity;

  /// No description provided for @lite_quantityHint.
  ///
  /// In vi, this message translates to:
  /// **'1-50'**
  String get lite_quantityHint;

  /// No description provided for @lite_waitingPair.
  ///
  /// In vi, this message translates to:
  /// **'Chờ ghép cặp'**
  String get lite_waitingPair;

  /// No description provided for @lite_noPendingPairs.
  ///
  /// In vi, this message translates to:
  /// **'Không có người chơi đang chờ ghép cặp'**
  String get lite_noPendingPairs;

  /// No description provided for @lite_pairing.
  ///
  /// In vi, this message translates to:
  /// **'Đang ghép...'**
  String get lite_pairing;

  /// No description provided for @lite_pairSelected.
  ///
  /// In vi, this message translates to:
  /// **'Ghép 2 người đã chọn'**
  String get lite_pairSelected;

  /// No description provided for @lite_autoPairing.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp tự động'**
  String get lite_autoPairing;

  /// No description provided for @lite_random.
  ///
  /// In vi, this message translates to:
  /// **'Ngẫu nhiên'**
  String get lite_random;

  /// No description provided for @lite_eloBalanced.
  ///
  /// In vi, this message translates to:
  /// **'Cân bằng ELO'**
  String get lite_eloBalanced;

  /// No description provided for @lite_oddNotice.
  ///
  /// In vi, this message translates to:
  /// **'Số lẻ: 1 người chơi sẽ ở lại trạng thái chờ ghép'**
  String get lite_oddNotice;

  /// No description provided for @lite_paired.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghép cặp'**
  String get lite_paired;

  /// No description provided for @lite_createBracketTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bracket?'**
  String get lite_createBracketTitle;

  /// No description provided for @lite_createBracketConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi tạo bracket, không thể ghép thêm cặp mới. Tiếp tục?'**
  String get lite_createBracketConfirm;

  /// No description provided for @lite_createBracket.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bracket'**
  String get lite_createBracket;

  /// No description provided for @lite_bracketCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo bracket thành công!'**
  String get lite_bracketCreated;

  /// No description provided for @lite_noBracket.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bracket'**
  String get lite_noBracket;

  /// No description provided for @lite_viewBracketDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xem sơ đồ thi đấu để theo dõi các trận đấu'**
  String get lite_viewBracketDesc;

  /// No description provided for @lite_createBracketDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bracket để bắt đầu các trận đấu'**
  String get lite_createBracketDesc;

  /// No description provided for @lite_bracketComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng xem bracket sẽ được cập nhật sau'**
  String get lite_bracketComingSoon;

  /// No description provided for @lite_matchesAfterBracket.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách trận đấu sẽ xuất hiện sau khi tạo bracket'**
  String get lite_matchesAfterBracket;

  /// No description provided for @lite_sessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại rồi thử tạo bracket.'**
  String get lite_sessionExpired;

  /// No description provided for @lite_unauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản chưa được xác thực hoặc không có quyền tạo bracket.'**
  String get lite_unauthorized;

  /// No description provided for @lite_unpairTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy ghép cặp?'**
  String get lite_unpairTitle;

  /// No description provided for @lite_unpairContent.
  ///
  /// In vi, this message translates to:
  /// **'Hai người chơi sẽ trở lại danh sách chờ ghép.'**
  String get lite_unpairContent;

  /// No description provided for @lite_keepPair.
  ///
  /// In vi, this message translates to:
  /// **'Giữ nguyên'**
  String get lite_keepPair;

  /// No description provided for @lite_unpair.
  ///
  /// In vi, this message translates to:
  /// **'Hủy ghép'**
  String get lite_unpair;

  /// No description provided for @lite_unpairSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy ghép cặp'**
  String get lite_unpairSuccess;

  /// No description provided for @lite_unpairApiNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy API hủy ghép trên máy chủ. Vui lòng cập nhật backend.'**
  String get lite_unpairApiNotFound;

  /// No description provided for @lite_unpairError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy ghép cặp. Vui lòng thử lại.'**
  String get lite_unpairError;

  /// No description provided for @lite_pendingPair.
  ///
  /// In vi, this message translates to:
  /// **'Chờ cặp'**
  String get lite_pendingPair;

  /// No description provided for @lite_pairingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp người chơi'**
  String get lite_pairingTitle;

  /// No description provided for @lite_loadParticipantsError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách người tham gia'**
  String get lite_loadParticipantsError;

  /// No description provided for @lite_pairSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp thành công'**
  String get lite_pairSuccess;

  /// No description provided for @lite_pairError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi ghép cặp: '**
  String get lite_pairError;

  /// No description provided for @lite_generateConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận ghép cặp'**
  String get lite_generateConfirmTitle;

  /// No description provided for @lite_generateRandomConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Ghép ngẫu nhiên tất cả người chơi đang chờ?'**
  String get lite_generateRandomConfirm;

  /// No description provided for @lite_generateEloConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Ghép tất cả người chơi đang chờ theo ELO cân bằng?'**
  String get lite_generateEloConfirm;

  /// No description provided for @lite_confirmButton.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get lite_confirmButton;

  /// No description provided for @lite_autoPairSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp tự động thành công'**
  String get lite_autoPairSuccess;

  /// No description provided for @lite_autoPairSuccessOdd.
  ///
  /// In vi, this message translates to:
  /// **'Ghép cặp thành công ({count} người lẻ)'**
  String lite_autoPairSuccessOdd(Object count);

  /// No description provided for @lite_pairGenerateError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi sinh cặp: '**
  String get lite_pairGenerateError;

  /// No description provided for @lite_createBracketNotAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Chức năng tạo bracket sẽ khả dụng sau khi backend cập nhật. Lỗi: '**
  String get lite_createBracketNotAvailable;

  /// No description provided for @lite_unpairErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi hủy cặp: '**
  String get lite_unpairErrorTitle;

  /// No description provided for @lite_joinButton.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia giải'**
  String get lite_joinButton;

  /// No description provided for @lite_joinSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia thành công!'**
  String get lite_joinSuccess;

  /// No description provided for @lite_joinError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tham gia giải đấu.'**
  String get lite_joinError;

  /// No description provided for @lite_clubRequestSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu vào CLB!'**
  String get lite_clubRequestSuccess;

  /// No description provided for @lite_clubRequestError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi yêu cầu vào CLB.'**
  String get lite_clubRequestError;

  /// No description provided for @lite_alreadyJoined.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã tham gia giải này'**
  String get lite_alreadyJoined;

  /// No description provided for @lite_viewTournament.
  ///
  /// In vi, this message translates to:
  /// **'Xem giải đấu'**
  String get lite_viewTournament;

  /// No description provided for @lite_registrationClosed.
  ///
  /// In vi, this message translates to:
  /// **'Giải đã đóng đăng ký'**
  String get lite_registrationClosed;

  /// No description provided for @lite_registrationNotOpen.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu chưa mở đăng ký'**
  String get lite_registrationNotOpen;

  /// No description provided for @lite_tournamentFull.
  ///
  /// In vi, this message translates to:
  /// **'Giải đã đủ số lượng'**
  String get lite_tournamentFull;

  /// No description provided for @lite_requiresClubPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa là thành viên CLB '**
  String get lite_requiresClubPrefix;

  /// No description provided for @lite_joinClub.
  ///
  /// In vi, this message translates to:
  /// **'Vào CLB'**
  String get lite_joinClub;

  /// No description provided for @lite_clubHintAfterJoin.
  ///
  /// In vi, this message translates to:
  /// **'Sau đó nhấn Tham gia giải bên dưới'**
  String get lite_clubHintAfterJoin;

  /// No description provided for @lite_clubNeedsApprovalSuffix.
  ///
  /// In vi, this message translates to:
  /// **' cần duyệt thành viên'**
  String get lite_clubNeedsApprovalSuffix;

  /// No description provided for @lite_requestClub.
  ///
  /// In vi, this message translates to:
  /// **'Xin vào CLB'**
  String get lite_requestClub;

  /// No description provided for @lite_clubApprovalHint.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần được duyệt trước khi tham gia giải'**
  String get lite_clubApprovalHint;

  /// No description provided for @lite_clubInviteOnlySuffix.
  ///
  /// In vi, this message translates to:
  /// **' chỉ dành cho thành viên được mời'**
  String get lite_clubInviteOnlySuffix;

  /// No description provided for @lite_clubPendingApproval.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu vào CLB đang chờ duyệt'**
  String get lite_clubPendingApproval;

  /// No description provided for @lite_yourAccountName.
  ///
  /// In vi, this message translates to:
  /// **'Tên tài khoản của bạn'**
  String get lite_yourAccountName;

  /// No description provided for @lite_nameFromProfile.
  ///
  /// In vi, this message translates to:
  /// **'Tên sẽ được lấy từ hồ sơ cá nhân'**
  String get lite_nameFromProfile;

  /// No description provided for @lite_joining.
  ///
  /// In vi, this message translates to:
  /// **'Đang tham gia...'**
  String get lite_joining;

  /// No description provided for @lite_sending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi...'**
  String get lite_sending;

  /// No description provided for @club_clubNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy câu lạc bộ'**
  String get club_clubNotFound;

  /// No description provided for @club_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin câu lạc bộ'**
  String get club_loadError;

  /// No description provided for @club_sportFallback.
  ///
  /// In vi, this message translates to:
  /// **'Thể thao'**
  String get club_sportFallback;

  /// No description provided for @club_manageShort.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý'**
  String get club_manageShort;

  /// No description provided for @club_memberCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String club_memberCount(Object count);

  /// No description provided for @club_badge.
  ///
  /// In vi, this message translates to:
  /// **'Câu Lạc Bộ'**
  String get club_badge;

  /// No description provided for @club_joinLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get club_joinLoading;

  /// No description provided for @club_joined.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia'**
  String get club_joined;

  /// No description provided for @club_pendingApproval.
  ///
  /// In vi, this message translates to:
  /// **'Chờ phê duyệt'**
  String get club_pendingApproval;

  /// No description provided for @club_joinButton.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia CLB'**
  String get club_joinButton;

  /// No description provided for @club_joinSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia câu lạc bộ thành công!'**
  String get club_joinSuccess;

  /// No description provided for @club_joinFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tham gia câu lạc bộ'**
  String get club_joinFailed;

  /// No description provided for @club_infoSection.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN'**
  String get club_infoSection;

  /// No description provided for @club_memberInfo.
  ///
  /// In vi, this message translates to:
  /// **'Số thành viên'**
  String get club_memberInfo;

  /// No description provided for @club_location.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm'**
  String get club_location;

  /// No description provided for @club_joinModeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức tham gia'**
  String get club_joinModeLabel;

  /// No description provided for @club_joinModeOpen.
  ///
  /// In vi, this message translates to:
  /// **'Tự do'**
  String get club_joinModeOpen;

  /// No description provided for @club_joinModeApprovalNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Cần phê duyệt'**
  String get club_joinModeApprovalNeeded;

  /// No description provided for @club_joinModeInvite.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mời'**
  String get club_joinModeInvite;

  /// No description provided for @club_sportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thi đấu'**
  String get club_sportLabel;

  /// No description provided for @club_noTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giải đấu nào'**
  String get club_noTournaments;

  /// No description provided for @club_createTournament.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải đấu'**
  String get club_createTournament;

  /// No description provided for @club_createNewTournament.
  ///
  /// In vi, this message translates to:
  /// **'+ Tạo giải đấu mới'**
  String get club_createNewTournament;

  /// No description provided for @club_loadDataError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách giải đấu'**
  String get club_loadDataError;

  /// No description provided for @club_teamCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max} đội'**
  String club_teamCount(Object count, Object max);

  /// No description provided for @club_liteManage.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh (Quản lý)'**
  String get club_liteManage;

  /// No description provided for @club_quickTournament.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh (Lite)'**
  String get club_quickTournament;

  /// No description provided for @club_advanced.
  ///
  /// In vi, this message translates to:
  /// **'Nâng cao'**
  String get club_advanced;

  /// No description provided for @club_selectTournamentType.
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại giải đấu'**
  String get club_selectTournamentType;

  /// No description provided for @club_selectTournamentDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn hình thức giải đấu muốn tạo'**
  String get club_selectTournamentDesc;

  /// No description provided for @club_liteTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nhanh (Lite)'**
  String get club_liteTournament;

  /// No description provided for @club_30sOnApp.
  ///
  /// In vi, this message translates to:
  /// **'30s TRÊN APP'**
  String get club_30sOnApp;

  /// No description provided for @club_liteDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tạo và quản lý sơ đồ thi đấu ngay trên app điện thoại'**
  String get club_liteDesc;

  /// No description provided for @club_advancedTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nâng Cao (Full)'**
  String get club_advancedTournament;

  /// No description provided for @club_createOnWeb.
  ///
  /// In vi, this message translates to:
  /// **'TẠO TRÊN WEB'**
  String get club_createOnWeb;

  /// No description provided for @club_advancedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đầy đủ tính năng, lệ phí, phân quyền trên website'**
  String get club_advancedDesc;

  /// No description provided for @club_createAdvancedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Giải Nâng Cao'**
  String get club_createAdvancedTitle;

  /// No description provided for @club_advancedWebDialog.
  ///
  /// In vi, this message translates to:
  /// **'Để quản lý giải đấu nâng cao (phân chia bảng đấu phức tạp, thu lệ phí, tùy chỉnh luật...), vui lòng truy cập website sporto.asia trên máy tính.'**
  String get club_advancedWebDialog;

  /// No description provided for @club_copyWebLink.
  ///
  /// In vi, this message translates to:
  /// **'Đến trang tạo'**
  String get club_copyWebLink;

  /// No description provided for @club_membersLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get club_membersLabel;

  /// No description provided for @club_owner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ sở hữu'**
  String get club_owner;

  /// No description provided for @club_admin.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên'**
  String get club_admin;

  /// No description provided for @club_setAdmin.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm Quản trị viên'**
  String get club_setAdmin;

  /// No description provided for @club_setMod.
  ///
  /// In vi, this message translates to:
  /// **'Đặt làm Điều hành viên'**
  String get club_setMod;

  /// No description provided for @club_demoteToMember.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển thành Thành viên'**
  String get club_demoteToMember;

  /// No description provided for @club_kickFromClub.
  ///
  /// In vi, this message translates to:
  /// **'Xóa khỏi câu lạc bộ'**
  String get club_kickFromClub;

  /// No description provided for @club_deleteMemberTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get club_deleteMemberTitle;

  /// No description provided for @club_deleteMemberConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa {name} khỏi câu lạc bộ?'**
  String club_deleteMemberConfirm(Object name);

  /// No description provided for @club_updatedMember.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật thành viên'**
  String get club_updatedMember;

  /// No description provided for @club_inviteMember.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get club_inviteMember;

  /// No description provided for @club_searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo tên hoặc email...'**
  String get club_searchHint;

  /// No description provided for @club_inviteSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời thành công!'**
  String get club_inviteSent;

  /// No description provided for @club_noUsersFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng phù hợp'**
  String get club_noUsersFound;

  /// No description provided for @club_joinRequests.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu tham gia ({count})'**
  String club_joinRequests(Object count);

  /// No description provided for @club_approvedMember.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt tham gia câu lạc bộ!'**
  String get club_approvedMember;

  /// No description provided for @club_rejected.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối yêu cầu tham gia'**
  String get club_rejected;

  /// No description provided for @club_approve.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get club_approve;

  /// No description provided for @club_reject.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get club_reject;

  /// No description provided for @club_noImages.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hình ảnh nào'**
  String get club_noImages;

  /// No description provided for @club_gallerySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hình ảnh giải đấu và câu lạc bộ sẽ hiển thị ở đây'**
  String get club_gallerySubtitle;

  /// No description provided for @club_imageCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} hình ảnh'**
  String club_imageCount(Object count);

  /// No description provided for @club_tabSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get club_tabSettings;

  /// No description provided for @club_managementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Điều phối Câu Lạc Bộ'**
  String get club_managementTitle;

  /// No description provided for @club_activeMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get club_activeMembers;

  /// No description provided for @club_pendingRequests.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get club_pendingRequests;

  /// No description provided for @club_invited.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời'**
  String get club_invited;

  /// No description provided for @club_banned.
  ///
  /// In vi, this message translates to:
  /// **'Bị cấm'**
  String get club_banned;

  /// No description provided for @club_joinRequestSection.
  ///
  /// In vi, this message translates to:
  /// **'Đơn xin gia nhập ({count})'**
  String club_joinRequestSection(Object count);

  /// No description provided for @club_approvedAlert.
  ///
  /// In vi, this message translates to:
  /// **'Đã chấp nhận thành viên!'**
  String get club_approvedAlert;

  /// No description provided for @club_rejectedAlert.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối đơn gia nhập.'**
  String get club_rejectedAlert;

  /// No description provided for @club_ownerInviteInfo.
  ///
  /// In vi, this message translates to:
  /// **'Chủ sở hữu có thể mời với vai trò Thành viên hoặc Điều hành viên.'**
  String get club_ownerInviteInfo;

  /// No description provided for @club_adminInviteInfo.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị viên có thể mời người dùng tham gia làm Thành viên.'**
  String get club_adminInviteInfo;

  /// No description provided for @club_roleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò mời:'**
  String get club_roleLabel;

  /// No description provided for @club_memberChip.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get club_memberChip;

  /// No description provided for @club_adminChip.
  ///
  /// In vi, this message translates to:
  /// **'Điều hành viên'**
  String get club_adminChip;

  /// No description provided for @club_inviteButton.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lời mời'**
  String get club_inviteButton;

  /// No description provided for @club_noUsersOrInClub.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy người dùng hoặc họ đã ở trong CLB.'**
  String get club_noUsersOrInClub;

  /// No description provided for @club_invitedSection.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời đã gửi ({count})'**
  String club_invitedSection(Object count);

  /// No description provided for @club_revokeInvite.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi lời mời'**
  String get club_revokeInvite;

  /// No description provided for @club_cancelInvite.
  ///
  /// In vi, this message translates to:
  /// **'Hủy lời mời'**
  String get club_cancelInvite;

  /// No description provided for @club_pendingPostsSection.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết chờ duyệt ({count})'**
  String club_pendingPostsSection(Object count);

  /// No description provided for @club_noPendingPosts.
  ///
  /// In vi, this message translates to:
  /// **'Không có bài viết chờ duyệt.'**
  String get club_noPendingPosts;

  /// No description provided for @club_rejectPost.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get club_rejectPost;

  /// No description provided for @club_approvePost.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get club_approvePost;

  /// No description provided for @club_postApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt bài viết.'**
  String get club_postApproved;

  /// No description provided for @club_postRejected.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối bài viết.'**
  String get club_postRejected;

  /// No description provided for @club_postModerationError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý bài viết.'**
  String get club_postModerationError;

  /// No description provided for @club_reportsSection.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo bài viết ({count})'**
  String club_reportsSection(Object count);

  /// No description provided for @club_noPendingReports.
  ///
  /// In vi, this message translates to:
  /// **'Không có báo cáo đang chờ xử lý.'**
  String get club_noPendingReports;

  /// No description provided for @club_reportReasonSpam.
  ///
  /// In vi, this message translates to:
  /// **'Spam / quảng cáo'**
  String get club_reportReasonSpam;

  /// No description provided for @club_reportReasonHarassment.
  ///
  /// In vi, this message translates to:
  /// **'Quấy rối / xúc phạm'**
  String get club_reportReasonHarassment;

  /// No description provided for @club_reportReasonHate.
  ///
  /// In vi, this message translates to:
  /// **'Thù ghét / phân biệt'**
  String get club_reportReasonHate;

  /// No description provided for @club_reportReasonSexual.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung phản cảm'**
  String get club_reportReasonSexual;

  /// No description provided for @club_reportReasonViolence.
  ///
  /// In vi, this message translates to:
  /// **'Bạo lực / đe dọa'**
  String get club_reportReasonViolence;

  /// No description provided for @club_reportReasonOther.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get club_reportReasonOther;

  /// No description provided for @club_reportedBy.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo bởi {name}'**
  String club_reportedBy(Object name);

  /// No description provided for @club_postBy.
  ///
  /// In vi, this message translates to:
  /// **'Bài của {name}: {text}'**
  String club_postBy(Object name, Object text);

  /// No description provided for @club_dismissReport.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get club_dismissReport;

  /// No description provided for @club_resolveReport.
  ///
  /// In vi, this message translates to:
  /// **'Đã xử lý'**
  String get club_resolveReport;

  /// No description provided for @club_reportResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận xử lý báo cáo.'**
  String get club_reportResolved;

  /// No description provided for @club_reportDismissed.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ qua báo cáo.'**
  String get club_reportDismissed;

  /// No description provided for @club_reportUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật báo cáo. Vui lòng thử lại.'**
  String get club_reportUpdateError;

  /// No description provided for @club_managementActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hoàn tất thao tác. Vui lòng thử lại.'**
  String get club_managementActionError;

  /// No description provided for @club_tournamentManagement.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải đấu CLB'**
  String get club_tournamentManagement;

  /// No description provided for @club_tournamentManagementDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mới và điều hành các giải đấu của Câu lạc bộ.'**
  String get club_tournamentManagementDescription;

  /// No description provided for @club_chooseTournamentTypeDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hình thức tổ chức phù hợp với quy mô giải của CLB'**
  String get club_chooseTournamentTypeDescription;

  /// No description provided for @club_liteCreatedOnApp.
  ///
  /// In vi, this message translates to:
  /// **'TẠO TRÊN APP'**
  String get club_liteCreatedOnApp;

  /// No description provided for @club_liteTournamentDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tạo trực tiếp trên điện thoại trong 30 giây, tự động chia bảng và theo dõi tỷ số.'**
  String get club_liteTournamentDescription;

  /// No description provided for @club_standardTournamentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải Tiêu chuẩn'**
  String get club_standardTournamentTitle;

  /// No description provided for @club_standardTournamentTitleAdvanced.
  ///
  /// In vi, this message translates to:
  /// **'Giải Tiêu chuẩn (Nâng cao)'**
  String get club_standardTournamentTitleAdvanced;

  /// No description provided for @club_standardCreatedOnWeb.
  ///
  /// In vi, this message translates to:
  /// **'TẠO TRÊN WEB'**
  String get club_standardCreatedOnWeb;

  /// No description provided for @club_standardTournamentDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu quy mô lớn với đầy đủ tính năng sơ đồ thi đấu, tài chính & trọng tài.'**
  String get club_standardTournamentDescription;

  /// No description provided for @club_noManagedTournaments.
  ///
  /// In vi, this message translates to:
  /// **'CLB chưa có giải đấu nào. Bấm nút phía trên để tạo giải!'**
  String get club_noManagedTournaments;

  /// No description provided for @club_managedTournamentsHeading.
  ///
  /// In vi, this message translates to:
  /// **'CÁC GIẢI ĐẤU ĐANG ĐIỀU HÀNH'**
  String get club_managedTournamentsHeading;

  /// No description provided for @club_liteTournamentShort.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nhanh'**
  String get club_liteTournamentShort;

  /// No description provided for @club_standardTournamentShort.
  ///
  /// In vi, this message translates to:
  /// **'Giải Tiêu chuẩn'**
  String get club_standardTournamentShort;

  /// No description provided for @club_viewTournament.
  ///
  /// In vi, this message translates to:
  /// **'Xem trang giải'**
  String get club_viewTournament;

  /// No description provided for @club_manageTournament.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải'**
  String get club_manageTournament;

  /// No description provided for @club_loadTournamentsError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách giải. Vui lòng thử lại.'**
  String get club_loadTournamentsError;

  /// No description provided for @club_aboutSection.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get club_aboutSection;

  /// No description provided for @club_active.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get club_active;

  /// No description provided for @club_bannedSection.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên bị cấm ({count})'**
  String club_bannedSection(Object count);

  /// No description provided for @club_createdAt.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo'**
  String get club_createdAt;

  /// No description provided for @club_dangerSection.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực nguy hiểm'**
  String get club_dangerSection;

  /// No description provided for @club_deleteClub.
  ///
  /// In vi, this message translates to:
  /// **'Xóa CLB'**
  String get club_deleteClub;

  /// No description provided for @club_deleteConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa CLB'**
  String get club_deleteConfirmTitle;

  /// No description provided for @club_deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa CLB'**
  String get club_deleted;

  /// No description provided for @club_deleteSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn câu lạc bộ và toàn bộ dữ liệu'**
  String get club_deleteSubtitle;

  /// No description provided for @club_deleteWarning.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa {name}?'**
  String club_deleteWarning(Object name);

  /// No description provided for @club_editInfo.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa thông tin'**
  String get club_editInfo;

  /// No description provided for @club_editInfoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật tên, mô tả, ảnh đại diện'**
  String get club_editInfoSubtitle;

  /// No description provided for @club_joinModeApproval.
  ///
  /// In vi, this message translates to:
  /// **'Xét duyệt'**
  String get club_joinModeApproval;

  /// No description provided for @club_joinModeSection.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức tham gia'**
  String get club_joinModeSection;

  /// No description provided for @club_label.
  ///
  /// In vi, this message translates to:
  /// **'CLB'**
  String get club_label;

  /// No description provided for @club_loadImagesError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải ảnh'**
  String get club_loadImagesError;

  /// No description provided for @club_loadListError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách'**
  String get club_loadListError;

  /// No description provided for @club_manageClub.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý CLB'**
  String get club_manageClub;

  /// No description provided for @club_manageClubSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt thành viên, cập nhật cài đặt'**
  String get club_manageClubSubtitle;

  /// No description provided for @club_noMembers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành viên'**
  String get club_noMembers;

  /// No description provided for @club_noSport.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có môn thể thao'**
  String get club_noSport;

  /// No description provided for @club_pending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get club_pending;

  /// No description provided for @club_sectionInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin CLB'**
  String get club_sectionInfo;

  /// No description provided for @club_statsSection.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get club_statsSection;

  /// No description provided for @club_statusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get club_statusLabel;

  /// No description provided for @club_tabAbout.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get club_tabAbout;

  /// No description provided for @club_tabGallery.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện'**
  String get club_tabGallery;

  /// No description provided for @club_tabMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get club_tabMembers;

  /// No description provided for @club_tabRankings.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng'**
  String get club_tabRankings;

  /// No description provided for @club_tabTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get club_tabTournaments;

  /// No description provided for @club_unban.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ cấm'**
  String get club_unban;

  /// No description provided for @club_unbanned.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ cấm thành viên'**
  String get club_unbanned;

  /// No description provided for @edit_tab_profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get edit_tab_profile;

  /// No description provided for @edit_tab_bank.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get edit_tab_bank;

  /// No description provided for @edit_tab_security.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật'**
  String get edit_tab_security;

  /// No description provided for @edit_profile_load_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải hồ sơ: {error}'**
  String edit_profile_load_error(Object error);

  /// No description provided for @edit_avatar_title.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ảnh đại diện'**
  String get edit_avatar_title;

  /// No description provided for @edit_take_photo.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh mới'**
  String get edit_take_photo;

  /// No description provided for @edit_choose_from_library.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get edit_choose_from_library;

  /// No description provided for @edit_avatar_upload_success.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh đại diện thành công'**
  String get edit_avatar_upload_success;

  /// No description provided for @edit_avatar_upload_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải ảnh: {error}'**
  String edit_avatar_upload_error(Object error);

  /// No description provided for @edit_full_name_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ và tên của bạn'**
  String get edit_full_name_hint;

  /// No description provided for @edit_full_name_required.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ và tên'**
  String get edit_full_name_required;

  /// No description provided for @edit_email_label.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get edit_email_label;

  /// No description provided for @edit_email_hint.
  ///
  /// In vi, this message translates to:
  /// **'example@domain.com'**
  String get edit_email_hint;

  /// No description provided for @edit_email_required.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email'**
  String get edit_email_required;

  /// No description provided for @edit_email_invalid.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get edit_email_invalid;

  /// No description provided for @edit_email_verified_already.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được xác minh'**
  String get edit_email_verified_already;

  /// No description provided for @edit_email_verify_success.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được xác minh thành công'**
  String get edit_email_verify_success;

  /// No description provided for @edit_phone_hint.
  ///
  /// In vi, this message translates to:
  /// **'0987654321'**
  String get edit_phone_hint;

  /// No description provided for @edit_phone_required.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số điện thoại'**
  String get edit_phone_required;

  /// No description provided for @edit_phone_invalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ'**
  String get edit_phone_invalid;

  /// No description provided for @edit_phone_verified_already.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại đã được xác minh'**
  String get edit_phone_verified_already;

  /// No description provided for @edit_otp_send_failed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi mã OTP đến SĐT'**
  String get edit_otp_send_failed;

  /// No description provided for @edit_otp_send_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi mã OTP: {error}'**
  String edit_otp_send_error(Object error);

  /// No description provided for @edit_otp_enter_code.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã xác minh'**
  String get edit_otp_enter_code;

  /// No description provided for @edit_otp_label.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP'**
  String get edit_otp_label;

  /// No description provided for @edit_otp_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã OTP từ tin nhắn'**
  String get edit_otp_hint;

  /// No description provided for @edit_phone_verify_title.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh số điện thoại'**
  String get edit_phone_verify_title;

  /// No description provided for @edit_phone_verify_success.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh số điện thoại thành công'**
  String get edit_phone_verify_success;

  /// No description provided for @edit_phone_verify_failed.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh thất bại: {error}'**
  String edit_phone_verify_failed(Object error);

  /// No description provided for @edit_password_required.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu'**
  String get edit_password_required;

  /// No description provided for @edit_current_password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get edit_current_password;

  /// No description provided for @edit_password_confirm_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mật khẩu để xác nhận'**
  String get edit_password_confirm_hint;

  /// No description provided for @edit_delete_account_title.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get edit_delete_account_title;

  /// No description provided for @edit_delete_account_confirm.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xoá vĩnh viễn.'**
  String get edit_delete_account_confirm;

  /// No description provided for @edit_delete_account_error.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản thất bại: {error}'**
  String edit_delete_account_error(Object error);

  /// No description provided for @edit_account_deleted.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản đã được xoá'**
  String get edit_account_deleted;

  /// No description provided for @edit_update_success.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật thông tin thành công'**
  String get edit_update_success;

  /// No description provided for @edit_update_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String edit_update_error(Object error);

  /// No description provided for @edit_save_changes.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get edit_save_changes;

  /// No description provided for @edit_saved_changes.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thay đổi'**
  String get edit_saved_changes;

  /// No description provided for @edit_bio_label.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu (bio)'**
  String get edit_bio_label;

  /// No description provided for @edit_bio_hint.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu ngắn về bản thân...'**
  String get edit_bio_hint;

  /// No description provided for @edit_address_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ'**
  String get edit_address_hint;

  /// No description provided for @edit_bank_account_title.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản ngân hàng nhận thưởng'**
  String get edit_bank_account_title;

  /// No description provided for @edit_bank_account_desc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng để ban tổ chức chuyển khoản giải thưởng từ các giải đấu.'**
  String get edit_bank_account_desc;

  /// No description provided for @edit_bank_name.
  ///
  /// In vi, this message translates to:
  /// **'Tên ngân hàng'**
  String get edit_bank_name;

  /// No description provided for @edit_bank_name_hint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Vietcombank, Techcombank...'**
  String get edit_bank_name_hint;

  /// No description provided for @edit_bank_account_number.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get edit_bank_account_number;

  /// No description provided for @edit_bank_account_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tài khoản'**
  String get edit_bank_account_hint;

  /// No description provided for @edit_bank_account_name.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản'**
  String get edit_bank_account_name;

  /// No description provided for @edit_bank_account_name_hint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên chủ tài khoản (Viết hoa không dấu)'**
  String get edit_bank_account_name_hint;

  /// No description provided for @edit_security_account.
  ///
  /// In vi, this message translates to:
  /// **'Bảo mật tài khoản'**
  String get edit_security_account;

  /// No description provided for @edit_change_password_desc.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mật khẩu đăng nhập của bạn'**
  String get edit_change_password_desc;

  /// No description provided for @edit_delete_account.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get edit_delete_account;

  /// No description provided for @edit_delete_account_warning.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn tài khoản và dữ liệu cá nhân của bạn.'**
  String get edit_delete_account_warning;

  /// No description provided for @edit_bank_saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thông tin ngân hàng'**
  String get edit_bank_saved;

  /// No description provided for @edit_bank_load_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin ngân hàng'**
  String get edit_bank_load_error;

  /// No description provided for @edit_bank_account_name_hint_short.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên chủ tài khoản'**
  String get edit_bank_account_name_hint_short;

  /// No description provided for @edit_bank_info_desc.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin ngân hàng dùng để nhận tiền thưởng giải đấu. Dữ liệu được bảo mật và không hiển thị công khai.'**
  String get edit_bank_info_desc;

  /// No description provided for @edit_verification_status.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái xác thực'**
  String get edit_verification_status;

  /// No description provided for @edit_verify_email.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh Email'**
  String get edit_verify_email;

  /// No description provided for @edit_verify_email_desc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác minh tới email đang dùng'**
  String get edit_verify_email_desc;

  /// No description provided for @edit_verification_load_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải trạng thái'**
  String get edit_verification_load_error;

  /// No description provided for @edit_strong_password.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mạnh'**
  String get edit_strong_password;

  /// No description provided for @edit_strong_password_desc.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu 6 ký tự, nên có chữ hoa và số'**
  String get edit_strong_password_desc;

  /// No description provided for @edit_sessions.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập'**
  String get edit_sessions;

  /// No description provided for @edit_current_device.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị hiện tại'**
  String get edit_current_device;

  /// No description provided for @edit_active.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get edit_active;

  /// No description provided for @edit_bio_label_short.
  ///
  /// In vi, this message translates to:
  /// **'Tiểu sử'**
  String get edit_bio_label_short;

  /// No description provided for @edit_bio_hint_short.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu bản thân...'**
  String get edit_bio_hint_short;

  /// No description provided for @edit_phone_hint_inline.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số điện thoại'**
  String get edit_phone_hint_inline;

  /// No description provided for @edit_full_name_hint_short.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ tên'**
  String get edit_full_name_hint_short;

  /// No description provided for @edit_full_name_required_short.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ tên'**
  String get edit_full_name_required_short;

  /// No description provided for @edit_overview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get edit_overview;

  /// No description provided for @edit_achievements.
  ///
  /// In vi, this message translates to:
  /// **'Danh hiệu'**
  String get edit_achievements;

  /// No description provided for @edit_elo_tab.
  ///
  /// In vi, this message translates to:
  /// **'ELO'**
  String get edit_elo_tab;

  /// No description provided for @edit_rank_by_sport.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng theo bộ môn'**
  String get edit_rank_by_sport;

  /// No description provided for @edit_matches_load_error.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được lịch sử trận đấu'**
  String get edit_matches_load_error;

  /// No description provided for @edit_no_public_matches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu công khai'**
  String get edit_no_public_matches;

  /// No description provided for @edit_not_played.
  ///
  /// In vi, this message translates to:
  /// **'Chưa diễn ra'**
  String get edit_not_played;

  /// No description provided for @edit_achievements_highlight.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích nổi bật'**
  String get edit_achievements_highlight;

  /// No description provided for @edit_no_achievements.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thành tích nào'**
  String get edit_no_achievements;

  /// No description provided for @edit_champion.
  ///
  /// In vi, this message translates to:
  /// **'Quán quân'**
  String get edit_champion;

  /// No description provided for @edit_runner_up.
  ///
  /// In vi, this message translates to:
  /// **'Á quân'**
  String get edit_runner_up;

  /// No description provided for @edit_third_place.
  ///
  /// In vi, this message translates to:
  /// **'Hạng ba'**
  String get edit_third_place;

  /// No description provided for @edit_no_user_data.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu người dùng'**
  String get edit_no_user_data;

  /// No description provided for @edit_view_history_detail.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch sử chi tiết'**
  String get edit_view_history_detail;

  /// No description provided for @edit_sport_count.
  ///
  /// In vi, this message translates to:
  /// **'Bộ môn'**
  String get edit_sport_count;

  /// No description provided for @edit_total_elo.
  ///
  /// In vi, this message translates to:
  /// **'Tổng ELO'**
  String get edit_total_elo;

  /// No description provided for @edit_avg_elo.
  ///
  /// In vi, this message translates to:
  /// **'ELO TB'**
  String get edit_avg_elo;

  /// No description provided for @edit_total_matches.
  ///
  /// In vi, this message translates to:
  /// **'Tổng trận'**
  String get edit_total_matches;

  /// No description provided for @edit_elo_chart.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ ELO'**
  String get edit_elo_chart;

  /// No description provided for @edit_detailed_stats.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê chi tiết'**
  String get edit_detailed_stats;

  /// No description provided for @edit_coach.
  ///
  /// In vi, this message translates to:
  /// **'Huấn luyện viên'**
  String get edit_coach;

  /// No description provided for @edit_cannot_load_info.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin'**
  String get edit_cannot_load_info;

  /// No description provided for @edit_no_rank_data.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu xếp hạng'**
  String get edit_no_rank_data;

  /// No description provided for @edit_profile_athlete.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ Vận động viên'**
  String get edit_profile_athlete;

  /// No description provided for @edit_profile_card.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ VĐV & ELO'**
  String get edit_profile_card;

  /// No description provided for @edit_verify.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh'**
  String get edit_verify;

  /// No description provided for @rank_current_elo.
  ///
  /// In vi, this message translates to:
  /// **'ELO hiện tại'**
  String get rank_current_elo;

  /// No description provided for @rank_no_history.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử biến động ELO'**
  String get rank_no_history;

  /// No description provided for @rank_no_history_desc.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tham gia các trận đấu xếp hạng để ghi nhận điểm ELO'**
  String get rank_no_history_desc;

  /// No description provided for @rank_peak_elo.
  ///
  /// In vi, this message translates to:
  /// **'Peak ELO (Cao nhất)'**
  String get rank_peak_elo;

  /// No description provided for @rank_public.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get rank_public;

  /// No description provided for @rank_activity.
  ///
  /// In vi, this message translates to:
  /// **'HOẠT ĐỘNG'**
  String get rank_activity;

  /// No description provided for @rank_decay.
  ///
  /// In vi, this message translates to:
  /// **'Suy giảm ELO (không thi đấu)'**
  String get rank_decay;

  /// No description provided for @rank_update.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ELO'**
  String get rank_update;

  /// No description provided for @exploreHeaderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get exploreHeaderTitle;

  /// No description provided for @exploreHeaderSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giải đấu phù hợp với bạn'**
  String get exploreHeaderSubtitle;

  /// No description provided for @exploreNationalRanking.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng Quốc gia'**
  String get exploreNationalRanking;

  /// No description provided for @exploreWinsStat.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get exploreWinsStat;

  /// No description provided for @exploreEloToGold.
  ///
  /// In vi, this message translates to:
  /// **'Còn 50 ELO nữa lên Hạng Vàng'**
  String get exploreEloToGold;

  /// No description provided for @exploreHighForm.
  ///
  /// In vi, this message translates to:
  /// **'Phong độ cao'**
  String get exploreHighForm;

  /// No description provided for @exploreSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm giải đấu, môn thể thao...'**
  String get exploreSearchHint;

  /// No description provided for @exploreFeaturedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu nổi bật'**
  String get exploreFeaturedTitle;

  /// No description provided for @exploreLiveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu đang diễn ra'**
  String get exploreLiveTitle;

  /// No description provided for @exploreLiveEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu nào đang diễn ra'**
  String get exploreLiveEmpty;

  /// No description provided for @exploreRecentResultsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả trận đấu vừa qua'**
  String get exploreRecentResultsTitle;

  /// No description provided for @exploreUpcomingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch thi đấu sắp diễn ra'**
  String get exploreUpcomingTitle;

  /// No description provided for @exploreViewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get exploreViewAll;

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giải đấu'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Thử thay đổi bộ lọc hoặc từ khoá tìm kiếm'**
  String get exploreEmptyHint;

  /// No description provided for @exploreRankedTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải xếp hạng'**
  String get exploreRankedTournament;

  /// No description provided for @exploreFriendlyTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu giao lưu'**
  String get exploreFriendlyTournament;

  /// No description provided for @exploreBracketLosers.
  ///
  /// In vi, this message translates to:
  /// **'NHÁNH THUA'**
  String get exploreBracketLosers;

  /// No description provided for @exploreBracketGroup.
  ///
  /// In vi, this message translates to:
  /// **'VÒNG BẢNG'**
  String get exploreBracketGroup;

  /// No description provided for @exploreBracketKnockout.
  ///
  /// In vi, this message translates to:
  /// **'VÒNG KNOCKOUT'**
  String get exploreBracketKnockout;

  /// No description provided for @exploreCourtNotAssigned.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp sân'**
  String get exploreCourtNotAssigned;

  /// No description provided for @exploreByeAdvance.
  ///
  /// In vi, this message translates to:
  /// **'Vô thẳng'**
  String get exploreByeAdvance;

  /// No description provided for @exploreCheer.
  ///
  /// In vi, this message translates to:
  /// **'Cổ vũ'**
  String get exploreCheer;

  /// No description provided for @exploreDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get exploreDetails;

  /// No description provided for @exploreShareSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu: {tournament} • {court}'**
  String exploreShareSubtitle(Object tournament, Object court);

  /// No description provided for @exploreLiveBadge.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu đang Live 🔴'**
  String get exploreLiveBadge;

  /// No description provided for @exploreMatchBadge.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get exploreMatchBadge;

  /// No description provided for @exploreMatchStatusLive.
  ///
  /// In vi, this message translates to:
  /// **'ĐANG DIỄN RA • VÒNG {round}'**
  String exploreMatchStatusLive(Object round);

  /// No description provided for @exploreMatchStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'ĐÃ HOÀN THÀNH • VÒNG {round}'**
  String exploreMatchStatusCompleted(Object round);

  /// No description provided for @exploreMatchStatusScheduled.
  ///
  /// In vi, this message translates to:
  /// **'SẮP DIỄN RA • VÒNG {round}'**
  String exploreMatchStatusScheduled(Object round);

  /// No description provided for @exploreRecentResultsLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải kết quả trận đấu...'**
  String get exploreRecentResultsLoading;

  /// No description provided for @exploreRecentResultsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được kết quả trận đấu. Vui lòng thử lại.'**
  String get exploreRecentResultsLoadError;

  /// No description provided for @exploreRecentResultsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận nào kết thúc gần đây'**
  String get exploreRecentResultsEmpty;

  /// No description provided for @rankingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin xếp hạng'**
  String get rankingTitle;

  /// No description provided for @rankingLoadErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin xếp hạng'**
  String get rankingLoadErrorTitle;

  /// No description provided for @rankingLoadErrorSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng thử lại sau.'**
  String get rankingLoadErrorSubtitle;

  /// No description provided for @rankingUserFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get rankingUserFallback;

  /// No description provided for @rankingEloRating.
  ///
  /// In vi, this message translates to:
  /// **'ĐIỂM ELO'**
  String get rankingEloRating;

  /// No description provided for @rankingMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận'**
  String get rankingMatches;

  /// No description provided for @rankingWins.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get rankingWins;

  /// No description provided for @rankingLosses.
  ///
  /// In vi, this message translates to:
  /// **'Thua'**
  String get rankingLosses;

  /// No description provided for @leaderboardNoSports.
  ///
  /// In vi, this message translates to:
  /// **'Không có môn thể thao'**
  String get leaderboardNoSports;

  /// No description provided for @leaderboardNoSportsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có môn thể thao nào được định nghĩa.'**
  String get leaderboardNoSportsSubtitle;

  /// No description provided for @leaderboardProvinceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/Thành:'**
  String get leaderboardProvinceLabel;

  /// No description provided for @leaderboardSearchEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy \"{query}\"'**
  String leaderboardSearchEmpty(Object query);

  /// No description provided for @leaderboardSearchEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Vận động viên có thể nằm ngoài Top 100 hoặc chưa tham gia giải đấu.'**
  String get leaderboardSearchEmptyHint;

  /// No description provided for @leaderboardRank5To10.
  ///
  /// In vi, this message translates to:
  /// **'HẠNG 5 — 10'**
  String get leaderboardRank5To10;

  /// No description provided for @leaderboardRank4To10.
  ///
  /// In vi, this message translates to:
  /// **'HẠNG 4 — 10'**
  String get leaderboardRank4To10;

  /// No description provided for @leaderboardTop11To100Title.
  ///
  /// In vi, this message translates to:
  /// **'Xem Hạng 11 – 100'**
  String get leaderboardTop11To100Title;

  /// No description provided for @leaderboardTop11To100Subtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng đầy đủ vận động viên trên toàn quốc'**
  String get leaderboardTop11To100Subtitle;

  /// No description provided for @leaderboardNationwide.
  ///
  /// In vi, this message translates to:
  /// **'TOÀN QUỐC'**
  String get leaderboardNationwide;

  /// No description provided for @leaderboardNoRank4To10.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vận động viên ở Hạng 4 – 10'**
  String get leaderboardNoRank4To10;

  /// No description provided for @leaderboardNoRank11To100.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vận động viên ở Hạng 11 – 100'**
  String get leaderboardNoRank11To100;

  /// No description provided for @leaderboardNoTop100.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa có hạng trong Top 100. Tham gia giải đấu để được xếp hạng!'**
  String get leaderboardNoTop100;

  /// No description provided for @rankingWinRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ thắng'**
  String get rankingWinRate;

  /// No description provided for @rankingRecentMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu gần đây'**
  String get rankingRecentMatches;

  /// No description provided for @rankingNoMatchData.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu trận đấu'**
  String get rankingNoMatchData;

  /// No description provided for @rankingLeadGroup.
  ///
  /// In vi, this message translates to:
  /// **'DẪN ĐẦU NHÓM'**
  String get rankingLeadGroup;

  /// No description provided for @rankingTopAthlete.
  ///
  /// In vi, this message translates to:
  /// **'Vận động viên xuất sắc'**
  String get rankingTopAthlete;

  /// No description provided for @rankingElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO'**
  String get rankingElo;

  /// No description provided for @clubRankingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng CLB'**
  String get clubRankingTitle;

  /// No description provided for @clubRankingSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm thành viên trong top 20...'**
  String get clubRankingSearchHint;

  /// No description provided for @clubRankingFilterTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc xếp hạng'**
  String get clubRankingFilterTooltip;

  /// No description provided for @clubRankingAutoRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Tự động cập nhật mỗi 30 giây'**
  String get clubRankingAutoRefresh;

  /// No description provided for @clubRankingViewAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả xếp hạng →'**
  String get clubRankingViewAll;

  /// No description provided for @clubRankingFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc xếp hạng'**
  String get clubRankingFilterTitle;

  /// No description provided for @clubRankingFilterHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn môn, thể thức và giới tính'**
  String get clubRankingFilterHint;

  /// No description provided for @clubRankingSport.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get clubRankingSport;

  /// No description provided for @clubRankingFormat.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức'**
  String get clubRankingFormat;

  /// No description provided for @clubRankingGender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get clubRankingGender;

  /// No description provided for @clubRankingSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đơn'**
  String get clubRankingSingles;

  /// No description provided for @clubRankingDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi'**
  String get clubRankingDoubles;

  /// No description provided for @clubRankingMixedDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam nữ'**
  String get clubRankingMixedDoubles;

  /// No description provided for @clubRankingMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get clubRankingMale;

  /// No description provided for @clubRankingFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get clubRankingFemale;

  /// No description provided for @clubRankingApply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get clubRankingApply;

  /// No description provided for @clubRankingMyRank.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng của bạn'**
  String get clubRankingMyRank;

  /// No description provided for @clubRankingPeak.
  ///
  /// In vi, this message translates to:
  /// **'Cao nhất: {elo}'**
  String clubRankingPeak(Object elo);

  /// No description provided for @clubRankingError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải xếp hạng'**
  String get clubRankingError;

  /// No description provided for @clubRankingSearchEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thành viên'**
  String get clubRankingSearchEmpty;

  /// No description provided for @clubRankingEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu xếp hạng'**
  String get clubRankingEmpty;

  /// No description provided for @clubRankingEmptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn bộ lọc khác hoặc tham gia thi đấu để có ELO'**
  String get clubRankingEmptyHint;

  /// No description provided for @clubRankingErrorHint.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng thử lại sau'**
  String get clubRankingErrorHint;

  /// No description provided for @clubRankingTeamFallback.
  ///
  /// In vi, this message translates to:
  /// **'Đội bóng'**
  String get clubRankingTeamFallback;

  /// No description provided for @clubRankingMemberFallback.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get clubRankingMemberFallback;

  /// No description provided for @clubRankingUnranked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp hạng'**
  String get clubRankingUnranked;

  /// No description provided for @clubInvitesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời CLB'**
  String get clubInvitesTitle;

  /// No description provided for @clubInvitesInvitedBy.
  ///
  /// In vi, this message translates to:
  /// **'Được mời bởi {name}'**
  String clubInvitesInvitedBy(Object name);

  /// No description provided for @clubInvitesPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get clubInvitesPending;

  /// No description provided for @clubInvitesEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có lời mời nào'**
  String get clubInvitesEmptyTitle;

  /// No description provided for @clubInvitesEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các lời mời tham gia câu lạc bộ sẽ hiển thị tại đây'**
  String get clubInvitesEmptySubtitle;

  /// No description provided for @clubInvitesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải lời mời'**
  String get clubInvitesLoadError;

  /// No description provided for @clubInvitesAlreadyMember.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã là thành viên của câu lạc bộ này.'**
  String get clubInvitesAlreadyMember;

  /// No description provided for @clubInvitesActionError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi xử lý lời mời.'**
  String get clubInvitesActionError;

  /// No description provided for @clubTournamentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get clubTournamentsTitle;

  /// No description provided for @clubTournamentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có giải đấu'**
  String get clubTournamentsEmpty;

  /// No description provided for @clubTournamentsCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải đấu'**
  String get clubTournamentsCreate;

  /// No description provided for @clubTournamentsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách giải đấu'**
  String get clubTournamentsLoadError;

  /// No description provided for @clubTournamentsChooseType.
  ///
  /// In vi, this message translates to:
  /// **'Chọn loại giải đấu'**
  String get clubTournamentsChooseType;

  /// No description provided for @clubTournamentsChooseTypeHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hình thức tạo giải phù hợp cho câu lạc bộ của bạn'**
  String get clubTournamentsChooseTypeHint;

  /// No description provided for @clubTournamentsLiteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải Nhanh (Lite)'**
  String get clubTournamentsLiteTitle;

  /// No description provided for @clubTournamentsLiteDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh trong 30 giây. Sinh mã QR và link mời để chia sẻ trực tiếp cho các thành viên.'**
  String get clubTournamentsLiteDescription;

  /// No description provided for @clubTournamentsWebTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh trên Web'**
  String get clubTournamentsWebTitle;

  /// No description provided for @clubTournamentsWebDescription.
  ///
  /// In vi, this message translates to:
  /// **'Form nhanh đầy đủ hơn Lite; giải vẫn thuộc CLB và mở quản lý nâng cao trên web.'**
  String get clubTournamentsWebDescription;

  /// No description provided for @clubTournamentsAdvancedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải nâng cao trên Web'**
  String get clubTournamentsAdvancedTitle;

  /// No description provided for @clubTournamentsAdvancedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Tạo trên Web'**
  String get clubTournamentsAdvancedBadge;

  /// No description provided for @clubTournamentsAdvancedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu nâng cao có nhiều cấu hình chuyên sâu (Vòng bảng, Knockout, Lịch thi đấu, Lệ phí và Giải thưởng).\\n\\nVui lòng truy cập trang web sporto.asia trên máy tính để tạo giải nâng cao cho câu lạc bộ!'**
  String get clubTournamentsAdvancedDescription;

  /// No description provided for @clubTournamentsAdvancedCardDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khởi tạo trên Web sporto.asia. Đầy đủ cấu hình: Thể thức Vòng bảng, Knockout, Lịch thi đấu và Giải thưởng.'**
  String get clubTournamentsAdvancedCardDescription;

  /// No description provided for @clubTournamentsClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get clubTournamentsClose;

  /// No description provided for @clubTournamentsCopyWebLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link Web'**
  String get clubTournamentsCopyWebLink;

  /// No description provided for @clubTournamentsLinkCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép link tạo giải'**
  String get clubTournamentsLinkCopied;

  /// No description provided for @myReportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo của tôi'**
  String get myReportsTitle;

  /// No description provided for @myReportsBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get myReportsBack;

  /// No description provided for @myReportsRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới báo cáo'**
  String get myReportsRefresh;

  /// No description provided for @myReportsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải lịch sử báo cáo'**
  String get myReportsLoadError;

  /// No description provided for @myReportsRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get myReportsRetry;

  /// No description provided for @myReportsEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa gửi báo cáo nào'**
  String get myReportsEmptyTitle;

  /// No description provided for @myReportsEmptySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các báo cáo bạn gửi sẽ được hiển thị tại đây để theo dõi trạng thái xử lý.'**
  String get myReportsEmptySubtitle;

  /// No description provided for @myReportsStatusSubmitted.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get myReportsStatusSubmitted;

  /// No description provided for @myReportsStatusTriaged.
  ///
  /// In vi, this message translates to:
  /// **'Đã phân loại'**
  String get myReportsStatusTriaged;

  /// No description provided for @myReportsStatusUnderReview.
  ///
  /// In vi, this message translates to:
  /// **'Đang xem xét'**
  String get myReportsStatusUnderReview;

  /// No description provided for @myReportsStatusEscalated.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển cấp'**
  String get myReportsStatusEscalated;

  /// No description provided for @myReportsStatusResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải quyết'**
  String get myReportsStatusResolved;

  /// No description provided for @myReportsStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối'**
  String get myReportsStatusRejected;

  /// No description provided for @myReportsTargetUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get myReportsTargetUser;

  /// No description provided for @myReportsTargetTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get myReportsTargetTournament;

  /// No description provided for @myReportsTargetMatch.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get myReportsTargetMatch;

  /// No description provided for @myReportsTargetCommunity.
  ///
  /// In vi, this message translates to:
  /// **'Cộng đồng'**
  String get myReportsTargetCommunity;

  /// No description provided for @myReportsCategoryCheating.
  ///
  /// In vi, this message translates to:
  /// **'Gian lận'**
  String get myReportsCategoryCheating;

  /// No description provided for @myReportsCategoryRuleViolation.
  ///
  /// In vi, this message translates to:
  /// **'Vi phạm luật'**
  String get myReportsCategoryRuleViolation;

  /// No description provided for @myReportsCategoryAbusiveBehavior.
  ///
  /// In vi, this message translates to:
  /// **'Hành vi xúc phạm'**
  String get myReportsCategoryAbusiveBehavior;

  /// No description provided for @myReportsCategoryFakeInformation.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin giả mạo'**
  String get myReportsCategoryFakeInformation;

  /// No description provided for @myReportsCategoryPaymentFraud.
  ///
  /// In vi, this message translates to:
  /// **'Gian lận thanh toán'**
  String get myReportsCategoryPaymentFraud;

  /// No description provided for @myReportsCategoryUnsafeOrganization.
  ///
  /// In vi, this message translates to:
  /// **'Tổ chức không an toàn'**
  String get myReportsCategoryUnsafeOrganization;

  /// No description provided for @myReportsCategoryOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get myReportsCategoryOther;

  /// No description provided for @myReportsUnknownTarget.
  ///
  /// In vi, this message translates to:
  /// **'Đối tượng không xác định'**
  String get myReportsUnknownTarget;

  /// No description provided for @myReportsUnknownDate.
  ///
  /// In vi, this message translates to:
  /// **'Không rõ thời gian'**
  String get myReportsUnknownDate;

  /// No description provided for @myReportsViewTarget.
  ///
  /// In vi, this message translates to:
  /// **'Xem đối tượng'**
  String get myReportsViewTarget;

  /// No description provided for @myReportsSentAt.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi: {date}'**
  String myReportsSentAt(Object date);

  /// No description provided for @myReportsResolutionNote.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú xử lý'**
  String get myReportsResolutionNote;

  /// No description provided for @myReportsPageCount.
  ///
  /// In vi, this message translates to:
  /// **'Trang {page}/{totalPages}'**
  String myReportsPageCount(Object page, Object totalPages);

  /// No description provided for @myReportsPreviousPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang trước'**
  String get myReportsPreviousPage;

  /// No description provided for @myReportsNextPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang sau'**
  String get myReportsNextPage;

  /// No description provided for @settingsPrivacyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền riêng tư'**
  String get settingsPrivacyTitle;

  /// No description provided for @settingsStrangerMessages.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn từ người lạ'**
  String get settingsStrangerMessages;

  /// No description provided for @settingsStrangerMessagesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép người chưa kết nối với bạn bắt đầu cuộc trò chuyện.'**
  String get settingsStrangerMessagesDescription;

  /// No description provided for @settingsStrangerMessagesOn.
  ///
  /// In vi, this message translates to:
  /// **'Đang cho phép'**
  String get settingsStrangerMessagesOn;

  /// No description provided for @settingsStrangerMessagesOff.
  ///
  /// In vi, this message translates to:
  /// **'Đang chặn'**
  String get settingsStrangerMessagesOff;

  /// No description provided for @settingsStrangerMessagesUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật quyền nhận tin nhắn'**
  String get settingsStrangerMessagesUpdated;

  /// No description provided for @settingsStrangerMessagesUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật quyền nhận tin nhắn'**
  String get settingsStrangerMessagesUpdateError;

  /// No description provided for @dashboardRankings.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng công khai'**
  String get dashboardRankings;

  /// No description provided for @dashboardRankingsSub.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi thứ hạng và phong độ người chơi'**
  String get dashboardRankingsSub;

  /// No description provided for @dashboardChat.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get dashboardChat;

  /// No description provided for @dashboardChatSub.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện với người chơi và câu lạc bộ'**
  String get dashboardChatSub;

  /// No description provided for @dashboardReports.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử báo cáo'**
  String get dashboardReports;

  /// No description provided for @dashboardReportsSub.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi các báo cáo bạn đã gửi'**
  String get dashboardReportsSub;

  /// No description provided for @dashboardFootballTeams.
  ///
  /// In vi, this message translates to:
  /// **'Đội bóng của tôi'**
  String get dashboardFootballTeams;

  /// No description provided for @dashboardFootballTeamsSub.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đội hình và ELO bóng đá'**
  String get dashboardFootballTeamsSub;

  /// No description provided for @chatScreenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đoạn chat'**
  String get chatScreenTitle;

  /// No description provided for @chatScreenConversations.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện'**
  String get chatScreenConversations;

  /// No description provided for @chatScreenAiAssistant.
  ///
  /// In vi, this message translates to:
  /// **'AI Trợ lý'**
  String get chatScreenAiAssistant;

  /// No description provided for @chatScreenSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ CSKH'**
  String get chatScreenSupport;

  /// No description provided for @chatScreenSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm tin nhắn, người chơi hoặc CLB...'**
  String get chatScreenSearchHint;

  /// No description provided for @chatScreenClubBadge.
  ///
  /// In vi, this message translates to:
  /// **'CLB'**
  String get chatScreenClubBadge;

  /// No description provided for @chatScreenRevokedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn đã bị thu hồi'**
  String get chatScreenRevokedMessage;

  /// No description provided for @chatScreenImageMessage.
  ///
  /// In vi, this message translates to:
  /// **'[Hình ảnh]'**
  String get chatScreenImageMessage;

  /// No description provided for @chatScreenStartConversation.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu cuộc trò chuyện'**
  String get chatScreenStartConversation;

  /// No description provided for @chatScreenNoSearchResults.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy cuộc trò chuyện phù hợp.'**
  String get chatScreenNoSearchResults;

  /// No description provided for @chatScreenNoConversations.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có cuộc trò chuyện nào.'**
  String get chatScreenNoConversations;

  /// No description provided for @chatScreenAiGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào! Mình là trợ lý AI Sporto. Bạn có thể hỏi về luật thi đấu, cách tính điểm ELO, hay cách đăng ký tham gia các giải đấu!'**
  String get chatScreenAiGreeting;

  /// No description provided for @chatScreenAiPromptRegistration.
  ///
  /// In vi, this message translates to:
  /// **'Cách đăng ký giải đấu?'**
  String get chatScreenAiPromptRegistration;

  /// No description provided for @chatScreenAiPromptElo.
  ///
  /// In vi, this message translates to:
  /// **'Hệ số ELO tính thế nào?'**
  String get chatScreenAiPromptElo;

  /// No description provided for @chatScreenAiPromptCreateClub.
  ///
  /// In vi, this message translates to:
  /// **'Làm sao để tạo CLB?'**
  String get chatScreenAiPromptCreateClub;

  /// No description provided for @chatScreenAiPromptRules.
  ///
  /// In vi, this message translates to:
  /// **'Luật thi đấu Pickleball?'**
  String get chatScreenAiPromptRules;

  /// No description provided for @chatScreenAiTyping.
  ///
  /// In vi, this message translates to:
  /// **'Sporto AI đang soạn câu trả lời...'**
  String get chatScreenAiTyping;

  /// No description provided for @chatScreenAiInputHint.
  ///
  /// In vi, this message translates to:
  /// **'Hỏi AI Sporto bất cứ điều gì...'**
  String get chatScreenAiInputHint;

  /// No description provided for @chatScreenAiFallbackReply.
  ///
  /// In vi, this message translates to:
  /// **'Sporto AI đang xử lý yêu cầu của bạn...'**
  String get chatScreenAiFallbackReply;

  /// No description provided for @chatScreenAiErrorReply.
  ///
  /// In vi, this message translates to:
  /// **'Xin lỗi, tạm thời hệ thống AI đang bận. Bạn có thể thử lại sau ít phút nhé!'**
  String get chatScreenAiErrorReply;

  /// No description provided for @chatScreenSupportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trung tâm hỗ trợ Sporto'**
  String get chatScreenSupportTitle;

  /// No description provided for @chatScreenSupportDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hãy gửi câu hỏi, nhân viên CSKH sẽ hỗ trợ bạn sớm nhất.'**
  String get chatScreenSupportDescription;

  /// No description provided for @chatScreenSupportInputHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập nội dung cần hỗ trợ...'**
  String get chatScreenSupportInputHint;

  /// No description provided for @chatRoomSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn & Cài đặt'**
  String get chatRoomSettingsTitle;

  /// No description provided for @chatRoomAdminSection.
  ///
  /// In vi, this message translates to:
  /// **'QUẢN TRỊ PHÒNG CHAT (CHỦ PHÒNG / ADMIN)'**
  String get chatRoomAdminSection;

  /// No description provided for @chatRoomNotificationsSection.
  ///
  /// In vi, this message translates to:
  /// **'CÀI ĐẶT THÔNG BÁO'**
  String get chatRoomNotificationsSection;

  /// No description provided for @chatRoomPinnedSection.
  ///
  /// In vi, this message translates to:
  /// **'TIN NHẮN ĐÃ GHIM'**
  String get chatRoomPinnedSection;

  /// No description provided for @chatRoomSharedMediaSection.
  ///
  /// In vi, this message translates to:
  /// **'ẢNH & PHƯƠNG TIỆN ĐÃ CHIA SẺ ({count})'**
  String chatRoomSharedMediaSection(Object count);

  /// No description provided for @chatRoomMembersSection.
  ///
  /// In vi, this message translates to:
  /// **'THÀNH VIÊN TRONG PHÒNG ({count})'**
  String chatRoomMembersSection(Object count);

  /// No description provided for @chatRoomOtherOptionsSection.
  ///
  /// In vi, this message translates to:
  /// **'TÙY CHỌN KHÁC'**
  String get chatRoomOtherOptionsSection;

  /// No description provided for @chatRoomClubType.
  ///
  /// In vi, this message translates to:
  /// **'👥 CÂU LẠC BỘ'**
  String get chatRoomClubType;

  /// No description provided for @chatRoomDirectType.
  ///
  /// In vi, this message translates to:
  /// **'💬 TRỰC TIẾP'**
  String get chatRoomDirectType;

  /// No description provided for @chatRoomViewClub.
  ///
  /// In vi, this message translates to:
  /// **'Xem trang CLB'**
  String get chatRoomViewClub;

  /// No description provided for @chatRoomNotificationsMutedAction.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo phòng chat'**
  String get chatRoomNotificationsMutedAction;

  /// No description provided for @chatRoomNotificationsMentionsAction.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận thông báo khi được nhắc tên (@mention)'**
  String get chatRoomNotificationsMentionsAction;

  /// No description provided for @chatRoomNotificationsAllAction.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật tất cả thông báo'**
  String get chatRoomNotificationsAllAction;

  /// No description provided for @chatRoomRenameTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên phòng chat'**
  String get chatRoomRenameTitle;

  /// No description provided for @chatRoomRenameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên phòng chat mới...'**
  String get chatRoomRenameHint;

  /// No description provided for @chatRoomSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get chatRoomSave;

  /// No description provided for @chatRoomChangeAvatarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện phòng chat'**
  String get chatRoomChangeAvatarTitle;

  /// No description provided for @chatRoomChangeAvatarSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tải ảnh mới từ thư viện của bạn'**
  String get chatRoomChangeAvatarSubtitle;

  /// No description provided for @chatRoomAnnouncementOnlyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ chỉ thông báo'**
  String get chatRoomAnnouncementOnlyTitle;

  /// No description provided for @chatRoomAnnouncementOnlySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ Ban Quản Trị mới có thể gửi tin nhắn'**
  String get chatRoomAnnouncementOnlySubtitle;

  /// No description provided for @chatRoomSlowModeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ làm chậm (Slow mode)'**
  String get chatRoomSlowModeTitle;

  /// No description provided for @chatRoomSlowModeWait.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên phải chờ {seconds} giây giữa mỗi tin'**
  String chatRoomSlowModeWait(Object seconds);

  /// No description provided for @chatRoomSlowModeOffSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt làm chậm (nhắn tin bình thường)'**
  String get chatRoomSlowModeOffSubtitle;

  /// No description provided for @chatRoomSlowModeOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get chatRoomSlowModeOff;

  /// No description provided for @chatRoomAllNotificationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả tin nhắn'**
  String get chatRoomAllNotificationsTitle;

  /// No description provided for @chatRoomAllNotificationsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo cho mọi tin nhắn, ảnh và bình chọn'**
  String get chatRoomAllNotificationsSubtitle;

  /// No description provided for @chatRoomMentionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khi được nhắc tên (@mentions)'**
  String get chatRoomMentionsTitle;

  /// No description provided for @chatRoomMentionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thông báo khi ai đó nhắc đến bạn (@bạn)'**
  String get chatRoomMentionsSubtitle;

  /// No description provided for @chatRoomMutedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt thông báo'**
  String get chatRoomMutedTitle;

  /// No description provided for @chatRoomMutedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt toàn bộ thông báo từ phòng chat này'**
  String get chatRoomMutedSubtitle;

  /// No description provided for @chatRoomReactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo khi thả cảm xúc ❤️'**
  String get chatRoomReactionsTitle;

  /// No description provided for @chatRoomReactionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo khi thành viên bày tỏ cảm xúc'**
  String get chatRoomReactionsSubtitle;

  /// No description provided for @chatRoomRepliesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo khi có người trả lời 💬'**
  String get chatRoomRepliesTitle;

  /// No description provided for @chatRoomRepliesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo khi ai đó trả lời tin nhắn của bạn'**
  String get chatRoomRepliesSubtitle;

  /// No description provided for @chatRoomSoundTitle.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh thông báo 🔊'**
  String get chatRoomSoundTitle;

  /// No description provided for @chatRoomSoundSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Phát âm thanh khi có tin nhắn mới'**
  String get chatRoomSoundSubtitle;

  /// No description provided for @chatRoomPinnedFrom.
  ///
  /// In vi, this message translates to:
  /// **'Ghim từ: {sender}'**
  String chatRoomPinnedFrom(Object sender);

  /// No description provided for @chatRoomMediaPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'[Hình ảnh/Phương tiện]'**
  String get chatRoomMediaPlaceholder;

  /// No description provided for @chatRoomGoToMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đi đến tin nhắn'**
  String get chatRoomGoToMessage;

  /// No description provided for @chatRoomSharedMediaEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hình ảnh nào được chia sẻ trong phòng chat này.'**
  String get chatRoomSharedMediaEmpty;

  /// No description provided for @chatRoomAllMembersCanChat.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thành viên trong CLB đều có quyền tham gia và nhắn tin.'**
  String get chatRoomAllMembersCanChat;

  /// No description provided for @chatRoomRoleOwner.
  ///
  /// In vi, this message translates to:
  /// **'CHỦ NHIỆM'**
  String get chatRoomRoleOwner;

  /// No description provided for @chatRoomRoleAdmin.
  ///
  /// In vi, this message translates to:
  /// **'QUẢN TRỊ'**
  String get chatRoomRoleAdmin;

  /// No description provided for @chatRoomRoleMember.
  ///
  /// In vi, this message translates to:
  /// **'THÀNH VIÊN'**
  String get chatRoomRoleMember;

  /// No description provided for @chatRoomClearHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lịch sử cuộc trò chuyện?'**
  String get chatRoomClearHistoryTitle;

  /// No description provided for @chatRoomClearHistoryDescription.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ tin nhắn sẽ bị xóa khỏi chế độ xem của bạn. Các thành viên khác vẫn xem được bình thường.'**
  String get chatRoomClearHistoryDescription;

  /// No description provided for @chatRoomClearHistoryAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa lịch sử'**
  String get chatRoomClearHistoryAction;

  /// No description provided for @chatRoomClearHistorySuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa lịch sử cuộc trò chuyện phía bạn.'**
  String get chatRoomClearHistorySuccess;

  /// No description provided for @chatRoomUploadAvatarError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải ảnh lên.'**
  String get chatRoomUploadAvatarError;

  /// No description provided for @chatRoomSettingsUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật cài đặt phòng chat.'**
  String get chatRoomSettingsUpdated;

  /// No description provided for @chatRoomSettingsUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật cài đặt phòng chat. Vui lòng thử lại.'**
  String get chatRoomSettingsUpdateError;

  /// No description provided for @chatRoomViewProfile.
  ///
  /// In vi, this message translates to:
  /// **'Xem trang cá nhân'**
  String get chatRoomViewProfile;

  /// No description provided for @chatRoomPrivateMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin riêng'**
  String get chatRoomPrivateMessage;

  /// No description provided for @chatRoomBlockUser.
  ///
  /// In vi, this message translates to:
  /// **'Chặn người dùng này'**
  String get chatRoomBlockUser;

  /// No description provided for @chatRoomBlockedUser.
  ///
  /// In vi, this message translates to:
  /// **'Đã chặn {name}'**
  String chatRoomBlockedUser(Object name);

  /// No description provided for @chatPollValidationError.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập câu hỏi và ít nhất 2 phương án.'**
  String get chatPollValidationError;

  /// No description provided for @chatPollCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo cuộc bình chọn'**
  String get chatPollCreateTitle;

  /// No description provided for @chatPollQuestionHint.
  ///
  /// In vi, this message translates to:
  /// **'Đặt câu hỏi bình chọn...'**
  String get chatPollQuestionHint;

  /// No description provided for @chatPollOptionsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Các lựa chọn:'**
  String get chatPollOptionsLabel;

  /// No description provided for @chatPollOptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn {number}'**
  String chatPollOptionHint(Object number);

  /// No description provided for @chatPollAddOption.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lựa chọn'**
  String get chatPollAddOption;

  /// No description provided for @chatPollAllowMultiple.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép chọn nhiều phương án'**
  String get chatPollAllowMultiple;

  /// No description provided for @chatPollSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bình chọn'**
  String get chatPollSubmit;

  /// No description provided for @chatImageLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải hình ảnh'**
  String get chatImageLoadError;

  /// No description provided for @chatImageClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get chatImageClose;

  /// No description provided for @chatDetailRoomFallback.
  ///
  /// In vi, this message translates to:
  /// **'Phòng chat'**
  String get chatDetailRoomFallback;

  /// No description provided for @chatDetailToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get chatDetailToday;

  /// No description provided for @chatDetailYesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get chatDetailYesterday;

  /// No description provided for @chatDetailPollTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bình chọn'**
  String get chatDetailPollTooltip;

  /// No description provided for @chatDetailRoomSettingsTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn & Thông báo'**
  String get chatDetailRoomSettingsTooltip;

  /// No description provided for @chatDetailPinnedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn đã ghim'**
  String get chatDetailPinnedLabel;

  /// No description provided for @chatDetailAttachedImage.
  ///
  /// In vi, this message translates to:
  /// **'📷 [Hình ảnh đính kèm]'**
  String get chatDetailAttachedImage;

  /// No description provided for @chatDetailPollPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'📊 [Bình chọn]'**
  String get chatDetailPollPlaceholder;

  /// No description provided for @chatDetailViewMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xem tin nhắn'**
  String get chatDetailViewMessage;

  /// No description provided for @chatDetailNoMessages.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn nào.'**
  String get chatDetailNoMessages;

  /// No description provided for @chatDetailStartConversation.
  ///
  /// In vi, this message translates to:
  /// **'Hãy gửi tin nhắn đầu tiên để bắt đầu trò chuyện!'**
  String get chatDetailStartConversation;

  /// No description provided for @chatDetailSeenBy.
  ///
  /// In vi, this message translates to:
  /// **'Đã xem bởi {name}'**
  String chatDetailSeenBy(Object name);

  /// No description provided for @chatDetailTyping.
  ///
  /// In vi, this message translates to:
  /// **'{name} đang soạn tin...'**
  String chatDetailTyping(Object name);

  /// No description provided for @chatDetailOnlineCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} người đang online'**
  String chatDetailOnlineCount(Object count);

  /// No description provided for @chatDetailActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get chatDetailActive;

  /// No description provided for @chatDetailRecentlyActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động gần đây'**
  String get chatDetailRecentlyActive;

  /// No description provided for @chatDetailReplyTo.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời {name}'**
  String chatDetailReplyTo(Object name);

  /// No description provided for @chatDetailMediaPollPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'[Hình ảnh / Bình chọn]'**
  String get chatDetailMediaPollPlaceholder;

  /// No description provided for @chatDetailSendImage.
  ///
  /// In vi, this message translates to:
  /// **'Gửi ảnh'**
  String get chatDetailSendImage;

  /// No description provided for @chatDetailTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get chatDetailTakePhoto;

  /// No description provided for @chatDetailMessageHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin...'**
  String get chatDetailMessageHint;

  /// No description provided for @chatDetailSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get chatDetailSend;

  /// No description provided for @chatDetailLike.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get chatDetailLike;

  /// No description provided for @adminClubsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý CLB'**
  String get adminClubsTitle;

  /// No description provided for @adminClubsSearchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm CLB...'**
  String get adminClubsSearchHint;

  /// No description provided for @adminClubsFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminClubsFilterAll;

  /// No description provided for @adminClubsFilterActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get adminClubsFilterActive;

  /// No description provided for @adminClubsFilterPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get adminClubsFilterPending;

  /// No description provided for @adminClubsFilterInactive.
  ///
  /// In vi, this message translates to:
  /// **'Đã khóa'**
  String get adminClubsFilterInactive;

  /// No description provided for @adminClubsFilterRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminClubsFilterRejected;

  /// No description provided for @adminClubsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách'**
  String get adminClubsLoadError;

  /// No description provided for @adminClubsStatTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng'**
  String get adminClubsStatTotal;

  /// No description provided for @adminClubsStatActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get adminClubsStatActive;

  /// No description provided for @adminClubsStatPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ'**
  String get adminClubsStatPending;

  /// No description provided for @adminClubsStatRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminClubsStatRejected;

  /// No description provided for @adminClubsMembers.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String adminClubsMembers(Object count);

  /// No description provided for @adminClubsStatusActive.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get adminClubsStatusActive;

  /// No description provided for @adminClubsStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get adminClubsStatusPending;

  /// No description provided for @adminClubsStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminClubsStatusRejected;

  /// No description provided for @adminClubsView.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get adminClubsView;

  /// No description provided for @adminClubsApprove.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get adminClubsApprove;

  /// No description provided for @adminClubsReject.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminClubsReject;

  /// No description provided for @adminClubsDisable.
  ///
  /// In vi, this message translates to:
  /// **'Vô hiệu'**
  String get adminClubsDisable;

  /// No description provided for @adminClubsApprovedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt CLB'**
  String get adminClubsApprovedFeedback;

  /// No description provided for @adminClubsUpdatedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật CLB'**
  String get adminClubsUpdatedFeedback;

  /// No description provided for @adminClubsActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật CLB. Vui lòng thử lại.'**
  String get adminClubsActionError;

  /// No description provided for @adminClubsRejectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối CLB'**
  String get adminClubsRejectTitle;

  /// No description provided for @adminClubsDisableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vô hiệu hoá CLB'**
  String get adminClubsDisableTitle;

  /// No description provided for @adminClubsReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (bắt buộc)'**
  String get adminClubsReasonHint;

  /// No description provided for @adminClubsCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get adminClubsCancel;

  /// No description provided for @adminClubsConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get adminClubsConfirm;

  /// No description provided for @adminClubsRejectError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý CLB. Vui lòng thử lại.'**
  String get adminClubsRejectError;

  /// No description provided for @adminClubsEmptyAll.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có câu lạc bộ nào'**
  String get adminClubsEmptyAll;

  /// No description provided for @adminClubsEmptyActive.
  ///
  /// In vi, this message translates to:
  /// **'Không có CLB đang hoạt động'**
  String get adminClubsEmptyActive;

  /// No description provided for @adminClubsEmptyPending.
  ///
  /// In vi, this message translates to:
  /// **'Không có CLB chờ duyệt'**
  String get adminClubsEmptyPending;

  /// No description provided for @adminClubsEmptyRejected.
  ///
  /// In vi, this message translates to:
  /// **'Không có CLB bị từ chối'**
  String get adminClubsEmptyRejected;

  /// No description provided for @adminChangeRequestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu thay đổi'**
  String get adminChangeRequestsTitle;

  /// No description provided for @adminChangeRequestsFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminChangeRequestsFilterAll;

  /// No description provided for @adminChangeRequestsFilterPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get adminChangeRequestsFilterPending;

  /// No description provided for @adminChangeRequestsFilterApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt'**
  String get adminChangeRequestsFilterApproved;

  /// No description provided for @adminChangeRequestsFilterRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminChangeRequestsFilterRejected;

  /// No description provided for @adminChangeRequestsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có yêu cầu nào'**
  String get adminChangeRequestsEmpty;

  /// No description provided for @adminChangeRequestsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu'**
  String get adminChangeRequestsLoadError;

  /// No description provided for @adminChangeRequestsTypeOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get adminChangeRequestsTypeOther;

  /// No description provided for @adminChangeRequestsRequester.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get adminChangeRequestsRequester;

  /// No description provided for @adminChangeRequestsStatusApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt'**
  String get adminChangeRequestsStatusApproved;

  /// No description provided for @adminChangeRequestsStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminChangeRequestsStatusRejected;

  /// No description provided for @adminChangeRequestsStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get adminChangeRequestsStatusPending;

  /// No description provided for @adminChangeRequestsApprove.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get adminChangeRequestsApprove;

  /// No description provided for @adminChangeRequestsReject.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminChangeRequestsReject;

  /// No description provided for @adminChangeRequestsApprovedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt yêu cầu'**
  String get adminChangeRequestsApprovedFeedback;

  /// No description provided for @adminChangeRequestsRejectedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối yêu cầu'**
  String get adminChangeRequestsRejectedFeedback;

  /// No description provided for @adminChangeRequestsActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý yêu cầu. Vui lòng thử lại.'**
  String get adminChangeRequestsActionError;

  /// No description provided for @adminDisputesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khiếu nại'**
  String get adminDisputesTitle;

  /// No description provided for @adminDisputesFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminDisputesFilterAll;

  /// No description provided for @adminDisputesFilterOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get adminDisputesFilterOpen;

  /// No description provided for @adminDisputesFilterResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải quyết'**
  String get adminDisputesFilterResolved;

  /// No description provided for @adminDisputesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có khiếu nại nào'**
  String get adminDisputesEmpty;

  /// No description provided for @adminDisputesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu'**
  String get adminDisputesLoadError;

  /// No description provided for @adminDisputesReasonFallback.
  ///
  /// In vi, this message translates to:
  /// **'Khiếu nại'**
  String get adminDisputesReasonFallback;

  /// No description provided for @adminDisputesUserFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get adminDisputesUserFallback;

  /// No description provided for @adminDisputesStatusOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get adminDisputesStatusOpen;

  /// No description provided for @adminDisputesStatusResolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải quyết'**
  String get adminDisputesStatusResolved;

  /// No description provided for @adminDisputesCreatedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tạo: {date}'**
  String adminDisputesCreatedAt(Object date);

  /// No description provided for @adminDisputesResolve.
  ///
  /// In vi, this message translates to:
  /// **'Đóng khiếu nại'**
  String get adminDisputesResolve;

  /// No description provided for @adminDisputesResolvedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng khiếu nại'**
  String get adminDisputesResolvedFeedback;

  /// No description provided for @adminDisputesResolveError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đóng khiếu nại. Vui lòng thử lại.'**
  String get adminDisputesResolveError;

  /// No description provided for @pendingClubsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt CLB'**
  String get pendingClubsTitle;

  /// No description provided for @pendingClubsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có CLB nào chờ duyệt'**
  String get pendingClubsEmpty;

  /// No description provided for @pendingClubsAllReviewed.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả CLB đã được xét duyệt'**
  String get pendingClubsAllReviewed;

  /// No description provided for @pendingClubsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải danh sách'**
  String get pendingClubsLoadError;

  /// No description provided for @pendingClubsRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get pendingClubsRetry;

  /// No description provided for @pendingClubsMemberCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String pendingClubsMemberCount(Object count);

  /// No description provided for @pendingClubsStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get pendingClubsStatus;

  /// No description provided for @pendingClubsApprove.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get pendingClubsApprove;

  /// No description provided for @pendingClubsReject.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get pendingClubsReject;

  /// No description provided for @pendingClubsApprovedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt CLB'**
  String get pendingClubsApprovedFeedback;

  /// No description provided for @pendingClubsApproveError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể duyệt CLB. Vui lòng thử lại.'**
  String get pendingClubsApproveError;

  /// No description provided for @pendingClubsRejectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối CLB'**
  String get pendingClubsRejectTitle;

  /// No description provided for @pendingClubsRejectQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối \"{name}\"?'**
  String pendingClubsRejectQuestion(Object name);

  /// No description provided for @pendingClubsRejectReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Lý do từ chối (bắt buộc)'**
  String get pendingClubsRejectReasonHint;

  /// No description provided for @pendingClubsCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get pendingClubsCancel;

  /// No description provided for @pendingClubsRejectedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối CLB'**
  String get pendingClubsRejectedFeedback;

  /// No description provided for @pendingClubsRejectError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể từ chối CLB. Vui lòng thử lại.'**
  String get pendingClubsRejectError;

  /// No description provided for @pendingClubsConfirmReject.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận từ chối'**
  String get pendingClubsConfirmReject;

  /// No description provided for @adminTransactionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử giao dịch'**
  String get adminTransactionsTitle;

  /// No description provided for @adminTransactionsFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminTransactionsFilterAll;

  /// No description provided for @adminTransactionsFilterCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get adminTransactionsFilterCompleted;

  /// No description provided for @adminTransactionsFilterPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get adminTransactionsFilterPending;

  /// No description provided for @adminTransactionsFilterFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get adminTransactionsFilterFailed;

  /// No description provided for @adminTransactionsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có giao dịch nào'**
  String get adminTransactionsEmpty;

  /// No description provided for @adminTransactionsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu'**
  String get adminTransactionsLoadError;

  /// No description provided for @adminTransactionsUserFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get adminTransactionsUserFallback;

  /// No description provided for @adminTransactionsStatusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get adminTransactionsStatusCompleted;

  /// No description provided for @adminTransactionsStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ xử lý'**
  String get adminTransactionsStatusPending;

  /// No description provided for @adminTransactionsStatusFailed.
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get adminTransactionsStatusFailed;

  /// No description provided for @adminTransactionsReference.
  ///
  /// In vi, this message translates to:
  /// **'Mã GD: {reference}'**
  String adminTransactionsReference(Object reference);

  /// No description provided for @adminVerificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực'**
  String get adminVerificationTitle;

  /// No description provided for @adminVerificationTypeAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminVerificationTypeAll;

  /// No description provided for @adminVerificationTypeUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get adminVerificationTypeUser;

  /// No description provided for @adminVerificationTypeClub.
  ///
  /// In vi, this message translates to:
  /// **'CLB'**
  String get adminVerificationTypeClub;

  /// No description provided for @adminVerificationTypeTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get adminVerificationTypeTournament;

  /// No description provided for @adminVerificationStatusAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get adminVerificationStatusAll;

  /// No description provided for @adminVerificationStatusPending.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get adminVerificationStatusPending;

  /// No description provided for @adminVerificationStatusVerified.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get adminVerificationStatusVerified;

  /// No description provided for @adminVerificationStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminVerificationStatusRejected;

  /// No description provided for @adminVerificationEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có yêu cầu xác thực'**
  String get adminVerificationEmpty;

  /// No description provided for @adminVerificationLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải dữ liệu'**
  String get adminVerificationLoadError;

  /// No description provided for @adminVerificationStatusVerifiedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get adminVerificationStatusVerifiedLabel;

  /// No description provided for @adminVerificationStatusRejectedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminVerificationStatusRejectedLabel;

  /// No description provided for @adminVerificationStatusPendingLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chờ duyệt'**
  String get adminVerificationStatusPendingLabel;

  /// No description provided for @adminVerificationApprove.
  ///
  /// In vi, this message translates to:
  /// **'Xác thực'**
  String get adminVerificationApprove;

  /// No description provided for @adminVerificationReject.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get adminVerificationReject;

  /// No description provided for @adminVerificationVerifiedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác thực'**
  String get adminVerificationVerifiedFeedback;

  /// No description provided for @adminVerificationActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý yêu cầu xác thực. Vui lòng thử lại.'**
  String get adminVerificationActionError;

  /// No description provided for @adminVerificationRejectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối xác thực'**
  String get adminVerificationRejectTitle;

  /// No description provided for @adminVerificationRejectReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Lý do từ chối (bắt buộc)'**
  String get adminVerificationRejectReasonHint;

  /// No description provided for @adminVerificationCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get adminVerificationCancel;

  /// No description provided for @adminVerificationRejectedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối xác thực'**
  String get adminVerificationRejectedFeedback;

  /// No description provided for @adminVerificationRejectError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể từ chối xác thực. Vui lòng thử lại.'**
  String get adminVerificationRejectError;

  /// No description provided for @chatViewReactions.
  ///
  /// In vi, this message translates to:
  /// **'Xem người bày tỏ cảm xúc'**
  String get chatViewReactions;

  /// No description provided for @chatReplyAction.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get chatReplyAction;

  /// No description provided for @chatCopyTextAction.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép văn bản'**
  String get chatCopyTextAction;

  /// No description provided for @chatCopiedFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép vào bộ nhớ tạm.'**
  String get chatCopiedFeedback;

  /// No description provided for @chatUnpinMessageAction.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ ghim tin nhắn'**
  String get chatUnpinMessageAction;

  /// No description provided for @chatPinMessageAction.
  ///
  /// In vi, this message translates to:
  /// **'Ghim tin nhắn'**
  String get chatPinMessageAction;

  /// No description provided for @chatRevokeMessageAction.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi tin nhắn'**
  String get chatRevokeMessageAction;

  /// No description provided for @clubDetailChatTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Trò chuyện CLB'**
  String get clubDetailChatTooltip;

  /// No description provided for @clubDetailShareTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get clubDetailShareTooltip;

  /// No description provided for @clubDetailNotificationsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo câu lạc bộ'**
  String get clubDetailNotificationsTitle;

  /// No description provided for @clubDetailNotificationsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh nhận tin nhắn và thông báo từ {clubName}'**
  String clubDetailNotificationsDescription(Object clubName);

  /// No description provided for @clubDetailNotificationsAllTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả tin nhắn'**
  String get clubDetailNotificationsAllTitle;

  /// No description provided for @clubDetailNotificationsAllSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo cho mọi tin nhắn mới (Mặc định)'**
  String get clubDetailNotificationsAllSubtitle;

  /// No description provided for @clubDetailNotificationsMentionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khi được @tag'**
  String get clubDetailNotificationsMentionsTitle;

  /// No description provided for @clubDetailNotificationsMentionsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thông báo khi có người nhắc tên bạn hoặc @all'**
  String get clubDetailNotificationsMentionsSubtitle;

  /// No description provided for @clubDetailNotificationsMutedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tắt thông báo (Im lặng)'**
  String get clubDetailNotificationsMutedTitle;

  /// No description provided for @clubDetailNotificationsMutedSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận thông báo đẩy từ câu lạc bộ này'**
  String get clubDetailNotificationsMutedSubtitle;

  /// No description provided for @clubDetailNotificationsUpdatedAll.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật nhận tất cả thông báo CLB'**
  String get clubDetailNotificationsUpdatedAll;

  /// No description provided for @clubDetailNotificationsUpdatedMentions.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận thông báo khi được @nhắc tên'**
  String get clubDetailNotificationsUpdatedMentions;

  /// No description provided for @clubDetailNotificationsUpdatedMuted.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo CLB (Im lặng)'**
  String get clubDetailNotificationsUpdatedMuted;

  /// No description provided for @clubDetailNotificationsUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật cài đặt thông báo.'**
  String get clubDetailNotificationsUpdateError;

  /// No description provided for @clubDetailManageTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị CLB'**
  String get clubDetailManageTooltip;

  /// No description provided for @clubDetailLeaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời câu lạc bộ?'**
  String get clubDetailLeaveTitle;

  /// No description provided for @clubDetailLeaveDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ không còn quyền truy cập các nội dung dành cho thành viên.'**
  String get clubDetailLeaveDescription;

  /// No description provided for @clubDetailLeaveAction.
  ///
  /// In vi, this message translates to:
  /// **'Rời CLB'**
  String get clubDetailLeaveAction;

  /// No description provided for @clubDetailLeftSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời câu lạc bộ'**
  String get clubDetailLeftSuccess;

  /// No description provided for @clubDetailLeaveError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể rời câu lạc bộ'**
  String get clubDetailLeaveError;

  /// No description provided for @clubDetailJoinQuestionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi tham gia CLB'**
  String get clubDetailJoinQuestionsTitle;

  /// No description provided for @clubDetailJoinQuestionsInstruction.
  ///
  /// In vi, this message translates to:
  /// **'Hãy trả lời các câu hỏi để gửi yêu cầu tham gia.'**
  String get clubDetailJoinQuestionsInstruction;

  /// No description provided for @clubDetailJoinQuestionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng trả lời câu hỏi này'**
  String get clubDetailJoinQuestionRequired;

  /// No description provided for @clubDetailSubmitJoinRequest.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu'**
  String get clubDetailSubmitJoinRequest;

  /// No description provided for @clubDetailJoinRequestError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi yêu cầu tham gia CLB. Vui lòng thử lại.'**
  String get clubDetailJoinRequestError;

  /// No description provided for @clubDetailJoinedSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia câu lạc bộ thành công!'**
  String get clubDetailJoinedSuccess;

  /// No description provided for @clubDetailOpenLinkError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở liên kết này.'**
  String get clubDetailOpenLinkError;

  /// No description provided for @clubDetailNoFilteredTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Không có giải phù hợp với bộ lọc'**
  String get clubDetailNoFilteredTournaments;

  /// No description provided for @clubDetailClearFilters.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bộ lọc'**
  String get clubDetailClearFilters;

  /// No description provided for @clubDetailQuickWebTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh trên Web'**
  String get clubDetailQuickWebTitle;

  /// No description provided for @clubDetailQuickWebDescription.
  ///
  /// In vi, this message translates to:
  /// **'Form nhanh đầy đủ hơn Lite; giải vẫn thuộc CLB.'**
  String get clubDetailQuickWebDescription;

  /// No description provided for @clubDetailMemberActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật thành viên. Vui lòng thử lại.'**
  String get clubDetailMemberActionError;

  /// No description provided for @clubDetailGalleryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ảnh ({count})'**
  String clubDetailGalleryTitle(Object count);

  /// No description provided for @clubDetailClubLogo.
  ///
  /// In vi, this message translates to:
  /// **'Logo CLB'**
  String get clubDetailClubLogo;

  /// No description provided for @clubDetailCoverImage.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get clubDetailCoverImage;

  /// No description provided for @clubDetailActivityImage.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh hoạt động'**
  String get clubDetailActivityImage;

  /// No description provided for @clubDetailAddFirstImage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh đầu tiên'**
  String get clubDetailAddFirstImage;

  /// No description provided for @clubDetailAddImage.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get clubDetailAddImage;

  /// No description provided for @clubDetailGalleryAdded.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm ảnh vào thư viện'**
  String get clubDetailGalleryAdded;

  /// No description provided for @clubDetailGalleryAddError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thêm ảnh vào thư viện'**
  String get clubDetailGalleryAddError;

  /// No description provided for @clubDetailDeleteImageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hình ảnh'**
  String get clubDetailDeleteImageTitle;

  /// No description provided for @clubDetailDeleteImageDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xoá ảnh này khỏi thư viện CLB?'**
  String get clubDetailDeleteImageDescription;

  /// No description provided for @clubDetailGalleryRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá ảnh khỏi thư viện'**
  String get clubDetailGalleryRemoved;

  /// No description provided for @clubDetailGalleryRemoveError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xoá ảnh'**
  String get clubDetailGalleryRemoveError;

  /// No description provided for @clubDetailDeleteAction.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get clubDetailDeleteAction;

  /// No description provided for @communitySocialSettingsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải cài đặt sinh hoạt CLB.'**
  String get communitySocialSettingsLoadError;

  /// No description provided for @communitySocialSettingsSaveSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu cài đặt sinh hoạt CLB'**
  String get communitySocialSettingsSaveSuccess;

  /// No description provided for @communitySocialSettingsSaveError.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cài đặt thất bại. Vui lòng thử lại.'**
  String get communitySocialSettingsSaveError;

  /// No description provided for @communitySocialSettingsCreateTagError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo tag.'**
  String get communitySocialSettingsCreateTagError;

  /// No description provided for @communitySocialSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sinh hoạt CLB'**
  String get communitySocialSettingsTitle;

  /// No description provided for @communitySocialSettingsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển bảng tin, bình luận, chat và tag thành viên.'**
  String get communitySocialSettingsDescription;

  /// No description provided for @communitySocialSettingsPostingPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền đăng bài'**
  String get communitySocialSettingsPostingPolicy;

  /// No description provided for @communitySocialSettingsTaggingPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Quyền gắn thẻ'**
  String get communitySocialSettingsTaggingPolicy;

  /// No description provided for @communitySocialSettingsMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get communitySocialSettingsMembers;

  /// No description provided for @communitySocialSettingsAdmins.
  ///
  /// In vi, this message translates to:
  /// **'Ban quản trị'**
  String get communitySocialSettingsAdmins;

  /// No description provided for @communitySocialSettingsPostingOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt đăng bài'**
  String get communitySocialSettingsPostingOff;

  /// No description provided for @communitySocialSettingsTaggingOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt gắn thẻ'**
  String get communitySocialSettingsTaggingOff;

  /// No description provided for @communitySocialSettingsApproval.
  ///
  /// In vi, this message translates to:
  /// **'Bài thành viên phải duyệt'**
  String get communitySocialSettingsApproval;

  /// No description provided for @communitySocialSettingsComments.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép bình luận'**
  String get communitySocialSettingsComments;

  /// No description provided for @communitySocialSettingsChat.
  ///
  /// In vi, this message translates to:
  /// **'Mở chat CLB'**
  String get communitySocialSettingsChat;

  /// No description provided for @communitySocialSettingsPublicFeed.
  ///
  /// In vi, this message translates to:
  /// **'Cho khách xem bảng tin'**
  String get communitySocialSettingsPublicFeed;

  /// No description provided for @communitySocialSettingsSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu cài đặt'**
  String get communitySocialSettingsSave;

  /// No description provided for @communitySocialSettingsSaving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get communitySocialSettingsSaving;

  /// No description provided for @communitySocialSettingsTagPresetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tag vui của CLB'**
  String get communitySocialSettingsTagPresetsTitle;

  /// No description provided for @communitySocialSettingsTagPresetsDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhãn màu để gán nhanh cho thành viên.'**
  String get communitySocialSettingsTagPresetsDescription;

  /// No description provided for @communitySocialSettingsTagNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: MVP tuần'**
  String get communitySocialSettingsTagNameHint;

  /// No description provided for @communitySocialSettingsColorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màu tag'**
  String get communitySocialSettingsColorTitle;

  /// No description provided for @communitySocialSettingsClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get communitySocialSettingsClose;

  /// No description provided for @coreAppTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản Lý Giải Đấu'**
  String get coreAppTitle;

  /// No description provided for @coreBackToHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get coreBackToHome;

  /// No description provided for @coreShareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get coreShareTitle;

  /// No description provided for @coreCopyLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link'**
  String get coreCopyLink;

  /// No description provided for @coreLinkCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết vào bộ nhớ tạm!'**
  String get coreLinkCopied;

  /// No description provided for @coreShareViaApp.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ qua App'**
  String get coreShareViaApp;

  /// No description provided for @coreQrCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR'**
  String get coreQrCode;

  /// No description provided for @coreQrCodeShareTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR Chia Sẻ'**
  String get coreQrCodeShareTitle;

  /// No description provided for @coreUpdateAvailable.
  ///
  /// In vi, this message translates to:
  /// **'Có phiên bản mới'**
  String get coreUpdateAvailable;

  /// No description provided for @coreUpdateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Sporto đã có phiên bản mới {latestVersion}. Cập nhật để nhận các cải tiến mới nhất.'**
  String coreUpdateDescription(Object latestVersion);

  /// No description provided for @coreUpdateLater.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get coreUpdateLater;

  /// No description provided for @coreUpdateNow.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngay'**
  String get coreUpdateNow;

  /// No description provided for @coreRegistrationOpening.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở đăng ký'**
  String get coreRegistrationOpening;

  /// No description provided for @coreCountdownDays.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String coreCountdownDays(Object days);

  /// No description provided for @coreCountdownTime.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày {clock}'**
  String coreCountdownTime(Object clock, Object days);

  /// No description provided for @coreCountdownClock.
  ///
  /// In vi, this message translates to:
  /// **'Còn {clock}'**
  String coreCountdownClock(Object clock);

  /// No description provided for @coreView.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get coreView;

  /// No description provided for @coreLive.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get coreLive;

  /// No description provided for @coreShareDetailsAt.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết tại: {url}'**
  String coreShareDetailsAt(Object url);

  /// No description provided for @settingsImageSizeLimit.
  ///
  /// In vi, this message translates to:
  /// **'Kích thước ảnh không được vượt quá 5MB'**
  String get settingsImageSizeLimit;

  /// No description provided for @settingsGenderChangeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu thay đổi giới tính'**
  String get settingsGenderChangeTitle;

  /// No description provided for @settingsGenderLockedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Vì bạn đã hoàn thành ít nhất một giải đấu, giới tính đã bị khóa để đảm bảo công bằng. Yêu cầu sẽ được gửi tới Admin để phê duyệt thủ công.'**
  String get settingsGenderLockedMessage;

  /// No description provided for @settingsDesiredGender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính mong muốn'**
  String get settingsDesiredGender;

  /// No description provided for @settingsRequestSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu. Vui lòng chờ Admin phê duyệt.'**
  String get settingsRequestSent;

  /// No description provided for @settingsRequestFailed.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu thất bại. Vui lòng thử lại.'**
  String get settingsRequestFailed;

  /// No description provided for @settingsSendRequest.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu'**
  String get settingsSendRequest;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu thay đổi'**
  String get settingsSaveChanges;

  /// No description provided for @settingsProfileUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật hồ sơ. Vui lòng thử lại.'**
  String get settingsProfileUpdateError;

  /// No description provided for @settingsProfileLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải hồ sơ'**
  String get settingsProfileLoadError;

  /// No description provided for @settingsFullNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập họ tên đầy đủ'**
  String get settingsFullNameHint;

  /// No description provided for @settingsFullNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ tên'**
  String get settingsFullNameRequired;

  /// No description provided for @settingsFullNameMin.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên phải có ít nhất 2 ký tự'**
  String get settingsFullNameMin;

  /// No description provided for @settingsFullNameMax.
  ///
  /// In vi, this message translates to:
  /// **'Họ tên tối đa 100 ký tự'**
  String get settingsFullNameMax;

  /// No description provided for @settingsPhoneInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ'**
  String get settingsPhoneInvalid;

  /// No description provided for @settingsCompetitionRegion.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực tranh tài'**
  String get settingsCompetitionRegion;

  /// No description provided for @settingsCompetitionRegionHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn khu vực để tham gia xếp hạng Tier S'**
  String get settingsCompetitionRegionHint;

  /// No description provided for @settingsDetailedAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ chi tiết'**
  String get settingsDetailedAddress;

  /// No description provided for @settingsDetailedAddressHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ cụ thể của bạn'**
  String get settingsDetailedAddressHint;

  /// No description provided for @settingsAddressMax.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ tối đa 255 ký tự'**
  String get settingsAddressMax;

  /// No description provided for @settingsAutoDetected.
  ///
  /// In vi, this message translates to:
  /// **'Đã tự nhận diện: {province}'**
  String settingsAutoDetected(Object province);

  /// No description provided for @settingsBio.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu bản thân'**
  String get settingsBio;

  /// No description provided for @settingsBioHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết một chút về phong cách chơi của bạn...'**
  String get settingsBioHint;

  /// No description provided for @settingsBioMax.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu tối đa 500 ký tự'**
  String get settingsBioMax;

  /// No description provided for @settingsUploading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get settingsUploading;

  /// No description provided for @settingsChangeCover.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi ảnh bìa'**
  String get settingsChangeCover;

  /// No description provided for @settingsTapToChangeAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để đổi ảnh đại diện'**
  String get settingsTapToChangeAvatar;

  /// No description provided for @settingsChooseDateOfBirth.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày sinh'**
  String get settingsChooseDateOfBirth;

  /// No description provided for @settingsGenderLocked.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính đã bị khóa sau khi giải đấu hoàn thành.'**
  String get settingsGenderLocked;

  /// No description provided for @settingsRequestGenderChange.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu đổi'**
  String get settingsRequestGenderChange;

  /// No description provided for @settingsNoTierSRegion.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn (Không tranh hạng Tier S)'**
  String get settingsNoTierSRegion;

  /// No description provided for @commonCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy bỏ'**
  String get commonCancel;

  /// No description provided for @settingsBankLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin ngân hàng'**
  String get settingsBankLoadError;

  /// No description provided for @settingsRefundSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu cấu hình hoàn tiền'**
  String get settingsRefundSaved;

  /// No description provided for @settingsBankUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu thông tin ngân hàng. Vui lòng thử lại.'**
  String get settingsBankUpdateError;

  /// No description provided for @settingsPayoutMethod.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng / Ví nhận tiền'**
  String get settingsPayoutMethod;

  /// No description provided for @settingsNoBank.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn ngân hàng/ví'**
  String get settingsNoBank;

  /// No description provided for @settingsWalletPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Ví điện tử {wallet}'**
  String settingsWalletPrefix(Object wallet);

  /// No description provided for @settingsWalletPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại ví'**
  String get settingsWalletPhone;

  /// No description provided for @settingsAccountNumber.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get settingsAccountNumber;

  /// No description provided for @settingsWalletNumberHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 0912345678'**
  String get settingsWalletNumberHint;

  /// No description provided for @settingsBankNumberHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: 0011001234567'**
  String get settingsBankNumberHint;

  /// No description provided for @settingsAccountHolder.
  ///
  /// In vi, this message translates to:
  /// **'Tên chủ tài khoản / ví (Viết hoa không dấu)'**
  String get settingsAccountHolder;

  /// No description provided for @settingsAccountHolderHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: NGUYEN VAN A'**
  String get settingsAccountHolderHint;

  /// No description provided for @settingsRefundInfo.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình tài khoản nhận hoàn tiền chính xác để BTC gửi lại lệ phí giải khi bạn rút khỏi giải trước khi giải khởi tranh. Dữ liệu được bảo mật.'**
  String get settingsRefundInfo;

  /// No description provided for @settingsVerificationStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái xác thực'**
  String get settingsVerificationStatus;

  /// No description provided for @settingsPhoneNotUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật số điện thoại'**
  String get settingsPhoneNotUpdated;

  /// No description provided for @settingsVerifyEmail.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh Email'**
  String get settingsVerifyEmail;

  /// No description provided for @settingsVerifyEmailSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã xác minh tới email đang dùng'**
  String get settingsVerifyEmailSubtitle;

  /// No description provided for @settingsVerifyPhone.
  ///
  /// In vi, this message translates to:
  /// **'Xác minh số điện thoại'**
  String get settingsVerifyPhone;

  /// No description provided for @settingsVerifyPhoneSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã OTP tới số điện thoại đang dùng'**
  String get settingsVerifyPhoneSubtitle;

  /// No description provided for @settingsStatusLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải trạng thái'**
  String get settingsStatusLoadError;

  /// No description provided for @settingsPasswordSection.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get settingsPasswordSection;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật mật khẩu đăng nhập'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @settingsStrongPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mạnh'**
  String get settingsStrongPassword;

  /// No description provided for @settingsStrongPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu 8 ký tự, nên có chữ hoa và số'**
  String get settingsStrongPasswordSubtitle;

  /// No description provided for @settingsSessions.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập'**
  String get settingsSessions;

  /// No description provided for @settingsCurrentDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị hiện tại'**
  String get settingsCurrentDevice;

  /// No description provided for @settingsActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get settingsActive;

  /// No description provided for @settingsOnline.
  ///
  /// In vi, this message translates to:
  /// **'Online'**
  String get settingsOnline;

  /// No description provided for @settingsCommunitySafety.
  ///
  /// In vi, this message translates to:
  /// **'An toàn cộng đồng'**
  String get settingsCommunitySafety;

  /// No description provided for @settingsMyReports.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo của tôi'**
  String get settingsMyReports;

  /// No description provided for @settingsMyReportsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi trạng thái và kết quả xử lý báo cáo'**
  String get settingsMyReportsSubtitle;

  /// No description provided for @settingsDangerZone.
  ///
  /// In vi, this message translates to:
  /// **'Vùng nguy hiểm'**
  String get settingsDangerZone;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản cá nhân'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountDescription.
  ///
  /// In vi, this message translates to:
  /// **'Khi thực hiện xóa tài khoản, tất cả dữ liệu cá nhân, hồ sơ thi đấu và thông tin liên quan sẽ bị ẩn vĩnh viễn. Bạn không thể đăng nhập hoặc tham gia giải đấu nào sau hành động này.'**
  String get settingsDeleteAccountDescription;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsConfirmDeleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa tài khoản'**
  String get settingsConfirmDeleteTitle;

  /// No description provided for @settingsDeleteIrreversible.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này KHÔNG THỂ HOÀN TÁC. Tất cả dữ liệu cá nhân, hồ sơ thi đấu sẽ bị ẩn vĩnh viễn. Nhập mật khẩu hiện tại để tiếp tục.'**
  String get settingsDeleteIrreversible;

  /// No description provided for @settingsConfirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận'**
  String get settingsConfirmPassword;

  /// No description provided for @settingsConfirmDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get settingsConfirmDelete;

  /// No description provided for @settingsPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mật khẩu xác nhận'**
  String get settingsPasswordRequired;

  /// No description provided for @settingsDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản thất bại. Vui lòng thử lại.'**
  String get settingsDeleteFailed;

  /// No description provided for @settingsGenderNotSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get settingsGenderNotSelected;

  /// No description provided for @settingsGenderMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get settingsGenderMale;

  /// No description provided for @settingsGenderFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get settingsGenderFemale;

  /// No description provided for @settingsGenderOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get settingsGenderOther;

  /// No description provided for @settingsDobDisplay.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {day}/{month}/{year}'**
  String settingsDobDisplay(Object day, Object month, Object year);

  /// No description provided for @settingsClubNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo Câu lạc bộ'**
  String get settingsClubNotifications;

  /// No description provided for @settingsNoClubsForNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tham gia câu lạc bộ nào'**
  String get settingsNoClubsForNotifications;

  /// No description provided for @settingsClubNotificationsHint.
  ///
  /// In vi, this message translates to:
  /// **'Khi gia nhập CLB, bạn có thể tùy chỉnh nhận thông báo tại đây.'**
  String get settingsClubNotificationsHint;

  /// No description provided for @settingsNotificationsAllUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật nhận tất cả thông báo'**
  String get settingsNotificationsAllUpdated;

  /// No description provided for @settingsNotificationsMentionsUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận thông báo khi được @nhắc tên'**
  String get settingsNotificationsMentionsUpdated;

  /// No description provided for @settingsNotificationsMutedUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo CLB (Im lặng)'**
  String get settingsNotificationsMutedUpdated;

  /// No description provided for @settingsNotificationsUpdateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật cài đặt thông báo'**
  String get settingsNotificationsUpdateFailed;

  /// No description provided for @settingsClubNotificationAllSummary.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tất cả tin nhắn & thông báo'**
  String get settingsClubNotificationAllSummary;

  /// No description provided for @settingsClubNotificationMentionsSummary.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận thông báo khi được @nhắc tên'**
  String get settingsClubNotificationMentionsSummary;

  /// No description provided for @settingsClubNotificationMutedSummary.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo (Im lặng)'**
  String get settingsClubNotificationMutedSummary;

  /// No description provided for @settingsNotificationAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get settingsNotificationAll;

  /// No description provided for @settingsNotificationMentions.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ @tag'**
  String get settingsNotificationMentions;

  /// No description provided for @settingsNotificationMuted.
  ///
  /// In vi, this message translates to:
  /// **'Tắt'**
  String get settingsNotificationMuted;

  /// No description provided for @settingsSaveButton.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get settingsSaveButton;

  /// No description provided for @profileVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}{build}'**
  String profileVersion(Object build, Object version);

  /// No description provided for @profileNotRanked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp hạng'**
  String get profileNotRanked;

  /// No description provided for @profileRankStatus.
  ///
  /// In vi, this message translates to:
  /// **'TRẠNG THÁI'**
  String get profileRankStatus;

  /// No description provided for @profileRankLabel.
  ///
  /// In vi, this message translates to:
  /// **'RANK'**
  String get profileRankLabel;

  /// No description provided for @profileNoRank.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có rank'**
  String get profileNoRank;

  /// No description provided for @profileEloProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến tới {nextLabel} ({percent}%)'**
  String profileEloProgress(Object nextLabel, Object percent);

  /// No description provided for @profileMatches.
  ///
  /// In vi, this message translates to:
  /// **'trận'**
  String get profileMatches;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get profilePhoneLabel;

  /// No description provided for @profileDobLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngày sinh'**
  String get profileDobLabel;

  /// No description provided for @profileGenderLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get profileGenderLabel;

  /// No description provided for @profileAddressLabel.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ'**
  String get profileAddressLabel;

  /// No description provided for @profileProvinceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/Thành phố'**
  String get profileProvinceLabel;

  /// No description provided for @profileEmailStatusLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái email'**
  String get profileEmailStatusLabel;

  /// No description provided for @profileEmailVerifiedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được xác thực và sẵn sàng cho các chức năng bảo mật.'**
  String get profileEmailVerifiedDescription;

  /// No description provided for @profileEmailUnverifiedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa xác thực, nên xác minh để hoàn tất bảo mật tài khoản.'**
  String get profileEmailUnverifiedDescription;

  /// No description provided for @profilePhoneVerifiedLabel.
  ///
  /// In vi, this message translates to:
  /// **'SĐT xác thực'**
  String get profilePhoneVerifiedLabel;

  /// No description provided for @profileBankLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get profileBankLabel;

  /// No description provided for @profileBankAccountLabel.
  ///
  /// In vi, this message translates to:
  /// **'STK'**
  String get profileBankAccountLabel;

  /// No description provided for @profileOwnerTournamentRole.
  ///
  /// In vi, this message translates to:
  /// **'Chủ giải'**
  String get profileOwnerTournamentRole;

  /// No description provided for @profileOrganizerTournamentRole.
  ///
  /// In vi, this message translates to:
  /// **'Ban tổ chức'**
  String get profileOrganizerTournamentRole;

  /// No description provided for @profileRefereeTournamentRole.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tài'**
  String get profileRefereeTournamentRole;

  /// No description provided for @profilePlayerTournamentRole.
  ///
  /// In vi, this message translates to:
  /// **'Người chơi'**
  String get profilePlayerTournamentRole;

  /// No description provided for @profileNoManagedTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo hoặc tham gia giải nào.'**
  String get profileNoManagedTournaments;

  /// No description provided for @profileViewDashboard.
  ///
  /// In vi, this message translates to:
  /// **'Xem Dashboard'**
  String get profileViewDashboard;

  /// No description provided for @profileViewAllCount.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả ({count})'**
  String profileViewAllCount(Object count);

  /// No description provided for @profileTournamentLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu'**
  String get profileTournamentLoadError;

  /// No description provided for @profileNoClubs.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo hoặc tham gia câu lạc bộ nào.'**
  String get profileNoClubs;

  /// No description provided for @profileCreateClub.
  ///
  /// In vi, this message translates to:
  /// **'Tạo CLB mới'**
  String get profileCreateClub;

  /// No description provided for @profileClubLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách CLB'**
  String get profileClubLoadError;

  /// No description provided for @profileOwnerRole.
  ///
  /// In vi, this message translates to:
  /// **'Chủ sở hữu'**
  String get profileOwnerRole;

  /// No description provided for @profileAdminRole.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị'**
  String get profileAdminRole;

  /// No description provided for @profileMemberRole.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia'**
  String get profileMemberRole;

  /// No description provided for @profileDefaultSport.
  ///
  /// In vi, this message translates to:
  /// **'THỂ THAO'**
  String get profileDefaultSport;

  /// No description provided for @profileMembers.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get profileMembers;

  /// No description provided for @profileRecentCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Vừa kết thúc'**
  String get profileRecentCompleted;

  /// No description provided for @profileInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get profileInProgress;

  /// No description provided for @profileRegistrationOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở đăng ký'**
  String get profileRegistrationOpen;

  /// No description provided for @profileUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get profileUpcoming;

  /// No description provided for @profileNoFollowedTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa theo dõi giải nào.'**
  String get profileNoFollowedTournaments;

  /// No description provided for @profileNoMatchingTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Không có giải đấu phù hợp với bộ lọc.'**
  String get profileNoMatchingTournaments;

  /// No description provided for @profileFollowedLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách theo dõi'**
  String get profileFollowedLoadError;

  /// No description provided for @profileRecentlyCompletedHint.
  ///
  /// In vi, this message translates to:
  /// **'Vừa kết thúc trong 14 ngày gần đây'**
  String get profileRecentlyCompletedHint;

  /// No description provided for @profileCompletedHint.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get profileCompletedHint;

  /// No description provided for @profileInProgressHint.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get profileInProgressHint;

  /// No description provided for @profileRegistrationHint.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở đăng ký'**
  String get profileRegistrationHint;

  /// No description provided for @profileUpcomingHint.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get profileUpcomingHint;

  /// No description provided for @profileFollowingHint.
  ///
  /// In vi, this message translates to:
  /// **'Đang theo dõi'**
  String get profileFollowingHint;

  /// No description provided for @profileNoName.
  ///
  /// In vi, this message translates to:
  /// **'(Chưa có tên)'**
  String get profileNoName;

  /// No description provided for @profileLiteTournamentHint.
  ///
  /// In vi, this message translates to:
  /// **'Giải nhanh (Lite) • Quản lý trên app'**
  String get profileLiteTournamentHint;

  /// No description provided for @profileAdvancedTournamentHint.
  ///
  /// In vi, this message translates to:
  /// **'Giải nâng cao • Quản lý đầy đủ'**
  String get profileAdvancedTournamentHint;

  /// No description provided for @profileDeleteTournamentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa giải đấu?'**
  String get profileDeleteTournamentTitle;

  /// No description provided for @profileDeleteTournamentContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa \"{name}\"?'**
  String profileDeleteTournamentContent(Object name);

  /// No description provided for @profileCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get profileCancel;

  /// No description provided for @profileTournamentDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa giải đấu'**
  String get profileTournamentDeleted;

  /// No description provided for @profileTournamentDeleteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa giải đấu'**
  String get profileTournamentDeleteFailed;

  /// No description provided for @profileAdvancedManagementTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải Nâng Cao'**
  String get profileAdvancedManagementTitle;

  /// No description provided for @profileAdvancedManagementContent.
  ///
  /// In vi, this message translates to:
  /// **'App hiện chỉ hỗ trợ quản lý giải nhanh (Lite). Giải Nâng Cao vui lòng quản lý trên web.'**
  String get profileAdvancedManagementContent;

  /// No description provided for @profileUnderstood.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get profileUnderstood;

  /// No description provided for @profileLoadErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin'**
  String get profileLoadErrorTitle;

  /// No description provided for @profileUnknownUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get profileUnknownUser;

  /// No description provided for @liveCheerFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể gửi cổ vũ. Vui lòng thử lại.'**
  String get liveCheerFailed;

  /// No description provided for @liveCommentFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi bình luận. Vui lòng thử lại!'**
  String get liveCommentFailed;

  /// No description provided for @livePenaltyRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận {option}.'**
  String livePenaltyRecorded(Object option);

  /// No description provided for @livePenaltyRecordedFor.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận {option} cho {team}.'**
  String livePenaltyRecordedFor(Object option, Object team);

  /// No description provided for @liveFoulSelectTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội nào bị phạt?'**
  String get liveFoulSelectTeam;

  /// No description provided for @liveForceWinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xử thắng nhanh'**
  String get liveForceWinTitle;

  /// No description provided for @liveForceWinContent.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xử thắng cho một đội (đối thủ bỏ cuộc hoặc phạm quy)?'**
  String get liveForceWinContent;

  /// No description provided for @liveCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get liveCancel;

  /// No description provided for @liveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get liveConfirm;

  /// No description provided for @liveMatchTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trực tiếp'**
  String get liveMatchTitle;

  /// No description provided for @liveMatchDetailsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi Tiết Trận Đấu'**
  String get liveMatchDetailsTitle;

  /// No description provided for @liveRefereeDeskTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bàn Trọng Tài'**
  String get liveRefereeDeskTitle;

  /// No description provided for @liveMatchNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trận đấu'**
  String get liveMatchNotFound;

  /// No description provided for @liveMatchLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu trận đấu.'**
  String get liveMatchLoadError;

  /// No description provided for @liveBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get liveBack;

  /// No description provided for @liveMatchInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin trận đấu'**
  String get liveMatchInfo;

  /// No description provided for @liveAppliedRules.
  ///
  /// In vi, this message translates to:
  /// **'Luật giải đang áp dụng'**
  String get liveAppliedRules;

  /// No description provided for @liveAppliedRulesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Các thông số được lấy từ cấu hình của ban tổ chức. App chỉ mở bảng chấm điểm theo luật này.'**
  String get liveAppliedRulesDescription;

  /// No description provided for @liveSportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn'**
  String get liveSportLabel;

  /// No description provided for @liveFormatLabel.
  ///
  /// In vi, this message translates to:
  /// **'Format'**
  String get liveFormatLabel;

  /// No description provided for @liveWinLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get liveWinLabel;

  /// No description provided for @liveSetTargetLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mốc set'**
  String get liveSetTargetLabel;

  /// No description provided for @liveRuleLabel.
  ///
  /// In vi, this message translates to:
  /// **'Luật'**
  String get liveRuleLabel;

  /// No description provided for @liveScoringLabel.
  ///
  /// In vi, this message translates to:
  /// **'Scoring'**
  String get liveScoringLabel;

  /// No description provided for @liveTiebreakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiebreak'**
  String get liveTiebreakLabel;

  /// No description provided for @livePointsValue.
  ///
  /// In vi, this message translates to:
  /// **'{value} điểm'**
  String livePointsValue(Object value);

  /// No description provided for @liveGamesValue.
  ///
  /// In vi, this message translates to:
  /// **'{value} game'**
  String liveGamesValue(Object value);

  /// No description provided for @liveSetValue.
  ///
  /// In vi, this message translates to:
  /// **'{value} set'**
  String liveSetValue(Object value);

  /// No description provided for @liveDifferenceTwo.
  ///
  /// In vi, this message translates to:
  /// **'Cách biệt 2'**
  String get liveDifferenceTwo;

  /// No description provided for @liveNoDifferenceTwo.
  ///
  /// In vi, this message translates to:
  /// **'Không cách biệt 2'**
  String get liveNoDifferenceTwo;

  /// No description provided for @liveMatchConfiguration.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình Trận đấu'**
  String get liveMatchConfiguration;

  /// No description provided for @liveTournamentConfiguration.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình giải đang áp dụng'**
  String get liveTournamentConfiguration;

  /// No description provided for @liveTournamentConfigurationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Màn setup đang lấy mặc định từ cấu hình giải đấu. Bạn có thể chỉnh ở cấp trận nếu cần.'**
  String get liveTournamentConfigurationDescription;

  /// No description provided for @liveDefaultConfigurationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giải chưa có sportRules chi tiết, hệ thống đang dùng cấu hình mặc định theo môn.'**
  String get liveDefaultConfigurationDescription;

  /// No description provided for @liveScoreTargetTennis.
  ///
  /// In vi, this message translates to:
  /// **'Số game để chạm mốc set (mặc định {value})'**
  String liveScoreTargetTennis(Object value);

  /// No description provided for @liveScoreTargetSideOut.
  ///
  /// In vi, this message translates to:
  /// **'Mốc điểm game side-out (mặc định {value})'**
  String liveScoreTargetSideOut(Object value);

  /// No description provided for @liveScoreTargetSet.
  ///
  /// In vi, this message translates to:
  /// **'Mốc điểm mỗi set (mặc định {value})'**
  String liveScoreTargetSet(Object value);

  /// No description provided for @liveTimeLimitLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giới hạn thời gian (phút, tuỳ chọn)'**
  String get liveTimeLimitLabel;

  /// No description provided for @liveTimeLimitHelper.
  ///
  /// In vi, this message translates to:
  /// **'Nếu để trống, trận sẽ không giới hạn thời gian ở cấp trận.'**
  String get liveTimeLimitHelper;

  /// No description provided for @liveWinByTwoSetting.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng luật cách biệt 2 {unit}'**
  String liveWinByTwoSetting(Object unit);

  /// No description provided for @liveStartMatch.
  ///
  /// In vi, this message translates to:
  /// **'BẮT ĐẦU TRẬN ĐẤU'**
  String get liveStartMatch;

  /// No description provided for @liveStartShort.
  ///
  /// In vi, this message translates to:
  /// **'BẮT ĐẦU'**
  String get liveStartShort;

  /// No description provided for @liveOpenScoreboard.
  ///
  /// In vi, this message translates to:
  /// **'MỞ BẢNG CHẤM ĐIỂM'**
  String get liveOpenScoreboard;

  /// No description provided for @liveOpenScoreboardShort.
  ///
  /// In vi, this message translates to:
  /// **'MỞ BẢNG'**
  String get liveOpenScoreboardShort;

  /// No description provided for @liveRefereeNotStarted.
  ///
  /// In vi, this message translates to:
  /// **'BÀN TRỌNG TÀI - CHƯA BẮT ĐẦU'**
  String get liveRefereeNotStarted;

  /// No description provided for @liveRefereeInProgress.
  ///
  /// In vi, this message translates to:
  /// **'BÀN TRỌNG TÀI - ĐANG THI ĐẤU'**
  String get liveRefereeInProgress;

  /// No description provided for @liveStartAndScoreHint.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút để bắt đầu & chấm điểm'**
  String get liveStartAndScoreHint;

  /// No description provided for @liveOpenScoreboardHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở bàn chấm điểm để ghi nhận tỉ số'**
  String get liveOpenScoreboardHint;

  /// No description provided for @liveStartMatchHint.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút để bắt đầu trận đấu'**
  String get liveStartMatchHint;

  /// No description provided for @liveScoreAndPenaltyHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở bàn chấm điểm & thẻ phạt'**
  String get liveScoreAndPenaltyHint;

  /// No description provided for @liveMaxScore.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa: {value}'**
  String liveMaxScore(Object value);

  /// No description provided for @liveEndMatch.
  ///
  /// In vi, this message translates to:
  /// **'KẾT THÚC'**
  String get liveEndMatch;

  /// No description provided for @liveWhistle.
  ///
  /// In vi, this message translates to:
  /// **'THỔI CÒI'**
  String get liveWhistle;

  /// No description provided for @liveConfirmEndTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận kết thúc trận đấu'**
  String get liveConfirmEndTitle;

  /// No description provided for @liveConfirmEndContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn kết thúc trận đấu này và chốt kết quả tỉ số?'**
  String get liveConfirmEndContent;

  /// No description provided for @liveUpdateScoreFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật điểm trận đấu. Vui lòng thử lại.'**
  String get liveUpdateScoreFailed;

  /// No description provided for @liveLiveBadge.
  ///
  /// In vi, this message translates to:
  /// **'LIVE'**
  String get liveLiveBadge;

  /// No description provided for @liveScheduledStatus.
  ///
  /// In vi, this message translates to:
  /// **'SẮP ĐẤU'**
  String get liveScheduledStatus;

  /// No description provided for @liveCameraLabel.
  ///
  /// In vi, this message translates to:
  /// **'CAM 1 (SÂN CHÍNH)'**
  String get liveCameraLabel;

  /// No description provided for @liveViewerCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} đang xem'**
  String liveViewerCount(Object count);

  /// No description provided for @liveScoreTab.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ số & Diễn biến'**
  String get liveScoreTab;

  /// No description provided for @liveDiscussionTab.
  ///
  /// In vi, this message translates to:
  /// **'Phòng thảo luận'**
  String get liveDiscussionTab;

  /// No description provided for @liveSinglesElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO Đơn'**
  String get liveSinglesElo;

  /// No description provided for @liveDoublesElo.
  ///
  /// In vi, this message translates to:
  /// **'ELO Đôi'**
  String get liveDoublesElo;

  /// No description provided for @liveNoElo.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có'**
  String get liveNoElo;

  /// No description provided for @liveAthleteOne.
  ///
  /// In vi, this message translates to:
  /// **'VĐV 1'**
  String get liveAthleteOne;

  /// No description provided for @liveAthleteTwo.
  ///
  /// In vi, this message translates to:
  /// **'VĐV 2'**
  String get liveAthleteTwo;

  /// No description provided for @livePenaltyLogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phạt và thẻ'**
  String get livePenaltyLogTitle;

  /// No description provided for @livePenaltyCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} ghi nhận'**
  String livePenaltyCount(Object count);

  /// No description provided for @liveMatchFallback.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu'**
  String get liveMatchFallback;

  /// No description provided for @liveSetWins.
  ///
  /// In vi, this message translates to:
  /// **'SET THẮNG: {value}'**
  String liveSetWins(Object value);

  /// No description provided for @liveSetScoresTitle.
  ///
  /// In vi, this message translates to:
  /// **'TỈ SỐ CÁC SET'**
  String get liveSetScoresTitle;

  /// No description provided for @liveMatchDetails.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin trận đấu chi tiết'**
  String get liveMatchDetails;

  /// No description provided for @liveTournamentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu'**
  String get liveTournamentLabel;

  /// No description provided for @liveDefaultTournament.
  ///
  /// In vi, this message translates to:
  /// **'Giải Vô Địch Mùa Hè'**
  String get liveDefaultTournament;

  /// No description provided for @liveRefereeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trọng tài chính'**
  String get liveRefereeLabel;

  /// No description provided for @liveUnknownValue.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get liveUnknownValue;

  /// No description provided for @liveScheduledTimeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian xếp lịch'**
  String get liveScheduledTimeLabel;

  /// No description provided for @liveNotScheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xếp lịch'**
  String get liveNotScheduled;

  /// No description provided for @liveSummaryTennis.
  ///
  /// In vi, this message translates to:
  /// **'BO{bestOf} • {value} game/set'**
  String liveSummaryTennis(Object bestOf, Object value);

  /// No description provided for @liveSummarySideOut.
  ///
  /// In vi, this message translates to:
  /// **'BO{bestOf} • side-out • chạm {value}'**
  String liveSummarySideOut(Object bestOf, Object value);

  /// No description provided for @liveSummaryRally.
  ///
  /// In vi, this message translates to:
  /// **'BO{bestOf} • {value} điểm/set'**
  String liveSummaryRally(Object bestOf, Object value);

  /// No description provided for @liveModelGame.
  ///
  /// In vi, this message translates to:
  /// **'Game'**
  String get liveModelGame;

  /// No description provided for @liveModelSideOut.
  ///
  /// In vi, this message translates to:
  /// **'Side-out'**
  String get liveModelSideOut;

  /// No description provided for @liveModelRally.
  ///
  /// In vi, this message translates to:
  /// **'Rally'**
  String get liveModelRally;

  /// No description provided for @liveCurrentSetFinished.
  ///
  /// In vi, this message translates to:
  /// **'KẾT THÚC'**
  String get liveCurrentSetFinished;

  /// No description provided for @liveCurrentSet.
  ///
  /// In vi, this message translates to:
  /// **'Set {value}'**
  String liveCurrentSet(Object value);

  /// No description provided for @liveCurrentRound.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp {value}'**
  String liveCurrentRound(Object value);

  /// No description provided for @liveEmptyDiscussion.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thảo luận'**
  String get liveEmptyDiscussion;

  /// No description provided for @liveEmptyDiscussionHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy là người đầu tiên chia sẻ cảm nghĩ!'**
  String get liveEmptyDiscussionHint;

  /// No description provided for @liveViewerPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Người xem'**
  String get liveViewerPlaceholder;

  /// No description provided for @liveCommentHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập bình luận...'**
  String get liveCommentHint;

  /// No description provided for @liveLoginToComment.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để bình luận'**
  String get liveLoginToComment;

  /// No description provided for @liveLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get liveLogin;

  /// No description provided for @liveCourtDefault.
  ///
  /// In vi, this message translates to:
  /// **'Sân trung tâm'**
  String get liveCourtDefault;

  /// No description provided for @liveDoublesEloValue.
  ///
  /// In vi, this message translates to:
  /// **'ELO đôi: {value}'**
  String liveDoublesEloValue(Object value);

  /// No description provided for @livePenaltyYellowCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ vàng'**
  String get livePenaltyYellowCard;

  /// No description provided for @livePenaltyRedCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ đỏ'**
  String get livePenaltyRedCard;

  /// No description provided for @livePenaltyPoint.
  ///
  /// In vi, this message translates to:
  /// **'Phạt điểm'**
  String get livePenaltyPoint;

  /// No description provided for @livePenaltyGame.
  ///
  /// In vi, this message translates to:
  /// **'Phạt game'**
  String get livePenaltyGame;

  /// No description provided for @livePenaltyServiceFault.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi giao bóng'**
  String get livePenaltyServiceFault;

  /// No description provided for @livePenaltyMisconduct.
  ///
  /// In vi, this message translates to:
  /// **'Hành vi không đúng mực'**
  String get livePenaltyMisconduct;

  /// No description provided for @livePenaltyWarning.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get livePenaltyWarning;

  /// No description provided for @clubDetailRulesTitle.
  ///
  /// In vi, this message translates to:
  /// **'NỘI QUY CÂU LẠC BỘ'**
  String get clubDetailRulesTitle;

  /// No description provided for @clubDetailContactTitle.
  ///
  /// In vi, this message translates to:
  /// **'LIÊN HỆ'**
  String get clubDetailContactTitle;

  /// No description provided for @clubDetailOtherSport.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get clubDetailOtherSport;

  /// No description provided for @clubDetailFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lọc giải đấu'**
  String get clubDetailFilterTitle;

  /// No description provided for @clubDetailAllTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả giải'**
  String get clubDetailAllTournaments;

  /// No description provided for @clubDetailClubTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Nội bộ CLB'**
  String get clubDetailClubTournaments;

  /// No description provided for @clubDetailOpenTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Mở rộng'**
  String get clubDetailOpenTournaments;

  /// No description provided for @clubDetailAllStatuses.
  ///
  /// In vi, this message translates to:
  /// **'Mọi trạng thái'**
  String get clubDetailAllStatuses;

  /// No description provided for @clubDetailUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get clubDetailUpcoming;

  /// No description provided for @clubDetailOngoing.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get clubDetailOngoing;

  /// No description provided for @clubDetailCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get clubDetailCompleted;

  /// No description provided for @clubDetailAllSports.
  ///
  /// In vi, this message translates to:
  /// **'Mọi môn'**
  String get clubDetailAllSports;

  /// No description provided for @clubDetailManageTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý giải'**
  String get clubDetailManageTournaments;

  /// No description provided for @clubDetailClubTournamentBadge.
  ///
  /// In vi, this message translates to:
  /// **'Nội bộ CLB'**
  String get clubDetailClubTournamentBadge;

  /// No description provided for @clubDetailOpenTournamentBadge.
  ///
  /// In vi, this message translates to:
  /// **'Mở rộng'**
  String get clubDetailOpenTournamentBadge;

  /// No description provided for @clubDetailRankedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng ELO'**
  String get clubDetailRankedBadge;

  /// No description provided for @clubDetailCasualBadge.
  ///
  /// In vi, this message translates to:
  /// **'Phong trào'**
  String get clubDetailCasualBadge;

  /// No description provided for @clubDetailSeriesBadge.
  ///
  /// In vi, this message translates to:
  /// **'Chuỗi giải'**
  String get clubDetailSeriesBadge;

  /// No description provided for @clubDetailLiteBadge.
  ///
  /// In vi, this message translates to:
  /// **'Nhanh (Lite)'**
  String get clubDetailLiteBadge;

  /// No description provided for @clubDetailSocialSettings.
  ///
  /// In vi, this message translates to:
  /// **'Sinh hoạt CLB'**
  String get clubDetailSocialSettings;

  /// No description provided for @clubDetailSocialSettingsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt bảng tin, bình luận, chat và tag thành viên'**
  String get clubDetailSocialSettingsSubtitle;

  /// No description provided for @clubDetailQuickStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái nhanh'**
  String get clubDetailQuickStatus;

  /// No description provided for @clubDetailStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get clubDetailStatus;

  /// No description provided for @clubDetailActiveStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get clubDetailActiveStatus;

  /// No description provided for @clubDetailVisibility.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ hiển thị'**
  String get clubDetailVisibility;

  /// No description provided for @clubDetailRestrictedVisibility.
  ///
  /// In vi, this message translates to:
  /// **'Hạn chế'**
  String get clubDetailRestrictedVisibility;

  /// No description provided for @clubDetailPrivateVisibility.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get clubDetailPrivateVisibility;

  /// No description provided for @clubDetailInternalChat.
  ///
  /// In vi, this message translates to:
  /// **'Phòng chat nội bộ'**
  String get clubDetailInternalChat;

  /// No description provided for @clubDetailChatOpen.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở'**
  String get clubDetailChatOpen;

  /// No description provided for @clubDetailChatClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get clubDetailChatClosed;

  /// No description provided for @clubDetailDeleteNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập chính xác tên CLB để xác nhận:'**
  String get clubDetailDeleteNameHint;

  /// No description provided for @clubDetailCurrentClubName.
  ///
  /// In vi, this message translates to:
  /// **'Tên CLB hiện tại'**
  String get clubDetailCurrentClubName;

  /// No description provided for @clubDetailFeedTab.
  ///
  /// In vi, this message translates to:
  /// **'Bảng tin'**
  String get clubDetailFeedTab;

  /// No description provided for @homeClubTab.
  ///
  /// In vi, this message translates to:
  /// **'Câu lạc bộ'**
  String get homeClubTab;

  /// No description provided for @homeRankingsTab.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get homeRankingsTab;

  /// No description provided for @homeWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến với Tìm và quản lý giải đấu thể thao'**
  String get homeWelcomeTitle;

  /// No description provided for @homeLoginForStats.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem ELO & thống kê'**
  String get homeLoginForStats;

  /// No description provided for @homeDefaultUser.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get homeDefaultUser;

  /// No description provided for @homeEloStartHint.
  ///
  /// In vi, this message translates to:
  /// **'Đánh 1 trận xếp hạng để bắt đầu tiến trình ELO'**
  String get homeEloStartHint;

  /// No description provided for @homeBusyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đang bận, vui lòng thử lại sau'**
  String get homeBusyMessage;

  /// No description provided for @homeFindTournamentsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tìm và tham gia các giải đấu thể thao'**
  String get homeFindTournamentsSubtitle;

  /// No description provided for @homeSearchMatchesHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm trận đấu, đội hoặc người chơi...'**
  String get homeSearchMatchesHint;

  /// No description provided for @homeSearchTournamentsHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm giải đấu...'**
  String get homeSearchTournamentsHint;

  /// No description provided for @homeSearchClubsHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm câu lạc bộ...'**
  String get homeSearchClubsHint;

  /// No description provided for @homeSearchAthletesHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm vận động viên...'**
  String get homeSearchAthletesHint;

  /// No description provided for @homeSearchGenericHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm...'**
  String get homeSearchGenericHint;

  /// No description provided for @homeCompletedMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận đấu vừa kết thúc'**
  String get homeCompletedMatches;

  /// No description provided for @homeNoCompletedMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu vừa kết thúc'**
  String get homeNoCompletedMatches;

  /// No description provided for @homeExploreFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc Khám phá'**
  String get homeExploreFilterTitle;

  /// No description provided for @homeLiveStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trực tiếp'**
  String get homeLiveStatus;

  /// No description provided for @homeCompletedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get homeCompletedStatus;

  /// No description provided for @homeRankingFilter.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng'**
  String get homeRankingFilter;

  /// No description provided for @homeRankedYes.
  ///
  /// In vi, this message translates to:
  /// **'Có tính ELO'**
  String get homeRankedYes;

  /// No description provided for @homeRankedNo.
  ///
  /// In vi, this message translates to:
  /// **'Không tính ELO'**
  String get homeRankedNo;

  /// No description provided for @homeTournamentFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc Giải đấu'**
  String get homeTournamentFilterTitle;

  /// No description provided for @homeCompetitionContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung thi đấu'**
  String get homeCompetitionContent;

  /// No description provided for @homeInProgressStatus.
  ///
  /// In vi, this message translates to:
  /// **'Thi đấu'**
  String get homeInProgressStatus;

  /// No description provided for @homeFormatDoubleElimination.
  ///
  /// In vi, this message translates to:
  /// **'Thắng/thua'**
  String get homeFormatDoubleElimination;

  /// No description provided for @homeFormatGroupStagePlayoff.
  ///
  /// In vi, this message translates to:
  /// **'Vòng bảng + playoff'**
  String get homeFormatGroupStagePlayoff;

  /// No description provided for @homeLocationProvince.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/Thành'**
  String get homeLocationProvince;

  /// No description provided for @homeLocationWard.
  ///
  /// In vi, this message translates to:
  /// **'Phường/Xã'**
  String get homeLocationWard;

  /// No description provided for @homeSelectProvinceFirst.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Tỉnh/Thành trước'**
  String get homeSelectProvinceFirst;

  /// No description provided for @homeFromDate.
  ///
  /// In vi, this message translates to:
  /// **'Từ ngày'**
  String get homeFromDate;

  /// No description provided for @homeToDate.
  ///
  /// In vi, this message translates to:
  /// **'Đến ngày'**
  String get homeToDate;

  /// No description provided for @homeClubFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc Câu lạc bộ'**
  String get homeClubFilterTitle;

  /// No description provided for @homeRankingFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc Xếp hạng ELO'**
  String get homeRankingFilterTitle;

  /// No description provided for @homeNoTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giải đấu'**
  String get homeNoTournaments;

  /// No description provided for @homeNoTournamentsHint.
  ///
  /// In vi, this message translates to:
  /// **'Thử thay đổi bộ lọc hoặc từ khoá'**
  String get homeNoTournamentsHint;

  /// No description provided for @homeNoMatchingTournaments.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy giải đấu phù hợp'**
  String get homeNoMatchingTournaments;

  /// No description provided for @homeNoClubs.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy câu lạc bộ'**
  String get homeNoClubs;

  /// No description provided for @homeNoClubsHint.
  ///
  /// In vi, this message translates to:
  /// **'Thử thay đổi môn thể thao hoặc từ khoá tìm kiếm'**
  String get homeNoClubsHint;

  /// No description provided for @homeLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get homeLoading;

  /// No description provided for @homeClubsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải danh sách CLB'**
  String get homeClubsLoadError;

  /// No description provided for @homeInviteOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mời'**
  String get homeInviteOnly;

  /// No description provided for @homeApproval.
  ///
  /// In vi, this message translates to:
  /// **'Xét duyệt'**
  String get homeApproval;

  /// No description provided for @homeOpenJoin.
  ///
  /// In vi, this message translates to:
  /// **'Tự do'**
  String get homeOpenJoin;

  /// No description provided for @homeMembersCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String homeMembersCount(Object count);

  /// No description provided for @homeMatchesStat.
  ///
  /// In vi, this message translates to:
  /// **'Trận'**
  String get homeMatchesStat;

  /// No description provided for @homeWinRateStat.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ thắng'**
  String get homeWinRateStat;

  /// No description provided for @homeSportFallback.
  ///
  /// In vi, this message translates to:
  /// **'THỂ THAO'**
  String get homeSportFallback;

  /// No description provided for @homeDataLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu'**
  String get homeDataLoadError;

  /// No description provided for @tournamentCardSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đơn'**
  String get tournamentCardSingles;

  /// No description provided for @tournamentCardDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi'**
  String get tournamentCardDoubles;

  /// No description provided for @tournamentCardContentCount.
  ///
  /// In vi, this message translates to:
  /// **'+{count} nội dung'**
  String tournamentCardContentCount(Object count);

  /// No description provided for @tournamentCardMonthLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thg {month}'**
  String tournamentCardMonthLabel(Object month);

  /// No description provided for @tournamentCardEloUnranked.
  ///
  /// In vi, this message translates to:
  /// **'KHÔNG TÍNH ELO'**
  String get tournamentCardEloUnranked;

  /// No description provided for @tournamentCardEloRanked.
  ///
  /// In vi, this message translates to:
  /// **'XẾP HẠNG ELO'**
  String get tournamentCardEloRanked;

  /// No description provided for @homeMatchesLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải dữ liệu trận đấu...'**
  String get homeMatchesLoading;

  /// No description provided for @homeMatchesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu trận đấu. Vui lòng thử lại.'**
  String get homeMatchesLoadError;

  /// No description provided for @register_teamTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký đội bóng'**
  String get register_teamTitle;

  /// No description provided for @register_invitedBannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn được chọn vào đội hình giải này'**
  String get register_invitedBannerTitle;

  /// No description provided for @register_invitedBannerDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hãy xác nhận trước khi Ban tổ chức khóa roster.'**
  String get register_invitedBannerDescription;

  /// No description provided for @register_confirmRoster.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get register_confirmRoster;

  /// No description provided for @register_declineRoster.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get register_declineRoster;

  /// No description provided for @register_chooseExistingTeam.
  ///
  /// In vi, this message translates to:
  /// **'Chọn đội đã tạo'**
  String get register_chooseExistingTeam;

  /// No description provided for @register_noMatchingTeams.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đội bóng phù hợp với môn này.'**
  String get register_noMatchingTeams;

  /// No description provided for @register_teamMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get register_teamMember;

  /// No description provided for @register_canRegister.
  ///
  /// In vi, this message translates to:
  /// **'Có quyền đăng ký'**
  String get register_canRegister;

  /// No description provided for @register_rosterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đội hình đăng ký'**
  String get register_rosterTitle;

  /// No description provided for @register_rosterInstructions.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tối đa {teamSize} cầu thủ chính và tối đa {maxReserve} dự bị. Có thể bổ sung sau khi lưu nháp.'**
  String register_rosterInstructions(Object teamSize, Object maxReserve);

  /// No description provided for @register_mainPlayer.
  ///
  /// In vi, this message translates to:
  /// **'Cầu thủ chính'**
  String get register_mainPlayer;

  /// No description provided for @register_reservePlayer.
  ///
  /// In vi, this message translates to:
  /// **'Cầu thủ dự bị'**
  String get register_reservePlayer;

  /// No description provided for @register_removeSelection.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn'**
  String get register_removeSelection;

  /// No description provided for @register_quickCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo đội nhanh'**
  String get register_quickCreateTitle;

  /// No description provided for @register_teamNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội'**
  String get register_teamNameHint;

  /// No description provided for @register_createTeam.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get register_createTeam;

  /// No description provided for @register_rosterLocked.
  ///
  /// In vi, this message translates to:
  /// **'Roster đã khóa, chỉ có thể xem đội hình.'**
  String get register_rosterLocked;

  /// No description provided for @register_updateRoster.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật roster'**
  String get register_updateRoster;

  /// No description provided for @register_saveDraft.
  ///
  /// In vi, this message translates to:
  /// **'Lưu đăng ký nháp'**
  String get register_saveDraft;

  /// No description provided for @register_selectedTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký đội đã chọn'**
  String get register_selectedTeam;

  /// No description provided for @register_teamCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo đội. Hãy mời đủ thành viên trong trang đội.'**
  String get register_teamCreated;

  /// No description provided for @register_rosterDraftSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu roster nháp.'**
  String get register_rosterDraftSaved;

  /// No description provided for @register_rosterUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật roster đội.'**
  String get register_rosterUpdated;

  /// No description provided for @register_draftRegistrationSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu đăng ký nháp. Hãy bổ sung đủ đội hình trước khi BTC khóa roster.'**
  String get register_draftRegistrationSaved;

  /// No description provided for @register_teamRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký đội thành công.'**
  String get register_teamRegistered;

  /// No description provided for @register_updateRosterError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật đội hình. Vui lòng thử lại.'**
  String get register_updateRosterError;

  /// No description provided for @register_createTeamError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo đội. Vui lòng thử lại.'**
  String get register_createTeamError;

  /// No description provided for @register_registrationError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đăng ký đội. Vui lòng thử lại.'**
  String get register_registrationError;

  /// No description provided for @createClubTournament_title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải đấu trong CLB'**
  String get createClubTournament_title;

  /// No description provided for @createClubTournament_nameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên giải đấu *'**
  String get createClubTournament_nameLabel;

  /// No description provided for @createClubTournament_nameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên giải đấu'**
  String get createClubTournament_nameRequired;

  /// No description provided for @createClubTournament_nameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Giải Cầu lông Mở rộng 2026'**
  String get createClubTournament_nameHint;

  /// No description provided for @createClubTournament_sportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get createClubTournament_sportLabel;

  /// No description provided for @createClubTournament_formatLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung thi đấu'**
  String get createClubTournament_formatLabel;

  /// No description provided for @createClubTournament_bracketLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức thi đấu'**
  String get createClubTournament_bracketLabel;

  /// No description provided for @createClubTournament_startDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngày bắt đầu (tuỳ chọn)'**
  String get createClubTournament_startDateLabel;

  /// No description provided for @createClubTournament_startDateHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày bắt đầu giải'**
  String get createClubTournament_startDateHint;

  /// No description provided for @createClubTournament_clearDate.
  ///
  /// In vi, this message translates to:
  /// **'Xóa ngày'**
  String get createClubTournament_clearDate;

  /// No description provided for @createClubTournament_notSelected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn'**
  String get createClubTournament_notSelected;

  /// No description provided for @createClubTournament_startDateNote.
  ///
  /// In vi, this message translates to:
  /// **'Có thể bổ sung hoặc thay đổi lịch trong trang quản lý sau khi tạo.'**
  String get createClubTournament_startDateNote;

  /// No description provided for @createClubTournament_pickStartDate.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày bắt đầu giải'**
  String get createClubTournament_pickStartDate;

  /// No description provided for @createClubTournament_continue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get createClubTournament_continue;

  /// No description provided for @createClubTournament_defaultTime.
  ///
  /// In vi, this message translates to:
  /// **'Mặc định (08:00)'**
  String get createClubTournament_defaultTime;

  /// No description provided for @createClubTournament_done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get createClubTournament_done;

  /// No description provided for @createClubTournament_pickStartTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ bắt đầu giải'**
  String get createClubTournament_pickStartTime;

  /// No description provided for @createClubTournament_recurringTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự động tạo giải định kỳ'**
  String get createClubTournament_recurringTitle;

  /// No description provided for @createClubTournament_recurringDescription.
  ///
  /// In vi, this message translates to:
  /// **'Cron sẽ tự tạo giải mới và báo cho thành viên CLB.'**
  String get createClubTournament_recurringDescription;

  /// No description provided for @createClubTournament_frequency.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất'**
  String get createClubTournament_frequency;

  /// No description provided for @createClubTournament_daily.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày'**
  String get createClubTournament_daily;

  /// No description provided for @createClubTournament_weekly.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tuần'**
  String get createClubTournament_weekly;

  /// No description provided for @createClubTournament_biweekly.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi 2 tuần'**
  String get createClubTournament_biweekly;

  /// No description provided for @createClubTournament_monthly.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi tháng'**
  String get createClubTournament_monthly;

  /// No description provided for @createClubTournament_weekday.
  ///
  /// In vi, this message translates to:
  /// **'Ngày trong tuần'**
  String get createClubTournament_weekday;

  /// No description provided for @createClubTournament_monday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 2'**
  String get createClubTournament_monday;

  /// No description provided for @createClubTournament_tuesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 3'**
  String get createClubTournament_tuesday;

  /// No description provided for @createClubTournament_wednesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 4'**
  String get createClubTournament_wednesday;

  /// No description provided for @createClubTournament_thursday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 5'**
  String get createClubTournament_thursday;

  /// No description provided for @createClubTournament_friday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 6'**
  String get createClubTournament_friday;

  /// No description provided for @createClubTournament_saturday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ 7'**
  String get createClubTournament_saturday;

  /// No description provided for @createClubTournament_sunday.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhật'**
  String get createClubTournament_sunday;

  /// No description provided for @createClubTournament_autoCreateTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ tự động tạo'**
  String get createClubTournament_autoCreateTime;

  /// No description provided for @createClubTournament_pickRecurringTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ tự động tạo giải'**
  String get createClubTournament_pickRecurringTime;

  /// No description provided for @createClubTournament_pickTime.
  ///
  /// In vi, this message translates to:
  /// **'Chọn giờ'**
  String get createClubTournament_pickTime;

  /// No description provided for @createClubTournament_advanceDays.
  ///
  /// In vi, this message translates to:
  /// **'Tạo trước ngày thi đấu'**
  String get createClubTournament_advanceDays;

  /// No description provided for @createClubTournament_sameDay.
  ///
  /// In vi, this message translates to:
  /// **'Ngay ngày thi đấu'**
  String get createClubTournament_sameDay;

  /// No description provided for @createClubTournament_beforeDays.
  ///
  /// In vi, this message translates to:
  /// **'Trước {days} ngày'**
  String createClubTournament_beforeDays(Object days);

  /// No description provided for @createClubTournament_maxTeams.
  ///
  /// In vi, this message translates to:
  /// **'Số đội tối đa'**
  String get createClubTournament_maxTeams;

  /// No description provided for @createClubTournament_maxTeamsHint.
  ///
  /// In vi, this message translates to:
  /// **'16'**
  String get createClubTournament_maxTeamsHint;

  /// No description provided for @createClubTournament_maxTeamsInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Từ 2-128 đội'**
  String get createClubTournament_maxTeamsInvalid;

  /// No description provided for @createClubTournament_descriptionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (không bắt buộc)'**
  String get createClubTournament_descriptionLabel;

  /// No description provided for @createClubTournament_descriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin thêm về giải đấu...'**
  String get createClubTournament_descriptionHint;

  /// No description provided for @createClubTournament_ranked.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng ELO'**
  String get createClubTournament_ranked;

  /// No description provided for @createClubTournament_unranked.
  ///
  /// In vi, this message translates to:
  /// **'Phong trào'**
  String get createClubTournament_unranked;

  /// No description provided for @createClubTournament_rankedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả ảnh hưởng đến điểm ELO'**
  String get createClubTournament_rankedDescription;

  /// No description provided for @createClubTournament_unrankedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giải giao hữu, không tính xếp hạng'**
  String get createClubTournament_unrankedDescription;

  /// No description provided for @createClubTournament_creating.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo...'**
  String get createClubTournament_creating;

  /// No description provided for @createClubTournament_create.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải đấu'**
  String get createClubTournament_create;

  /// No description provided for @createClubTournament_submitError.
  ///
  /// In vi, this message translates to:
  /// **'Đã có lỗi xảy ra khi tạo giải đấu.'**
  String get createClubTournament_submitError;

  /// No description provided for @createClubTournament_forbiddenError.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền tạo giải trong CLB này hoặc tài khoản chưa xác thực email.'**
  String get createClubTournament_forbiddenError;

  /// No description provided for @createClubTournament_sportBadminton.
  ///
  /// In vi, this message translates to:
  /// **'Cầu lông'**
  String get createClubTournament_sportBadminton;

  /// No description provided for @createClubTournament_sportTennis.
  ///
  /// In vi, this message translates to:
  /// **'Tennis'**
  String get createClubTournament_sportTennis;

  /// No description provided for @createClubTournament_sportPickleball.
  ///
  /// In vi, this message translates to:
  /// **'Pickleball'**
  String get createClubTournament_sportPickleball;

  /// No description provided for @createClubTournament_sportTableTennis.
  ///
  /// In vi, this message translates to:
  /// **'Bóng bàn'**
  String get createClubTournament_sportTableTennis;

  /// No description provided for @createClubTournament_sportFootball.
  ///
  /// In vi, this message translates to:
  /// **'Bóng đá'**
  String get createClubTournament_sportFootball;

  /// No description provided for @quickCreateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải nhanh'**
  String get quickCreateTitle;

  /// No description provided for @quickCreateHeading.
  ///
  /// In vi, this message translates to:
  /// **'Giải Public'**
  String get quickCreateHeading;

  /// No description provided for @quickCreateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhanh trên app, bổ sung cấu hình nâng cao trong trang quản lý web.'**
  String get quickCreateDescription;

  /// No description provided for @quickCreateNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên giải đấu *'**
  String get quickCreateNameLabel;

  /// No description provided for @quickCreateNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Giải Cầu lông Cuối Tuần'**
  String get quickCreateNameHint;

  /// No description provided for @quickCreateSportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao *'**
  String get quickCreateSportLabel;

  /// No description provided for @quickCreateFormatLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung thi đấu'**
  String get quickCreateFormatLabel;

  /// No description provided for @quickCreateBracketLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức'**
  String get quickCreateBracketLabel;

  /// No description provided for @quickCreateMaxTeamsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số đội / người tối đa'**
  String get quickCreateMaxTeamsLabel;

  /// No description provided for @quickCreateMaxTeamsHint.
  ///
  /// In vi, this message translates to:
  /// **'16'**
  String get quickCreateMaxTeamsHint;

  /// No description provided for @quickCreateVisibilityLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị giải đấu'**
  String get quickCreateVisibilityLabel;

  /// No description provided for @quickCreateVisibilityPublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get quickCreateVisibilityPublic;

  /// No description provided for @quickCreateVisibilityPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Không niêm yết'**
  String get quickCreateVisibilityPrivate;

  /// No description provided for @quickCreateRegistrationNote.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký mặc định ở chế độ Xét duyệt. Bạn có thể thay đổi cách nhận đăng ký trong trang quản lý web sau khi tạo.'**
  String get quickCreateRegistrationNote;

  /// No description provided for @quickCreateClubNote.
  ///
  /// In vi, this message translates to:
  /// **'Không có lựa chọn câu lạc bộ trong luồng Public. Muốn tạo trong CLB, hãy vào trang CLB và chọn Lite CLB hoặc Tạo nhanh trên web.'**
  String get quickCreateClubNote;

  /// No description provided for @quickCreateSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải nhanh'**
  String get quickCreateSubmit;

  /// No description provided for @quickCreateSubmitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo...'**
  String get quickCreateSubmitting;

  /// No description provided for @quickCreateCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo giải. Đang mở trang quản lý trên web.'**
  String get quickCreateCreated;

  /// No description provided for @quickCreateNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên giải đấu.'**
  String get quickCreateNameRequired;

  /// No description provided for @quickCreateMaxTeamsInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Quy mô phải từ 2 đến 32 người/đội.'**
  String get quickCreateMaxTeamsInvalid;

  /// No description provided for @quickCreateMissingId.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận được mã giải đấu.'**
  String get quickCreateMissingId;

  /// No description provided for @quickCreateSubmitError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo giải đấu.'**
  String get quickCreateSubmitError;

  /// No description provided for @quickCreateOpenWebError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở trang quản lý trên web.'**
  String get quickCreateOpenWebError;

  /// No description provided for @quickCreateFormatSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đơn'**
  String get quickCreateFormatSingles;

  /// No description provided for @quickCreateFormatDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đôi'**
  String get quickCreateFormatDoubles;

  /// No description provided for @quickCreateFormatMixedDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam nữ'**
  String get quickCreateFormatMixedDoubles;

  /// No description provided for @quickCreateBracketSingle.
  ///
  /// In vi, this message translates to:
  /// **'Đấu loại trực tiếp'**
  String get quickCreateBracketSingle;

  /// No description provided for @quickCreateBracketDouble.
  ///
  /// In vi, this message translates to:
  /// **'Đấu loại kép'**
  String get quickCreateBracketDouble;

  /// No description provided for @quickCreateBracketRoundRobin.
  ///
  /// In vi, this message translates to:
  /// **'Vòng tròn'**
  String get quickCreateBracketRoundRobin;

  /// No description provided for @quickCreateBracketGroup.
  ///
  /// In vi, this message translates to:
  /// **'Vòng bảng + Loại trực tiếp'**
  String get quickCreateBracketGroup;

  /// No description provided for @tournamentSettingsCategoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hạng mục / Nội dung'**
  String get tournamentSettingsCategoryLabel;

  /// No description provided for @tournamentSettingsDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get tournamentSettingsDetails;

  /// No description provided for @tournamentSettingsTeamsRoundRobinTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng đội dự kiến (3 - 16 đội)'**
  String get tournamentSettingsTeamsRoundRobinTitle;

  /// No description provided for @tournamentSettingsTeamsStandardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số lượng đội dự kiến (2 - 32 đội)'**
  String get tournamentSettingsTeamsStandardTitle;

  /// No description provided for @tournamentSettingsTeamsRoundRobinHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: 5, 8, 10...'**
  String get tournamentSettingsTeamsRoundRobinHint;

  /// No description provided for @tournamentSettingsTeamsStandardHint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý sơ đồ chuẩn nhất: 4, 8, 16, 32'**
  String get tournamentSettingsTeamsStandardHint;

  /// No description provided for @tournamentSettingsInvalidNumber.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập số hợp lệ'**
  String get tournamentSettingsInvalidNumber;

  /// No description provided for @tournamentSettingsRoundRobinMin.
  ///
  /// In vi, this message translates to:
  /// **'Đấu vòng tròn cần ít nhất 3 đội'**
  String get tournamentSettingsRoundRobinMin;

  /// No description provided for @tournamentSettingsRoundRobinMax.
  ///
  /// In vi, this message translates to:
  /// **'Đấu vòng tròn tối đa hỗ trợ 16 đội'**
  String get tournamentSettingsRoundRobinMax;

  /// No description provided for @tournamentSettingsTeamsMin.
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất 2 đội'**
  String get tournamentSettingsTeamsMin;

  /// No description provided for @tournamentSettingsTeamsMax.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa chỉ hỗ trợ 32 đội'**
  String get tournamentSettingsTeamsMax;

  /// No description provided for @tournamentSettingsRoundCountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số vòng đấu (Số vòng bạn muốn diễn ra)'**
  String get tournamentSettingsRoundCountTitle;

  /// No description provided for @tournamentSettingsRoundCountHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Nhập đúng số vòng mà bạn muốn tổ chức'**
  String get tournamentSettingsRoundCountHint;

  /// No description provided for @tournamentSettingsRoundCountPositive.
  ///
  /// In vi, this message translates to:
  /// **'Số vòng phải lớn hơn 0'**
  String get tournamentSettingsRoundCountPositive;

  /// No description provided for @tournamentSettingsRoundCountMax.
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 38 vòng để tránh quá tải'**
  String get tournamentSettingsRoundCountMax;

  /// No description provided for @tournamentSettingsLoadingSports.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách môn thi đấu...'**
  String get tournamentSettingsLoadingSports;

  /// No description provided for @tournamentCategoryMenSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đơn nam'**
  String get tournamentCategoryMenSingles;

  /// No description provided for @tournamentCategoryWomenSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đơn nữ'**
  String get tournamentCategoryWomenSingles;

  /// No description provided for @tournamentCategoryMenDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam'**
  String get tournamentCategoryMenDoubles;

  /// No description provided for @tournamentCategoryWomenDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nữ'**
  String get tournamentCategoryWomenDoubles;

  /// No description provided for @tournamentCategoryMixedDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đôi nam nữ'**
  String get tournamentCategoryMixedDoubles;

  /// No description provided for @createClubTournament_formatSingles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đơn'**
  String get createClubTournament_formatSingles;

  /// No description provided for @createClubTournament_formatDoubles.
  ///
  /// In vi, this message translates to:
  /// **'Đánh đôi'**
  String get createClubTournament_formatDoubles;

  /// No description provided for @createClubTournament_bracketSingleElimination.
  ///
  /// In vi, this message translates to:
  /// **'Loại trực tiếp'**
  String get createClubTournament_bracketSingleElimination;

  /// No description provided for @createClubTournament_bracketSingleEliminationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Loại ngay khi thua'**
  String get createClubTournament_bracketSingleEliminationDescription;

  /// No description provided for @createClubTournament_bracketDoubleElimination.
  ///
  /// In vi, this message translates to:
  /// **'Loại kép'**
  String get createClubTournament_bracketDoubleElimination;

  /// No description provided for @createClubTournament_bracketDoubleEliminationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Có nhánh thắng/thua'**
  String get createClubTournament_bracketDoubleEliminationDescription;

  /// No description provided for @createClubTournament_bracketRoundRobin.
  ///
  /// In vi, this message translates to:
  /// **'Vòng tròn'**
  String get createClubTournament_bracketRoundRobin;

  /// No description provided for @createClubTournament_bracketRoundRobinDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả gặp nhau'**
  String get createClubTournament_bracketRoundRobinDescription;

  /// No description provided for @createClubTournament_bracketGroupStageKnockout.
  ///
  /// In vi, this message translates to:
  /// **'Vòng bảng + Loại trực tiếp'**
  String get createClubTournament_bracketGroupStageKnockout;

  /// No description provided for @createClubTournament_bracketGroupStageKnockoutDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chia bảng, chọn đội đi tiếp'**
  String get createClubTournament_bracketGroupStageKnockoutDescription;

  /// No description provided for @createClubTournament_successTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo giải thành công!'**
  String get createClubTournament_successTitle;

  /// No description provided for @createClubTournament_copyLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link'**
  String get createClubTournament_copyLink;

  /// No description provided for @createClubTournament_linkCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép link mời!'**
  String get createClubTournament_linkCopied;

  /// No description provided for @createClubTournament_share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get createClubTournament_share;

  /// No description provided for @createClubTournament_shareText.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia giải {name}: {link}'**
  String createClubTournament_shareText(Object name, Object link);

  /// No description provided for @createClubTournament_manageQuickly.
  ///
  /// In vi, this message translates to:
  /// **'Vào quản lý nhanh'**
  String get createClubTournament_manageQuickly;

  /// No description provided for @createClubTournament_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get createClubTournament_close;

  /// No description provided for @editClub_title.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa CLB'**
  String get editClub_title;

  /// No description provided for @editClub_save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get editClub_save;

  /// No description provided for @editClub_saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get editClub_saving;

  /// No description provided for @editClub_imagesSection.
  ///
  /// In vi, this message translates to:
  /// **'HÌNH ẢNH & NHẬN DIỆN'**
  String get editClub_imagesSection;

  /// No description provided for @editClub_imagesSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Logo và ảnh bìa đại diện cho câu lạc bộ trên hệ thống'**
  String get editClub_imagesSubtitle;

  /// No description provided for @editClub_logoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Logo CLB'**
  String get editClub_logoTitle;

  /// No description provided for @editClub_logoHint.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ 1:1'**
  String get editClub_logoHint;

  /// No description provided for @editClub_bannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get editClub_bannerTitle;

  /// No description provided for @editClub_bannerHint.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ 3:1 (1200×400)'**
  String get editClub_bannerHint;

  /// No description provided for @editClub_captureNew.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh mới'**
  String get editClub_captureNew;

  /// No description provided for @editClub_chooseLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get editClub_chooseLibrary;

  /// No description provided for @editClub_changeImage.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi'**
  String get editClub_changeImage;

  /// No description provided for @editClub_logoUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh đại diện (PNG, JPG tỉ lệ 1:1)'**
  String get editClub_logoUpdated;

  /// No description provided for @editClub_bannerUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh bìa (khuyên dùng 1200x400 px)'**
  String get editClub_bannerUpdated;

  /// No description provided for @editClub_imageUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật ảnh CLB'**
  String get editClub_imageUpdateError;

  /// No description provided for @editClub_primarySportError.
  ///
  /// In vi, this message translates to:
  /// **'Câu lạc bộ phải có đúng 1 môn thể thao chính.'**
  String get editClub_primarySportError;

  /// No description provided for @editClub_provinceRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn tỉnh/thành phố.'**
  String get editClub_provinceRequired;

  /// No description provided for @editClub_saved.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật cài đặt câu lạc bộ thành công!'**
  String get editClub_saved;

  /// No description provided for @editClub_saveError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String editClub_saveError(Object error);

  /// No description provided for @editClub_basicSection.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG TIN CƠ BẢN'**
  String get editClub_basicSection;

  /// No description provided for @editClub_basicSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tên, môn thể thao chính và giới thiệu câu lạc bộ'**
  String get editClub_basicSubtitle;

  /// No description provided for @editClub_clubName.
  ///
  /// In vi, this message translates to:
  /// **'Tên câu lạc bộ'**
  String get editClub_clubName;

  /// No description provided for @editClub_clubNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: CLB Pickleball Trang Hưng'**
  String get editClub_clubNameHint;

  /// No description provided for @editClub_clubNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên câu lạc bộ.'**
  String get editClub_clubNameRequired;

  /// No description provided for @editClub_clubNameMax.
  ///
  /// In vi, this message translates to:
  /// **'Tên tối đa 255 ký tự.'**
  String get editClub_clubNameMax;

  /// No description provided for @editClub_primarySport.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao chính'**
  String get editClub_primarySport;

  /// No description provided for @editClub_primarySportDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi CLB gắn liền với một bộ môn thi đấu chính.'**
  String get editClub_primarySportDescription;

  /// No description provided for @editClub_descriptionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu & Mô tả'**
  String get editClub_descriptionLabel;

  /// No description provided for @editClub_descriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Mục đích hoạt động, thời gian sinh hoạt, tiêu chí...'**
  String get editClub_descriptionHint;

  /// No description provided for @editClub_locationSection.
  ///
  /// In vi, this message translates to:
  /// **'ĐỊA ĐIỂM & KHU VỰC HOẠT ĐỘNG'**
  String get editClub_locationSection;

  /// No description provided for @editClub_locationSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực hành chính và địa chỉ sân sinh hoạt'**
  String get editClub_locationSubtitle;

  /// No description provided for @editClub_administrativeArea.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực hành chính'**
  String get editClub_administrativeArea;

  /// No description provided for @editClub_detailedAddress.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ sân chi tiết'**
  String get editClub_detailedAddress;

  /// No description provided for @editClub_detailedAddressHint.
  ///
  /// In vi, this message translates to:
  /// **'Số nhà, tên đường, cụm sân thi đấu...'**
  String get editClub_detailedAddressHint;

  /// No description provided for @editClub_privacySection.
  ///
  /// In vi, this message translates to:
  /// **'QUYỀN RIÊNG TƯ & THÀNH VIÊN'**
  String get editClub_privacySection;

  /// No description provided for @editClub_privacySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quy chế xét duyệt, giới hạn số lượng và nội quy'**
  String get editClub_privacySubtitle;

  /// No description provided for @editClub_visibility.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ hiển thị'**
  String get editClub_visibility;

  /// No description provided for @editClub_memberJoinMethod.
  ///
  /// In vi, this message translates to:
  /// **'Cách thức tiếp nhận thành viên'**
  String get editClub_memberJoinMethod;

  /// No description provided for @editClub_memberLimit.
  ///
  /// In vi, this message translates to:
  /// **'Giới hạn số lượng thành viên'**
  String get editClub_memberLimit;

  /// No description provided for @editClub_memberLimitHint.
  ///
  /// In vi, this message translates to:
  /// **'Để trống nếu không giới hạn số lượng'**
  String get editClub_memberLimitHint;

  /// No description provided for @editClub_rules.
  ///
  /// In vi, this message translates to:
  /// **'Nội quy câu lạc bộ'**
  String get editClub_rules;

  /// No description provided for @editClub_rulesHint.
  ///
  /// In vi, this message translates to:
  /// **'Quy định ứng xử, đóng quỹ định kỳ, kỷ luật...'**
  String get editClub_rulesHint;

  /// No description provided for @editClub_approvalSection.
  ///
  /// In vi, this message translates to:
  /// **'CÂU HỎI XÉT DUYỆT ĐƠN'**
  String get editClub_approvalSection;

  /// No description provided for @editClub_approvalSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Người xin gia nhập phải trả lời câu hỏi này để BQT duyệt'**
  String get editClub_approvalSubtitle;

  /// No description provided for @editClub_questionHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu hỏi (VD: Trình độ ELO/DUPR?)...'**
  String get editClub_questionHint;

  /// No description provided for @editClub_addQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Thêm câu hỏi'**
  String get editClub_addQuestion;

  /// No description provided for @editClub_socialSection.
  ///
  /// In vi, this message translates to:
  /// **'MẠNG XÃ HỘI & KÊNH LIÊN HỆ'**
  String get editClub_socialSection;

  /// No description provided for @editClub_socialSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết Facebook, Zalo, Tiktok... của câu lạc bộ'**
  String get editClub_socialSubtitle;

  /// No description provided for @editClub_saveAll.
  ///
  /// In vi, this message translates to:
  /// **'Lưu toàn bộ thay đổi'**
  String get editClub_saveAll;

  /// No description provided for @editClub_dangerTitle.
  ///
  /// In vi, this message translates to:
  /// **'VÙNG NGUY HIỂM'**
  String get editClub_dangerTitle;

  /// No description provided for @editClub_dangerDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này sẽ xoá vĩnh viễn Câu lạc bộ cùng toàn bộ bài viết, bảng xếp hạng và lịch sử giải đấu.'**
  String get editClub_dangerDescription;

  /// No description provided for @editClub_deleteClub.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn câu lạc bộ'**
  String get editClub_deleteClub;

  /// No description provided for @editClub_deleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn câu lạc bộ'**
  String get editClub_deleteTitle;

  /// No description provided for @editClub_deleteDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xoá câu lạc bộ \"{name}\"? Toàn bộ dữ liệu thành viên, bài viết và hoạt động sẽ bị xoá vĩnh viễn và không thể khôi phục.'**
  String editClub_deleteDescription(Object name);

  /// No description provided for @editClub_confirmName.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên câu lạc bộ {name} để xác nhận:'**
  String editClub_confirmName(Object name);

  /// No description provided for @editClub_clubNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên câu lạc bộ'**
  String get editClub_clubNameLabel;

  /// No description provided for @editClub_deleteForever.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn'**
  String get editClub_deleteForever;

  /// No description provided for @editClub_deleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá câu lạc bộ thành công.'**
  String get editClub_deleted;

  /// No description provided for @editClub_deleteError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi khi thực hiện xoá câu lạc bộ: {error}'**
  String editClub_deleteError(Object error);

  /// No description provided for @editClub_loadingSports.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải danh sách môn thể thao...'**
  String get editClub_loadingSports;

  /// No description provided for @editClub_joinOpen.
  ///
  /// In vi, this message translates to:
  /// **'Mở tự do'**
  String get editClub_joinOpen;

  /// No description provided for @editClub_joinOpenDescription.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên nhấn tham gia là vào nhóm ngay.'**
  String get editClub_joinOpenDescription;

  /// No description provided for @editClub_joinApproval.
  ///
  /// In vi, this message translates to:
  /// **'Cần phê duyệt đơn'**
  String get editClub_joinApproval;

  /// No description provided for @editClub_joinApprovalDescription.
  ///
  /// In vi, this message translates to:
  /// **'Phải trả lời câu hỏi và chờ BQT chấp thuận.'**
  String get editClub_joinApprovalDescription;

  /// No description provided for @editClub_joinInviteOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận lời mời'**
  String get editClub_joinInviteOnly;

  /// No description provided for @editClub_joinInviteOnlyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thành viên được mời mới có thể tham gia.'**
  String get editClub_joinInviteOnlyDescription;

  /// No description provided for @editClub_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thông tin CLB'**
  String get editClub_loadError;

  /// No description provided for @editClub_retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get editClub_retry;

  /// No description provided for @footballTeams_title.
  ///
  /// In vi, this message translates to:
  /// **'Đội bóng của tôi'**
  String get footballTeams_title;

  /// No description provided for @footballTeams_activeCount.
  ///
  /// In vi, this message translates to:
  /// **'Đội đang hoạt động {count}/3'**
  String footballTeams_activeCount(Object count);

  /// No description provided for @footballTeams_eloMembers.
  ///
  /// In vi, this message translates to:
  /// **'ELO {elo} · {memberCount} thành viên'**
  String footballTeams_eloMembers(Object elo, Object memberCount);

  /// No description provided for @footballTeams_newTeamName.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội mới'**
  String get footballTeams_newTeamName;

  /// No description provided for @footballTeams_create.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get footballTeams_create;

  /// No description provided for @footballTeams_teamInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đội'**
  String get footballTeams_teamInfo;

  /// No description provided for @footballTeams_teamName.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội'**
  String get footballTeams_teamName;

  /// No description provided for @footballTeams_save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get footballTeams_save;

  /// No description provided for @footballTeams_inviteMembers.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get footballTeams_inviteMembers;

  /// No description provided for @footballTeams_nameOrEmail.
  ///
  /// In vi, this message translates to:
  /// **'Tên hoặc email'**
  String get footballTeams_nameOrEmail;

  /// No description provided for @footballTeams_accountFallback.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get footballTeams_accountFallback;

  /// No description provided for @footballTeams_invite.
  ///
  /// In vi, this message translates to:
  /// **'Mời'**
  String get footballTeams_invite;

  /// No description provided for @footballTeams_inviteSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lời mời.'**
  String get footballTeams_inviteSent;

  /// No description provided for @footballTeams_pendingInvite.
  ///
  /// In vi, this message translates to:
  /// **'Đang mời - chờ xác nhận'**
  String get footballTeams_pendingInvite;

  /// No description provided for @footballTeams_captain.
  ///
  /// In vi, this message translates to:
  /// **'Đội trưởng'**
  String get footballTeams_captain;

  /// No description provided for @footballTeams_manager.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý'**
  String get footballTeams_manager;

  /// No description provided for @footballTeams_player.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get footballTeams_player;

  /// No description provided for @footballTeams_cancelInvite.
  ///
  /// In vi, this message translates to:
  /// **'Hủy lời mời'**
  String get footballTeams_cancelInvite;

  /// No description provided for @footballTeams_genericError.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra'**
  String get footballTeams_genericError;

  /// No description provided for @club_acceptInvite.
  ///
  /// In vi, this message translates to:
  /// **'Chấp nhận lời mời'**
  String get club_acceptInvite;

  /// No description provided for @club_notificationSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt thông báo'**
  String get club_notificationSettings;

  /// No description provided for @club_notificationsMuted.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt thông báo'**
  String get club_notificationsMuted;

  /// No description provided for @club_notificationsMentionsOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khi được nhắc tên'**
  String get club_notificationsMentionsOnly;

  /// No description provided for @club_notificationsAll.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tất cả thông báo'**
  String get club_notificationsAll;

  /// No description provided for @club_leaveClub.
  ///
  /// In vi, this message translates to:
  /// **'Rời khỏi câu lạc bộ'**
  String get club_leaveClub;

  /// No description provided for @club_leaveClubDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hủy tư cách thành viên của câu lạc bộ này'**
  String get club_leaveClubDescription;

  /// No description provided for @clubChat_notificationAllEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật nhận tất cả thông báo CLB'**
  String get clubChat_notificationAllEnabled;

  /// No description provided for @clubChat_notificationMentionsOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ nhận thông báo khi được @nhắc tên'**
  String get clubChat_notificationMentionsOnly;

  /// No description provided for @clubChat_notificationMuted.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt thông báo CLB (Im lặng)'**
  String get clubChat_notificationMuted;

  /// No description provided for @clubChat_notificationUpdateError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể cập nhật cài đặt thông báo.'**
  String get clubChat_notificationUpdateError;

  /// No description provided for @clubChat_notificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo câu lạc bộ'**
  String get clubChat_notificationTitle;

  /// No description provided for @clubChat_notificationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chỉnh nhận tin nhắn và thông báo từ {name}'**
  String clubChat_notificationDescription(Object name);

  /// No description provided for @clubChat_allMessages.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả tin nhắn'**
  String get clubChat_allMessages;

  /// No description provided for @clubChat_allMessagesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo cho mọi tin nhắn mới (Mặc định)'**
  String get clubChat_allMessagesDescription;

  /// No description provided for @clubChat_mentionsOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ khi được @tag'**
  String get clubChat_mentionsOnly;

  /// No description provided for @clubChat_mentionsOnlyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thông báo khi có người nhắc tên bạn hoặc @all'**
  String get clubChat_mentionsOnlyDescription;

  /// No description provided for @clubChat_muted.
  ///
  /// In vi, this message translates to:
  /// **'Tắt thông báo (Im lặng)'**
  String get clubChat_muted;

  /// No description provided for @clubChat_mutedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Không nhận thông báo đẩy từ câu lạc bộ này'**
  String get clubChat_mutedDescription;

  /// No description provided for @clubChat_clearTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đoạn chat?'**
  String get clubChat_clearTitle;

  /// No description provided for @clubChat_clearDescription.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử tin nhắn cũ sẽ được xóa khỏi tài khoản của bạn và không thể khôi phục. Các thành viên khác trong CLB không bị ảnh hưởng.'**
  String get clubChat_clearDescription;

  /// No description provided for @clubChat_clearAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đoạn chat'**
  String get clubChat_clearAction;

  /// No description provided for @clubChat_cleared.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa toàn bộ lịch sử đoạn chat.'**
  String get clubChat_cleared;

  /// No description provided for @clubChat_clearError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa lịch sử đoạn chat lúc này.'**
  String get clubChat_clearError;

  /// No description provided for @clubChat_openError.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể mở trò chuyện. Thử lại sau.'**
  String get clubChat_openError;

  /// No description provided for @clubChat_connectionError.
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối. Kéo xuống để thử lại.'**
  String get clubChat_connectionError;

  /// No description provided for @clubChat_uploadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải ảnh lên.'**
  String get clubChat_uploadError;

  /// No description provided for @clubChat_revokeError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thu hồi tin nhắn.'**
  String get clubChat_revokeError;

  /// No description provided for @clubChat_pinned.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghim tin nhắn.'**
  String get clubChat_pinned;

  /// No description provided for @clubChat_pinError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể ghim tin nhắn.'**
  String get clubChat_pinError;

  /// No description provided for @clubChat_owner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ CLB'**
  String get clubChat_owner;

  /// No description provided for @clubChat_moderator.
  ///
  /// In vi, this message translates to:
  /// **'Quản trị'**
  String get clubChat_moderator;

  /// No description provided for @clubChat_reply.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get clubChat_reply;

  /// No description provided for @clubChat_copy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get clubChat_copy;

  /// No description provided for @clubChat_pin.
  ///
  /// In vi, this message translates to:
  /// **'Ghim tin nhắn'**
  String get clubChat_pin;

  /// No description provided for @clubChat_revoke.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get clubChat_revoke;

  /// No description provided for @clubChat_roomPinnedNotice.
  ///
  /// In vi, this message translates to:
  /// **'Phòng chat có tin nhắn vừa được ghim.'**
  String get clubChat_roomPinnedNotice;

  /// No description provided for @clubChat_reactionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thả cảm xúc lúc này.'**
  String get clubChat_reactionError;

  /// No description provided for @clubChat_menuNotification.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo CLB'**
  String get clubChat_menuNotification;

  /// No description provided for @clubChat_menuClear.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đoạn chat'**
  String get clubChat_menuClear;

  /// No description provided for @clubChat_typing.
  ///
  /// In vi, this message translates to:
  /// **'Đang nhập…'**
  String get clubChat_typing;

  /// No description provided for @clubChat_empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn nào.'**
  String get clubChat_empty;

  /// No description provided for @clubChat_revoked.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn đã thu hồi'**
  String get clubChat_revoked;

  /// No description provided for @clubChat_heartTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Thả tim'**
  String get clubChat_heartTooltip;

  /// No description provided for @clubChat_replyTo.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời {name}'**
  String clubChat_replyTo(Object name);

  /// No description provided for @clubChat_composerHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn trong CLB'**
  String get clubChat_composerHint;

  /// No description provided for @clubChat_sendError.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn thất bại.'**
  String get clubChat_sendError;

  /// No description provided for @standings_empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu bảng xếp hạng'**
  String get standings_empty;

  /// No description provided for @standings_title.
  ///
  /// In vi, this message translates to:
  /// **'Bảng Xếp Hạng Vòng Tròn ({groupCount} Bảng)'**
  String standings_title(Object groupCount);

  /// No description provided for @standings_groupTeams.
  ///
  /// In vi, this message translates to:
  /// **'{teamCount} Đội'**
  String standings_groupTeams(Object teamCount);

  /// No description provided for @standings_rank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng'**
  String get standings_rank;

  /// No description provided for @standings_team.
  ///
  /// In vi, this message translates to:
  /// **'Đội'**
  String get standings_team;

  /// No description provided for @standings_teamAthletes.
  ///
  /// In vi, this message translates to:
  /// **'Đội VĐV'**
  String get standings_teamAthletes;

  /// No description provided for @standings_matches.
  ///
  /// In vi, this message translates to:
  /// **'Trận'**
  String get standings_matches;

  /// No description provided for @standings_playedShort.
  ///
  /// In vi, this message translates to:
  /// **'MP'**
  String get standings_playedShort;

  /// No description provided for @standings_wonShort.
  ///
  /// In vi, this message translates to:
  /// **'W'**
  String get standings_wonShort;

  /// No description provided for @standings_drawnShort.
  ///
  /// In vi, this message translates to:
  /// **'D'**
  String get standings_drawnShort;

  /// No description provided for @standings_lostShort.
  ///
  /// In vi, this message translates to:
  /// **'L'**
  String get standings_lostShort;

  /// No description provided for @standings_pointsForShort.
  ///
  /// In vi, this message translates to:
  /// **'GF'**
  String get standings_pointsForShort;

  /// No description provided for @standings_pointsAgainstShort.
  ///
  /// In vi, this message translates to:
  /// **'GA'**
  String get standings_pointsAgainstShort;

  /// No description provided for @standings_differenceShort.
  ///
  /// In vi, this message translates to:
  /// **'GD'**
  String get standings_differenceShort;

  /// No description provided for @standings_pointsShort.
  ///
  /// In vi, this message translates to:
  /// **'Pts'**
  String get standings_pointsShort;

  /// No description provided for @standings_winsShort.
  ///
  /// In vi, this message translates to:
  /// **'T'**
  String get standings_winsShort;

  /// No description provided for @standings_lossesShort.
  ///
  /// In vi, this message translates to:
  /// **'B'**
  String get standings_lossesShort;

  /// No description provided for @standings_points.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get standings_points;

  /// No description provided for @standings_difference.
  ///
  /// In vi, this message translates to:
  /// **'Hiệu số'**
  String get standings_difference;

  /// No description provided for @standings_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String standings_error(Object error);

  /// No description provided for @createClub_title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo câu lạc bộ'**
  String get createClub_title;

  /// No description provided for @createClub_nameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên câu lạc bộ *'**
  String get createClub_nameLabel;

  /// No description provided for @createClub_nameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Tên phải ít nhất 3 ký tự'**
  String get createClub_nameRequired;

  /// No description provided for @createClub_nameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: CLB Cầu lông ABC'**
  String get createClub_nameHint;

  /// No description provided for @createClub_sportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thể thao'**
  String get createClub_sportLabel;

  /// No description provided for @createClub_descriptionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả (không bắt buộc)'**
  String get createClub_descriptionLabel;

  /// No description provided for @createClub_descriptionHint.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu về câu lạc bộ...'**
  String get createClub_descriptionHint;

  /// No description provided for @createClub_rulesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội quy (không bắt buộc)'**
  String get createClub_rulesLabel;

  /// No description provided for @createClub_rulesHint.
  ///
  /// In vi, this message translates to:
  /// **'1. Tôn trọng lẫn nhau\\n2. Đúng giờ...'**
  String get createClub_rulesHint;

  /// No description provided for @createClub_locationLabel.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực hoạt động'**
  String get createClub_locationLabel;

  /// No description provided for @createClub_locationHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: 3/9 Thành Thái, Phường Diên Hồng, TP.HCM'**
  String get createClub_locationHint;

  /// No description provided for @createClub_autoDetected.
  ///
  /// In vi, this message translates to:
  /// **'Đã tự nhận diện: {location}'**
  String createClub_autoDetected(Object location);

  /// No description provided for @createClub_visibilityLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị câu lạc bộ'**
  String get createClub_visibilityLabel;

  /// No description provided for @createClub_joinMethodLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức tham gia'**
  String get createClub_joinMethodLabel;

  /// No description provided for @createClub_submitting.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo...'**
  String get createClub_submitting;

  /// No description provided for @createClub_submit.
  ///
  /// In vi, this message translates to:
  /// **'Tạo câu lạc bộ'**
  String get createClub_submit;

  /// No description provided for @createClub_success.
  ///
  /// In vi, this message translates to:
  /// **'Tạo câu lạc bộ thành công!'**
  String get createClub_success;

  /// No description provided for @createClub_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String createClub_error(Object error);

  /// No description provided for @createClub_primarySportError.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy môn thể thao đã chọn. Vui lòng thử lại.'**
  String get createClub_primarySportError;

  /// No description provided for @createClub_provinceRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn tỉnh/thành phố'**
  String get createClub_provinceRequired;

  /// No description provided for @createClub_provinceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tỉnh/thành phố *'**
  String get createClub_provinceLabel;

  /// No description provided for @createClub_wardLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phường/xã'**
  String get createClub_wardLabel;

  /// No description provided for @createClub_provinceLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tỉnh/thành'**
  String get createClub_provinceLoadError;

  /// No description provided for @createClub_wardLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được phường/xã'**
  String get createClub_wardLoadError;

  /// No description provided for @createClub_coverImageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh bìa'**
  String get createClub_coverImageTitle;

  /// No description provided for @createClub_logoImageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn logo / avatar'**
  String get createClub_logoImageTitle;

  /// No description provided for @createClub_photoLibrary.
  ///
  /// In vi, this message translates to:
  /// **'Thư viện ảnh'**
  String get createClub_photoLibrary;

  /// No description provided for @createClub_camera.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get createClub_camera;

  /// No description provided for @createClub_logoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Logo / avatar'**
  String get createClub_logoTitle;

  /// No description provided for @createClub_bannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bìa'**
  String get createClub_bannerTitle;

  /// No description provided for @createClub_removeImage.
  ///
  /// In vi, this message translates to:
  /// **'Gỡ ảnh'**
  String get createClub_removeImage;

  /// No description provided for @createClub_imageTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'{type} không được vượt quá {maxMb}MB'**
  String createClub_imageTooLarge(Object type, Object maxMb);

  /// No description provided for @createClub_questionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi xin vào (tối đa 5)'**
  String get createClub_questionsTitle;

  /// No description provided for @createClub_questionHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Bạn đang chơi ở trình độ nào?'**
  String get createClub_questionHint;

  /// No description provided for @createClub_visibilityPublic.
  ///
  /// In vi, this message translates to:
  /// **'Công khai'**
  String get createClub_visibilityPublic;

  /// No description provided for @createClub_visibilityPublicDescription.
  ///
  /// In vi, this message translates to:
  /// **'Ai cũng có thể tìm thấy CLB'**
  String get createClub_visibilityPublicDescription;

  /// No description provided for @createClub_visibilityPrivate.
  ///
  /// In vi, this message translates to:
  /// **'Riêng tư'**
  String get createClub_visibilityPrivate;

  /// No description provided for @createClub_visibilityPrivateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thành viên mới xem được nội dung'**
  String get createClub_visibilityPrivateDescription;

  /// No description provided for @createClub_visibilityRestricted.
  ///
  /// In vi, this message translates to:
  /// **'Hạn chế'**
  String get createClub_visibilityRestricted;

  /// No description provided for @createClub_visibilityRestrictedDescription.
  ///
  /// In vi, this message translates to:
  /// **'Hiện khi tìm kiếm, cần tham gia để xem'**
  String get createClub_visibilityRestrictedDescription;

  /// No description provided for @createClub_joinOpen.
  ///
  /// In vi, this message translates to:
  /// **'Tự do'**
  String get createClub_joinOpen;

  /// No description provided for @createClub_joinOpenDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bất kỳ ai cũng có thể tham gia'**
  String get createClub_joinOpenDescription;

  /// No description provided for @createClub_joinApproval.
  ///
  /// In vi, this message translates to:
  /// **'Xét duyệt'**
  String get createClub_joinApproval;

  /// No description provided for @createClub_joinApprovalDescription.
  ///
  /// In vi, this message translates to:
  /// **'Cần được phê duyệt khi tham gia'**
  String get createClub_joinApprovalDescription;

  /// No description provided for @createClub_joinInviteOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mời'**
  String get createClub_joinInviteOnly;

  /// No description provided for @createClub_joinInviteOnlyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ thành viên được mời mới tham gia'**
  String get createClub_joinInviteOnlyDescription;

  /// No description provided for @registerRankingConsentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đồng ý hiển thị kết quả và điểm ELO trên bảng xếp hạng'**
  String get registerRankingConsentTitle;

  /// No description provided for @registerRankingConsentDescription.
  ///
  /// In vi, this message translates to:
  /// **'Giải có xếp hạng chỉ ghi nhận ELO sau khi bạn đồng ý.'**
  String get registerRankingConsentDescription;

  /// No description provided for @registerPublicBracketElo.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ thi đấu công khai, tích lũy điểm ELO tự động sau giải'**
  String get registerPublicBracketElo;

  /// No description provided for @registerAdditionalInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng ký bổ sung'**
  String get registerAdditionalInfoTitle;

  /// No description provided for @registerAdditionalInfoDescription.
  ///
  /// In vi, this message translates to:
  /// **'Ban tổ chức yêu cầu các thông tin dưới đây cho nội dung bạn đã chọn.'**
  String get registerAdditionalInfoDescription;

  /// No description provided for @registerDetailsContent.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get registerDetailsContent;

  /// No description provided for @registerDetailsFormat.
  ///
  /// In vi, this message translates to:
  /// **'Hình thức'**
  String get registerDetailsFormat;

  /// No description provided for @registerDetailsStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái hồ sơ'**
  String get registerDetailsStatus;

  /// No description provided for @registerDetailsPendingApproval.
  ///
  /// In vi, this message translates to:
  /// **'Chờ BTC duyệt'**
  String get registerDetailsPendingApproval;

  /// No description provided for @registerDetailsWaitlisted.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách chờ'**
  String get registerDetailsWaitlisted;

  /// No description provided for @registerDetailsApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã được duyệt'**
  String get registerDetailsApproved;

  /// No description provided for @registerDetailsRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký'**
  String get registerDetailsRegistered;

  /// No description provided for @registerDetailsPayment.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán'**
  String get registerDetailsPayment;

  /// No description provided for @registerDetailsPaid.
  ///
  /// In vi, this message translates to:
  /// **'Đã thanh toán'**
  String get registerDetailsPaid;

  /// No description provided for @registerDetailsUnpaid.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thanh toán'**
  String get registerDetailsUnpaid;

  /// No description provided for @registerViewInviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Xem mã mời & Link ghép đôi'**
  String get registerViewInviteCode;

  /// No description provided for @registerPayNow.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán {amount}đ'**
  String registerPayNow(Object amount);

  /// No description provided for @registerFeePending2.
  ///
  /// In vi, this message translates to:
  /// **'Phí tham gia {amount}đ chưa thanh toán'**
  String registerFeePending2(Object amount);

  /// No description provided for @registerApprovalSuccessTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu thành công!'**
  String get registerApprovalSuccessTitle;

  /// No description provided for @registerLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String registerLoadError(Object error);

  /// No description provided for @registerCustomFieldRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng điền “{label}”.'**
  String registerCustomFieldRequired(Object label);

  /// No description provided for @registerCustomFieldEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'“{label}” phải là email hợp lệ.'**
  String registerCustomFieldEmailInvalid(Object label);

  /// No description provided for @registerCustomFieldNumberInvalid.
  ///
  /// In vi, this message translates to:
  /// **'“{label}” phải là số.'**
  String registerCustomFieldNumberInvalid(Object label);

  /// No description provided for @registerCustomFieldMin.
  ///
  /// In vi, this message translates to:
  /// **'“{label}” không được nhỏ hơn {min}.'**
  String registerCustomFieldMin(Object label, Object min);

  /// No description provided for @registerCustomFieldMax.
  ///
  /// In vi, this message translates to:
  /// **'“{label}” không được lớn hơn {max}.'**
  String registerCustomFieldMax(Object label, Object max);

  /// No description provided for @registerCustomFieldSelectInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn của “{label}” không hợp lệ.'**
  String registerCustomFieldSelectInvalid(Object label);

  /// No description provided for @registerCustomFieldCheckboxRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần xác nhận “{label}”.'**
  String registerCustomFieldCheckboxRequired(Object label);

  /// No description provided for @autoDraw_saved.
  ///
  /// In vi, this message translates to:
  /// **'Bốc thăm và lưu thành công!'**
  String get autoDraw_saved;

  /// No description provided for @autoDraw_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String autoDraw_error(Object error);

  /// No description provided for @autoDraw_title.
  ///
  /// In vi, this message translates to:
  /// **'Bốc thăm & Phân bảng'**
  String get autoDraw_title;

  /// No description provided for @autoDraw_tournamentError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi giải đấu'**
  String get autoDraw_tournamentError;

  /// No description provided for @autoDraw_teamCount.
  ///
  /// In vi, this message translates to:
  /// **'Tổng số đội: {count}'**
  String autoDraw_teamCount(Object count);

  /// No description provided for @autoDraw_format.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức: {format}'**
  String autoDraw_format(Object format);

  /// No description provided for @autoDraw_startedLocked.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đang diễn ra. Chức năng làm lại sơ đồ đã bị khóa.'**
  String get autoDraw_startedLocked;

  /// No description provided for @autoDraw_redraw.
  ///
  /// In vi, this message translates to:
  /// **'Làm lại sơ đồ'**
  String get autoDraw_redraw;

  /// No description provided for @autoDraw_auto.
  ///
  /// In vi, this message translates to:
  /// **'Bốc thăm tự động'**
  String get autoDraw_auto;

  /// No description provided for @autoDraw_manual.
  ///
  /// In vi, this message translates to:
  /// **'Bốc thăm từng đội'**
  String get autoDraw_manual;

  /// No description provided for @autoDraw_remaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} đội chưa bốc'**
  String autoDraw_remaining(Object count);

  /// No description provided for @autoDraw_oneTeam.
  ///
  /// In vi, this message translates to:
  /// **'Bốc 1 đội'**
  String get autoDraw_oneTeam;

  /// No description provided for @autoDraw_revealAll.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tất cả'**
  String get autoDraw_revealAll;

  /// No description provided for @autoDraw_bye.
  ///
  /// In vi, this message translates to:
  /// **'ĐẶC CÁCH VÀO VÒNG TRONG'**
  String get autoDraw_bye;

  /// No description provided for @autoDraw_vs.
  ///
  /// In vi, this message translates to:
  /// **'VS'**
  String get autoDraw_vs;

  /// No description provided for @autoDraw_previewHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn Bốc thăm để xem trước các cặp đấu'**
  String get autoDraw_previewHint;

  /// No description provided for @autoDraw_saveStart.
  ///
  /// In vi, this message translates to:
  /// **'Lưu & Bắt đầu giải'**
  String get autoDraw_saveStart;

  /// No description provided for @autoDraw_matchLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải trận đấu: {error}'**
  String autoDraw_matchLoadError(Object error);

  /// No description provided for @teamList_invalidImport.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dữ liệu hợp lệ trong file'**
  String get teamList_invalidImport;

  /// No description provided for @teamList_importSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Import thành công {count} đội!'**
  String teamList_importSuccess(Object count);

  /// No description provided for @teamList_importError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi import: {error}'**
  String teamList_importError(Object error);

  /// No description provided for @teamList_deleteAllTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ?'**
  String get teamList_deleteAllTitle;

  /// No description provided for @teamList_deleteAllContent.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn xóa TOÀN BỘ các đội bóng?\n\nHành động này cũng sẽ xóa toàn bộ sơ đồ/kết quả thi đấu của giải.'**
  String get teamList_deleteAllContent;

  /// No description provided for @teamList_deleteAllConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tất cả'**
  String get teamList_deleteAllConfirm;

  /// No description provided for @teamList_deleteAllDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa toàn bộ đội bóng!'**
  String get teamList_deleteAllDone;

  /// No description provided for @teamList_error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi: {error}'**
  String teamList_error(Object error);

  /// No description provided for @teamList_title.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý đội / VĐV'**
  String get teamList_title;

  /// No description provided for @teamList_importTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Import từ Excel'**
  String get teamList_importTooltip;

  /// No description provided for @teamList_deleteAll.
  ///
  /// In vi, this message translates to:
  /// **'Xóa toàn bộ đội'**
  String get teamList_deleteAll;

  /// No description provided for @teamList_empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đội nào'**
  String get teamList_empty;

  /// No description provided for @teamList_addNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm đội mới'**
  String get teamList_addNew;

  /// No description provided for @teamList_locked.
  ///
  /// In vi, this message translates to:
  /// **'Giải đấu đang diễn ra. Không thể thêm đội.'**
  String get teamList_locked;

  /// No description provided for @teamList_add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm đội'**
  String get teamList_add;

  /// No description provided for @teamList_approved.
  ///
  /// In vi, this message translates to:
  /// **'✓ Đã duyệt'**
  String get teamList_approved;

  /// No description provided for @teamList_deleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đội'**
  String get teamList_deleteTitle;

  /// No description provided for @teamList_deleteContent.
  ///
  /// In vi, this message translates to:
  /// **'Xóa đội {name}?'**
  String teamList_deleteContent(Object name);

  /// No description provided for @teamList_deleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get teamList_deleteConfirm;

  /// No description provided for @teamList_deleteError.
  ///
  /// In vi, this message translates to:
  /// **'{error}'**
  String teamList_deleteError(Object error);

  /// No description provided for @transactionsAmount.
  ///
  /// In vi, this message translates to:
  /// **'{amount} đ'**
  String transactionsAmount(Object amount);

  /// No description provided for @refereeInvitesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lời mời trọng tài'**
  String get refereeInvitesTitle;

  /// No description provided for @refereeInviteAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận lời mời trọng tài'**
  String get refereeInviteAccepted;

  /// No description provided for @refereeInviteDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối lời mời trọng tài'**
  String get refereeInviteDeclined;

  /// No description provided for @refereeInviteActionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xử lý lời mời: {error}'**
  String refereeInviteActionError(Object error);

  /// No description provided for @refereeInvitesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Không có lời mời nào'**
  String get refereeInvitesEmpty;

  /// No description provided for @refereeInvitesEmptyDescription.
  ///
  /// In vi, this message translates to:
  /// **'Khi ban tổ chức mời bạn làm trọng tài, lời mời sẽ hiện tại đây.'**
  String get refereeInvitesEmptyDescription;

  /// No description provided for @refereeInvitesLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải lời mời trọng tài'**
  String get refereeInvitesLoadError;

  /// No description provided for @refereeInvitesRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get refereeInvitesRetry;

  /// No description provided for @officialScore_overrideReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do ngoại lệ bắt buộc...'**
  String get officialScore_overrideReasonHint;

  /// No description provided for @officialScore_completeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chốt kết quả trận đấu'**
  String get officialScore_completeTitle;

  /// No description provided for @officialScore_saveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận lưu kết quả'**
  String get officialScore_saveTitle;

  /// No description provided for @officialScore_completeContent.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả đã đủ điều kiện. Chốt trận để công khai điểm và cập nhật giải đấu?'**
  String get officialScore_completeContent;

  /// No description provided for @officialScore_saveContent.
  ///
  /// In vi, this message translates to:
  /// **'Lưu kết quả hiện tại theo ngoại lệ của trọng tài? Hành động này sẽ được ghi vào lịch sử trận.'**
  String get officialScore_saveContent;

  /// No description provided for @officialScore_saving.
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu...'**
  String get officialScore_saving;

  /// No description provided for @officialScore_penaltySelectionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn đội bị phạt trước khi ghi nhận.'**
  String get officialScore_penaltySelectionRequired;

  /// No description provided for @officialScore_penaltyReasonLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lý do / ghi chú'**
  String get officialScore_penaltyReasonLabel;

  /// No description provided for @officialScore_penaltyReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do nếu cần'**
  String get officialScore_penaltyReasonHint;

  /// No description provided for @officialScore_penaltyConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận ghi phạt'**
  String get officialScore_penaltyConfirmTitle;

  /// No description provided for @officialScore_penaltyConfirmContent.
  ///
  /// In vi, this message translates to:
  /// **'{penalty} cho {team}. Tiếp tục ghi nhận?'**
  String officialScore_penaltyConfirmContent(Object penalty, Object team);

  /// No description provided for @officialScore_matchInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin & Cài đặt trận đấu'**
  String get officialScore_matchInfoTitle;

  /// No description provided for @officialScore_sport.
  ///
  /// In vi, this message translates to:
  /// **'Môn: {sport}'**
  String officialScore_sport(Object sport);

  /// No description provided for @officialScore_format.
  ///
  /// In vi, this message translates to:
  /// **'Thể thức: BO{bestOf}'**
  String officialScore_format(Object bestOf);

  /// No description provided for @officialScore_setsToWin.
  ///
  /// In vi, this message translates to:
  /// **'Số set thắng: {count} set'**
  String officialScore_setsToWin(Object count);

  /// No description provided for @officialScore_pointsPerSet.
  ///
  /// In vi, this message translates to:
  /// **'Mốc set: {points} {unit}'**
  String officialScore_pointsPerSet(Object points, Object unit);

  /// No description provided for @officialScore_maxPoints.
  ///
  /// In vi, this message translates to:
  /// **'Trần điểm: {points}'**
  String officialScore_maxPoints(Object points);

  /// No description provided for @officialScore_court.
  ///
  /// In vi, this message translates to:
  /// **'Sân: {court}'**
  String officialScore_court(Object court);

  /// No description provided for @officialScore_round.
  ///
  /// In vi, this message translates to:
  /// **'Vòng: {round}'**
  String officialScore_round(Object round);

  /// No description provided for @officialScore_penaltyRulesDescription.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi được áp dụng theo luật môn và cấu hình giải. BO{bestOf} · {points} điểm/set'**
  String officialScore_penaltyRulesDescription(Object bestOf, Object points);

  /// No description provided for @officialScore_penaltyOptionsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mức phạt được phép chọn'**
  String get officialScore_penaltyOptionsTitle;

  /// No description provided for @officialScore_penalizedTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội bị phạt'**
  String get officialScore_penalizedTeam;

  /// No description provided for @officialScore_scoringTennisSet.
  ///
  /// In vi, this message translates to:
  /// **'Game/Set'**
  String get officialScore_scoringTennisSet;

  /// No description provided for @officialScore_scoringPickleballSideOut.
  ///
  /// In vi, this message translates to:
  /// **'Pickleball side-out'**
  String get officialScore_scoringPickleballSideOut;

  /// No description provided for @officialScore_scoringRallyPoint.
  ///
  /// In vi, this message translates to:
  /// **'Rally point'**
  String get officialScore_scoringRallyPoint;

  /// No description provided for @officialScore_gameSetUnit.
  ///
  /// In vi, this message translates to:
  /// **'game/set'**
  String get officialScore_gameSetUnit;

  /// No description provided for @officialScore_pointsSetUnit.
  ///
  /// In vi, this message translates to:
  /// **'điểm/set'**
  String get officialScore_pointsSetUnit;

  /// No description provided for @officialScore_penaltyRulesTennis.
  ///
  /// In vi, this message translates to:
  /// **'Tennis không dùng thẻ màu riêng; có cảnh báo, vi phạm tác phong, phạt điểm và phạt game.'**
  String get officialScore_penaltyRulesTennis;

  /// No description provided for @officialScore_penaltyRulesPickleball.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kỹ thuật được ghi nhận riêng; không tự động cộng điểm khi chưa có quyết định xử điểm.'**
  String get officialScore_penaltyRulesPickleball;

  /// No description provided for @officialScore_penaltyRulesTableTennis.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo, lỗi kỹ thuật và thẻ được ghi nhận theo preset bóng bàn của hệ thống.'**
  String get officialScore_penaltyRulesTableTennis;

  /// No description provided for @officialScore_penaltyRulesBadminton.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo, lỗi kỹ thuật và thẻ được ghi nhận theo quyết định của trọng tài/BTC.'**
  String get officialScore_penaltyRulesBadminton;

  /// No description provided for @officialScore_penaltyRulesDefault.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng theo quy định cụ thể của giải đấu và ban tổ chức.'**
  String get officialScore_penaltyRulesDefault;

  /// No description provided for @officialScore_penaltyServiceFaultBadminton.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi giao cầu'**
  String get officialScore_penaltyServiceFaultBadminton;

  /// No description provided for @officialScore_penaltyServiceFault.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi giao bóng'**
  String get officialScore_penaltyServiceFault;

  /// No description provided for @officialScore_penaltyMisconduct.
  ///
  /// In vi, this message translates to:
  /// **'Hành vi không đúng mực'**
  String get officialScore_penaltyMisconduct;

  /// No description provided for @officialScore_penaltyCodeViolation.
  ///
  /// In vi, this message translates to:
  /// **'Vi phạm tác phong'**
  String get officialScore_penaltyCodeViolation;

  /// No description provided for @officialScore_penaltyTechnicalFault.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kỹ thuật'**
  String get officialScore_penaltyTechnicalFault;

  /// No description provided for @officialScore_penaltyUnsportsmanlike.
  ///
  /// In vi, this message translates to:
  /// **'Thi đấu thiếu fair-play'**
  String get officialScore_penaltyUnsportsmanlike;

  /// No description provided for @officialScore_penaltyFoul.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi / Truất quyền'**
  String get officialScore_penaltyFoul;

  /// No description provided for @officialScore_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get officialScore_close;

  /// No description provided for @bracketView_searchHint.
  ///
  /// In vi, this message translates to:
  /// **'Tìm kiếm theo tên người chơi hoặc tên đội...'**
  String get bracketView_searchHint;

  /// No description provided for @bracketView_statusTitle.
  ///
  /// In vi, this message translates to:
  /// **'TRẠNG THÁI:'**
  String get bracketView_statusTitle;

  /// No description provided for @bracketView_live.
  ///
  /// In vi, this message translates to:
  /// **'Trực tiếp'**
  String get bracketView_live;

  /// No description provided for @bracketView_scheduled.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đấu'**
  String get bracketView_scheduled;

  /// No description provided for @bracketView_completed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong'**
  String get bracketView_completed;

  /// No description provided for @bracketView_branchTitle.
  ///
  /// In vi, this message translates to:
  /// **'NHÁNH THI ĐẤU:'**
  String get bracketView_branchTitle;

  /// No description provided for @bracketView_winners.
  ///
  /// In vi, this message translates to:
  /// **'Nhánh thắng'**
  String get bracketView_winners;

  /// No description provided for @bracketView_losers.
  ///
  /// In vi, this message translates to:
  /// **'Nhánh thua'**
  String get bracketView_losers;

  /// No description provided for @bracketView_stageTitle.
  ///
  /// In vi, this message translates to:
  /// **'GIAI ĐOẠN:'**
  String get bracketView_stageTitle;

  /// No description provided for @bracketView_groupStage.
  ///
  /// In vi, this message translates to:
  /// **'Vòng bảng'**
  String get bracketView_groupStage;

  /// No description provided for @bracketView_knockoutStage.
  ///
  /// In vi, this message translates to:
  /// **'Vòng Knockout'**
  String get bracketView_knockoutStage;

  /// No description provided for @bracketView_groupTitle.
  ///
  /// In vi, this message translates to:
  /// **'BẢNG ĐẤU:'**
  String get bracketView_groupTitle;

  /// No description provided for @bracketView_roundTitle.
  ///
  /// In vi, this message translates to:
  /// **'VÒNG ĐẤU:'**
  String get bracketView_roundTitle;

  /// No description provided for @bracketView_round.
  ///
  /// In vi, this message translates to:
  /// **'Vòng {round}'**
  String bracketView_round(Object round);

  /// No description provided for @bracketView_knockoutMap.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ Knockout'**
  String get bracketView_knockoutMap;

  /// No description provided for @bracketView_doubleEliminationMap.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ loại kép'**
  String get bracketView_doubleEliminationMap;

  /// No description provided for @bracketView_roundRobinMap.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ Vòng tròn'**
  String get bracketView_roundRobinMap;

  /// No description provided for @bracketView_noMatches.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có trận đấu nào'**
  String get bracketView_noMatches;

  /// No description provided for @bracketView_noMatchingMatches.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy trận đấu phù hợp'**
  String get bracketView_noMatchingMatches;

  /// No description provided for @bracketView_drawHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bốc thăm để tạo sơ đồ thi đấu'**
  String get bracketView_drawHint;

  /// No description provided for @bracketView_crossTable.
  ///
  /// In vi, this message translates to:
  /// **'Bảng chéo'**
  String get bracketView_crossTable;

  /// No description provided for @bracketView_standings.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get bracketView_standings;

  /// No description provided for @bracketView_schedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch thi đấu'**
  String get bracketView_schedule;

  /// No description provided for @bracketView_rateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống đang giới hạn yêu cầu. Vui lòng thử lại sau ít giây.'**
  String get bracketView_rateLimited;

  /// No description provided for @bracketView_loadError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải dữ liệu bảng thi đấu.'**
  String get bracketView_loadError;

  /// No description provided for @bracketView_unknownParticipant.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get bracketView_unknownParticipant;

  /// No description provided for @bracketView_officialResults.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả chính thức'**
  String get bracketView_officialResults;

  /// No description provided for @bracketView_sharedRank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {rank} đồng hạng'**
  String bracketView_sharedRank(Object rank);

  /// No description provided for @bracketView_rank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {rank}'**
  String bracketView_rank(Object rank);

  /// No description provided for @bracketView_knockoutTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ Loại trực tiếp'**
  String get bracketView_knockoutTitle;

  /// No description provided for @bracketView_knockoutDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhánh đấu loại trực tiếp các đội vượt qua vòng bảng'**
  String get bracketView_knockoutDescription;

  /// No description provided for @bracketView_doubleEliminationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem phân nhánh thắng và nhánh thua (Double Elimination)'**
  String get bracketView_doubleEliminationDescription;

  /// No description provided for @bracketView_roundRobinDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem sơ đồ thi đấu các lượt trận vòng tròn'**
  String get bracketView_roundRobinDescription;

  /// No description provided for @bracketView_singleEliminationDescription.
  ///
  /// In vi, this message translates to:
  /// **'Xem phân nhánh đấu loại trực tiếp (Single Elimination)'**
  String get bracketView_singleEliminationDescription;

  /// No description provided for @communitySocial_deletePostTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bài viết?'**
  String get communitySocial_deletePostTitle;

  /// No description provided for @communitySocial_deletePostContent.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết sẽ bị xóa khỏi bảng tin. Bạn có chắc chắn không?'**
  String get communitySocial_deletePostContent;

  /// No description provided for @communitySocial_delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get communitySocial_delete;

  /// No description provided for @communitySocial_postDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa bài viết.'**
  String get communitySocial_postDeleted;

  /// No description provided for @communitySocial_postDeleteError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa bài viết.'**
  String get communitySocial_postDeleteError;

  /// No description provided for @communitySocial_defaultUser.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get communitySocial_defaultUser;

  /// No description provided for @communitySocial_defaultMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get communitySocial_defaultMember;

  /// No description provided for @communitySocial_postingDisabled.
  ///
  /// In vi, this message translates to:
  /// **'CLB đang tắt đăng bài.'**
  String get communitySocial_postingDisabled;

  /// No description provided for @communitySocial_joinToPost.
  ///
  /// In vi, this message translates to:
  /// **'Hãy tham gia CLB để đăng bài.'**
  String get communitySocial_joinToPost;

  /// No description provided for @communitySocial_openChat.
  ///
  /// In vi, this message translates to:
  /// **'Mở trò chuyện CLB'**
  String get communitySocial_openChat;

  /// No description provided for @communitySocial_recentMatches.
  ///
  /// In vi, this message translates to:
  /// **'Trận gần đây'**
  String get communitySocial_recentMatches;

  /// No description provided for @communitySocial_eloBoard.
  ///
  /// In vi, this message translates to:
  /// **'Bảng ELO'**
  String get communitySocial_eloBoard;

  /// No description provided for @communitySocial_emptyFeed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bài đăng nào. Hãy chia sẻ điều đầu tiên!'**
  String get communitySocial_emptyFeed;

  /// No description provided for @communitySocial_retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get communitySocial_retry;

  /// No description provided for @withdraw_title.
  ///
  /// In vi, this message translates to:
  /// **'Rút lui'**
  String get withdraw_title;

  /// No description provided for @withdraw_refundProfileDescription.
  ///
  /// In vi, this message translates to:
  /// **'Tiền hoàn sẽ được chuyển vào tài khoản ngân hàng trong hồ sơ của bạn.'**
  String get withdraw_refundProfileDescription;

  /// No description provided for @withdraw_refundInputDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đóng phí. Vui lòng nhập thông tin ngân hàng để nhận hoàn tiền (sẽ được lưu vào hồ sơ).'**
  String get withdraw_refundInputDescription;

  /// No description provided for @withdraw_freeDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn rút lui khỏi giải đấu này?'**
  String get withdraw_freeDescription;

  /// No description provided for @withdraw_bankNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên ngân hàng'**
  String get withdraw_bankNameLabel;

  /// No description provided for @withdraw_bankNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Vietcombank, Techcombank'**
  String get withdraw_bankNameHint;

  /// No description provided for @withdraw_bankNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên ngân hàng'**
  String get withdraw_bankNameRequired;

  /// No description provided for @withdraw_accountNumberLabel.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản'**
  String get withdraw_accountNumberLabel;

  /// No description provided for @withdraw_accountNumberHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập số tài khoản'**
  String get withdraw_accountNumberHint;

  /// No description provided for @withdraw_accountNumberInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Số tài khoản không hợp lệ'**
  String get withdraw_accountNumberInvalid;

  /// No description provided for @withdraw_accountNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chủ tài khoản'**
  String get withdraw_accountNameLabel;

  /// No description provided for @withdraw_accountNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VIẾT HOA KHÔNG DẤU'**
  String get withdraw_accountNameHint;

  /// No description provided for @withdraw_accountNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Nhập tên chủ tài khoản'**
  String get withdraw_accountNameRequired;

  /// No description provided for @withdraw_irreversibleWarning.
  ///
  /// In vi, this message translates to:
  /// **'Hành động này không thể hoàn tác.'**
  String get withdraw_irreversibleWarning;

  /// No description provided for @withdraw_processing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get withdraw_processing;

  /// No description provided for @withdraw_confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận rút lui'**
  String get withdraw_confirm;

  /// No description provided for @withdraw_refundSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã rút lui. Tiền hoàn sẽ được xử lý trong 3–5 ngày.'**
  String get withdraw_refundSuccess;

  /// No description provided for @withdraw_success.
  ///
  /// In vi, this message translates to:
  /// **'Đã rút lui khỏi giải đấu'**
  String get withdraw_success;

  /// No description provided for @withdraw_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể rút lui khỏi giải đấu. Vui lòng thử lại.'**
  String get withdraw_error;

  /// No description provided for @withdraw_bankInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng hoàn tiền'**
  String get withdraw_bankInfoTitle;

  /// No description provided for @withdraw_change.
  ///
  /// In vi, this message translates to:
  /// **'Đổi'**
  String get withdraw_change;

  /// No description provided for @withdraw_bankLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngân hàng'**
  String get withdraw_bankLabel;

  /// No description provided for @withdraw_accountNumberShort.
  ///
  /// In vi, this message translates to:
  /// **'Số TK'**
  String get withdraw_accountNumberShort;

  /// No description provided for @withdraw_accountNameShort.
  ///
  /// In vi, this message translates to:
  /// **'Chủ TK'**
  String get withdraw_accountNameShort;

  /// No description provided for @communityPoll_registrationJoined.
  ///
  /// In vi, this message translates to:
  /// **'Đã bình chọn và đăng ký tham gia giải.'**
  String get communityPoll_registrationJoined;

  /// No description provided for @communityPoll_registrationWithdrawn.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận lựa chọn và hủy đăng ký giải.'**
  String get communityPoll_registrationWithdrawn;

  /// No description provided for @communityPoll_registrationJoinPending.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận bình chọn nhưng chưa đăng ký được giải.'**
  String get communityPoll_registrationJoinPending;

  /// No description provided for @communityPoll_registrationWithdrawPending.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghi nhận bình chọn nhưng chưa hủy được đăng ký giải.'**
  String get communityPoll_registrationWithdrawPending;

  /// No description provided for @communityPoll_voteError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể ghi nhận bình chọn.'**
  String get communityPoll_voteError;

  /// No description provided for @communityPoll_addOptionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lựa chọn'**
  String get communityPoll_addOptionTitle;

  /// No description provided for @communityPoll_optionHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lựa chọn'**
  String get communityPoll_optionHint;

  /// No description provided for @communityPoll_add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get communityPoll_add;

  /// No description provided for @communityPoll_addOptionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể thêm lựa chọn.'**
  String get communityPoll_addOptionError;

  /// No description provided for @communityPoll_closed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng'**
  String get communityPoll_closed;

  /// No description provided for @communityPoll_multipleHint.
  ///
  /// In vi, this message translates to:
  /// **'Có thể chọn một hoặc nhiều lựa chọn.'**
  String get communityPoll_multipleHint;

  /// No description provided for @communityPoll_singleHint.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ được chọn một lựa chọn.'**
  String get communityPoll_singleHint;

  /// No description provided for @communityPoll_tournamentHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Có để đăng ký; chọn Không để hủy đăng ký.'**
  String get communityPoll_tournamentHint;

  /// No description provided for @communityPoll_addOption.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lựa chọn'**
  String get communityPoll_addOption;

  /// No description provided for @communityPoll_voteCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt bình chọn'**
  String communityPoll_voteCount(Object count);

  /// No description provided for @teamAdd_createTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm đội / VĐV'**
  String get teamAdd_createTitle;

  /// No description provided for @teamAdd_editTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thông tin đội'**
  String get teamAdd_editTitle;

  /// No description provided for @teamAdd_nameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên đội / VĐV *'**
  String get teamAdd_nameLabel;

  /// No description provided for @teamAdd_nameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Đội Sấm sét'**
  String get teamAdd_nameHint;

  /// No description provided for @teamAdd_nameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên'**
  String get teamAdd_nameRequired;

  /// No description provided for @teamAdd_members.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get teamAdd_members;

  /// No description provided for @teamAdd_add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get teamAdd_add;

  /// No description provided for @teamAdd_memberHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên thành viên {index}'**
  String teamAdd_memberHint(Object index);

  /// No description provided for @teamAdd_contactEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email liên hệ (tùy chọn)'**
  String get teamAdd_contactEmail;

  /// No description provided for @teamAdd_save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu đội'**
  String get teamAdd_save;

  /// No description provided for @teamAdd_created.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm đội thành công!'**
  String get teamAdd_created;

  /// No description provided for @teamAdd_updated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật đội thành công!'**
  String get teamAdd_updated;

  /// No description provided for @teamAdd_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu thông tin đội. Vui lòng thử lại.'**
  String get teamAdd_error;

  /// No description provided for @matchBottom_overrideHint.
  ///
  /// In vi, this message translates to:
  /// **'Lý do override (ghi rõ lý do ngoại lệ)'**
  String get matchBottom_overrideHint;

  /// No description provided for @matchBottom_team1Wins.
  ///
  /// In vi, this message translates to:
  /// **'Đội 1 thắng'**
  String get matchBottom_team1Wins;

  /// No description provided for @matchBottom_team2Wins.
  ///
  /// In vi, this message translates to:
  /// **'Đội 2 thắng'**
  String get matchBottom_team2Wins;

  /// No description provided for @matchBottom_overrideAction.
  ///
  /// In vi, this message translates to:
  /// **'Override (chốt tỉ số ngoại lệ)'**
  String get matchBottom_overrideAction;

  /// No description provided for @matchBottom_cancelOverride.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ override'**
  String get matchBottom_cancelOverride;

  /// No description provided for @report_title.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo vi phạm'**
  String get report_title;

  /// No description provided for @report_description.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn lý do báo cáo. Thông tin của bạn sẽ được bảo mật.'**
  String get report_description;

  /// No description provided for @report_reasonSpam.
  ///
  /// In vi, this message translates to:
  /// **'Spam / Quảng cáo'**
  String get report_reasonSpam;

  /// No description provided for @report_reasonInappropriate.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung không phù hợp'**
  String get report_reasonInappropriate;

  /// No description provided for @report_reasonCheating.
  ///
  /// In vi, this message translates to:
  /// **'Gian lận'**
  String get report_reasonCheating;

  /// No description provided for @report_reasonOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get report_reasonOther;

  /// No description provided for @report_detailsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả chi tiết (không bắt buộc)'**
  String get report_detailsLabel;

  /// No description provided for @report_detailsHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lý do chi tiết...'**
  String get report_detailsHint;

  /// No description provided for @report_evidenceLabel.
  ///
  /// In vi, this message translates to:
  /// **'Minh chứng (không bắt buộc)'**
  String get report_evidenceLabel;

  /// No description provided for @report_uploadFile.
  ///
  /// In vi, this message translates to:
  /// **'Tải tệp'**
  String get report_uploadFile;

  /// No description provided for @report_uploadedCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/5 tệp đã tải lên'**
  String report_uploadedCount(Object count);

  /// No description provided for @report_submit.
  ///
  /// In vi, this message translates to:
  /// **'Gửi báo cáo'**
  String get report_submit;

  /// No description provided for @report_success.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn đã báo cáo. Chúng tôi sẽ xem xét.'**
  String get report_success;

  /// No description provided for @report_error.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi báo cáo. Hãy thử lại.'**
  String get report_error;

  /// No description provided for @report_fileTooLarge.
  ///
  /// In vi, this message translates to:
  /// **'Tệp tối đa 15MB.'**
  String get report_fileTooLarge;

  /// No description provided for @report_uploadError.
  ///
  /// In vi, this message translates to:
  /// **'Tải tệp thất bại. Vui lòng thử lại.'**
  String get report_uploadError;

  /// No description provided for @communityComment_title.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận'**
  String get communityComment_title;

  /// No description provided for @communityComment_close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get communityComment_close;

  /// No description provided for @communityComment_empty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bình luận nào.'**
  String get communityComment_empty;

  /// No description provided for @communityComment_emptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy là người đầu tiên chia sẻ ý kiến!'**
  String get communityComment_emptyHint;

  /// No description provided for @communityComment_loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get communityComment_loading;

  /// No description provided for @communityComment_loadMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm bình luận cũ hơn'**
  String get communityComment_loadMore;

  /// No description provided for @communityComment_deleteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa bình luận?'**
  String get communityComment_deleteTitle;

  /// No description provided for @communityComment_deleteDescription.
  ///
  /// In vi, this message translates to:
  /// **'Bình luận này và các câu trả lời sẽ bị xóa.'**
  String get communityComment_deleteDescription;

  /// No description provided for @communityComment_delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get communityComment_delete;

  /// No description provided for @communityComment_write.
  ///
  /// In vi, this message translates to:
  /// **'Viết bình luận…'**
  String get communityComment_write;

  /// No description provided for @communityComment_replyHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết câu trả lời cho {author}…'**
  String communityComment_replyHint(Object author);

  /// No description provided for @communityComment_send.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get communityComment_send;

  /// No description provided for @communityComment_member.
  ///
  /// In vi, this message translates to:
  /// **'thành viên'**
  String get communityComment_member;

  /// No description provided for @communityComment_replyingTo.
  ///
  /// In vi, this message translates to:
  /// **'Đang trả lời {author}'**
  String communityComment_replyingTo(Object author);

  /// No description provided for @communityComment_like.
  ///
  /// In vi, this message translates to:
  /// **'Thích'**
  String get communityComment_like;

  /// No description provided for @communityComment_reply.
  ///
  /// In vi, this message translates to:
  /// **'Trả lời'**
  String get communityComment_reply;

  /// No description provided for @communityComment_owner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ CLB'**
  String get communityComment_owner;

  /// No description provided for @communityComment_admin.
  ///
  /// In vi, this message translates to:
  /// **'BQT'**
  String get communityComment_admin;

  /// No description provided for @communityComment_justNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get communityComment_justNow;

  /// No description provided for @communityComment_minutes.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút'**
  String communityComment_minutes(Object count);

  /// No description provided for @communityComment_hours.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ'**
  String communityComment_hours(Object count);

  /// No description provided for @communityComment_days.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String communityComment_days(Object count);

  /// No description provided for @communityComment_loadMoreError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tải thêm bình luận.'**
  String get communityComment_loadMoreError;

  /// No description provided for @communityComment_submitError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể gửi bình luận.'**
  String get communityComment_submitError;

  /// No description provided for @communityComment_deleteError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa bình luận.'**
  String get communityComment_deleteError;

  /// No description provided for @communityComposer_mentionLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chỉ có thể gắn tối đa {count} thành viên.'**
  String communityComposer_mentionLimit(Object count);

  /// No description provided for @communityComposer_duplicateName.
  ///
  /// In vi, this message translates to:
  /// **'CLB có hai thành viên cùng tên. Hãy dùng tên khác để tránh nhầm lẫn.'**
  String get communityComposer_duplicateName;

  /// No description provided for @communityComposer_hint.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ điều gì đó với CLB… Gõ @ để nhắc tên'**
  String get communityComposer_hint;

  /// No description provided for @communityComposer_image.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get communityComposer_image;

  /// No description provided for @communityComposer_images.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {count}'**
  String communityComposer_images(Object count);

  /// No description provided for @communityComposer_tag.
  ///
  /// In vi, this message translates to:
  /// **'Gắn thẻ'**
  String get communityComposer_tag;

  /// No description provided for @communityComposer_post.
  ///
  /// In vi, this message translates to:
  /// **'Đăng'**
  String get communityComposer_post;

  /// No description provided for @communityComposer_tagTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn để gán nhãn thành viên'**
  String get communityComposer_tagTooltip;

  /// No description provided for @communityComposer_searchUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thể tìm thành viên'**
  String get communityComposer_searchUnavailable;

  /// No description provided for @communityComposer_noMembers.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thành viên'**
  String get communityComposer_noMembers;

  /// No description provided for @communityComposer_assignTagTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gán nhãn vui'**
  String get communityComposer_assignTagTooltip;

  /// No description provided for @communityPollBuilder_title.
  ///
  /// In vi, this message translates to:
  /// **'Tạo cuộc thăm dò ý kiến'**
  String get communityPollBuilder_title;

  /// No description provided for @communityPollBuilder_cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy bình chọn'**
  String get communityPollBuilder_cancel;

  /// No description provided for @communityPollBuilder_questionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi bình chọn *'**
  String get communityPollBuilder_questionLabel;

  /// No description provided for @communityPollBuilder_questionHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập câu hỏi hoặc chủ đề...'**
  String get communityPollBuilder_questionHint;

  /// No description provided for @communityPollBuilder_optionHint.
  ///
  /// In vi, this message translates to:
  /// **'Lựa chọn {number}'**
  String communityPollBuilder_optionHint(Object number);

  /// No description provided for @communityPollBuilder_addOption.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lựa chọn'**
  String get communityPollBuilder_addOption;

  /// No description provided for @communityPollBuilder_allowMultiple.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép chọn nhiều câu trả lời'**
  String get communityPollBuilder_allowMultiple;

  /// No description provided for @communityPollBuilder_allowAddOptions.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép mọi người thêm lựa chọn mới'**
  String get communityPollBuilder_allowAddOptions;

  /// No description provided for @communityPollBuilder_expiry.
  ///
  /// In vi, this message translates to:
  /// **'Thời hạn:'**
  String get communityPollBuilder_expiry;

  /// No description provided for @communityPollBuilder_noLimit.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get communityPollBuilder_noLimit;

  /// No description provided for @communityPollBuilder_days.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày'**
  String communityPollBuilder_days(Object count);

  /// No description provided for @clubSocialLinks_valueRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập giá trị liên kết.'**
  String get clubSocialLinks_valueRequired;

  /// No description provided for @clubSocialLinks_labelRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập nhãn liên kết.'**
  String get clubSocialLinks_labelRequired;

  /// No description provided for @clubSocialLinks_added.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm liên hệ mới!'**
  String get clubSocialLinks_added;

  /// No description provided for @clubSocialLinks_removed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa liên hệ!'**
  String get clubSocialLinks_removed;

  /// No description provided for @clubSocialLinks_other.
  ///
  /// In vi, this message translates to:
  /// **'Khác...'**
  String get clubSocialLinks_other;

  /// No description provided for @clubSocialLinks_customLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên kênh (Telegram, Viber...)'**
  String get clubSocialLinks_customLabel;

  /// No description provided for @clubSocialLinks_valueHint.
  ///
  /// In vi, this message translates to:
  /// **'Đường dẫn liên kết hoặc số điện thoại...'**
  String get clubSocialLinks_valueHint;

  /// No description provided for @clubSocialLinks_add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm liên kết'**
  String get clubSocialLinks_add;

  /// No description provided for @footballScore_status.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get footballScore_status;

  /// No description provided for @footballScore_events.
  ///
  /// In vi, this message translates to:
  /// **'Diễn biến'**
  String get footballScore_events;

  /// No description provided for @footballScore_team1.
  ///
  /// In vi, this message translates to:
  /// **'Đội 1'**
  String get footballScore_team1;

  /// No description provided for @footballScore_team2.
  ///
  /// In vi, this message translates to:
  /// **'Đội 2'**
  String get footballScore_team2;

  /// No description provided for @footballScore_yellowCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ vàng'**
  String get footballScore_yellowCard;

  /// No description provided for @footballScore_redCard.
  ///
  /// In vi, this message translates to:
  /// **'Thẻ đỏ'**
  String get footballScore_redCard;

  /// No description provided for @footballScore_foul.
  ///
  /// In vi, this message translates to:
  /// **'Phạm lỗi'**
  String get footballScore_foul;

  /// No description provided for @footballScore_substitution.
  ///
  /// In vi, this message translates to:
  /// **'Thay người'**
  String get footballScore_substitution;

  /// No description provided for @footballScore_firstHalf.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp 1'**
  String get footballScore_firstHalf;

  /// No description provided for @footballScore_halftime.
  ///
  /// In vi, this message translates to:
  /// **'Giải lao'**
  String get footballScore_halftime;

  /// No description provided for @footballScore_secondHalf.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp 2'**
  String get footballScore_secondHalf;

  /// No description provided for @footballScore_stoppageTime.
  ///
  /// In vi, this message translates to:
  /// **'Bù giờ'**
  String get footballScore_stoppageTime;

  /// No description provided for @footballScore_fullTime.
  ///
  /// In vi, this message translates to:
  /// **'Hết giờ'**
  String get footballScore_fullTime;

  /// No description provided for @footballScore_extraTimeFirstHalf.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp phụ 1'**
  String get footballScore_extraTimeFirstHalf;

  /// No description provided for @footballScore_extraTimeBreak.
  ///
  /// In vi, this message translates to:
  /// **'Nghỉ hiệp phụ'**
  String get footballScore_extraTimeBreak;

  /// No description provided for @footballScore_extraTimeSecondHalf.
  ///
  /// In vi, this message translates to:
  /// **'Hiệp phụ 2'**
  String get footballScore_extraTimeSecondHalf;

  /// No description provided for @footballScore_penaltyShootout.
  ///
  /// In vi, this message translates to:
  /// **'Luân lưu'**
  String get footballScore_penaltyShootout;

  /// No description provided for @footballScore_completed.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành'**
  String get footballScore_completed;

  /// No description provided for @footballScore_penaltyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Luân lưu'**
  String get footballScore_penaltyLabel;

  /// No description provided for @footballScore_minute.
  ///
  /// In vi, this message translates to:
  /// **'Phút'**
  String get footballScore_minute;

  /// No description provided for @footballScore_addedMinute.
  ///
  /// In vi, this message translates to:
  /// **'Bù giờ +'**
  String get footballScore_addedMinute;

  /// No description provided for @lite_kickParticipantSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã loại {teamName} khỏi giải.'**
  String lite_kickParticipantSuccess(Object teamName);

  /// No description provided for @lite_kickParticipantError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể loại đội khỏi giải. Vui lòng thử lại.'**
  String get lite_kickParticipantError;

  /// No description provided for @lite_recreateBracketTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lại bracket?'**
  String get lite_recreateBracketTitle;

  /// No description provided for @lite_recreateBracketConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bracket cũ và lịch trận chưa bắt đầu sẽ bị thay thế hoàn toàn. Không thể hoàn tác. Bạn có chắc muốn tiếp tục?'**
  String get lite_recreateBracketConfirm;

  /// No description provided for @lite_recreateBracket.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lại'**
  String get lite_recreateBracket;

  /// No description provided for @lite_recreatedBracket.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo lại bracket mới.'**
  String get lite_recreatedBracket;

  /// No description provided for @series_scheduleEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch thi đấu'**
  String get series_scheduleEmpty;

  /// No description provided for @series_rankingsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bảng xếp hạng'**
  String get series_rankingsEmpty;

  /// No description provided for @series_rankingsUpdateHint.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng sẽ cập nhật sau mỗi chặng'**
  String get series_rankingsUpdateHint;

  /// No description provided for @series_ongoing.
  ///
  /// In vi, this message translates to:
  /// **'Đang diễn ra'**
  String get series_ongoing;

  /// No description provided for @series_completed.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get series_completed;

  /// No description provided for @series_upcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp diễn ra'**
  String get series_upcoming;

  /// No description provided for @series_pointsSummary.
  ///
  /// In vi, this message translates to:
  /// **'{points} điểm'**
  String series_pointsSummary(Object points);

  /// No description provided for @series_recordSummary.
  ///
  /// In vi, this message translates to:
  /// **'{wins} thắng - {losses} thua'**
  String series_recordSummary(Object wins, Object losses);

  /// No description provided for @lite_teamUnnamed.
  ///
  /// In vi, this message translates to:
  /// **'Đội chưa đặt tên'**
  String get lite_teamUnnamed;

  /// No description provided for @lite_memberCountStatus.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên • {status}'**
  String lite_memberCountStatus(Object count, Object status);

  /// No description provided for @lite_rosterConfirmed.
  ///
  /// In vi, this message translates to:
  /// **'Đã chốt đội hình'**
  String get lite_rosterConfirmed;

  /// No description provided for @lite_memberUnnamed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật tên'**
  String get lite_memberUnnamed;

  /// No description provided for @lite_removeTeamFromTournament.
  ///
  /// In vi, this message translates to:
  /// **'Loại đội khỏi giải'**
  String get lite_removeTeamFromTournament;

  /// No description provided for @lite_statusKicked.
  ///
  /// In vi, this message translates to:
  /// **'Đã loại'**
  String get lite_statusKicked;

  /// No description provided for @lite_statusRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký'**
  String get lite_statusRegistered;

  /// No description provided for @lite_statusComplete.
  ///
  /// In vi, this message translates to:
  /// **'Đã đủ đội'**
  String get lite_statusComplete;

  /// No description provided for @lite_statusRegistering.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng ký'**
  String get lite_statusRegistering;

  /// No description provided for @lite_roleMain.
  ///
  /// In vi, this message translates to:
  /// **'Chính'**
  String get lite_roleMain;

  /// No description provided for @lite_roleReserve.
  ///
  /// In vi, this message translates to:
  /// **'Dự bị'**
  String get lite_roleReserve;

  /// No description provided for @lite_roleMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get lite_roleMember;

  /// No description provided for @lite_kickTeamTitle.
  ///
  /// In vi, this message translates to:
  /// **'Loại đội khỏi giải?'**
  String get lite_kickTeamTitle;

  /// No description provided for @lite_kickReasonLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lý do (không bắt buộc)'**
  String get lite_kickReasonLabel;

  /// No description provided for @lite_kickReasonHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Không đủ điều kiện tham gia'**
  String get lite_kickReasonHint;

  /// No description provided for @lite_kickTeamAction.
  ///
  /// In vi, this message translates to:
  /// **'Loại đội'**
  String get lite_kickTeamAction;

  /// No description provided for @ranking_userFallback.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get ranking_userFallback;

  /// No description provided for @ranking_profileTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Trang cá nhân'**
  String get ranking_profileTooltip;

  /// No description provided for @ranking_categoryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn xếp hạng'**
  String get ranking_categoryLabel;

  /// No description provided for @ranking_topFootballTeam.
  ///
  /// In vi, this message translates to:
  /// **'Đội bóng cao nhất: {teamName}'**
  String ranking_topFootballTeam(Object teamName);

  /// No description provided for @ranking_eloValue.
  ///
  /// In vi, this message translates to:
  /// **'{elo} ELO'**
  String ranking_eloValue(Object elo);

  /// No description provided for @ranking_progressTitle.
  ///
  /// In vi, this message translates to:
  /// **'TIẾN TRÌNH ELO NỔI BẬT'**
  String get ranking_progressTitle;

  /// No description provided for @ranking_overviewLabel.
  ///
  /// In vi, this message translates to:
  /// **'Môn thi đấu • Tổng quan'**
  String get ranking_overviewLabel;

  /// No description provided for @ranking_maxElo.
  ///
  /// In vi, this message translates to:
  /// **'TỐI ĐA'**
  String get ranking_maxElo;

  /// No description provided for @ranking_matchesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Trận'**
  String get ranking_matchesLabel;

  /// No description provided for @ranking_winsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thắng'**
  String get ranking_winsLabel;

  /// No description provided for @ranking_winRateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tỉ lệ'**
  String get ranking_winRateLabel;

  /// No description provided for @ranking_peakLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cao nhất'**
  String get ranking_peakLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
