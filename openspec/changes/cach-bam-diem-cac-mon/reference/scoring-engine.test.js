const E = require('./scoring-engine.js');
const assert = require('assert');
let n = 0; const ok = (c, m) => { assert(c, m); n++; };

// Pickleball side-out doubles
let s = E.pbCreate({ doubles: true });
ok(E.pbCall(s) === '0-0-2', 'start 0-0-2');
s = E.pbRally(s, 1); // server team 0 serves, team 1 wins -> serverNo 2 is first server so side-out directly
ok(s.serving === 1 && s.serverNo === 1 && s.score[1] === 0, 'start 0-0-2 loss = side out, no point');
s = E.pbRally(s, 1); ok(s.score[1] === 1, 'serving team wins +1');
s = E.pbRally(s, 0); ok(s.serving === 1 && s.serverNo === 2 && s.score[0] === 0, 'receiver wins => serve 2 no point');
s = E.pbRally(s, 0); ok(s.serving === 0 && s.serverNo === 1, 'second loss => side out');
// game to 11 win by 2
s = E.pbCreate({ doubles: false });
for (let i = 0; i < 10; i++) s = E.pbRally(s, 0);
ok(!s.over && s.score[0] === 10, '10-0 not over');
s = E.pbRally(s, 0); ok(s.over && s.matchWinner === 0, '11-0 wins');
// win by 2
s = E.pbCreate({ doubles: false });
s.score = [10, 10]; s.serving = 0; s = E.pbRally(s, 0); ok(!s.over, '11-10 continues');
s = E.pbRally(s, 0); ok(s.over, '12-10 ends');
// singles no serve 2
s = E.pbCreate({ doubles: false }); s = E.pbRally(s, 1);
ok(s.serving === 1 && s.serverNo === 1, 'singles side out immediately');
ok(E.pbCourt(E.pbCreate({doubles:false})) === 'phải', 'court even right');

// Rally pickleball
let r = E.pbrCreate({ bestOf: 3 });
r = E.pbrRally(r, 1); ok(r.score[1] === 1 && r.serving === 1, 'rally: receiver wins point + serve');
let r2 = E.pbrCreate({ bestOf: 1, target: 11, cap: 15 }); r2.score = [14, 14]; r2 = E.pbrRally(r2, 0);
ok(r2.over, 'cap 15 wins at once');

// Badminton
let b = E.bdCreate({ doubles: false });
b = E.bdRally(b, 1); ok(b.serving === 1 && b.score[1] === 1, 'bd winner serves');
let b2 = E.bdCreate(); b2.score = [20, 20]; b2.serving = 0; b2 = E.bdRally(b2, 0);
ok(!b2.over, '21-20 continues'); b2 = E.bdRally(b2, 0); ok(b2.games[0] === 1, '22-20 ends game');
let b3 = E.bdCreate(); b3.score = [29, 29]; b3 = E.bdRally(b3, 1); ok(b3.games[1] === 1, '30 cap');
let b4 = E.bdCreate(); b4.score = [10, 3]; b4 = E.bdRally(b4, 0);
ok(b4.flags.some(f => /60/.test(f)), '60s interval at 11');

// Table tennis
let t = E.ttCreate();
ok(E.ttServer(t) === 0, 'tt first server 0');
t = E.ttRally(t, 0); ok(E.ttServer(t) === 0, 'after 1 pt same server');
t = E.ttRally(t, 1); ok(E.ttServer(t) === 1, 'after 2 pts server changes');
let t2 = E.ttCreate(); t2.score = [10, 10]; ok(E.ttServer(t2) === 0, '10-10 server same as even total');
t2 = E.ttRally(t2, 0); ok(E.ttServer(t2) === 1, 'deuce: serve every point');
t2 = E.ttRally(t2, 1); ok(E.ttServer(t2) === 0, 'deuce alternates');
let t3 = E.ttCreate({ bestOf: 5 }); t3.score = [10, 5]; t3 = E.ttRally(t3, 0);
ok(t3.games[0] === 1 && t3.firstServer === 1 && t3.score[0] === 0, 'game won, first server flips');

