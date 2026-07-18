# Content restructure & site-quality backlog

Status: most of the 17-item redesign brief has now shipped across three
work sessions. This document tracks what's done, what's still open, and
the one item (lesson splitting) that stays a recommendation-only
deliverable by the brief's own explicit instruction.

## What shipped

**Structural (homepage/nav):**
- Homepage (`index.qmd`) rebuilt: hero with the required description and
  two CTAs; three track-summary cards; the classic per-session
  image+title+description grid (one per track, plus Tools) restored using
  Quarto listings with `fields: [image, title, description]` only — no
  dates, no reading-time, no category tag cloud; a compact Resources strip.
- New `start.qmd` (Start Here), three track overview pages
  (`learn/build-with-r.qmd`, `learn/ai.qmd`, `learn/thinking.qmd`).
- Navbar simplified to Home / Start here / Learn (▸ 3 tracks) / Practice /
  Resources / About R4DEV (renamed from "Wait, what did I get myself
  into?", kept as the About page's subtitle).
- AI capstone nav-duplication resolved: "Ask R4DEV" is a distinctly
  labelled entry on the Work with AI track page with a callout explaining
  it's a live demo embedded in *Grounded in truth*, not a separate lesson.

**Per-lesson (items 5–7, all 18 lessons across all three tracks):**
- YAML metadata standardised: `order`, `level`, `duration`, `track`,
  `prerequisites` added to every lesson's frontmatter.
- Every lesson has a `.lesson-info` block (level/time/prerequisites/tools)
  and a "You will learn to" section (3–5 objectives) near the top.
- Every lesson has a "Key takeaways" section (3–5 points) and a
  `.continue-learning` footer (previous/track overview/next) near the
  bottom, before any References block. Track-final lessons point sideways
  at another track instead of a nonexistent "next" lesson.
- Practice-exercise difficulty labels standardised to Basic/Intermediate/
  Advanced (was "Easy"/Intermediate/Advanced) across all 12 lessons that
  had them.
- Two stray `# References` H1 headings (07-shiny, 08-reports) demoted to
  `## References`.

**Copyedit & labels (items 9–10):**
- All of the brief's specifically-named typos fixed (analise, begining,
  millenia/chery, a list a articles/propositions, area un which, Rstudio,
  revealsj, Feeback, apps and dashboard), plus the `girafe` category tag
  on 02-plots *and* 05-maps corrected to `ggiraph` (the actual package).
- A representative British-English pass across lesson prose (analyse,
  visualise, favourite, modelled, customise, colour, defence, summarising,
  memorising, industrialise, Randomise) — this was a thorough grep-driven
  sweep of common American-spelling words, not a mechanical global
  find/replace, and deliberately left `color`/`colour` untouched wherever
  the prose is describing a same-named `color=` code parameter sitting
  right next to it (changing the prose there would desync it from the
  code being described). A handful of live-executing chunk output strings
  were left alone — see "Not done" below.
