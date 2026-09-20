import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/app_theme.dart';

/// The app-wide icon contract.
///
/// Keep icon selection here instead of sprinkling icon-library names through
/// feature screens. The aliases are intentionally semantic and all resolve to
/// Lucide's same-weight outline set, so neutral icons inherit the current
/// theme while status icons can still use an explicit semantic tone.
class AppIcons {
  AppIcons._();

  // Navigation and common actions.
  static const IconData back = LucideIcons.arrowLeft;
  static const IconData forward = LucideIcons.arrowRight;
  static const IconData up = LucideIcons.arrowUp;
  static const IconData upRight = LucideIcons.arrowUpRight;
  static const IconData sort = LucideIcons.arrowDownUp;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData add = LucideIcons.plus;
  static const IconData remove = LucideIcons.minus;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData cancel = LucideIcons.circleX;
  static const IconData circle = LucideIcons.circle;
  static const IconData circleDot = LucideIcons.circleDot;
  static const IconData square = LucideIcons.square;
  static const IconData squareCheck = LucideIcons.squareCheck;
  static const IconData menu = LucideIcons.menu;
  static const IconData moreHorizontal = LucideIcons.moreHorizontal;
  static const IconData moreVertical = LucideIcons.moreVertical;
  static const IconData expand = LucideIcons.maximize;
  static const IconData filter = LucideIcons.filter;
  static const IconData tune = LucideIcons.slidersHorizontal;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData externalLink = LucideIcons.externalLink;
  static const IconData zoomIn = LucideIcons.zoomIn;
  static const IconData zoomOut = LucideIcons.zoomOut;
  static const IconData atSign = LucideIcons.atSign;
  static const IconData headset = LucideIcons.headset;
  static const IconData repeat = LucideIcons.repeat;
  static const IconData volume = LucideIcons.volume2;

  // App navigation and discovery.
  static const IconData home = LucideIcons.house;
  static const IconData dashboard = LucideIcons.layoutDashboard;
  static const IconData search = LucideIcons.search;
  static const IconData searchOff = LucideIcons.searchX;
  static const IconData explore = LucideIcons.compass;
  static const IconData settings = LucideIcons.settings;
  static const IconData list = LucideIcons.list;
  static const IconData grid = LucideIcons.grid2x2;
  static const IconData layers = LucideIcons.layers;
  static const IconData file = LucideIcons.file;
  static const IconData fileText = LucideIcons.fileText;
  static const IconData fileImage = LucideIcons.fileImage;
  static const IconData table = LucideIcons.table;

  // Sport and competition.
  static const IconData trophy = LucideIcons.trophy;
  static const IconData medal = LucideIcons.medal;
  static const IconData award = LucideIcons.award;
  static const IconData swords = LucideIcons.swords;
  static const IconData target = LucideIcons.target;
  // Lucide does not provide exact racket/paddle glyphs for every sport, so
  // keep the fallback geometry distinct and recognisable without emojis.
  static const IconData sportPickleball = LucideIcons.disc3;
  static const IconData sportBadminton = LucideIcons.volleyball;
  static const IconData sportTennis = LucideIcons.crosshair;
  static const IconData sportTableTennis = LucideIcons.disc;
  static const IconData sportFootball = LucideIcons.goal;
  static const IconData chart = LucideIcons.chartBar;
  static const IconData trendingUp = LucideIcons.trendingUp;
  static const IconData trendingDown = LucideIcons.trendingDown;
  static const IconData activity = LucideIcons.activity;
  static const IconData timer = LucideIcons.timer;
  static const IconData play = LucideIcons.play;
  static const IconData pause = LucideIcons.pause;
  static const IconData radio = LucideIcons.radio;

  // People, clubs and social.
  static const IconData user = LucideIcons.user;
  static const IconData userRound = LucideIcons.userRound;
  static const IconData users = LucideIcons.users;
  static const IconData userAdd = LucideIcons.userPlus;
  static const IconData userRemove = LucideIcons.userMinus;
  static const IconData chat = LucideIcons.messageCircle;
  static const IconData messages = LucideIcons.messagesSquare;
  static const IconData reply = LucideIcons.reply;
  static const IconData send = LucideIcons.send;
  static const IconData share = LucideIcons.share2;
  static const IconData link = LucideIcons.link;
  static const IconData handshake = LucideIcons.handshake;
  static const IconData heart = LucideIcons.heart;
  static const IconData star = LucideIcons.star;
  static const IconData bookmark = LucideIcons.bookmark;
  static const IconData thumbsUp = LucideIcons.thumbsUp;
  static const IconData hand = LucideIcons.hand;
  static const IconData megaphone = LucideIcons.megaphone;

