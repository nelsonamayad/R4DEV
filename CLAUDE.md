# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

R4DEV is a Quarto website teaching reproducible data analysis in R (tidyverse-first), created by Nelson Amaya. It is published to Netlify at https://r4dev.netlify.app/ (site id in `_publish.yml`). The site is a workshop: each session is a standalone `.qmd` lesson that downloads real data from the web and builds plots, maps, animations, text analysis, and Shiny apps.

The workshop is being modernized (as of mid-2026): several sessions rely on tools that no longer work — notably `spotifyr` (Spotify killed its audio-features API; appears in `sessions_workshop/02-plots`, `05-maps`, `07-shiny`) — and new sessions are planned covering programmatic LLM use in R: `ellmer`, `shinychat`, `querychat`, and related tooling. When touching a session, flag deprecated/broken packages and prefer replacements consistent with the tidyverse style already used.

## Commands

```sh
quarto preview                        # live-reload dev server for the site
quarto render                         # full site build → _blog/
quarto render sessions_workshop/02-plots/02-plots.qmd   # render one session
quarto publish netlify                # deploy (uses _publish.yml)
```

- Rendering **executes all R chunks live** — there is no `freeze: auto` in `_quarto.yml`, so a full render needs every R package loaded by the sessions plus network access (sessions read data straight from URLs: OWID GitHub, Project Gutenberg, APIs, etc.). Prefer rendering the single file you changed.
- Shiny apps are run individually: `R -e 'shiny::runApp("shiny/affairs1969-sidebar")'` (each subfolder of `shiny/` is a standalone app with its own `app.R`).
- Parameterized reports: `param_reports/` is a **separate Quarto project** (own `_quarto.yml`, outputs to `param_reports/_reports/`); batch rendering is scripted in `param_reports/retractionwatch_create_reports.R`.
- `MyBlog/` is also a separate Quarto project — the demo blog students build in the publishing session. Don't merge its config with the root site.

## Structure

- `_quarto.yml` — site config: navbar (sessions are manually listed there), theme (`journal` + `style.css` + `_brand.yml`), Google Analytics, hypothes.is comments, `execute: warning: false`. Output goes to `_blog/`.
- `sessions_workshop/NN-name/NN-name.qmd` — the eight core lessons (01-quarto … 08-reports) plus `13-bayes/bayes.qmd`, which is `draft: true` with `eval: false` (unfinished, not in navbar).
- `sessions_tools/` — practice exercises (09), resources (10), feedback (11). `09-practice` uses the webR/quarto-live extensions for in-browser R exercises.
- `index.qmd` — landing page; session cards are auto-generated Quarto **listings** over `sessions_workshop/` and `sessions_tools/`, so a new session appears there automatically but must be added to the navbar in `_quarto.yml` by hand.
- `_extensions/` — vendored Quarto extensions: `coatless/webr`, `r-wasm/live`, `quarto-ext/shinylive`, `lightbox`, `fontawesome`, `shafayetShafee/downloadthis`. Update via `quarto add`, don't hand-edit.
- Root also holds workshop data assets referenced by sessions (PDFs, `KyotoFullFlower7.xlsx`, `gadm/`, media). `.RData` (~134 MB) is session residue, not source.

## Session file conventions

Each session `.qmd` follows the same pattern — keep it when editing or adding sessions:

- Frontmatter with `title`, `subtitle`, `description`, `categories`, `date`, `date-modified: last-modified`, an `image` (usually a gif in the session folder), and a `citation.url` pointing at the published page.
- Code uses the native pipe `|>`, explicit namespacing (`dplyr::mutate(...)`), and Quarto code annotations (`# <1>` with a matching numbered list below the chunk). Follows the tidyverse style guide.
- Prose is didactic, in English, with epigraph quotes, callouts (`callout-tip` etc.) and footnotes; data is imported from public URLs rather than bundled files where possible.
