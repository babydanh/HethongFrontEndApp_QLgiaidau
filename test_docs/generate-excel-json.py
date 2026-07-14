#!/usr/bin/env python3
"""Parse Flutter testcases from markdown → Excel + JSON."""

import json, os, re, sys
from datetime import datetime

PROJECT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
DOCS = os.path.join(PROJECT, 'test_docs')
EXCEL_PATH = os.path.join(DOCS, 'testcases.xlsx')
JSON_PATH = os.path.join(DOCS, 'testcases.json')

FILES = [
    'testcases-flutter-auth-payment-notification.md',
    'testcases-flutter-bracket-match-ranking.md',
    'testcases-flutter-community-referee-admin.md',
    'testcases-flutter-home-dashboard-upload.md',
]

TC_RE = re.compile(r'^### (TC-FLUTTER-[A-Z]+-\d+): (.+)$')

def parse_markdown(filepath):
    """Extract testcases from markdown file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    testcases = []
    current = None
    key = None
    value_lines = []

    for line in lines:
        m = TC_RE.match(line)
        if m:
            # Save previous
            if current:
                if key and value_lines:
                    current[key] = '\n'.join(value_lines).strip()
                testcases.append(current)

            current = {'id': m.group(1), 'title': m.group(2).strip(), 'module': '', 'screen': '', 'preconditions': '', 'steps': '', 'expected': '', 'edge_cases': ''}
            key = None
            value_lines = []
            continue

        if current is None:
            continue

        # Parse fields
        stripped = line.strip()
        if stripped.startswith('- **Module**:'):
            current['module'] = stripped.replace('- **Module**:', '').strip()
        elif stripped.startswith('- **Screen**:'):
            current['screen'] = stripped.replace('- **Screen**:', '').strip()
        elif stripped.startswith('- **Preconditions**:'):
            key = 'preconditions'
            value_lines = [stripped.replace('- **Preconditions**:', '').strip()]
        elif stripped.startswith('- **Steps**:'):
            if key and value_lines:
                current[key] = '\n'.join(value_lines).strip()
            key = 'steps'
            value_lines = []
        elif stripped.startswith('- **Expected**:'):
            if key and value_lines:
                current[key] = '\n'.join(value_lines).strip()
            key = 'expected'
            value_lines = []
        elif stripped.startswith('- **Edge cases**:'):
            if key and value_lines:
                current[key] = '\n'.join(value_lines).strip()
            key = 'edge_cases'
            value_lines = []
        elif key and (stripped.startswith('-') or stripped.startswith('1.') or stripped.startswith('2.') or stripped.startswith('3.') or stripped.startswith('4.') or stripped.startswith('5.') or stripped.startswith('6.') or stripped.startswith('7.') or stripped.startswith('8.') or stripped.startswith('9.')):
            value_lines.append(stripped)
        elif key and value_lines and stripped:
            value_lines[-1] += ' ' + stripped

    if current:
        if key and value_lines:
            current[key] = '\n'.join(value_lines).strip()
        testcases.append(current)

    return testcases


def write_excel(testcases):
    """Write testcases to Excel via win32com."""
    try:
        import win32com.client
        excel = win32com.client.Dispatch('Excel.Application')
        excel.Visible = False
        excel.DisplayAlerts = False
        wb = excel.Workbooks.Add()
        ws = wb.ActiveSheet
        ws.Name = 'Flutter Testcases'
        mode = 'win32com'
    except:
        print('win32com not available')
        return

    # Header
    headers = ['ID', 'Module', 'Title', 'Screen', 'Preconditions', 'Steps', 'Expected Result', 'Edge Cases', 'Status', 'Actual Result']
    for i, h in enumerate(headers, 1):
        ws.Cells(1, i).Value = h
        ws.Cells(1, i).Font.Bold = True

    # Data
    for idx, tc in enumerate(testcases, 2):
        ws.Cells(idx, 1).Value = tc['id']
        ws.Cells(idx, 2).Value = tc['module']
        ws.Cells(idx, 3).Value = tc['title']
        ws.Cells(idx, 4).Value = tc['screen']
        ws.Cells(idx, 5).Value = tc.get('preconditions', '')
        ws.Cells(idx, 6).Value = tc.get('steps', '')
        ws.Cells(idx, 7).Value = tc.get('expected', '')
        ws.Cells(idx, 8).Value = tc.get('edge_cases', '')
        ws.Cells(idx, 9).Value = ''  # Status
        ws.Cells(idx, 10).Value = ''  # Actual Result

    # Column widths
    for i, w in enumerate([18, 10, 40, 40, 40, 40, 40, 40, 10, 20], 1):
        ws.Columns(i).ColumnWidth = w

    wb.SaveAs(EXCEL_PATH)
    wb.Close()
    excel.Quit()
    print(f'Excel: {EXCEL_PATH} ({len(testcases)} tests)')


def write_json(testcases):
    """Write testcases to JSON."""
    data = []
    for tc in testcases:
        data.append({
            'id': tc['id'],
            'module': tc['module'],
            'title': tc['title'],
            'screen': tc['screen'],
            'preconditions': tc.get('preconditions', ''),
            'steps': tc.get('steps', ''),
            'expectedResult': tc.get('expected', ''),
            'edgeCases': tc.get('edge_cases', ''),
            'status': '',
            'actualResult': '',
        })
    with open(JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f'JSON: {JSON_PATH} ({len(data)} tests)')


def main():
    all_tcs = []
    for fname in FILES:
        path = os.path.join(DOCS, fname)
        if not os.path.exists(path):
            print(f'Not found: {path}')
            continue
        tcs = parse_markdown(path)
        print(f'{fname}: {len(tcs)} testcases')
        all_tcs.extend(tcs)

    print(f'\nTotal: {len(all_tcs)} testcases')

    write_excel(all_tcs)
    write_json(all_tcs)

    # Module summary
    modules = {}
    for tc in all_tcs:
        m = tc['module']
        modules[m] = modules.get(m, 0) + 1
    print('\nModules:')
    for m, c in sorted(modules.items()):
        print(f'  {m}: {c}')


if __name__ == '__main__':
    main()
