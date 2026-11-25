import json
import os
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import app_video_clips as av  # noqa: E402
import flutter_json_to_allure as fa  # noqa: E402
from test_flutter_json_to_allure import SUITE, ev_done, ev_start, write_events  # noqa: E402


def seg(start_ms, dur_s, name=None):
    return av.Segment(name or f"seg_{start_ms}.mp4", start_ms, dur_s)


class PlanClipsTest(unittest.TestCase):
    def test_single_segment_offset_and_duration(self):
        plan = av.plan_clips([seg(1_000_000, 170)], 1_010_000, 1_030_000, pad_s=0)
        self.assertEqual(len(plan), 1)
        self.assertEqual(plan[0][0].name, "seg_1000000.mp4")
        self.assertAlmostEqual(plan[0][1], 10.0)
        self.assertAlmostEqual(plan[0][2], 20.0)

    def test_test_spanning_two_segments_gives_two_parts(self):
        segs = [seg(1_000_000, 170), seg(1_171_000, 170)]
        plan = av.plan_clips(segs, 1_160_000, 1_180_000, pad_s=0)
        self.assertEqual([p[0].name for p in plan], ["seg_1000000.mp4", "seg_1171000.mp4"])
        self.assertAlmostEqual(plan[0][1], 160.0)
        self.assertAlmostEqual(plan[0][2], 10.0)  # tới hết đoạn 1
        self.assertAlmostEqual(plan[1][1], 0.0)
        self.assertAlmostEqual(plan[1][2], 9.0)

    def test_padding_is_clamped_to_segment(self):
        plan = av.plan_clips([seg(1_000_000, 50)], 1_000_500, 1_049_800, pad_s=1)
        self.assertAlmostEqual(plan[0][1], 0.0)
        self.assertAlmostEqual(plan[0][2], 50.0)

    def test_no_overlap_returns_empty(self):
        self.assertEqual(av.plan_clips([seg(1_000_000, 10)], 2_000_000, 2_005_000), [])

    def test_clip_length_is_capped(self):
        plan = av.plan_clips([seg(0, 170)], 0, 169_000, pad_s=0, max_s=60)
        self.assertAlmostEqual(sum(p[2] for p in plan), 60.0)


class ListSegmentsTest(unittest.TestCase):
    def test_reads_epoch_from_file_name_and_sorts(self):
        with tempfile.TemporaryDirectory() as tmp:
            for n in ("seg_2000.mp4", "seg_1000.mp4", "ghi-chu.txt"):
                open(os.path.join(tmp, n), "wb").close()
            with mock.patch.object(av, "probe_duration", return_value=12.5):
                segs = av.list_segments(tmp)
            self.assertEqual([s.start_ms for s in segs], [1000, 2000])
            self.assertEqual(segs[0].duration_s, 12.5)


class ConvertWithVideoTest(unittest.TestCase):
    def test_every_case_gets_a_video_attachment_not_only_failed(self):
        events = [
            {"type": "suite", "time": 0, "suite": {"id": 0, "platform": "vm", "path": SUITE}},
            ev_start(1, "TC-VID-01 xanh", t=1000), ev_done(1, t=5000),
            ev_start(2, "TC-VID-02 đỏ", t=6000), ev_done(2, result="failure", t=9000),
        ]
        with tempfile.TemporaryDirectory() as tmp:
            src, out, vid = os.path.join(tmp, "r.json"), os.path.join(tmp, "out"), os.path.join(tmp, "vid")
            os.makedirs(vid)
            write_events(src, events)
            made = []

            def fake_cut(plan, dest, video_dir):
                made.append(dest)
                open(dest, "wb").write(b"mp4")
                return True

            with mock.patch.object(av, "list_segments", return_value=[seg(1_000_000, 170)]), \
                    mock.patch.object(av, "cut_clip", side_effect=fake_cut):
                n = fa.convert(src, out, video_dir=vid, run_start_ms=1_000_000)
            self.assertEqual(n, 2)
            results = [json.load(open(os.path.join(out, f))) for f in os.listdir(out) if f.endswith("-result.json")]
            for r in results:
                kinds = [a["type"] for a in r["attachments"]]
                self.assertIn("video/mp4", kinds, r["name"])
            self.assertEqual(len(made), 2)
            self.assertEqual(len([f for f in os.listdir(out) if f.endswith(".mp4")]), 2)

    def test_missing_video_does_not_break_conversion(self):
        events = [
            {"type": "suite", "time": 0, "suite": {"id": 0, "platform": "vm", "path": SUITE}},
            ev_start(1, "TC-VID-01", t=1000), ev_done(1, t=5000),
        ]
        with tempfile.TemporaryDirectory() as tmp:
            src, out = os.path.join(tmp, "r.json"), os.path.join(tmp, "out")
            write_events(src, events)
            with mock.patch.object(av, "list_segments", return_value=[]):
                n = fa.convert(src, out, video_dir=tmp, run_start_ms=1)
            self.assertEqual(n, 1)


if __name__ == "__main__":
    unittest.main()
