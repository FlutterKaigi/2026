"""Build a portable HTML proposal using only the Python standard library."""
from pathlib import Path
import base64
import json

ROOT = Path(__file__).resolve().parent
SRC = ROOT / 'src'


def uri(path):
    return 'data:image/png;base64,' + base64.b64encode(path.read_bytes()).decode()


vendor = (ROOT.parent.parent / 'tool/venue_map/vendor/three-r160.js').read_text()
model = (SRC / 'floor-plan.js').read_text()
art = uri(SRC / 'floor-map-gpt-image.png')
# Register the generated image's outer wall (82,70)–(1660,833) to the reference.
art_box = {'x': 35.43, 'y': 6.89, 'w': 799.52, 'h': 413.30}
art_script = 'const MAP_ART=' + json.dumps(art) + ';\nconst ART_BOX=' + json.dumps(art_box) + ';\n'
scene = (SRC / 'scene3d.js').read_text()
scene_html = '''<!doctype html><html lang="ja"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>
*{box-sizing:border-box}body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Hiragino Kaku Gothic ProN",Meiryo,sans-serif;background:#f4f3f7;overflow:hidden}#stage,#labels{position:absolute;inset:0}#labels{pointer-events:none;overflow:hidden}canvas{display:block;touch-action:none}.label{position:absolute;transform:translate(-50%,-50%);border:0;background:transparent;pointer-events:auto;color:var(--color);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;border-radius:8px;white-space:nowrap;padding:6px;line-height:1.3;cursor:pointer;text-shadow:0 1px 3px #fff}.label strong{font-size:14px}.label small{font-size:10px;letter-spacing:.08em}.label.hall{min-height:44px}.label.foyer{font-size:12px;background:#ffffffbd;padding:4px 7px}.label.foyer strong{font-size:15px}.label.facility{background:#fff;width:32px;height:32px;font-size:15px;font-weight:600;border:1px solid #ddd3e6;box-shadow:0 2px 6px #35254512}.label:hover,.label.selected{background:#fffffff0;outline:2px solid var(--color)}.label[hidden]{display:none}.label:focus-visible{outline:3px solid #9277be}
</style><div id="stage"></div><div id="labels"></div><script type="module">'''
scene_html += vendor + '\n{\n' + model + art_script + scene + '\n}\n</script></html>'
html = (SRC / 'venue-map.template.html').read_text()
replacements = {
    '__BRAND_MARK__': uri(SRC / 'brand-mark.png'),
    '__REFERENCE_PLAN__': uri(SRC / 'reference-plan.png'),
    '__THREE_SCENE_BASE64__': base64.b64encode(scene_html.encode()).decode(),
    '__PROTOTYPE_SCRIPT__': model + art_script + (SRC / 'prototype.js').read_text(),
}
for key, value in replacements.items():
    assert html.count(key) == 1, key
    html = html.replace(key, value)
assert '__PROTOTYPE_SCRIPT__' not in html
(ROOT / 'venue-map.html').write_text(html)
print(f'Built {ROOT / "venue-map.html"} ({len(html):,} characters)')