- Vague labels replaced: site-wide `code-summary` ("Click me!" → "Show the
  code"), About page's three collapsed callout titles, two links in
  Blogging with Quarto, one footnote link in Data from words.

**Item 13 — Blogging with Quarto modernised:**
- No longer framed as a 2022 development; explains website vs. blog;
  `quarto.yml` → `_quarto.yml` throughout; corrected the "every document
  in posts is included" claim to explain the listing's `contents` option;
  manual Netlify drag-and-drop relabelled as one option among others, with
  a new optional Git-based automatic deployment section; explains reading
  `output-dir` before deciding what to deploy; the "5 minutes" claim
  updated to a realistic 30–45 minutes first-time-through estimate.
  External Quarto/Netlify links spot-verified live.

**Item 11 — accessibility (concrete fixes, not a full audit):**
- Footer's Font Awesome R icon now has a `title` plus adjacent visible "R"
  text, so the sentence reads correctly even if the icon renders as
  nothing to assistive tech.
- `practice-yml.png` (the one screenshot with empty alt text) given a
  real descriptive alt string; grepped the whole site for generic
  (`alt="image"` etc.) or missing alt text — none found beyond that one.
  Decorative reaction gifs (bored.gif, wow.gif, mic-drop.gif) intentionally
  left with empty alt, which is the *correct* choice for decorative images.
- Heading hierarchy: grepped for stray top-level `# ` headings outside code
  chunks/callouts; found and fixed the two stray H1s noted above
  (07-shiny, 08-reports "References"). No other page-level h1 violations
  found — everything else matching that pattern was either a Quarto
  callout title (`# Basic` etc., which is not a real page heading) or an
  R code comment inside a fenced chunk.
- Verified: no `outline: none`/`outline: 0` in `style.css` (focus
  indicators are not being suppressed); buttons have `min-height: 44px`
  for mobile tap targets; `prefers-reduced-motion` respected for
  scroll-behavior.
- **Not done**: a full WCAG contrast-ratio audit, live keyboard-navigation
  walkthrough, or mobile-viewport visual check — this session has no
  browser/screenshot tooling, so these are verified structurally
  (semantic HTML, real `<a>` elements throughout the new components,
  Bootstrap's own contrast-managed CSS variables) but not visually.

**Item 12 — secrets scan done, path migration deferred:**
- Grepped all `.qmd` and `.R` files for API keys/tokens/passwords/secrets:
  none found embedded in source (they correctly live in `.Renviron`).
- `paste0(getwd(), "/file")` usage catalogued (~30 call sites across
  02-plots, 03-text, 04-animate, 05-maps, 06-scrap, 08-reports,
  07-shiny/revealjs.qmd) but **not migrated** to `here::here()` — see "Not
  done" below for why.

**Item 15 — site-quality automation added:**
- `checks/site_checks.py`: dependency-free (stdlib only) script that
  checks internal links, missing local images, generic/empty alt text,
  and duplicate navbar targets against the rendered `_blog/` output.
- `checks/generate_sitemap.py`: writes `_blog/sitemap.xml` (Quarto doesn't
  generate one on its own).
- `checks/dictionary.txt`: project word list (packages, authors, datasets,
  R/stats terminology) for use with an external spellchecker.
- `checks/README.md` documents how to run all of the above locally; the
  root `CLAUDE.md` commands section links to them.

**Item 16 — SEO:**
- Added `robots.txt` at the project root (Quarto copies it to output
  automatically) pointing at the new sitemap.
- Site-wide description/favicon/OG-image/twitter-card/site-url were
  already present; verified every lesson and new page has its own
  distinct `title`/`description`.

**Verification, every session:** full `quarto render` (zero errors, same
three pre-existing warnings each time, zero new ones) and a full internal
internal-link check (zero broken links introduced) after every batch of
changes — see `checks/site_checks.py` for the now-repeatable version of
that check.

---

## Not done, and why

### 1. Oversized-lesson splits (item 14) — recommendation only, by design

The brief is explicit: *"Do not split or move these lessons until the
recommendation has been reviewed."* That review hasn't happened, so the
five lessons flagged below are analysed but untouched. Durations are
rounded active-work estimates (line count / chunk count / heading count),
not automated reading time.

#### `sessions_workshop/03-text/03-text.qmd` — Data from words (~90 min)
- **Current topics**: PART I regex/tokenising/stemming/lemmatising, dplyr
  helpers, joins; PART II topic modelling ("book shuffle"); Bonus n-gram
  networks with ggraph.
- **Proposed modules**: 1) *Data from words* (keep title) — PART I only.
  2) *What books are about* (new) — PART II topic modelling + the ggraph
  bonus as its natural continuation.
- **Dependencies**: module 2 reuses module 1's corpus/tokenisation; keep
  adjacent in sequence.
- **Optional content**: the ggraph n-gram bonus stays clearly optional.
- **Links to update if split**: `learn/build-with-r.qmd` lesson list,
  `index.qmd` lesson count ("9 lessons"), `aliases:` entries, and the
  `r4dev-ask` ragnar store (ingested from the current single-page URL).

#### `sessions_thinking/04-causal/04-causal.qmd` — Draw your assumptions before drawing your conclusions (~90 min, 1212 lines — largest file on the site)
- **Current topics**: PART I–III (question/fork/collider), "seen before
  animated", PART IV identification ("earning the arrow"), PART V
  interactive OJS gallery, exercises.
- **Proposed modules**: 1) *Confounders and colliders* (PART I–III). 2)
  *Earning the arrow* (new) — PART IV + PART V gallery + exercises.
- **Dependencies**: module 2 assumes module 1's fork/collider vocabulary.
- **Optional content**: PART V's interactive gallery stays optional.
- **Links to update**: `learn/thinking.qmd` lesson list, `index.qmd`
  lesson count; check `{ojs}`/`ojs_define()` cross-references between
  parts before moving anything — PART V's cells may read data defined
  earlier in the same file.

