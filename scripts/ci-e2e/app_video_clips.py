#!/usr/bin/env python3
"""Cắt video từng ca test từ các đoạn quay màn hình emulator (job test-app-e2e).

Job quay liên tục bằng `adb shell screenrecord` (mỗi đoạn tối đa ~170 giây, tên `seg_<epoch_ms>.mp4`, epoch là
mốc bắt đầu đoạn). Mỗi ca test có mốc bắt đầu/kết thúc theo đồng hồ thật nên cắt được clip riêng cho cả ca đạt lẫn ca đỏ.
Cần `ffmpeg` và `ffprobe`; thiếu thì không có video, báo cáo Allure vẫn sinh bình thường.
"""
import os
import re
import shutil
import subprocess
import tempfile
from collections import namedtuple

Segment = namedtuple("Segment", "name start_ms duration_s")

SEG_RE = re.compile(r"^seg_(\d+)\.mp4$")
PAD_S = 1.0
MAX_CLIP_S = 300.0


def probe_duration(path):
    """Độ dài (giây) của file video, 0.0 nếu không đọc được."""
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", path],
            capture_output=True, text=True, timeout=60).stdout.strip()
        return float(out)
    except (OSError, ValueError, subprocess.SubprocessError):
        return 0.0


def list_segments(video_dir):
    segs = []
    for name in sorted(os.listdir(video_dir)):
        m = SEG_RE.match(name)
        if not m:
            continue
        duration = probe_duration(os.path.join(video_dir, name))
        if duration > 0:
            segs.append(Segment(name, int(m.group(1)), duration))
    return sorted(segs, key=lambda s: s.start_ms)


def plan_clips(segments, start_ms, stop_ms, pad_s=PAD_S, max_s=MAX_CLIP_S):
    """Danh sách (đoạn, giây bắt đầu trong đoạn, số giây) phủ [start_ms, stop_ms] kể cả đệm hai đầu."""
    lo = start_ms / 1000.0 - pad_s
    hi = stop_ms / 1000.0 + pad_s
    plan, total = [], 0.0
    for s in segments:
        seg_lo = s.start_ms / 1000.0
        seg_hi = seg_lo + s.duration_s
        a, b = max(lo, seg_lo), min(hi, seg_hi)
        if b <= a:
            continue
        length = min(b - a, max_s - total)
        if length <= 0:
            break
        plan.append((s, a - seg_lo, length))
        total += length
    return plan


def cut_clip(plan, dest, video_dir):
    """Cắt và nén các phần trong `plan` thành một file mp4 `dest`. Trả True nếu thành công."""
    if not plan or not shutil.which("ffmpeg"):
        return False
    with tempfile.TemporaryDirectory() as tmp:
        parts = []
        for i, (seg, offset, length) in enumerate(plan):
            part = os.path.join(tmp, f"p{i}.mp4")
            cmd = ["ffmpeg", "-y", "-v", "error", "-ss", f"{offset:.3f}", "-t", f"{length:.3f}",
                   "-i", os.path.join(video_dir, seg.name), "-an", "-vf", "scale=-2:480",
                   "-c:v", "libx264", "-preset", "veryfast", "-crf", "34", "-pix_fmt", "yuv420p",
                   "-movflags", "+faststart", part]
            if subprocess.run(cmd, capture_output=True, timeout=300).returncode != 0 or not os.path.exists(part):
                return False
            parts.append(part)
        if len(parts) == 1:
            shutil.move(parts[0], dest)
            return True
        listing = os.path.join(tmp, "list.txt")
        with open(listing, "w", encoding="utf-8") as fh:
            fh.write("".join(f"file '{p}'\n" for p in parts))
        cmd = ["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", listing, "-c", "copy",
               "-movflags", "+faststart", dest]
        return subprocess.run(cmd, capture_output=True, timeout=300).returncode == 0 and os.path.exists(dest)
