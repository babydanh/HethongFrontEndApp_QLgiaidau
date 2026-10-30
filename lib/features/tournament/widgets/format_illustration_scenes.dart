import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

/// Logical canvas every scene is authored on; the stage scales it to fit.
const Size kSceneCanvas = Size(320, 170);

/// Where a chip is at [time]: position, fade, fill level (0 plain .. 1 accent)
/// and size.
class SceneFrame {
  const SceneFrame(this.time, this.pos, this.opacity, this.win, this.scale);

  final double time;
  final Offset pos;
  final double opacity;
  final double win;
  final double scale;

  SceneFrame lerpTo(SceneFrame other, double progress) => SceneFrame(
    lerpDouble(time, other.time, progress)!,
    Offset.lerp(pos, other.pos, progress)!,
    lerpDouble(opacity, other.opacity, progress)!,
    lerpDouble(win, other.win, progress)!,
    lerpDouble(scale, other.scale, progress)!,
  );
}

/// One player/team: a label that travels through keyframes.
class SceneChip {
  SceneChip(this.label, Offset start)
    : _frames = [SceneFrame(0, start, 1, 0, 1)];

  final String label;
  final List<SceneFrame> _frames;

  /// Tweens to the given values between [from] and [end] seconds (a null value
  /// keeps the last one). Moves must be added in time order.
  SceneChip to(
    double from,
    double end, {
    Offset? pos,
    double? opacity,
    double? win,
    double? scale,
  }) {
    final last = _frames.last;
    if (last.time < from) {
      _frames.add(
        SceneFrame(from, last.pos, last.opacity, last.win, last.scale),
      );
    }
    final held = _frames.last;
    _frames.add(
      SceneFrame(
        end,
        pos ?? held.pos,
        opacity ?? held.opacity,
        win ?? held.win,
        scale ?? held.scale,
      ),
    );
    return this;
  }

  SceneFrame at(double time) {
    if (time <= _frames.first.time) return _frames.first;
    for (var i = 1; i < _frames.length; i++) {
      final next = _frames[i];
      if (time > next.time) continue;
      final prev = _frames[i - 1];
      final span = next.time - prev.time;
      final progress = span <= 0 ? 1.0 : (time - prev.time) / span;
      return prev.lerpTo(next, Curves.easeInOutCubic.transform(progress));
    }
    return _frames.last;
  }
}

/// A line between two points; drawn gradually from [start] to [end] seconds
/// (the default 0..0 means always fully drawn).
class SceneLink {
  const SceneLink(
    this.a,
    this.b, {
    this.start = 0,
    this.end = 0,
    this.accent = false,
  });

  final Offset a;
  final Offset b;
  final double start;
  final double end;
  final bool accent;
}

/// A whole looping illustration: empty [slots] and [links] as the bracket
/// skeleton, plus the [chips] moving through it for [duration] seconds.
class FormatScene {
  const FormatScene({
    required this.duration,
    required this.chips,
    this.slots = const [],
    this.links = const [],
  });

  final double duration;
  final List<SceneChip> chips;
  final List<Offset> slots;
  final List<SceneLink> links;
}

FormatScene sceneFor(String bracketType) => switch (bracketType.toUpperCase()) {
  'DOUBLE_ELIMINATION' => _doubleElimination(),
  'ROUND_ROBIN' => _roundRobin(),
  'GROUP_STAGE_KNOCKOUT' => _groupStageKnockout(),
  'SWISS' => _swiss(),
  _ => _singleElimination(),
};

const double _roundGap = 2.2;
const double _moveTime = 1.2;
const double _popTime = 0.8;
const double _firstMove = 0.8;

// ─── Loại trực tiếp: 8 đội, hạt giống cao thắng ───

FormatScene _singleElimination() {
  const xs = [28.0, 108.0, 188.0, 268.0];
  const seeds = [1, 8, 4, 5, 2, 7, 3, 6];
  final ys = <List<double>>[
    [for (var i = 0; i < 8; i++) 16 + i * 20.5],
  ];
  while (ys.last.length > 1) {
    final row = ys.last;
    ys.add([for (var i = 0; i < row.length; i += 2) (row[i] + row[i + 1]) / 2]);
  }
  Offset slot(int round, int index) => Offset(xs[round], ys[round][index]);
  final occupants = <List<int>>[seeds];
  while (occupants.last.length > 1) {
    final row = occupants.last;
    occupants.add([
      for (var i = 0; i < row.length; i += 2)
        row[i] < row[i + 1] ? row[i] : row[i + 1],
    ]);
  }

  final chips = <SceneChip>[];
  for (var i = 0; i < seeds.length; i++) {
    final chip = SceneChip('${seeds[i]}', slot(0, i));
    var index = i;
    var round = 0;
    for (; round < 3; round++) {
      final from = _firstMove + round * _roundGap;
      if (occupants[round + 1][index ~/ 2] != seeds[i]) {
        chip.to(from + 0.3, from + _moveTime, opacity: 0.3);
        break;
      }
      index ~/= 2;
      chip.to(from, from + _moveTime, pos: slot(round + 1, index));
    }
    if (round == 3) {
      final from = _firstMove + 3 * _roundGap;
      chip.to(from, from + _popTime, win: 1, scale: 1.3);
    }
    chips.add(chip);
  }
  return FormatScene(
    duration: 9,
    chips: chips,
    slots: [
      for (var r = 0; r < ys.length; r++)
        for (var i = 0; i < ys[r].length; i++) slot(r, i),
    ],
    links: [
      for (var r = 0; r < 3; r++)
        for (var i = 0; i < ys[r].length; i++)
          SceneLink(slot(r, i), slot(r + 1, i ~/ 2)),
    ],
  );
}

