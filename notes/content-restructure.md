# Content restructure & site-quality backlog

Status: **backlog, not yet actioned**. This document records what was deferred
from the July 2026 homepage/navigation redesign (structural phase, shipped)
so it can be picked up in follow-up passes without re-deriving the analysis.
Nothing described here has been split, moved, or rewritten yet — per the
brief, oversized lessons are *recommended* for splitting, not split, until
reviewed.

## What shipped in the structural phase

- Homepage (`index.qmd`) rebuilt around three track cards + a hero with two
  CTAs, category wall removed.
- New `start.qmd` (Start Here), three new track overview pages
  (`learn/build-with-r.qmd`, `learn/ai.qmd`, `learn/thinking.qmd`).
- Navbar simplified to Home / Start here / Learn (▸ 3 tracks) / Practice /
  Resources / About R4DEV (renamed from "Wait, what did I get myself into?").
- AI capstone nav-duplication resolved: "Ask R4DEV" is now a clearly
  distinct, separately-labelled entry on the Work with AI track page (with a
  callout explaining it's a live demo embedded at the end of *Grounded in
  truth*, not a standalone lesson) rather than a sibling dropdown item
  pointing at the same file as "Grounded in truth (ragnar)".
- Full-site render confirmed: no new warnings vs. the pre-change baseline;
  internal-link check found zero broken links introduced by the new pages
  (see below for pre-existing findings unrelated to this phase).

Everything below is **not yet done**.

---

## 1. Oversized-lesson split recommendations (spec item 14)

Estimated active-work time (rounded, based on line count / chunk count / H2
count, not automated reading time) for every lesson is now on file in
`learn/*.qmd`. Five lessons clock in at or above ~90 minutes, well past the
45–60 minute target. Recommendations below are **proposals only**.

### `sessions_workshop/03-text/03-text.qmd` — Data from words (~90 min)

- **Current topics**: PART I regex/tokenising/stemming/lemmatising, dplyr
  helpers, joins; PART II topic modelling ("book shuffle"); Bonus n-gram
  networks with ggraph.
- **Proposed modules**:
  1. *Data from words* (keep title) — PART I only: text → tidy data, regex,
     stems/lemmas, dplyr helpers, joins.
  2. *What books are about* (new) — PART II topic modelling + the ggraph
     n-gram bonus, folded in as its natural continuation.
- **Dependencies**: module 2 reuses module 1's corpus and tokenisation; must
  stay lesson 3→3b in sequence, not reordered elsewhere.
- **Content that should become optional**: the ggraph n-gram network section
  is already marked "Bonus track" — natural candidate to stay clearly
  optional inside module 2 rather than promoted to core.
- **Links needing updates if split**: `_quarto.yml` Learn menu is already
  track-page-based (no direct edit needed there), but `learn/build-with-r.qmd`
  lesson list, `index.qmd` lesson count ("9 lessons"), any `aliases:` entries,
  and the `r4dev-ask` ragnar store (which was ingested from the current
  single-page URL) would all need updating.

### `sessions_thinking/04-causal/04-causal.qmd` — Draw your assumptions before drawing your conclusions (~90 min, 1195 lines — largest file on the site)

- **Current topics**: PART I what regression can't answer; PART II
  confounding (the fork); PART III colliders; "seen before, animated"; PART
  IV identification ("earning the arrow"); PART V interactive OJS gallery;
  exercises.
- **Proposed modules**:
  1. *Confounders and colliders* — PART I–III, the core DAG vocabulary.
  2. *Earning the arrow* (new) — PART IV identification strategy + PART V
     interactive gallery + exercises.
- **Dependencies**: module 2 assumes module 1's DAG vocabulary (fork/collider
  terms used without redefinition).
- **Content that should become optional**: PART V's interactive gallery is
  already exploratory/self-directed — good candidate to stay explicitly
  optional in module 2 rather than required reading.
- **Links needing updates**: `learn/thinking.qmd` lesson list, `index.qmd`
  track lesson count, any `{ojs}`/`ojs_define()` cross-references between
  parts (check before moving — PART V's OJS cells may read data defined
  earlier in the same file).

