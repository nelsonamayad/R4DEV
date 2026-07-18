# Site-quality checks

Lightweight, local, informational checks for the rendered site. None of
these fail a build on their own -- there is no CI wired up (deploys are
manual, see the root `CLAUDE.md`), so run them by hand before publishing.

## 1. Render

```sh
quarto render
```

Rendering a lesson with live-executing code re-runs it if the source
file changed (`freeze: auto`), which can hit live APIs/credentials --
see the root `CLAUDE.md` for the `.Renviron` gotchas (non-standard
path, Census key, etc.) if a chunk fails on a missing key.

## 2. Structural checks (links, images, alt text, nav duplicates)

```sh
python checks/site_checks.py
```

Run this *after* `quarto render` -- it reads the `_blog/` output
directory. It reports, without failing:

- broken internal links (a local `href`/`src` that doesn't resolve to a
  real file, including Quarto's `.qmd` → `.html` rewriting);
- missing local images;
- generic alt text (`alt="image"`, `"screenshot"`, `"plot"`, `"graph"`)
  flagged for a human to write something descriptive -- empty `alt=""`
  is *not* flagged, since that's the correct choice for decorative
  images;
- two navbar entries in `_quarto.yml` pointing at the same `href`.

Known false positive: pages using the lightbox extension contain an
inline `<script>` with a `${href}` JS template literal, which this
script's simple regex can't tell apart from a real link -- ignore
`${href}` in the output.

## 3. Spelling

No spellchecking library is assumed to be installed. Use whatever's
available with `checks/dictionary.txt` as the custom word list, e.g.:

```sh
pip install codespell
codespell sessions_workshop sessions_ai sessions_thinking sessions_tools index.qmd start.qmd about.qmd learn --ignore-words checks/dictionary.txt
```

or point your editor's spellchecker (VS Code, RStudio) at
`checks/dictionary.txt` as a custom/personal dictionary.

## 4. Sitemap (SEO)

Quarto does not generate a `sitemap.xml` on its own -- only `site-url`,
used for absolute preview-image URLs. Run this after `quarto render`,
before publishing:

```sh
python checks/generate_sitemap.py
```

It writes `_blog/sitemap.xml` (gitignored, like the rest of `_blog/`)
listing every rendered page under the site's `site-url`. `robots.txt`
at the project root already points to it and is copied to the output
directory automatically by Quarto.

## What this doesn't cover

- Cross-page duplicate content, broken *external* links, or anything
  requiring network access -- out of scope for a fast local check.
- Whether a page's prose is actually correct -- these are structural
  checks, not a substitute for reading the render.