// ─── Nhánh thắng + nhánh thua: 4 đội, thua một lần chưa bị loại ───

FormatScene _doubleElimination() {
  const upper = [
    Offset(28, 16),
    Offset(28, 42),
    Offset(28, 68),
    Offset(28, 94),
  ];
  const upperFinal = [Offset(108, 29), Offset(108, 81)];
  const lower = [Offset(108, 128), Offset(108, 154)];
  const lowerFinal = [Offset(188, 128), Offset(188, 154)];
  const upperWinner = Offset(188, 55);
  const grand = [Offset(250, 70), Offset(250, 112)];
  const champion = Offset(300, 91);

  final one = SceneChip('1', upper[0]);
  final four = SceneChip('4', upper[1]);
  final two = SceneChip('2', upper[2]);
  final three = SceneChip('3', upper[3]);
  // Round 1 of the upper bracket: winners go on, losers drop to the lower one.
  one.to(0.8, 2.0, pos: upperFinal[0]);
  two.to(0.8, 2.0, pos: upperFinal[1]);
  four.to(0.8, 2.0, pos: lower[0]);
  three.to(0.8, 2.0, pos: lower[1]);
  // Upper final: 1 stays up, 2 drops into the lower final.
  one.to(2.6, 3.8, pos: upperWinner);
  two.to(2.6, 3.8, pos: lowerFinal[0]);
  // Lower round 1: 3 beats 4.
  three.to(4.4, 5.6, pos: lowerFinal[1]);
  four.to(4.7, 5.6, opacity: 0.3);
  // Lower final: 2 beats 3; the upper winner waits in the grand final.
  two.to(6.2, 7.4, pos: grand[1]);
  three.to(6.5, 7.4, opacity: 0.3);
  one.to(6.2, 7.4, pos: grand[0]);
  // Grand final: 1 is champion.
  one.to(8.0, 9.2, pos: champion, win: 1, scale: 1.3);
  two.to(8.3, 9.2, opacity: 0.3);

  return FormatScene(
    duration: 11,
    chips: [one, four, two, three],
    slots: [
      ...upper,
      ...upperFinal,
      ...lower,
      ...lowerFinal,
      upperWinner,
      ...grand,
      champion,
    ],
    links: [
      SceneLink(upper[0], upperFinal[0]),
      SceneLink(upper[1], upperFinal[0]),
      SceneLink(upper[2], upperFinal[1]),
      SceneLink(upper[3], upperFinal[1]),
      SceneLink(upperFinal[0], upperWinner),
      SceneLink(upperFinal[1], upperWinner),
      SceneLink(lower[0], lowerFinal[1]),
      SceneLink(lower[1], lowerFinal[1]),
      SceneLink(upperFinal[1], lowerFinal[0]),
      SceneLink(upperWinner, grand[0]),
      SceneLink(lowerFinal[0], grand[1]),
      SceneLink(lowerFinal[1], grand[1]),
      SceneLink(grand[0], champion),
      SceneLink(grand[1], champion),
    ],
  );
}

// ─── Vòng tròn: 4 đội, mỗi vòng sáng thêm 2 cặp, ô càng đậm càng nhiều trận thắng ───

FormatScene _roundRobin() {
  const corners = [
    Offset(100, 35),
    Offset(220, 35),
    Offset(220, 135),
    Offset(100, 135),
  ];
  // Round pairs by team number (1-based); the lower number wins.
  const rounds = [
    [(1, 4), (2, 3)],
    [(1, 3), (2, 4)],
    [(1, 2), (3, 4)],
  ];
  final chips = [for (var i = 0; i < 4; i++) SceneChip('${i + 1}', corners[i])];
  final wins = List.filled(4, 0);
  final links = <SceneLink>[];
  for (var r = 0; r < rounds.length; r++) {
    final from = _firstMove + r * _roundGap;
    for (final (a, b) in rounds[r]) {
      links.add(
        SceneLink(
          corners[a - 1],
          corners[b - 1],
          start: from,
          end: from + 0.8,
          accent: true,
        ),
      );
      wins[a - 1]++;
    }
    for (var i = 0; i < 4; i++) {
      chips[i].to(from + 0.8, from + 1.4, win: wins[i] / 3);
    }
  }
  chips[0].to(7.4, 8.2, scale: 1.3);
  return FormatScene(duration: 9.5, chips: chips, slots: corners, links: links);
}

