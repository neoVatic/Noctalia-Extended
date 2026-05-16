#!/usr/bin/env python3
import json, os, sys, re

niri_file = os.path.expanduser("~/.config/niri/noctalia.kdl")
settings_file = os.path.expanduser("~/.config/noctalia/settings.json")

if not os.path.isfile(niri_file) or not os.path.isfile(settings_file):
    sys.exit(0)

with open(settings_file) as f:
    settings_data = json.load(f)
    enabled = settings_data.get("niriFocusGradient", False)
    to_c = settings_data.get("niriGradientTo")

with open(niri_file) as f:
    content = f.read()

# Remove all existing gradient lines
content = re.sub(r'^[ \t]*active-gradient.*\n?', '', content, flags=re.MULTILINE)

if enabled:
    # Find colors from anywhere in the file
    from_c = None
    if not to_c:
        for m in re.finditer(r'inactive-color\s+"(#[\da-fA-F]+)"', content):
            if to_c is None:
                to_c = m.group(1)
    for m in re.finditer(r'active-color\s+"(#[\da-fA-F]+)"', content):
        if from_c is None:
            from_c = m.group(1)
    if from_c and to_c:
        grad = f'active-gradient from="{from_c}" to="{to_c}"'
        # Only add inside layout block, in focus-ring/border/tab-indicator sections
        def add_in_layout(m):
            block = m.group(1)
            # Only target specific sub-sections
            for sec in ("focus-ring", "border", "tab-indicator"):
                block = re.sub(
                    rf'({re.escape(sec)}\s*\{{[^}}]*?)(active-color\s+"[^"]+")',
                    lambda m2: m2.group(1) + m2.group(2) + '\n        ' + grad,
                    block
                )
            return block
        content = re.sub(
            r'(layout\s*\{.*?\n\})',
            add_in_layout,
            content,
            flags=re.DOTALL
        )

with open(niri_file, 'w') as f:
    f.write(content)