  // Time and place.
  static const IconData calendar = LucideIcons.calendar;
  static const IconData calendarCheck = LucideIcons.calendarCheck;
  static const IconData calendarX = LucideIcons.calendarX;
  static const IconData calendarClock = LucideIcons.calendarClock;
  static const IconData clock = LucideIcons.clock;
  static const IconData history = LucideIcons.history;
  static const IconData hourglass = LucideIcons.hourglass;
  static const IconData map = LucideIcons.map;
  static const IconData mapPin = LucideIcons.mapPin;
  static const IconData globe = LucideIcons.globe;
  static const IconData building = LucideIcons.building2;
  static const IconData landmark = LucideIcons.landmark;

  // Media and files.
  static const IconData image = LucideIcons.image;
  static const IconData images = LucideIcons.images;
  static const IconData imageAdd = LucideIcons.imagePlus;
  static const IconData imageOff = LucideIcons.imageOff;
  static const IconData camera = LucideIcons.camera;
  static const IconData video = LucideIcons.video;
  static const IconData upload = LucideIcons.upload;
  static const IconData download = LucideIcons.download;
  static const IconData copy = LucideIcons.copy;
  static const IconData save = LucideIcons.save;
  static const IconData edit = LucideIcons.pencil;
  static const IconData delete = LucideIcons.trash2;
  static const IconData scissors = LucideIcons.scissors;
  static const IconData paperclip = LucideIcons.paperclip;

  // Account, security and status.
  static const IconData login = LucideIcons.logIn;
  static const IconData logout = LucideIcons.logOut;
  static const IconData mail = LucideIcons.mail;
  static const IconData phone = LucideIcons.phone;
  static const IconData bell = LucideIcons.bell;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData key = LucideIcons.keyRound;
  static const IconData lock = LucideIcons.lock;
  static const IconData lockOpen = LucideIcons.lockOpen;
  static const IconData fingerprint = LucideIcons.fingerprint;
  static const IconData shield = LucideIcons.shield;
  static const IconData shieldCheck = LucideIcons.shieldCheck;
  static const IconData verified = LucideIcons.badgeCheck;
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData error = LucideIcons.circleAlert;
  static const IconData info = LucideIcons.info;
  static const IconData help = LucideIcons.circleHelp;
  static const IconData ban = LucideIcons.ban;

  // Money and miscellaneous domain actions.
  static const IconData coins = LucideIcons.coins;
  static const IconData wallet = LucideIcons.walletCards;
  static const IconData creditCard = LucideIcons.creditCard;
  static const IconData tag = LucideIcons.tag;
  static const IconData tags = LucideIcons.tags;
  static const IconData receipt = LucideIcons.receipt;
  static const IconData qrCode = LucideIcons.qrCode;
  static const IconData scan = LucideIcons.scanLine;
  static const IconData sparkles = LucideIcons.sparkles;
  static const IconData zap = LucideIcons.zap;
  static const IconData flame = LucideIcons.flame;
  static const IconData moon = LucideIcons.moon;
  static const IconData box = LucideIcons.box;
  static const IconData infinity = LucideIcons.infinity;
  static const IconData cake = LucideIcons.cake;
  static const IconData code = LucideIcons.code2;

  /// Returns the shared monochrome sport glyph used across cards, filters and
  /// forms. Sport data stays a key; the visual is resolved only at the UI edge.
  static IconData forSport(String? sportKey) {
    return switch ((sportKey ?? '').trim().toLowerCase()) {
      'badminton' || 'cầu lông' => sportBadminton,
      'tennis' => sportTennis,
      'table_tennis' || 'bóng bàn' => sportTableTennis,
      'football' || 'bóng đá' => sportFootball,
      'pickleball' => sportPickleball,
      _ => trophy,
    };
  }

  /// Resolves a semantic icon tone from the active app theme.
  static Color color(
    BuildContext context, {
    AppIconTone tone = AppIconTone.neutral,
  }) {
    final colors = context.colors;
    return switch (tone) {
      AppIconTone.neutral => colors.textPrimary,
      AppIconTone.muted => colors.textMuted,
      AppIconTone.brand => AppTheme.primary,
      AppIconTone.success => colors.success,
      AppIconTone.warning => colors.warning,
      AppIconTone.danger => colors.error,
      AppIconTone.info => colors.info,
    };
  }
}

enum AppIconTone { neutral, muted, brand, success, warning, danger, info }

/// Use this when a new widget needs a standard icon without hand-picking a
/// color. Existing `Icon(AppIcons.*)` calls inherit the same theme color.
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final AppIconTone tone;
  final Color? color;

  const AppIcon(
    this.icon, {
    super.key,
    this.size,
    this.tone = AppIconTone.neutral,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppIcons.color(context, tone: tone),
    );
  }
}

class AppSportIcon extends StatelessWidget {
  final String? sportKey;
  final double? size;
  final Color? color;

  const AppSportIcon({
    super.key,
    required this.sportKey,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(AppIcons.forSport(sportKey), size: size, color: color);
  }
}