// ─── Vòng bảng rồi loại trực tiếp: 2 bảng × 4 đội, nhất nhì mỗi bảng đi tiếp ───

FormatScene _groupStageKnockout() {
  Offset groupSlot(int group, int rank) =>
      Offset(24 + group * 54.0, 22 + rank * 36.0);
  const semis = [
    Offset(160, 40),
    Offset(160, 70),
    Offset(160, 100),
    Offset(160, 130),
  ];
  const finals = [Offset(230, 55), Offset(230, 115)];
  const champion = Offset(290, 85);

  SceneChip team(String group, int rank) {
    final chip = SceneChip(
      '$group${rank + 1}',
      groupSlot(group == 'A' ? 0 : 1, rank),
    );
    // Group stage: the better the rank, the more matches won.
    return chip.to(0.8, 3.2, win: (3 - rank) / 3 * 0.8);
  }

  final a = [for (var k = 0; k < 4; k++) team('A', k)];
  final b = [for (var k = 0; k < 4; k++) team('B', k)];
  // Top two of each group enter the semi-finals; the rest fade out.
  a[0].to(3.8, 5.0, pos: semis[0]);
  b[1].to(3.8, 5.0, pos: semis[1]);
  b[0].to(3.8, 5.0, pos: semis[2]);
  a[1].to(3.8, 5.0, pos: semis[3]);
  for (final chip in [a[2], a[3], b[2], b[3]]) {
    chip.to(3.8, 5.0, opacity: 0.3);
  }
  // Semi-finals: A1 and B1 reach the final.
  a[0].to(5.8, 7.0, pos: finals[0]);
  b[0].to(5.8, 7.0, pos: finals[1]);
  b[1].to(6.1, 7.0, opacity: 0.3);
  a[1].to(6.1, 7.0, opacity: 0.3);
  // Final: A1 is champion.
  a[0].to(7.8, 8.8, pos: champion, win: 1, scale: 1.3);
  b[0].to(8.1, 8.8, opacity: 0.3);

  return FormatScene(
    duration: 10.5,
    chips: [...a, ...b],
    slots: [
      for (var g = 0; g < 2; g++)
        for (var k = 0; k < 4; k++) groupSlot(g, k),
      ...semis,
      ...finals,
      champion,
    ],
    links: [
      SceneLink(semis[0], finals[0]),
      SceneLink(semis[1], finals[0]),
      SceneLink(semis[2], finals[1]),
      SceneLink(semis[3], finals[1]),
      SceneLink(finals[0], champion),
      SceneLink(finals[1], champion),
    ],
  );
}

// ─── Thuỵ Sĩ: 8 người, 3 vòng, ghép người cùng điểm, xếp hạng theo tổng thắng ───

FormatScene _swiss() {
  const left = 116.0;
  const right = 176.0;
  const standingX = 270.0;
  // Pairings per round by seed (the lower seed wins), as in the description.
  const rounds = [
    [(1, 5), (2, 6), (3, 7), (4, 8)],
    [(1, 2), (3, 4), (5, 6), (7, 8)],
    [(1, 3), (2, 4), (5, 7), (6, 8)],
  ];
  double rowY(int index) => 26 + index * 38.0;
  double listY(int index) => 16 + index * 20.5;

  final chips = [
    for (var seed = 1; seed <= 8; seed++)
      SceneChip('$seed', Offset(36, listY(seed - 1))),
  ];
  final wins = List.filled(8, 0);
  final slots = <Offset>[
    for (var row = 0; row < 4; row++) ...[
      Offset(left, rowY(row)),
      Offset(right, rowY(row)),
    ],
    for (var k = 0; k < 8; k++) Offset(standingX, listY(k)),
  ];
  for (var r = 0; r < rounds.length; r++) {
    final from = _firstMove + r * 2.4;
    for (var row = 0; row < 4; row++) {
      final (a, b) = rounds[r][row];
      chips[a - 1].to(from, from + _moveTime, pos: Offset(left, rowY(row)));
      chips[b - 1].to(from, from + _moveTime, pos: Offset(right, rowY(row)));
      wins[a - 1]++;
    }
    for (var i = 0; i < 8; i++) {
      chips[i].to(from + 1.4, from + 1.9, win: wins[i] / 3);
    }
  }
  // Final standing: most wins first, ties by seed.
  final order = [for (var i = 0; i < 8; i++) i]
    ..sort((x, y) => wins[y] != wins[x] ? wins[y] - wins[x] : x - y);
  const standingFrom = 8.4;
  for (var k = 0; k < order.length; k++) {
    chips[order[k]].to(
      standingFrom,
      standingFrom + 1.4,
      pos: Offset(standingX, listY(k)),
    );
  }
  return FormatScene(duration: 11.5, chips: chips, slots: slots);
}