#### `sessions_workshop/07-shiny/07-shiny.qmd` — Make it shine (~90 min)
- **Current topics**: PART I (Shiny basics + publishing + embedding) +
  PART II (UI/reactivity) + a "this example is being retired" section +
  Shiny extensions + Bonus RevealJS presentations.
- **Proposed modules**: 1) *Make it shine* (keep title) — PART I + II. 2)
  *Presentations with Quarto* (new) — the RevealJS bonus, which arguably
  belongs next to **Blogging with Quarto** instead, since RevealJS is a
  Quarto output format, not a Shiny feature.
- **Dependencies**: module 2 has no real dependency on module 1 — flag for
  a scope decision (new lesson vs. appendix on 01-quarto), not a
  mechanical split.
- **Optional/removable**: "this example is being retired" — review for
  outright removal rather than carrying it into either module.
- **Links to update**: `sessions_workshop/07-shiny/revealjs.qmd` is
  already a separate file linked from the bonus section — check it
  survives wherever that section ends up.

#### `sessions_workshop/02-plots/02-plots.qmd` — Everything in its right place (~90 min, secondary candidate)
- **Proposed modules**: 1) *Tidy plotting fundamentals* (PART I). 2) *APIs
  and interactive plots* (PART II + ggiraph bonus).
- **Dependencies**: module 2 reuses module 1's tidied datasets.

#### `sessions_workshop/05-maps/05-maps.qmd` — Mapping despair in the USA (~90 min, secondary candidate)
- **Proposed modules**: 1) *Static maps* (PART I–II). 2) *Interactive & 3D
  maps* (PART III leaflet + rayshader bonus).
- **Dependencies**: module 2 reuses module 1's prepared spatial data.
- **Note**: unaffected by the `leaflet`/`terra`/GDAL build failure in
  `CLAUDE.md` — that only blocks *deployed Shiny apps* using leaflet, not
  this static/interactive-HTML lesson page.

### 2. `getwd()` → `here::here()` migration (item 12)

Catalogued (~30 call sites, listed above) but not migrated. Reasons:
`paste0(getwd(), "/file")` resolves correctly today because Quarto sets
the working directory to the `.qmd`'s own folder during render (documented
behaviour, and how every one of these chunks currently works without
error). `here::here()` resolves from the *project root*, not the current
file's directory, so this isn't a 1:1 textual substitution — each call
site needs the correct project-relative path (e.g.
`here::here("sessions_workshop/04-animate/sakura.jpg")`), plus adding
`library(here)` to that lesson's setup. The brief's own item 12 caution
applies directly here: *"Do not mechanically rewrite every existing code
block without testing it."* Several of the affected files (05-maps
especially) have expensive, credential- or network-dependent chunks
(Census API, CDC Socrata, rayshader video rendering) where a bad edit is
costly to catch. Recommend doing this as its own dedicated pass, one file
at a time, each with a full re-render to verify before moving to the next.

### 3. One live-code typo, deferred for the same reason

`sessions_workshop/03-text/03-text.qmd`'s `book_sentiments()` function has
an axis-label typo, `x="Sentimen AFINN"` (should be "Sentiment AFINN") —
inside a live ggplot `labs()` call. Low-risk to fix, but every edit to
that file's *code* (as opposed to prose) forces a re-execution of the
whole file under `freeze: auto`, including a PDF download and topic-model
fit. Flagged rather than fixed in this pass, to keep code-chunk edits
batched and deliberate rather than incidental.

### 4. Pre-existing issues found, not fixed (predate this work, out of scope)

- `sessions_workshop/07-shiny/07-shiny.qmd`: an example code block
  contains the literal placeholder `src="YOUR SHINYAPP URL"` — almost
  certainly an intentional student fill-in-the-blank, not a stale link,
  but worth a comment confirming that.
- `sessions_workshop/07-shiny/revealjs.qmd`: `<img src="../../r4dev_logo.png">`
  does not resolve — the real file is `logo/r4dev_dalle_1.png` at the
  project root. `revealjs.qmd` was out of scope for every phase so far.
- Two pre-existing Lua filter warnings survive unchanged across every
  render in this work: "List item 1 has no corresponding annotation in the
  code cell" (03-text.qmd, 04-animate.qmd) and an unclosed-div warning in
  `sessions_tools/02-resources/02-resources.qmd`. Present before this work
  started; not touched.

### 5. Full accessibility audit (item 11)

What shipped above are concrete, verifiable fixes, not a systematic
WCAG-level audit. Not done: measured contrast ratios in both themes, a
live keyboard-only navigation walkthrough, or checking real mobile
viewports — none of which are possible without browser/screenshot tooling
in this environment.
