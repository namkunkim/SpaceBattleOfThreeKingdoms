from html.parser import HTMLParser
from pathlib import Path
import re

class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.frames = []
    def handle_starttag(self, tag, attrs):
        if tag == 'iframe':
            self.frames.append(dict(attrs))

root = Path(__file__).resolve().parents[1]
page = Page()
page.feed((root / 'docs/ui/fleet-formations.html').read_text(encoding='utf-8'))
assert len(page.frames) == 1
inner = page.frames[0]['data-srcdoc']
assert 'fleet-formation-board' in inner
assert 'data:image/png;base64,' in inner
assert '__DATA__' not in inner
for doc in ['data/fleet-role-layout.md', 'docs/ui/FLEET-ROLE-LAYOUT.md', 'docs/ui/FORMATION-TAB-SPEC.md']:
    path = root / doc
    links = re.findall(r'\]\(([^)]+\.html)\)', path.read_text(encoding='utf-8'))
    assert links, doc
    for link in links:
        assert (path.parent / link).is_file(), (doc, link)
print('HTML_RECORD_PASS: standalone frame, embedded images, spec document links valid')
