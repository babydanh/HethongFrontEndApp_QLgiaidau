// Pure scoring engines for the Lavish prototype. Every action returns a NEW state
// (state.events = what just happened, state.flags = banners to show).
(function (root) {
  'use strict';
  const clone = (o) => JSON.parse(JSON.stringify(o));
  const other = (t) => 1 - t;

  // Winner of one game/set: cap wins at once, else target with a 2-point lead.
  function gameWinner(sc, target, winBy2, cap) {
    const hi = sc[0] >= sc[1] ? 0 : 1;
    const a = sc[hi], b = sc[other(hi)];
    if (cap && a >= cap) return hi;
    if (a >= target && (!winBy2 || a - b >= 2)) return hi;
    return null;
  }

  // ───────────── Pickleball side-out ─────────────
  function pbCreate(o) {
    o = o || {};
    const doubles = o.doubles !== false;
    return {
      sport: 'pb-sideout', doubles, target: o.target || 11, bestOf: o.bestOf || 1,
      score: [0, 0], games: [0, 0], gameNo: 1, firstServer: 0,
      serving: 0, serverNo: doubles ? 2 : 1, switchedDeciding: false,
      over: false, matchWinner: null, events: [], flags: [],
    };
  }
  function pbSwitchAt(target) { return target === 11 ? 6 : target === 15 ? 8 : 11; }
  // `winner` = the team that won the rally.
  function pbRally(s, winner) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    if (winner === n.serving) {
      n.score[winner]++;
      n.events.push(`Đội ${winner + 1} thắng pha khi đang giao: +1 điểm`);
    } else if (n.doubles && n.serverNo === 1) {
      n.serverNo = 2;
      n.events.push(`Đội ${other(winner) + 1} thua pha: GIAO 2 (cùng đội, không ai được điểm)`);
    } else {
      n.serving = winner; n.serverNo = 1;
      n.events.push(`Mất giao: đội ${winner + 1} giao (GIAO 1), không ai được điểm`);
    }
    const gw = gameWinner(n.score, n.target, true, null);
    if (gw !== null) {
      n.games[gw]++;
      n.events.push(`Đội ${gw + 1} thắng game ${n.gameNo} (${n.score[0]}-${n.score[1]})`);
      const need = Math.ceil(n.bestOf / 2);
      if (n.games[gw] >= need) {
        n.over = true; n.matchWinner = gw;
        n.events.push(`Đội ${gw + 1} thắng trận`);
      } else {
        n.gameNo++; n.score = [0, 0]; n.firstServer = other(n.firstServer);
        n.serving = n.firstServer; n.serverNo = n.doubles ? 2 : 1;
        n.switchedDeciding = false;
        n.flags.push('Đổi sân giữa các game');
      }
    } else if (n.gameNo === n.bestOf && n.bestOf > 1 && !n.switchedDeciding &&
      Math.max(n.score[0], n.score[1]) === pbSwitchAt(n.target)) {
      n.switchedDeciding = true;
      n.flags.push(`Game quyết định: đổi sân (một bên đạt ${pbSwitchAt(n.target)})`);
    }
    return n;
  }
  function pbCall(s) {
    const a = s.score[s.serving], b = s.score[other(s.serving)];
    return s.doubles ? `${a}-${b}-${s.serverNo}` : `${a}-${b}`;
  }
  function pbCourt(s) { return s.score[s.serving] % 2 === 0 ? 'phải' : 'trái'; }

  // ───────────── Pickleball rally ─────────────
  function pbrCreate(o) {
    o = o || {};
    return {
      sport: 'pb-rally', target: o.target || 11, cap: o.cap === undefined ? 15 : o.cap,
      bestOf: o.bestOf || 3, score: [0, 0], games: [0, 0], gameNo: 1, firstServer: 0,
      serving: 0, switchedDeciding: false, over: false, matchWinner: null, events: [], flags: [],
    };
  }
  function pbrRally(s, winner) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    n.score[winner]++;
    const had = n.serving === winner;
    n.serving = winner;
    n.events.push(`Đội ${winner + 1} thắng pha: +1 điểm${had ? '' : ' và giành quyền giao'}`);
    const gw = gameWinner(n.score, n.target, true, n.cap);
    if (gw !== null) {
      n.games[gw]++;
      n.events.push(`Đội ${gw + 1} thắng game ${n.gameNo} (${n.score[0]}-${n.score[1]})`);
      if (n.games[gw] >= Math.ceil(n.bestOf / 2)) {
        n.over = true; n.matchWinner = gw; n.events.push(`Đội ${gw + 1} thắng trận`);
      } else {
        n.gameNo++; n.score = [0, 0]; n.firstServer = other(n.firstServer);
        n.serving = n.firstServer; n.switchedDeciding = false;
        n.flags.push('Đổi sân giữa các game');
      }
    } else if (n.gameNo === n.bestOf && n.bestOf > 1 && !n.switchedDeciding &&
      Math.max(n.score[0], n.score[1]) === pbSwitchAt(n.target)) {
      n.switchedDeciding = true;
      n.flags.push(`Game quyết định: đổi sân (một bên đạt ${pbSwitchAt(n.target)})`);
    }
    return n;
  }

  // ───────────── Badminton (rally 21, cap 30) ─────────────
  function bdCreate(o) {
    o = o || {};
    return {
      sport: 'badminton', doubles: o.doubles !== false, bestOf: 3, target: 21, cap: 30,
      score: [0, 0], games: [0, 0], gameNo: 1, firstServer: 0, serving: 0,
      right: [0, 0], intervalDone: false, over: false, matchWinner: null, events: [], flags: [],
    };
  }
  function bdRally(s, winner) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    const prevMax = Math.max(n.score[0], n.score[1]);
    n.score[winner]++;
    if (winner === n.serving) {
      if (n.doubles) n.right[winner] = 1 - n.right[winner];
      n.events.push(`Đội ${winner + 1} thắng pha khi giao: +1 điểm, giao tiếp từ ô ${n.score[winner] % 2 === 0 ? 'phải' : 'trái'}${n.doubles ? ', hai VĐV đổi ô' : ''}`);
    } else {
      n.serving = winner;
      n.events.push(`Đội ${winner + 1} thắng pha: +1 điểm và giành quyền giao từ ô ${n.score[winner] % 2 === 0 ? 'phải' : 'trái'}`);
    }
    const gw = gameWinner(n.score, n.target, true, n.cap);
    if (gw !== null) {
      n.games[gw]++;
      n.events.push(`Đội ${gw + 1} thắng game ${n.gameNo} (${n.score[0]}-${n.score[1]})`);
      if (n.games[gw] >= 2) {
        n.over = true; n.matchWinner = gw; n.events.push(`Đội ${gw + 1} thắng trận`);
      } else {
        n.gameNo++; n.score = [0, 0]; n.right = [0, 0]; n.firstServer = gw; n.serving = gw;
        n.intervalDone = false;
        n.flags.push('Nghỉ giữa game 120 giây, đổi sân');
      }
    } else if (!n.intervalDone && prevMax < 11 && Math.max(n.score[0], n.score[1]) === 11) {
      n.intervalDone = true;
      n.flags.push('Nghỉ 60 giây (bên dẫn đạt 11)' + (n.gameNo === 3 ? ', đổi sân' : ''));
    }
    return n;
  }
  function bdServerPlayer(s) {
    const t = s.serving;
    return s.score[t] % 2 === 0 ? s.right[t] : 1 - s.right[t];
  }
  function bdCourt(s) { return s.score[s.serving] % 2 === 0 ? 'phải' : 'trái'; }

  // ───────────── Table tennis ─────────────
  function ttCreate(o) {
    o = o || {};
    return {
      sport: 'tabletennis', bestOf: o.bestOf || 5, target: 11,
      score: [0, 0], games: [0, 0], gameNo: 1, firstServer: 0,
      switchedLast: false, over: false, matchWinner: null, events: [], flags: [],
    };
  }
  function ttServer(s) {
    const total = s.score[0] + s.score[1];
    if (s.score[0] >= 10 && s.score[1] >= 10) return s.firstServer ^ ((total - 20) & 1);
    return s.firstServer ^ (Math.floor(total / 2) & 1);
  }
  function ttRally(s, winner) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    const before = ttServer(n);
    n.score[winner]++;
    n.events.push(`Đội ${winner + 1} thắng pha: +1 điểm`);
    const gw = gameWinner(n.score, n.target, true, null);
    if (gw !== null) {
      n.games[gw]++;
      n.events.push(`Đội ${gw + 1} thắng game ${n.gameNo} (${n.score[0]}-${n.score[1]})`);
      if (n.games[gw] >= Math.ceil(n.bestOf / 2)) {
        n.over = true; n.matchWinner = gw; n.events.push(`Đội ${gw + 1} thắng trận`);
      } else {
        n.gameNo++; n.score = [0, 0]; n.firstServer = other(n.firstServer); n.switchedLast = false;
        n.flags.push('Đổi sân sau mỗi game');
      }
    } else {
      const after = ttServer(n);
      if (after !== before) {
        const dz = n.score[0] >= 10 && n.score[1] >= 10;
        n.flags.push(`Đổi giao: đội ${after + 1} giao${dz ? ' (từ 10-10 đổi giao mỗi điểm)' : ' (mỗi 2 điểm)'}`);
      }
      const lastGame = n.gameNo === n.bestOf && n.bestOf > 1;
      if (lastGame && !n.switchedLast && Math.max(n.score[0], n.score[1]) === 5) {
        n.switchedLast = true; n.flags.push('Game cuối: đổi sân (một bên đạt 5)');
      }
    }
    return n;
  }

  // ───────────── Tennis ─────────────
  // finalMode: TB7 | TB10_FINAL | NO_TB_FINAL | MATCH_TB10
  function tnCreate(o) {
    o = o || {};
    return {
      sport: 'tennis', bestOf: o.bestOf || 3, noAd: !!o.noAd, finalMode: o.finalMode || 'TB7',
      sets: [], setsWon: [0, 0], games: [0, 0], pts: [0, 0], tb: null,
      server: 0, over: false, matchWinner: null, events: [], flags: [],
    };
  }
  function tnNeed(s) { return Math.ceil(s.bestOf / 2); }
  function tnIsFinalSet(s) { return s.setsWon[0] === tnNeed(s) - 1 && s.setsWon[1] === tnNeed(s) - 1; }
  function tnStartTb(n, target, kind) {
    n.tb = { pts: [0, 0], target, first: n.server, kind };
    n.events.push(kind === 'match' ? 'Match tie-break 10 điểm thay set quyết định' : `Tie-break ${target} điểm`);
  }
  function tnEndSet(n, w, label) {
    n.sets.push(label);
    n.setsWon[w]++;
    n.events.push(`Đội ${w + 1} thắng set ${n.sets.length} (${label})`);
    if (n.setsWon[w] >= tnNeed(n)) { n.over = true; n.matchWinner = w; n.events.push(`Đội ${w + 1} thắng trận`); }
    n.games = [0, 0]; n.pts = [0, 0];
  }
  function tnRally(s, winner) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    if (n.tb) {
      n.tb.pts[winner]++;
      const total = n.tb.pts[0] + n.tb.pts[1];
      const gw = gameWinner(n.tb.pts, n.tb.target, true, null);
      if (gw !== null) {
        const label = n.tb.kind === 'match'
          ? `match tie-break ${n.tb.pts[0]}-${n.tb.pts[1]}`
          : `${gw === 0 ? 7 : 6}-${gw === 0 ? 6 : 7} (${n.tb.pts[0]}-${n.tb.pts[1]})`;
        const first = n.tb.first;
        n.tb = null;
        tnEndSet(n, gw, label);
        n.server = other(first);
        return n;
      }
      if (total % 6 === 0) n.flags.push('Tie-break: đổi sân (mỗi 6 điểm)');
      return n;
    }
    n.pts[winner]++;
    const a = n.pts[winner], b = n.pts[other(winner)];
    const gameDone = n.noAd ? a >= 4 : (a >= 4 && a - b >= 2);
    if (!gameDone) return n;
    n.games[winner]++;
    n.events.push(`Đội ${winner + 1} thắng game (${n.games[0]}-${n.games[1]})`);
    n.pts = [0, 0];
    n.server = other(n.server);
    const g = n.games, lead = g[winner] - g[other(winner)];
    if (g[winner] >= 6 && lead >= 2) {
      tnEndSet(n, winner, `${g[0]}-${g[1]}`);
      return n;
    }
    if (g[0] === 6 && g[1] === 6) {
      const final = tnIsFinalSet(n);
      if (final && n.finalMode === 'TB10_FINAL') tnStartTb(n, 10, 'tb10');
      else if (final && n.finalMode === 'NO_TB_FINAL') n.events.push('Set quyết định không tie-break: đánh tiếp đến khi hơn 2 game');
      else tnStartTb(n, 7, 'tb7');
      return n;
    }
    if ((g[0] + g[1]) % 2 === 1) n.flags.push('Đổi sân (sau game lẻ)');
    return n;
  }
  // When sets are level and mode is MATCH_TB10, the "final set" is a 10-point match tie-break.
  function tnAfterSet(n) {
    if (n.finalMode === 'MATCH_TB10' && !n.over && !n.tb && n.games[0] === 0 && n.games[1] === 0 && n.pts[0] === 0 && n.pts[1] === 0 && tnIsFinalSet(n)) tnStartTb(n, 10, 'match');
    return n;
  }
  function tnRallyFull(s, w) { return tnAfterSet(tnRally(s, w)); }
  function tnTbServer(n) {
    const total = n.tb.pts[0] + n.tb.pts[1];
    return total === 0 ? n.tb.first : n.tb.first ^ (Math.floor((total + 1) / 2) & 1);
  }
  function tnPointLabel(s, side) {
    if (s.tb) return String(s.tb.pts[side]);
    const a = s.pts[side], b = s.pts[other(side)];
    if (a >= 3 && b >= 3 && !s.noAd) {
      if (a === b) return '40';
      return a > b ? 'AD' : '40';
    }
    return ['0', '15', '30', '40'][Math.min(a, 3)];
  }
  function tnCurrentServer(s) { return s.tb ? tnTbServer(s) : s.server; }

  // ───────────── Football ─────────────
  const FB_FLOW = { H1: 'HT', HT: 'H2', H2: 'FT', ET1: 'ETHT', ETHT: 'ET2', ET2: 'AET' };
  const FB_LABEL = {
    H1: 'Hiệp 1', HT: 'Nghỉ giữa hiệp', H2: 'Hiệp 2', FT: 'Hết 90 phút',
    ET1: 'Hiệp phụ 1', ETHT: 'Nghỉ hiệp phụ', ET2: 'Hiệp phụ 2', AET: 'Hết hiệp phụ',
    PEN: 'Luân lưu', END: 'Kết thúc',
  };
  function fbCreate(o) {
    o = o || {};
    return {
      sport: 'football', allowDraw: !!o.allowDraw, subsLimit: o.subsLimit || 5,
      phase: 'H1', goals: [0, 0], cards: [{}, {}], subs: [0, 0],
      pen: { kicks: [[], []], sudden: false }, over: false, winner: null, events: [], flags: [],
    };
  }
  function fbOnField(s, t) {
    const reds = Object.values(s.cards[t]).filter((c) => c.red).length;
    return 11 - reds;
  }
  function fbGoal(s, team, own) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over || !['H1', 'H2', 'ET1', 'ET2'].includes(n.phase)) {
      n.flags.push('Chỉ ghi bàn khi đang trong hiệp'); return n;
    }
    const scorer = own ? other(team) : team;
    n.goals[scorer]++;
    n.events.push(own ? `Phản lưới: bàn cho đội ${scorer + 1}` : `Bàn thắng cho đội ${scorer + 1}`);
    return n;
  }
  function fbCard(s, team, player, kind) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    const c = n.cards[team][player] || (n.cards[team][player] = { y: 0, red: false });
    if (c.red) { n.flags.push(`Cầu thủ số ${player} đã bị đuổi`); return n; }
    if (kind === 'Y') {
      c.y++;
      if (c.y >= 2) { c.red = true; n.events.push(`Thẻ vàng thứ 2: số ${player} (đội ${team + 1}) nhận thẻ đỏ, rời sân`); }
      else n.events.push(`Thẻ vàng: số ${player} (đội ${team + 1})`);
    } else {
      c.red = true; n.events.push(`Thẻ đỏ trực tiếp: số ${player} (đội ${team + 1}) rời sân`);
    }
    if (fbOnField(n, team) < 7) {
      n.flags.push('Dưới 7 cầu thủ: trận bị hủy theo luật'); n.over = true; n.winner = other(team);
      n.events.push(`Đội ${team + 1} còn dưới 7 người: trận dừng, đội ${other(team) + 1} thắng`);
    }
    return n;
  }
  function fbSub(s, team) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    if (n.subs[team] >= n.subsLimit) { n.flags.push(`Đội ${team + 1} đã dùng đủ ${n.subsLimit} lần thay người`); return n; }
    n.subs[team]++; n.events.push(`Đội ${team + 1} thay người (${n.subs[team]}/${n.subsLimit})`);
    return n;
  }
  function fbPenRound(n) {
    const k = n.pen.kicks, g = [k[0].filter(Boolean).length, k[1].filter(Boolean).length];
    const t = [k[0].length, k[1].length];
    if (t[0] === t[1] && t[0] >= 5) {
      if (g[0] !== g[1]) { n.over = true; n.winner = g[0] > g[1] ? 0 : 1; n.phase = 'END'; }
      else if (!n.pen.sudden) { n.pen.sudden = true; n.flags.push('Hoà sau 5 lượt: đá đến khi có người thắng (mỗi đội 1 lượt)'); }
    } else if (t[0] <= 5 && t[1] <= 5) {
      const left = [5 - t[0], 5 - t[1]];
      if (g[0] > g[1] + left[1]) { n.over = true; n.winner = 0; n.phase = 'END'; }
      else if (g[1] > g[0] + left[0]) { n.over = true; n.winner = 1; n.phase = 'END'; }
    }
  }
  function fbPen(s, team, scored) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.phase !== 'PEN' || n.over) return n;
    const k = n.pen.kicks;
    if (k[team].length > k[other(team)].length) { n.flags.push('Đến lượt đội kia sút'); return n; }
    k[team].push(!!scored);
    n.events.push(`Luân lưu đội ${team + 1}: ${scored ? 'vào' : 'hụt'}`);
    fbPenRound(n);
    if (n.over) n.events.push(`Đội ${n.winner + 1} thắng loạt luân lưu`);
    return n;
  }
  function fbNext(s) {
    const n = clone(s); n.events = []; n.flags = [];
    if (n.over) return n;
    const p = n.phase;
    if (FB_FLOW[p]) {
      n.phase = FB_FLOW[p];
    } else if (p === 'FT' || p === 'AET') {
      if (n.goals[0] !== n.goals[1]) { n.over = true; n.winner = n.goals[0] > n.goals[1] ? 0 : 1; n.phase = 'END'; }
      else if (n.allowDraw) { n.over = true; n.winner = null; n.phase = 'END'; n.events.push('Hòa (giải cho phép hòa)'); }
      else if (p === 'FT') { n.phase = 'ET1'; n.events.push('Hòa: đá hiệp phụ'); }
      else { n.phase = 'PEN'; n.events.push('Hòa sau hiệp phụ: đá luân lưu'); }
      return n;
    } else return n;
    if (n.phase === 'FT' || n.phase === 'AET') {
      // outcome decided on the next press, so the referee can still add stoppage goals
    }
    n.events.push(`Chuyển sang: ${FB_LABEL[n.phase]}`);
    return n;
  }

  const api = {
    gameWinner,
    pbCreate, pbRally, pbCall, pbCourt,
    pbrCreate, pbrRally,
    bdCreate, bdRally, bdServerPlayer, bdCourt,
    ttCreate, ttRally, ttServer,
    tnCreate, tnRally: tnRallyFull, tnPointLabel, tnCurrentServer,
    fbCreate, fbGoal, fbCard, fbSub, fbPen, fbNext, fbOnField, FB_LABEL,
  };
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.Engine = api;
})(typeof window !== 'undefined' ? window : globalThis);
