"""Build the offline 3D asset from the same floor data/image as Flutter's 2D view.

Run from the repository root: python3 apps/app/tool/venue_map/build.py
Requires the configured Flutter SDK (for its bundled font-subset executable).
"""
import base64
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
APP = ROOT.parent.parent
REPO = APP.parent.parent
PLAN = json.loads((APP / 'assets/venue_map/floor_plan.json').read_text())


def encoded(path):
    return base64.b64encode(path.read_bytes()).decode()


# Use the app's Noto Sans JP, keeping only glyphs used by offline map labels.
characters = set(chr(i) for i in range(32, 127)) | set('ⓘ↪')
for place in PLAN['places']:
    for name in place['name'].values():
        characters.update(name)
subsetter = next((REPO / '.fvm/flutter_sdk/bin/cache/artifacts/engine').glob('*/font-subset'), None)
if subsetter is None:
    raise RuntimeError('Run fvm flutter precache before generating the 3D map.')
with tempfile.TemporaryDirectory() as directory:
    font = Path(directory) / 'venue-map.ttf'
    subprocess.run(
        [str(subsetter), str(font), str(APP / 'res/assets/fonts/NotoSansJP/NotoSansJP-VariableFont.ttf')],
        input=' '.join(f'optional:0x{ord(char):x}' for char in sorted(characters)) + '\n',
        text=True, check=True, capture_output=True,
    )
    font_data = encoded(font)

html = (ROOT / 'template.html').read_text()
for key, value in {
    '__FONT__': font_data,
    '__VENDOR__': (ROOT / 'vendor/three-r160.js').read_text(),
    '__PLAN__': json.dumps(PLAN, ensure_ascii=False, separators=(',', ':')),
    '__ART__': encoded(APP / 'assets/venue_map/floor_map.png'),
    '__SCENE__': (ROOT / 'scene.js').read_text(),
}.items():
    assert html.count(key) == 1, key
    html = html.replace(key, value)
(APP / 'assets/html/venue_floor_plan_webview.html').write_text(html)
print(f'Built offline venue map ({len(html):,} characters).')
