#!/usr/bin/env python3
"""
Chạy Flutter integration test, ghi kết quả + lỗi vào report.json

Cách dùng:
  python scripts/run-and-report.py                              # chạy tất cả
  python scripts/run-and-report.py flow_auth_test.dart           # chạy 1 file
  python scripts/run-and-report.py flow_auth_test.dart --update  # chạy + update Excel
"""

import json, os, re, subprocess, sys
from datetime import datetime

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
INTEGRATION_DIR = os.path.join(PROJECT, 'integration_test')
REPORT_DIR = os.path.join(PROJECT, 'test_reports')
TC_RE = re.compile(r'(TC-FLUTTER-[A-Z]+-\d+)')
TIMESTAMP = datetime.now().strftime('%Y%m%d_%H%M%S')

def run_flutter_test(target: str = '') -> str:
    """Chạy flutter test và trả về raw output."""
    if target:
        test_path = os.path.join(INTEGRATION_DIR, target) if not target.startswith(INTEGRATION_DIR) else target
    else:
        test_path = INTEGRATION_DIR

    # Tìm flutter.exe trong PATH hoặc các vị trí phổ biến
    flutter_cmd = 'flutter'
    for path in os.environ.get('PATH', '').split(';'):
        candidate = os.path.join(path, 'flutter.bat')
        if os.path.exists(candidate):
            flutter_cmd = candidate
            break
        candidate2 = os.path.join(path, 'flutter.exe')
        if os.path.exists(candidate2):
            flutter_cmd = candidate2
            break
    # Fallback: đường dẫn tuyệt đối
    if flutter_cmd == 'flutter':
        for base in ['C:\\flutter\\bin', 'D:\\flutter\\bin', os.path.expanduser('~\\flutter\\bin')]:
            candidate = os.path.join(base, 'flutter.bat')
            if os.path.exists(candidate):
                flutter_cmd = candidate
                break

    print(f'▶️  Chạy: {flutter_cmd} test {test_path}')
    print('⏳  Đang chạy (chờ build + install)...\n')

    # Dùng --machine để parse, nhưng realtime in stdout ra màn hình
    import subprocess as sp
    process = sp.Popen(
        [flutter_cmd, 'test', '--machine', test_path],
        stdout=sp.PIPE, stderr=sp.STDOUT, text=True,
        cwd=PROJECT, shell=True
    )

    output_lines = []
    for line in process.stdout:
        line = line.rstrip('\n\r')
        output_lines.append(line)
        # In ra màn hình nếu không phải JSON machine event
        if not line.startswith('{'):
            print(line)
        else:
            # Thử parse để hiển thị progress
            try:
                ev = json.loads(line)
                if ev.get('type') == 'testStart':
                    print(f'  🔄 {ev.get("name", "")}')
                elif ev.get('type') == 'testDone':
                    name = ev.get('name', '')
                    passed = ev.get('result') == 'success'
                    icon = '✅' if passed else '❌'
                    print(f'  {icon} {name} ({ev.get("totalTime",0)}ms)')
            except:
                pass

    process.wait()
    return '\n'.join(output_lines)

def parse_results(raw: str) -> dict:
    """Parse machine output thành report."""
    events = []
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue

    # Lưu test names
    test_names = {}
    for ev in events:
        if ev.get('type') == 'testStart':
            tid = ev.get('testID')
            name = ev.get('name', '')
            if tid is not None:
                test_names[tid] = name

    results = []
    for ev in events:
        if ev.get('type') == 'testDone':
            tid = ev.get('testID')
            name = test_names.get(tid, '')
            tc_match = TC_RE.search(name)
            passed = ev.get('result') == 'success'
            results.append({
                'id': tc_match.group(0) if tc_match else name,
                'name': name,
                'status': 'Pass' if passed else 'Fail',
                'totalTime': ev.get('totalTime', 0),
            })

    # Thống kê
    total = len(results)
    passed = sum(1 for r in results if r['status'] == 'Pass')
    failed = total - passed
    failures = [r for r in results if r['status'] == 'Fail']

    return {
        'metadata': {
            'timestamp': datetime.now().isoformat(),
            'total': total,
            'passed': passed,
            'failed': failed,
            'duration_ms': sum(r['totalTime'] for r in results if isinstance(r.get('totalTime'), (int, float))),
        },
        'summary': f'{passed}/{total} passed, {failed} failed',
        'testCases': results,
        'failures': failures,
    }

def save_report(report: dict, target: str = ''):
    """Ghi report ra file JSON + TXT."""
    os.makedirs(REPORT_DIR, exist_ok=True)

    prefix = target.replace('.dart', '') if target else 'all'
    json_path = os.path.join(REPORT_DIR, f'{prefix}_report.json')
    txt_path = os.path.join(REPORT_DIR, f'{prefix}_report.txt')

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    # Ghi file text ngắn gọn
    with open(txt_path, 'w', encoding='utf-8') as f:
        f.write(f"=== KẾT QUẢ TEST {report['metadata']['timestamp']} ===\n")
        f.write(f"{report['summary']}\n")
        f.write(f"Thời gian: {report['metadata']['duration_ms']}ms\n\n")
        if report['failures']:
            f.write("--- FAILURES ---\n")
            for r in report['failures']:
                f.write(f"  ❌ {r['id']}: {r['name']}\n")
        f.write("\n--- TẤT CẢ ---\n")
        for r in report['testCases']:
            icon = '✅' if r['status'] == 'Pass' else '❌'
            f.write(f"  {icon} {r['id']}: {r['status']}\n")

    print(f'\n📄 Report: {json_path}')
    print(f'📄 Summary: {txt_path}')
    return json_path

def update_excel(report: dict):
    """Gọi Python script update-results.py để cập nhật Excel."""
    results_path = os.path.join(REPORT_DIR, '_flutter_results.json')

    # Tạo file results.json đúng format cho update-results.py
    results_data = [
        {'id': tc['id'], 'status': tc['status'], 'screenshot': ''}
        for tc in report['testCases']
    ]
    with open(results_path, 'w', encoding='utf-8') as f:
        json.dump(results_data, f, ensure_ascii=False, indent=2)

    # Gọi update-results.py
    update_script = os.path.join(PROJECT, 'test_docs', 'update-results.py')
    if os.path.exists(update_script):
        print(f'\n▶️  Cập nhật Excel...')
        subprocess.run(['python', update_script, results_path], cwd=PROJECT)

def main():
    target = ''
    update_excel_flag = False

    for arg in sys.argv[1:]:
        if arg == '--update':
            update_excel_flag = True
        elif not arg.startswith('-'):
            target = arg

    raw = run_flutter_test(target)
    report = parse_results(raw)
    save_report(report, target)

    print(f"\n{'='*50}")
    print(f"  {report['summary']}")
    print(f"{'='*50}")
    if report['failures']:
        print(f"\n❌  FAILED ({len(report['failures'])}):")
        for r in report['failures']:
            print(f"    - {r['id']}")

    if update_excel_flag:
        update_excel(report)

if __name__ == '__main__':
    main()