### `sessions_workshop/07-shiny/07-shiny.qmd` — Make it shine (~90 min)

- **Current topics**: PART I "the real beauty of R" + publishing apps free +
  embedding Shiny in a website; PART II UI design + reactivity; a
  "this example is being retired" section (already flagged stale in its own
  heading — worth a content review, not just a split); Shiny extensions;
  Bonus track RevealJS presentations; "learn more about RevealJS".
- **Proposed modules**:
  1. *Make it shine* (keep title) — PART I + PART II: build and publish a
     Shiny app.
  2. *Presentations with Quarto* (new, and arguably belongs next to
     **Blogging with Quarto** rather than staying under this lesson) —
     the RevealJS bonus track, since RevealJS is a Quarto output format, not
     a Shiny feature, and its current placement here is a legacy artifact.
- **Dependencies**: module 2 has no real dependency on module 1 — it could
  move to become an optional appendix on `01-quarto` instead of a new
  standalone lesson. Flag for a scope decision, not just a mechanical split.
- **Content that should become optional**: "This example is being retired" —
  review whether to remove outright rather than carry into either module.
- **Links needing updates**: `sessions_workshop/07-shiny/revealjs.qmd` is a
  separate file already (linked from the bonus section) — check that link
  survives wherever the bonus section ends up.

### `sessions_workshop/02-plots/02-plots.qmd` — Everything in its right place (~90 min, secondary candidate)

- **Current topics**: PART I tidy data/OWID/pipe/scales; PART II APIs
  (httr2), pivoting, tibble vs. tribble, esquisse, bonus girafe
  interactivity.
- **Proposed modules**: 1) *Tidy plotting fundamentals* (PART I), 2) *APIs
  and interactive plots* (PART II + girafe bonus).
- **Dependencies**: module 2's plots reuse module 1's tidied datasets.
- **Note**: this lesson's `girafe` category tag is also flagged in the
  copyedit backlog (§3) as possibly mislabelled — check together.

### `sessions_workshop/05-maps/05-maps.qmd` — Mapping despair in the USA (~90 min, secondary candidate)

- **Current topics**: PART I "walk before you run"; PART II despair in the
  US + CRS; PART III interactive leaflet maps (with an existing render-time
  caution callout); Bonus 3D maps with rayshader.
- **Proposed modules**: 1) *Static maps* (PART I–II), 2) *Interactive & 3D
  maps* (PART III + rayshader bonus).
- **Dependencies**: module 2 reuses module 1's prepared spatial data.
- **Note**: this is a lesson *page*, unaffected by the `leaflet`/`terra`/GDAL
  build failure documented in `CLAUDE.md` — that issue only blocks *deployed
  Shiny apps* using leaflet, not this static/interactive-HTML lesson render.

---

## 2. Lesson YAML metadata standardisation (spec item 5)

Not started. Needs, per lesson: `level` (Beginner|Intermediate|Advanced),
`duration` (rounded active-work estimate), `track`, `order`, `prerequisites`.
The three new `learn/*.qmd` pages currently hand-author lesson number,
outcome, level and duration in raw HTML (see their `lesson-list` blocks)
*because* this metadata doesn't exist in lesson frontmatter yet. Once item 5
lands, prefer swapping those hand-authored blocks for a Quarto `listing` that
reads the new YAML fields directly, per the spec's own guidance not to
duplicate metadata manually — the level/duration/outcome values already
drafted in this phase (visible in the three `learn/*.qmd` files) are a
reasonable starting point for the YAML values themselves.

## 3. Sitewide copyedit pass (spec item 9)

Not started systematically. Confirmed still present at time of writing:
- `sessions_workshop/01-quarto/01-quarto.qmd` description: "analise" →
  "analyse".
- `sessions_tools/02-resources/02-resources.qmd` description: "This is just
  the begining." → "beginning."
- `sessions_workshop/04-animate/04-animate.qmd` description: "millenia of
  chery tree blossoms" → "millennia of cherry tree blossoms".
