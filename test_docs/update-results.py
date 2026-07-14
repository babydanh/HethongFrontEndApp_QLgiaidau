#!/usr/bin/env python3
"""
Cập nhật kết quả test vào Excel + xuất JSON.

Cách dùng:
  python test_docs/update-results.py results.json

File results.json format:
  [
    {"id": "TC-FLUTTER-AUTH-003", "status": "Pass", "screenshot": "screenshots/001_login.png"},
    {"id": "TC-FLUTTER-AUTH-004", "status": "Fail", "screenshot": "screenshots/002_error.png"}
  ]
"""

import json, os, sys
from datetime import datetime

DOCS = os.path.join(os.path.dirname(os.path.abspath(__file__)))
EXCEL_PATH = os.path.join(DOCS, 'testcases.xlsx')
JSON_PATH = os.path.join(DOCS, 'testcases.json')


def update_excel(results):
    """Update Excel với kết quả test."""
    try:
        import win32com.client
        excel = win32com.client.Dispatch('Excel.Application')
        excel.Visible = False
        excel.DisplayAlerts = False
        wb = excel.Workbooks.Open(EXCEL_PATH)
    except:
        print('[ERROR] Can win32com. Excel khong the mo.')
        return

    ws = wb.ActiveSheet
    updated = 0
    not_found = []

    # Parse results: id → status + screenshot
    result_map = {}
    for r in results:
        result_map[r.get('id', '')] = {
            'status': r.get('status', ''),
            'screenshot': r.get('screenshot', ''),
        }

    # Duyệt sheet, tìm TC ID, update status
    row = 2
    while True:
        tc_id = ws.Cells(row, 1).Value  # Column A = ID
        if tc_id is None or str(tc_id).strip() == '':
            break

        tc_id = str(tc_id).strip()
        if tc_id in result_map:
            info = result_map[tc_id]
            # Chỉ set value — KHÔNG đụng Interior.Color, giữ nguyên format user
            ws.Cells(row, 9).Value = info['status']
            ws.Cells(row, 10).Value = info.get('screenshot', '')

            updated += 1

        row += 1

    wb.Save()
    wb.Close()
    excel.Quit()
    print(f'Da cap nhat: {updated} test cases')
    if not_found:
        print(f'Khong tim thay: {not_found}')


def export_json(results):
    """Xuất results.json chuẩn cho Flutter test."""
    data = []
    for r in results:
        data.append({
            'id': r.get('id', ''),
            'status': r.get('status', ''),
            'screenshot': r.get('screenshot', ''),
            'timestamp': datetime.now().isoformat(),
        })
    # Merge với testcases.json
    if os.path.exists(JSON_PATH):
        with open(JSON_PATH, 'r', encoding='utf-8') as f:
            existing = json.load(f)

        # Update status
        status_map = {r['id']: r['status'] for r in data}
        for tc in existing:
            if tc['id'] in status_map:
                tc['status'] = status_map[tc['id']]

        with open(JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(existing, f, ensure_ascii=False, indent=2)

    print(f'Da xuat JSON: {JSON_PATH}')


def read_file_auto_encoding(filepath):
    """Đọc file với auto-detect encoding (UTF-8, UTF-16)."""
    for enc in ['utf-8', 'utf-16', 'utf-16le']:
        try:
            with open(filepath, 'r', encoding=enc) as f:
                return f.read()
        except (UnicodeDecodeError, UnicodeError):
            continue
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()


def parse_flutter_results(filepath):
    """Parse flutter test --machine output (JSON Lines) -> list of {id, status}."""
    tc_re = __import__('re').compile(r'(TC-FLUTTER-[A-Z]+-\d+)')
    test_names = {}
    results = []

    text = read_file_auto_encoding(filepath)
    events = []
    for l in text.splitlines():
        l = l.strip()
        if not l:
            continue
        try:
            events.append(json.loads(l))
        except json.JSONDecodeError:
            continue

    for ev in events:
        if not isinstance(ev, dict):
            continue
        if ev.get('type') == 'testStart':
            tid = ev.get('testID', ev.get('test', {}).get('id'))
            name = str(ev.get('name', ev.get('test', {}).get('name', '')))
            if tid is not None:
                test_names[tid] = name

    for ev in events:
        if not isinstance(ev, dict):
            continue
        if ev.get('type') == 'testDone':
            tid = ev.get('testID')
            name = test_names.get(tid, '')
            m = tc_re.search(name)
            if not m:
                continue
            results.append({'id': m.group(0), 'status': 'Pass' if ev.get('result') == 'success' else 'Fail', 'screenshot': ''})

    if not results:
        text = read_file_auto_encoding(filepath)
        results = json.loads(text)
    return results


def main():
    if len(sys.argv) < 2:
        print('Cach dung: python test_docs/update-results.py results.json')
        sys.exit(1)

    results = parse_flutter_results(sys.argv[1])
    print(f'Doc {len(results)} ket qua test')
    update_excel(results)
    export_json(results)


if __name__ == '__main__':
    main()
