import json

log_file = r"C:\Users\GIGABYTE\.gemini\antigravity-ide\brain\22bfdce0-771c-4676-afc3-43ae3ba282ce\.system_generated\logs\transcript.jsonl"

lines = {}

with open(log_file, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'TOOL_RESPONSE' and 'view_file' in data.get('content', ''):
                content = data['content']
                if 'team_list_screen.dart' in content:
                    # extract lines
                    for part in content.split('\n'):
                        if part.startswith('1:') or part.startswith('50:') or part.startswith('150:') or part.startswith('250:'):
                            # It might be part of the lines
                            pass
                    
                    # A better way: parse the lines directly
                    lines_text = content.split('The following code has been modified to include a line number before every line')
                    if len(lines_text) > 1:
                        code_part = lines_text[1].split('The above content')[0]
                        for code_line in code_part.strip().split('\n'):
                            if ': ' in code_line:
                                num_str, rest = code_line.split(': ', 1)
                                if num_str.isdigit():
                                    lines[int(num_str)] = rest
        except Exception as e:
            pass

# Now lines has all the lines we ever viewed. We viewed 50-150, 150-250, 250-357.
# We also have lines 1-100 from the current file, but we need to adjust the imports and teamServiceProvider.
# Let's read lines 1-50 from the current file and apply the known fixes.
with open(r'd:\Duancanhan\app_quanly_giaidau\lib\features\teams\screens\team_list_screen.dart', 'r', encoding='utf-8') as f:
    current_lines = f.read().split('\n')

for i in range(1, 50):
    if i not in lines:
        lines[i] = current_lines[i-1]

# Apply known fixes to lines 1-50
# add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:uuid/uuid.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/providers/app_providers.dart';
import 'package:app_quanly_giaidau/data/models/team_model.dart';
import 'package:app_quanly_giaidau/providers/team_notifier.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
"""

# Let's just output lines 50 to 357 to a file, and manually prepend the imports and lines 14-49.
out_lines = []
for i in range(50, 358):
    if i in lines:
        out_lines.append(lines[i])

with open(r'd:\Duancanhan\app_quanly_giaidau\scratch_recover.dart', 'w', encoding='utf-8') as f:
    f.write('\n'.join(out_lines))