- The rest of the specific strings named in the brief (`a list a articles`,
  `propositions`→`prepositions`, `area un which`, `apps and dashboard`,
  `Rstudio`, `revealsj`, `girafe` metadata, `Feeback`) were not yet located —
  need a full grep pass across every `.qmd`, not just frontmatter.
- British-English pass (analyse/visualise/modelling/behaviour/customisation)
  not yet run across lesson bodies.

## 4. Per-lesson intro/outro blocks (spec items 6–7)

Not started. Every lesson needs a `.lesson-info` block (CSS already added in
this phase, unused so far — see `style.css`'s "lesson pages: info block"
section) with level/time/prerequisites/tools, a "You will learn to" list, and
a matching `.continue-learning` footer (CSS also already added) with
previous/track/next links. Mechanical once item 5's metadata exists to draw
from, but touches all ~19 lesson files — do as its own pass, not folded into
a content split.

## 5. Vague interactive labels (spec item 10)

Not started. At minimum, `_quarto.yml`'s site-wide `code-summary: "Click me!"`
and `about.qmd`'s three `# Click here` callout headers need renaming to
descriptive text (e.g. "Show the code", "What you'll learn"). A grep for
"Click here"/"Click me" across all `.qmd` files will find the rest.

## 6. Accessibility audit (spec item 11)

Not started as a systematic audit. One concrete finding from this phase:
the footer's "Created with {{< fa brands r-project >}} and Quarto" icon
(`_quarto.yml`'s `page-footer.right`) should be checked for an accessible
label on the Font Awesome icon — flagged, not fixed, in this pass.

## 7. Fragile file paths / secrets scan (spec item 12)

Not started. `paste0(getwd(), "/file")` patterns are known to exist per
`CLAUDE.md`'s own file-layout notes; a `here::here()` migration needs
per-chunk execution verification, not a mechanical find/replace.

## 8. Blogging with Quarto modernisation (spec item 13)

Not started.

## 9. Site-quality automation (spec item 15)

Not started. No CI exists yet (per `CLAUDE.md`, deploys are manual). A
lightweight local script (render + internal-link check, following the same
approach used ad hoc for this phase — see the link-check method note below)
is the natural first step; a project dictionary for spell-checking would need
package/dataset/author names collected from across all lesson frontmatter.

## 10. SEO / sharing metadata (spec item 16)

Partially satisfiable already: `_quarto.yml` has site-wide `description`,
`favicon`, `open-graph`/`twitter-card` images, and `site-url`. Not yet
verified: per-page descriptions on the three new `learn/*.qmd` pages (they do
have `description:` frontmatter, added in this phase) vs. every lesson;
sitemap/robots generation not yet confirmed enabled in Quarto's site output.

---

## Pre-existing issues found (not introduced by this phase, not yet fixed)

Found via the render + internal-link check run during the structural phase:

- `sessions_workshop/07-shiny/07-shiny.qmd`: an example code block contains
  the literal placeholder `src="YOUR SHINYAPP URL"` — intentional as a
  student fill-in-the-blank, but worth a comment confirming that's the
  intent rather than a stale real URL.
- `sessions_workshop/07-shiny/revealjs.qmd`: `<img src="../../r4dev_logo.png">`
  does not resolve — the file lives at `logo/r4dev_dalle_1.png` at the
  project root, not `r4dev_logo.png` two levels up from this file. Predates
  this phase; not fixed here since `revealjs.qmd` is outside phase-1 scope.
- Two pre-existing Lua filter warnings survive unchanged: "List item 1 has no
  corresponding annotation in the code cell" in `03-text.qmd` and
  `04-animate.qmd`, and an unclosed-div warning in
  `sessions_tools/02-resources/02-resources.qmd` (Div at line 7 unclosed,
  closes implicitly). None are new; all were present in the baseline render
  taken before this phase's changes.

### Link-check method

A one-off Python script scanned every rendered file under `_blog/` for local
`href`/`src` targets and checked each resolves to a real file (including
Quarto's `.qmd`→`.html` rewriting and `/index.html` directory fallback). It
is not yet wired into a repeatable command — see backlog item 9 above.
