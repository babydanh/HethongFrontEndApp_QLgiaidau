import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Wrapper — Phosphor Icons, nhất quán, dễ dùng
/// Dùng: `AppIcons.trophy()`, `AppIcons.heart(size: 20, color: Colors.red)`
class AppIcons {
  AppIcons._();

  // ── sport ──
  static Widget trophy({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.trophy(), size: size, color: color);
  static Widget medal({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.medal(), size: size, color: color);
  static Widget chartBar({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.chartBar(), size: size, color: color);
  static Widget lightning({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.lightning(), size: size, color: color);
  static Widget sword({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.sword(), size: size, color: color);

  // ── users ──
  static Widget users({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.users(), size: size, color: color);
  static Widget user({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.user(), size: size, color: color);

  // ── navigation ──
  static Widget arrowLeft({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.arrowLeft(), size: size, color: color);
  static Widget arrowRight({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.arrowRight(), size: size, color: color);
  static Widget caretDown({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.caretDown(), size: size, color: color);

  // ── actions ──
  static Widget share({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.shareNetwork(), size: size, color: color);
  static Widget bookmark({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.bookmark(), size: size, color: color);
  static Widget check({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.check(), size: size, color: color);
  static Widget x({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.x(), size: size, color: color);
  static Widget plus({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.plus(), size: size, color: color);
  static Widget minus({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.minus(), size: size, color: color);
  static Widget search({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.magnifyingGlass(), size: size, color: color);
  static Widget sort({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.arrowsDownUp(), size: size, color: color);
  static Widget pencil({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.pencilSimple(), size: size, color: color);
  static Widget trash({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.trash(), size: size, color: color);
  static Widget copy({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.copy(), size: size, color: color);
  static Widget download({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.downloadSimple(), size: size, color: color);
  static Widget scissors({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.scissors(), size: size, color: color);

  // ── status ──
  static Widget warning({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.warning(), size: size, color: color);
  static Widget info({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.info(), size: size, color: color);
  static Widget checkCircle({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.checkCircle(), size: size, color: color);
  static Widget xCircle({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.xCircle(), size: size, color: color);
  static Widget shieldCheck({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.shieldCheck(), size: size, color: color);

  // ── time / date ──
  static Widget clock({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.clock(), size: size, color: color);
  static Widget calendar({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.calendarBlank(), size: size, color: color);

  // ── location ──
  static Widget pin({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.mapPin(), size: size, color: color);
  static Widget globe({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.globe(), size: size, color: color);

  // ── notification ──
  static Widget bell({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.bell(), size: size, color: color);
  static Widget fire({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.fire(), size: size, color: color);
  static Widget star({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.star(), size: size, color: color);
  static Widget heart({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.heart(), size: size, color: color);
  static Widget heartFill({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.heartStraight(), size: size, color: color);

  // ── communication ──
  static Widget chatCircle({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.chatCircle(), size: size, color: color);
  static Widget phone({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.phone(), size: size, color: color);
  static Widget envelope({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.envelope(), size: size, color: color);

  // ── media ──
  static Widget image({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.image(), size: size, color: color);
  static Widget camera({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.camera(), size: size, color: color);

  // ── security ──
  static Widget eye({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.eye(), size: size, color: color);
  static Widget eyeSlash({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.eyeSlash(), size: size, color: color);
  static Widget key({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.key(), size: size, color: color);
  static Widget lock({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.lock(), size: size, color: color);
  static Widget lockOpen({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.lockOpen(), size: size, color: color);
  static Widget fingerprint({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.fingerprint(), size: size, color: color);

  // ── money / business ──
  static Widget coins({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.coins(), size: size, color: color);
  static Widget bank({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.bank(), size: size, color: color);
  static Widget tag({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.tag(), size: size, color: color);
  static Widget link({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.link(), size: size, color: color);

  // ── layout ──
  static Widget gridFour({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.gridFour(), size: size, color: color);
  static Widget list({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.list(), size: size, color: color);
  static Widget fileText({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.fileText(), size: size, color: color);
  static Widget settings({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.gear(), size: size, color: color);

  // ── social ──
  static Widget handWaving({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.handWaving(), size: size, color: color);
  static Widget handshake({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.handshake(), size: size, color: color);

  // ── warning / fill ──
  static Widget warningFill({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.warning(), size: size, color: color);
  static Widget trophyFill({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.trophy(), size: size, color: color);
  static Widget medalFill({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.medal(), size: size, color: color);
  static Widget lightningSlash({double size = 24, Color? color}) => PhosphorIcon(PhosphorIcons.lightningSlash(), size: size, color: color);
}
