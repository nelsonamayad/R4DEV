"""
Generate sitemap.xml for the rendered site.

Quarto does not generate a sitemap automatically (only site-url, used
for absolute preview-image URLs). Run this after `quarto render`:

    python checks/generate_sitemap.py

It writes _blog/sitemap.xml, listing every rendered page under the
site's `site-url` (read from _quarto.yml). Excludes the standalone
sub-projects (MyBlog/, param_reports/, shiny/) since they are already
excluded from the main project render.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BLOG = ROOT / "_blog"
QUARTO_YML = ROOT / "_quarto.yml"


def read_site_url():
    text = QUARTO_YML.read_text(encoding="utf-8")
    m = re.search(r'^\s*site-url:\s*"?([^"\n]+)"?\s*$', text, re.M)
    if not m:
        raise SystemExit("site-url not found in _quarto.yml")
    return m.group(1).rstrip("/")


def main():
    if not BLOG.exists():
        print(f"{BLOG} does not exist -- run `quarto render` first.")
        return 1

    site_url = read_site_url()
    html_files = sorted(p for p in BLOG.rglob("*.html") if "site_libs" not in p.parts)

    urls = []
    for f in html_files:
        rel = f.relative_to(BLOG).as_posix()
        urls.append(f"{site_url}/{rel}")

    body = "\n".join(
        f"  <url><loc>{u}</loc></url>" for u in urls
    )
    xml = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        f"{body}\n"
        "</urlset>\n"
    )

    out = BLOG / "sitemap.xml"
    out.write_text(xml, encoding="utf-8")
    print(f"Wrote {out} with {len(urls)} URLs.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