// Tennis
let n1 = E.tnCreate(); for (let i = 0; i < 4; i++) n1 = E.tnRally(n1, 0);
ok(n1.games[0] === 1 && n1.server === 1, 'game won, server alternates');
let d = E.tnCreate(); d.pts = [3, 3]; ok(E.tnPointLabel(d, 0) === '40', 'deuce 40');
d = E.tnRally(d, 0); ok(E.tnPointLabel(d, 0) === 'AD' && E.tnPointLabel(d, 1) === '40', 'ad');
d = E.tnRally(d, 1); ok(E.tnPointLabel(d, 0) === '40', 'back to deuce');
let na = E.tnCreate({ noAd: true }); na.pts = [3, 3]; na = E.tnRally(na, 1); ok(na.games[1] === 1, 'no-ad: next point wins');
let tb = E.tnCreate(); tb.games = [6, 5]; tb.pts = [3, 0]; // 6-5, win game => 7-5 set
tb = E.tnRally(tb, 0); ok(tb.setsWon[0] === 1, '7-5 set');
let tb2 = E.tnCreate(); tb2.games = [5, 6]; tb2.pts = [0, 3]; tb2.server = 0; tb2 = E.tnRally(tb2, 0); // 6-6
tb2.games = [5,6]; // reset check below
let t66 = E.tnCreate(); t66.games = [5, 6]; t66.pts = [3, 0]; t66 = E.tnRally(t66, 0);
ok(t66.tb && t66.tb.target === 7, '6-6 starts tie-break 7');
t66.tb.pts = [6, 6]; t66 = E.tnRally(t66, 0); ok(!!t66.tb, '7-6 in tb continues');
t66 = E.tnRally(t66, 0); ok(!t66.tb && t66.setsWon[0] === 1, 'tb 8-6 wins set');
let mt2 = E.tnCreate({ finalMode: 'MATCH_TB10' }); mt2.setsWon = [1, 0]; mt2.games = [2, 5]; mt2.pts = [0, 3];
mt2 = E.tnRally(mt2, 1);
ok(mt2.setsWon[0] === 1 && mt2.setsWon[1] === 1, 'sets level 1-1');
ok(mt2.tb && mt2.tb.target === 10 && mt2.tb.kind === 'match', 'match tb 10 starts instead of 3rd set');
mt2.tb.pts = [9, 9]; mt2 = E.tnRally(mt2, 0); ok(!!mt2.tb, '10-9 continues');
mt2 = E.tnRally(mt2, 0); ok(mt2.over && mt2.matchWinner === 0, '11-9 wins match');
// TB server: first serves 1, then 2 each
let ts = E.tnCreate(); ts.games=[5,6]; ts.pts=[3,0]; ts = E.tnRally(ts,0); const first=E.tnCurrentServer(ts);
ts = E.tnRally(ts,0); ok(E.tnCurrentServer(ts)!==first,'tb: after 1 pt server changes');
ts = E.tnRally(ts,0); ok(E.tnCurrentServer(ts)!==first,'tb: still other for pt 2');
ts = E.tnRally(ts,0); ok(E.tnCurrentServer(ts)===first,'tb: back after 2 pts');
// Football
let f = E.fbCreate();
f = E.fbGoal(f, 0); ok(f.goals[0] === 1, 'goal');
f = E.fbGoal(f, 0, true); ok(f.goals[1] === 1, 'own goal to other team');
f = E.fbCard(f, 0, 7, 'Y'); f = E.fbCard(f, 0, 7, 'Y'); ok(E.fbOnField(f, 0) === 10 && f.cards[0][7].red, '2 yellows = red');
f = E.fbNext(f); ok(f.phase === 'HT', 'H1->HT'); f = E.fbNext(f); f = E.fbNext(f); ok(f.phase === 'FT', 'FT');
f = E.fbNext(f); ok(f.phase === 'ET1', 'tie -> ET');
f = E.fbNext(f); f = E.fbNext(f); f = E.fbNext(f); ok(f.phase === 'AET', 'AET');
f = E.fbNext(f); ok(f.phase === 'PEN', 'tie -> PEN');
for (let i = 0; i < 5; i++) { f = E.fbPen(f, 0, true); f = E.fbPen(f, 1, false); }
ok(f.over && f.winner === 0, 'pen 5-0 decided');
let f2 = E.fbCreate(); f2 = E.fbNext(E.fbNext(E.fbNext(f2))); f2 = E.fbGoal(f2, 0);
ok(f2.goals[0] === 0, 'no goal at FT');
let f3 = E.fbCreate({ allowDraw: true }); f3.phase = 'FT'; f3 = E.fbNext(f3); ok(f3.over && f3.winner === null, 'draw allowed');
console.log('OK', n);
