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
