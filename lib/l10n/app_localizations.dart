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
  /// **'Hình thức thi đấu'**
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

  /// No description provided for @vnsport.
  ///
  /// In vi, this message translates to:
  /// **'VNSPORT'**
  String get vnsport;

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
  /// **'Mở đăng ký'**
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
