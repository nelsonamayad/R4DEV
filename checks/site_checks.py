"""
Lightweight site-quality checks for the rendered R4DEV site.

Run `quarto render` first, then run this script against the output
directory (`_blog` by default, matching `output-dir` in _quarto.yml).

    python checks/site_checks.py

Checks performed (all read-only, nothing here fails the build):
  1. Internal links  -- every local href/src resolves to a real file.
  2. Missing local images -- every <img src="..."> pointing at a local
     path actually exists on disk.
  3. Generic/empty alt text -- flags alt="image"/"screenshot"/"plot"/"graph"
     (case-insensitive) on non-decorative-looking images, as a prompt for
     human review, not a hard rule (empty alt is correct for decorative
     images, so empty alt is NOT flagged by itself).
  4. Duplicate navigation targets -- two different navbar entries (in
     _quarto.yml) pointing at the exact same href, which is usually a
     mistake left over from a rename or restructure.

This intentionally does NOT fail the build on unavoidable generated-doc
warnings (e.g. Quarto's own code-annotation/code-linking notices) --
it only reports what it finds. Spelling is not checked here: run a
general-purpose spellchecker (e.g. `codespell sessions_*/**/*.qmd` or
your editor's spellchecker) against the `.qmd` sources with
checks/dictionary.txt as the custom word list, since no bundled
spellchecking library is assumed to be installed on this machine.
"""

import re
import sys
from pathlib import Path
from urllib.parse import urlsplit, unquote

ROOT = Path(__file__).resolve().parent.parent
BLOG = ROOT / "_blog"
QUARTO_YML = ROOT / "_quarto.yml"

HREF_RE = re.compile(r'href="([^"]+)"')
IMG_RE = re.compile(r'<img\b[^>]*>')
IMG_SRC_RE = re.compile(r'src="([^"]+)"')
IMG_ALT_RE = re.compile(r'alt="([^"]*)"')
GENERIC_ALT = {"image", "screenshot", "plot", "graph", "picture", "photo"}


def check_links_and_images():
    if not BLOG.exists():
        print(f"[skip] {BLOG} does not exist -- run `quarto render` first.")
        return [], []

    html_files = list(BLOG.rglob("*.html"))
    broken_links = []
    missing_images = []

    for f in html_files:
        text = f.read_text(encoding="utf-8", errors="ignore")

        for m in HREF_RE.finditer(text):
            url = m.group(1)
            if not url or url.startswith("#"):
                continue
            if url.startswith(("http://", "https://", "mailto:", "javascript:", "data:")):
                continue
            if "${" in url:  # JS template literal inside an inline <script>, not a real link
                continue
            path_part = unquote(urlsplit(url).path)
            if not path_part:
                continue
            target = (BLOG / path_part.lstrip("/")) if path_part.startswith("/") else (f.parent / path_part).resolve()
            candidates = [target]
            if not str(target).endswith((".html", ".css", ".js", ".png", ".gif", ".jpg", ".jpeg", ".svg", ".ico", ".pdf", ".csv")):
                candidates += [Path(str(target) + ".html"), target / "index.html"]
            if not any(c.exists() for c in candidates):
                broken_links.append((str(f.relative_to(BLOG)), url))

        for img_tag in IMG_RE.finditer(text):
            tag = img_tag.group(0)
            src_m = IMG_SRC_RE.search(tag)
            if not src_m:
                continue
            src = src_m.group(1)
            if src.startswith(("http://", "https://", "data:")):
                continue
            img_path = (f.parent / unquote(src)).resolve()
            if not img_path.exists():
                missing_images.append((str(f.relative_to(BLOG)), src))

    return broken_links, missing_images


def check_generic_alt_text():
    if not BLOG.exists():
        return []
    flagged = []
    for f in BLOG.rglob("*.html"):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for img_tag in IMG_RE.finditer(text):
            tag = img_tag.group(0)
            alt_m = IMG_ALT_RE.search(tag)
            if not alt_m:
                continue
            alt = alt_m.group(1).strip().lower()
            if alt in GENERIC_ALT:
                flagged.append((str(f.relative_to(BLOG)), alt))
    return flagged


def check_duplicate_nav_targets():
    """Lightweight, dependency-free scan of _quarto.yml's navbar block.

    Not a full YAML parser: it just pairs each `text:`/`- text:` line with
    the next `href:` line that appears before another `text:` line, which
    matches how this project's navbar entries are always written. Good
    enough to catch two nav items pointing at the same href; not a
    substitute for validating arbitrary YAML structure.
    """
    if not QUARTO_YML.exists():
        return []

    lines = QUARTO_YML.read_text(encoding="utf-8").splitlines()
    try:
        start = next(i for i, l in enumerate(lines) if l.strip() == "navbar:")
    except StopIteration:
        return []
    end = next((i for i in range(start + 1, len(lines))
                if lines[i].strip().endswith(":") and not lines[i].startswith((" ", "\t"))), len(lines))
    block = lines[start:end]

    text_re = re.compile(r'^\s*-?\s*text:\s*"?([^"\n]*)"?\s*$')
    href_re = re.compile(r'^\s*href:\s*(\S+)\s*$')

    hrefs = {}
    dupes = []
    current_text = None
    for line in block:
        tm = text_re.match(line)
        if tm:
            current_text = tm.group(1)
            continue
        hm = href_re.match(line)
        if hm and current_text is not None:
            href = hm.group(1)
            if href in hrefs and hrefs[href] != current_text:
                dupes.append((hrefs[href], current_text, href))
            else:
                hrefs[href] = current_text
            current_text = None
    return dupes


def main():
    broken_links, missing_images = check_links_and_images()
    generic_alt = check_generic_alt_text()
    dup_nav = check_duplicate_nav_targets()

    print(f"Internal links: {len(broken_links)} broken")
    for src, url in broken_links:
        print(f"  {src}  ->  {url}")

    print(f"\nLocal images: {len(missing_images)} missing")
    for src, url in missing_images:
        print(f"  {src}  ->  {url}")

    print(f"\nGeneric alt text: {len(generic_alt)} flagged")
    for src, alt in generic_alt:
        print(f"  {src}  ->  alt=\"{alt}\"")

    print(f"\nDuplicate navbar targets: {len(dup_nav)} found")
    for text_a, text_b, href in dup_nav:
        print(f"  \"{text_a}\" and \"{text_b}\" both point to {href}")

    total = len(broken_links) + len(missing_images) + len(generic_alt) + len(dup_nav)
    print(f"\n{'No issues found.' if total == 0 else f'{total} item(s) flagged for review.'}")
    return 0  # informational only -- never fails the build


if __name__ == "__main__":
    sys.exit(main())
