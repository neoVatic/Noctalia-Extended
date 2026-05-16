#!/usr/bin/env python3
import json, os, sys, shutil

config_dir = os.path.expanduser("~/.config/niri")
config_file = os.path.join(config_dir, "config.kdl")
windows_file = os.path.join(config_dir, "noctalia-windows.kdl")
bak_file = os.path.join(config_dir, "config.kdl.nobak")
settings_file = os.path.expanduser("~/.config/noctalia/settings.json")

if not os.path.isfile(settings_file) or not os.path.isfile(config_file):
    sys.exit(0)

with open(settings_file) as f:
    settings_data = json.load(f)
    enabled = settings_data.get("general", {}).get("roundedCornersEnabled", False)

include_line = 'include "./noctalia-windows.kdl"'

with open(config_file) as f:
    config_content = f.read()

if include_line not in config_content:
    if not os.path.isfile(bak_file):
        shutil.copy2(config_file, bak_file)
    existing_include = 'include "./noctalia.kdl"'
    if existing_include in config_content:
        config_content = config_content.replace(existing_include, include_line + "\n" + existing_include)
    else:
        config_content += "\n" + include_line + "\n"
    with open(config_file, 'w') as f:
        f.write(config_content)

if enabled:
    with open(windows_file, 'w') as f:
        f.write('''window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}
''')
else:
    with open(windows_file, 'w') as f:
        f.write('')
