"""Build the offline 3D asset from the same floor data/image as Flutter's 2D view.

Run from the repository root: python3 apps/app/tool/venue_map/build.py
Requires the configured Flutter SDK (for its bundled font-subset executable).
"""
import base64
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
APP = ROOT.parent.parent
REPO = APP.parent.parent
PLAN = json.loads((APP / 'assets/venue_map/floor_plan.json').read_text())


def encoded(path):
    return base64.b64encode(path.read_bytes()).decode()


# Use the app's Noto Sans JP, keeping only glyphs used by offline map labels.
characters = set(chr(i) for i in range(32, 127))
for place in PLAN['places']:
    for name in [*place['name'].values(), *place.get('mapLabel', {}).values()]:
        characters.update(name)
sdk = REPO / '.fvm/flutter_sdk'
subsetter = next((sdk / 'bin/cache/artifacts/engine').glob('*/font-subset'), None)
if subsetter is None:
    raise RuntimeError('Run fvm flutter precache before generating the 3D map.')
# Use the exact Material glyphs from the configured SDK, as Flutter's 2D view does.
icon_source = (sdk / 'packages/flutter/lib/src/material/icons.dart').read_text()
icon_names = {place['materialIcon'] for place in PLAN['places'] if place['type'] == 'facility'}
icons = {}
for name in sorted(icon_names):
    match = re.search(rf'static const IconData {re.escape(name)} = IconData\((0x[0-9a-f]+),', icon_source)
    if not match:
        raise RuntimeError(f'Material icon not found: {name}')
    icons[name] = chr(int(match[1], 16))
with tempfile.TemporaryDirectory() as directory:
    font = Path(directory) / 'venue-map.ttf'
    subprocess.run(
        [str(subsetter), str(font), str(APP / 'res/assets/fonts/NotoSansJP/NotoSansJP-VariableFont.ttf')],
        input=' '.join(f'optional:0x{ord(char):x}' for char in sorted(characters)) + '\n',
        text=True, check=True, capture_output=True,
    )
    font_data = encoded(font)
    icon_font = Path(directory) / 'venue-map-icons.otf'
    subprocess.run(
        [str(subsetter), str(icon_font), str(sdk / 'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')],
        input=' '.join(f'0x{ord(char):x}' for char in icons.values()) + '\n',
        text=True, check=True, capture_output=True,
    )
    icon_font_data = encoded(icon_font)

html = (ROOT / 'template.html').read_text()
for key, value in {
    '__FONT__': font_data,
    '__ICON_FONT__': icon_font_data,
    '__ICONS__': json.dumps(icons, separators=(',', ':')),
    '__ICON_LICENSE__': (sdk / 'bin/cache/artifacts/material_fonts/MaterialIcons_LICENSE.txt').read_text(),
    '__VENDOR__': (ROOT / 'vendor/three-r160.js').read_text(),
    '__PLAN__': json.dumps(PLAN, ensure_ascii=False, separators=(',', ':')),
    '__ART__': encoded(APP / PLAN['artAsset']),
    '__ART_DARK__': encoded(APP / PLAN['artAssetDark']),
    '__LABEL_LAYOUT__': (ROOT / 'label-layout.js').read_text(),
    '__SCENE__': (ROOT / 'scene.js').read_text(),
}.items():
    assert html.count(key) == 1, key
    html = html.replace(key, value)
(APP / 'assets/html/venue_floor_plan_webview.html').write_text(html)
print(f'Built offline venue map ({len(html):,} characters).')
