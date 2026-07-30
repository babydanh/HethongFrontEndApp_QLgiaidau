const fs = require('fs');

function rebuildArb(file) {
  let raw = fs.readFileSync(file, 'utf8').replace(/^﻿/, '');

  // Find placeholder keys (@key with placeholders)
  const placeholderKeys = new Set();
  const placeholderRegex = /"@([\w]+)":\s*\{\s*"placeholders"/g;
  let match;
  while ((match = placeholderRegex.exec(raw)) !== null) {
    placeholderKeys.add(match[1]);
  }

  // Extract all string key-value pairs
  const pairs = [];
  const regex = /"([\w]+)":\s*"((?:[^"\\]|\\.)*)"/g;
  while ((match = regex.exec(raw)) !== null) {
    const key = match[1];
    const value = match[2].replace(/\\"/g, '"');
    if (!key.startsWith('@') && !key.startsWith('@@')) {
      pairs.push([key, value]);
    }
  }

  // Check locale from @@locale
  const localeMatch = raw.match(/"@@locale":\s*"(\w+)"/);
  const locale = localeMatch ? localeMatch[1] : 'vi';

  // Build clean JSON
  let json = '{\n';
  json += '  "@@locale": "' + locale + '",\n';

  const entries = [];
  for (const [k, v] of pairs) {
    const escaped = v.replace(/"/g, '\\"');
    const entry = '  "' + k + '": "' + escaped + '"';
    entries.push(entry);

    // Add placeholder metadata if this key has it
    if (placeholderKeys.has(k)) {
      // The original placeholder key existed, but we need to handle @key entries
    }
  }
  json += entries.join(',\n');
  json += '\n}\n';

  // Now extract and add placeholder objects for keys that have them
  // by reading them from the original content
  for (const pk of placeholderKeys) {
    const pkRegex = new RegExp('"@' + pk.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '":\\s*\\{[^}]*\\}[^}]*\\}', 'g');
    const pkMatch = pkRegex.exec(raw);
    if (pkMatch) {
      // Format the placeholder entry properly
      const pkContent = pkMatch[0]
        .replace(/,\s*$/, '')
        .replace(/\s+/g, ' ')
        .replace(/:\s*/g, ': ')
        .replace(/,\s*/g, ',\n    ');
      json = json.replace('}\n', ',\n  ' + pkMatch[0] + '\n}\n');
    }
  }

  // Final validation - ensure clean JSON
  // Remove any duplicate closing braces
  json = json.replace(/\}\s*\n\}/g, '}\n}');

  fs.writeFileSync(file, json, 'utf8');

  // Validate
  try {
    const parsed = JSON.parse(json);
    console.log(file.split('/').pop() + ': Valid JSON! Keys:', Object.keys(parsed).length - 1);
    return true;
  } catch(e) {
    console.log(file.split('/').pop() + ': Still invalid:', e.message.substring(0, 100));
    // Write debug info
    const lines = json.split('\n');
    const errMatch = e.message.match(/position (\d+)/);
    if (errMatch) {
      const pos = parseInt(errMatch[1]);
      let lineNum = 0;
      let charCount = 0;
      for (let i = 0; i < lines.length; i++) {
        charCount += lines[i].length + 1;
        if (charCount > pos) { lineNum = i + 1; break; }
      }
      console.log('Error near line', lineNum);
      for (let i = Math.max(0, lineNum - 3); i < Math.min(lines.length, lineNum + 2); i++) {
        console.log((i+1) + ': ' + JSON.stringify(lines[i].substring(0, 100)));
      }
    }
    return false;
  }
}

rebuildArb('app_vi.arb');
rebuildArb('app_en.arb');
