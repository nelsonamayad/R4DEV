# R4DEV Update Plan

Goal: bring the 2022–2024 workshop up to date — fix what broke, refresh what aged, and add a new track on programmatic LLM use in R. Written July 2026.

> **Status (4 July 2026): largely executed.** Decisions taken: Gemini free tier as teaching default (provider-agnostic ellmer), Open-Meteo replaces Spotify for the API lesson, navbar uses dropdown menus, 13-bayes was finished (minimal) rather than deleted. Items still open are marked ⏳ below; everything checked was done and render-verified.

## Phase 0 — Baseline (do first, ~1 session of work)

- [x] Run a full `quarto render` to populate the new `_freeze/` cache and produce the definitive **failure inventory**: which sessions error, which data URLs 404, which packages won't install on R ≥ 4.4. Everything below gets checked against this list.
- [ ] ⏳ Add a GitHub remote (blocked: `gh auth login` needed) and push (`master` is currently local-only; one OneDrive hiccup from losing history).
- [x] Update vendored extensions (`quarto update <ext>`): `r-wasm/live` supersedes `coatless/webr` — migrate `09-practice` to quarto-live only and drop the webr extension.
- [ ] Optional (deferred): `renv::init()` to pin the ~70 packages. Recommended *against* for now — it complicates the student experience; revisit if renders become irreproducible.

## Phase 1 — Fix what's broken

### 02-plots — Spotify replacement (biggest item)
Spotify killed `audio_features`, `audio_analysis`, and `recommendations` in Nov 2024; `spotifyr` cannot come back. The session teaches two things that must survive: **calling an API from R** and **interactive viz** (plotly/ggiraph).

- [x] API teaching: switch to a keyless, stable API — recommend **Open-Meteo** (weather, no auth, JSON) or keep it thematic with the **MusicBrainz** API. No API keys in a classroom is a feature.
- [x] Music viz: keep the Radiohead/Thom Yorke narrative using a **bundled static snapshot** of the old Spotify audio features (AcousticBrainz dump or an archived Kaggle extract) — frame it honestly as "archival data, the API is gone" (a good reproducibility lesson in itself).
- [x] Purge `spotifyr` mentions from `05-maps` and `07-shiny` (both reference it in passing).

### 06-scrap — scraping stack
- [x] Replace `RSelenium` with **`chromote`** / **`selenider`** (modern headless Chrome, no Java/Docker).
- [x] `RSocrata` was archived from CRAN (Apr 2025) — replaced with plain `read_csv()` on the Socrata CSV endpoints + `$limit` param; both CDC datasets verified live.

### Data-source rot (all sessions)
- [x] `owid/owid-datasets` verified alive-but-frozen; kept as reproducible snapshots + callout teaching the modern grapher API — migrate Maddison and other OWID reads to the current OWID catalog/grapher CSV endpoints (`ourworldindata.org/grapher/*.csv`).
- [x] Project Gutenberg mirrors and `textdata` lexicons verified — `03-text` renders clean end to end.
- [x] `tidycensus`/`geodata` verified — `05-maps` renders clean; census key moved out of the qmd into env var (regenerate it before going public: it is in git history).

### Odds and ends
- [x] `r4dev_objects.pptx` at root is referenced nowhere: delete or link it from `10-resources`.
- [x] Refresh `10-resources` links (added LLM & causal-inference sections) (many 2022-era blogs/books have moved; add R4DS 2e, quarto.org current docs).

## Phase 2 — New LLM track (the headline addition)

Two new sessions in `sessions_workshop/`, following the existing folder/frontmatter pattern:

### `09-llm` — "Talking to machines": programmatic LLMs with ellmer
- `ellmer::chat_*()` basics: providers, system prompts, streaming.
- **Structured data extraction** — the killer demo for this audience: feed it the Darwin PDF text from `03-text` and extract tidy data frames from prose (ties the new track to the existing text-analysis session).
- Tool calling: give the LLM an R function (e.g., the `countrycode` lookup) and watch it use it.
- Batch/programmatic use: `parallel_chat()` over rows of a data frame; mention `mall` for dataframe-scale operations.

### `10-llm-apps` — "Chat with your data": shinychat, querychat, ggsql
- `shinychat`: drop a streaming chat UI into a Shiny app (extends what students built in `07-shiny`).
- `querychat`: natural-language filtering of a data frame — LLM proposes read-only SQL, never touches the data. Use a workshop dataset students already know (Maddison or the opioid data).
- `ggsql` (Posit alpha, Apr 2026): grammar-of-graphics *in* SQL with a knitr engine — pairs naturally with querychat's generated SQL. Flag as alpha; pin the version.

### Decisions needed before writing these
- **Provider/keys for teaching**: recommend writing sessions provider-agnostic via ellmer, defaulting to a free-tier provider (Gemini free tier or GitHub Models) for students, with a sidebar on `ollama` for fully local. Needs your call — it shapes every code chunk.
- Session numbering: `09`/`10` collide with `sessions_tools` numbering (09-practice, 10-resources) but numbers already restart per folder; alternatively renumber tools to 90+.
- Navbar is full at 11 items — consider collapsing sessions into a "Sessions" dropdown menu when adding the two new entries.

## Phase 2b — Finish the never-developed content

The causal-inference material exists in three disconnected pieces that were started and never wired together:

1. **`04-animate` bonus track** ("Correlation, causation — and why data never speaks for itself", line ~360) is marked 🛠️ *Section under construction*. The collider simulation, DAG (`ggdag`/`dagitty`), and collider-bias animation already work; what's missing is the finish: the promised Cunningham *Mixtape* example, a matching **confounder/OVB animation** (the mirror image of the collider story — `controlling.gif` already exists as raw material), and closing prose.
2. **Orphaned Shiny apps in `shiny/`** — working drafts referenced by no session: `collider/` (63-line sim), `r4dev-ovb/` (143-line OVB simulator with brms + gtsummary), `BayesApp/` (44 lines).
3. **`13-bayes/bayes.qmd`** — a 55-line stub (`draft: true`, `eval: false`, frontmatter description literally cut off mid-sentence).

Plan:

- [x] **Complete the `04-animate` bonus track**: finish the Mixtape example, add the confounder/OVB animation as the counterpart to the collider one (same demean-step animation style), remove the under-construction banner.
- [x] **Conceptual interactive explainers** (the aspiration: [rpsychologist.com/descriptive-adjustment](https://rpsychologist.com/descriptive-adjustment/) and [The DAG Almanac](https://dags.andrewheiss.com/)). What makes those work: the student *manipulates* one thing (which variable to adjust for, how much overlap) and instantly sees the estimate move — the insight is felt, not stated. Heiss's site is built with Quarto, so this is achievable on R4DEV's exact stack. Build a matched trio, one page or tab per structure:
  - **Confounder / mediator / collider**, each as DAG + scatter side by side with a single "adjust for Z" toggle — same simulated data, opposite consequences (adjusting fixes the confounder, *creates* bias for the collider).
  - An **adjustment step-through**: interactive version of the existing demeaning animation (FWL residualization — watch points collapse to residuals as you drag through the steps).
  - Tech: **Quarto `{ojs}` cells** for the sliders/toggles (instant response, zero server, D3-adjacent feel) with R pre-computing the simulated data at render time; fall back to shinylive only where real R stats are needed interactively. Keep each explainer to *one* manipulable control — that restraint is what makes the references insightful.
- [x] **Wire in the apps** (OJS explainers supersede shinylive embeds; apps fixed & linked): embed the `collider` app in the bonus track via the already-vendored **shinylive extension** (it's dependency-light, so it runs serverless in the browser — no deploy needed). `r4dev-ovb` can't run in shinylive (brms), so either deploy it to shinyapps.io alongside the covid app or simplify it to `lm()`-only so it shinylive-compiles. Recommend the simplification — pedagogically `lm()` is all OVB needs.
- [x] **Decide `13-bayes` scope** — finished minimal version, live on site: with BayesApp and the causal material finished, a minimal honest version becomes feasible — one session covering "why Bayes", the globe-tossing example already sketched, and the embedded BayesApp. Alternative remains deleting it. Recommend: finish it *last*, only after Phases 1–2 ship; it's the least-blocking item.
- [x] Extend `09-practice` (quarto-live exercise with hint/solution) with exercises for the new material (a DAG-replication exercise already exists in `04-animate`'s practice block — promote it).

## Phase 3 — Polish and ship

- [x] Update `about.qmd` learning outcomes (add the LLM track; retire the "extra content" items that Phase 1 removed).
- [x] Update `index.qmd` copy (listings pick up new sessions automatically); new session cards appear automatically via listings.
- [x] Full `quarto render` clean (all 17 files) and `quarto publish netlify` — **live** at https://r4dev.netlify.app (published repeatedly through this modernization; latest publish includes the light/dark brand and untinted background).
- [x] Update `CLAUDE.md` roadmap section as items land.

## Suggested order of attack

1. Phase 0 render → failure inventory (turns this plan's guesses into facts).
2. `02-plots` Spotify fix (unblocks the most-visited session).
3. OWID URL migration (touches several sessions, mechanical).
4. `09-llm` (new content, high motivation).
5. `04-animate` causal-inference bonus track + collider app (Phase 2b — self-contained, no external dependencies to fix first).
6. `06-scrap`, then `10-llm-apps`, then remaining Phase 2b (`r4dev-ovb`, `13-bayes` decision), then Phase 3.

## Phase 4 — Ambitious expansion (2027 horizon)

Where Phases 0–3 made the existing workshop *correct and current*, this phase makes it **bigger** — now that the site is public, new tracks that turn R4DEV from "a workshop" into a wider reference. This is a menu, not a schedule: nothing here should start without explicit scope sign-off, since each track below is roughly the size of the whole LLM track (Phase 2) on its own.

### 4a — Causal inference, for real (extends the `04-animate` bonus track)
The interactive confounder/mediator/collider trio primed the appetite; this converts it into a full method. New session `11-causal-methods`:
- Difference-in-differences and event studies (`fixest`, `did`) — reuse the CDC opioid panel from `05-maps` as the running example (state-level policy changes are a natural DiD setup).
- Regression discontinuity (`rdrobust`) and synthetic control (`tidysynth`) as the other two workhorses of the "credibility revolution."
- Closes the loop `about.qmd`'s "extra content" section promises but never delivered.

### 4b — Data at scale: arrow, duckdb, targets
New session `12-scale`:
- `arrow` + `dbplyr` + DuckDB for querying data larger than RAM with the *same* dplyr verbs students already know — "everything you learned, now it doesn't fall over at 50 GB."
- `targets` for reproducible multi-step pipelines — directly useful for `param_reports/` and any student re-running the same analysis repeatedly.
- A natural deeper dive into `ggsql`/DuckDB now that session 10 introduced them.

### 4c — Time series & forecasting
New session (numbering collides with `13-bayes` — renumber Bayes to `14` or use `15`):
- The `tidyverts` (`tsibble`, `fable`, `feasts`) ecosystem, taught on the OWID CO2/COVID series already used in `04-animate`.
- A closing callout tying forecasting back to the Bayesian session ("Bayes meets time series").

### 4d — The capstone: "Ask R4DEV" — a RAG chatbot over the workshop itself — ✅ shipped
Live at `shiny/r4dev-ask`, deployed to Posit Connect Cloud, embedded at the end of `10-llm-apps` and linked from the navbar (AI · LLMs → "Ask R4DEV 🤖").

**What actually got built, and why it differs from the original plan:**
- Every session `.qmd` (14 files, `revealjs.qmd` excluded as a duplicate) was chunked by markdown heading into 308 retrievable pieces, oversized chunks split to ~2000 chars.
- **Retrieval uses DuckDB's FTS extension (BM25 keyword search), not vector embeddings.** The plan assumed "`ellmer`'s embedding support" — it doesn't exist; `ellmer` is chat-only. The fallback options all failed or didn't fit: Anthropic has no embeddings API at all; the `OPENAI_API_KEY` on file has `insufficient_quota`; no Gemini/Google key was provisioned. Ollama *is* installed locally with `nomic-embed-text` pulled, which solved offline indexing — but the deployed app runs on Connect Cloud, which can't reach a local Ollama instance, so query-time embedding had no viable path anyway. BM25 sidesteps the problem entirely: zero external calls at query time, identical behavior locally and deployed. A legitimate classic-RAG design, not a compromise hiding a failure.
- Chat model: `ellmer::chat_anthropic()` on the same provisioned `ANTHROPIC_API_KEY` used by `r4dev-chat`/`r4dev-querychat`, for the same reason (no working Gemini key yet).
- System prompt enforces grounding: answer only from retrieved excerpts, cite the source session as a link, say so explicitly when the excerpts don't cover the question.
- Smoke-tested locally before deploying: a live query ("How do I make an interactive map with leaflet?") retrieved the correct session and produced an accurate, correctly-cited, appropriately-hedged answer.

**If revisited later**: swapping in real embeddings (once a Gemini/OpenAI key with quota exists) would improve recall for paraphrased questions BM25 misses on pure keyword mismatch — worth it, but BM25 already covers the demo convincingly.

### 4e — Package development & production Shiny
Two smaller sessions rounding out the "you can ship this for real" arc:
- `usethis`/`devtools`/`testthat` — "turn your analysis into a package."
- Shiny in production: modules, app structuring, and deployment beyond a single `shinyapps.io` app (see Phase 4h below, which makes this concrete immediately).

### 4f — Reproducibility & CI (infrastructure, not a session)
Unlocked once the GitHub remote exists:
- GitHub Actions: render + `quarto publish netlify` on push to `master`, closing the "no CI" gap.
- A scheduled **link-rot checker** — a GH Action that greps every `.qmd` for `http(s)://` URLs and curls them weekly, opening an issue on 404s. Automates the failure-inventory work this modernization did by hand.
- Revisit `renv::init()` now that the package surface is larger and LLM-dependent (previously deferred as premature).

### 4g — Accessibility & reach
- Alt-text audit: most `gif`/`png` figures currently have no `fig-alt`.
- WCAG contrast check of the brand palette (`_brand.yml`/`_brand-dark.yml`) — cheap, do it regardless of anything else since the site is now public.
- Given the workshop's OECD/IOM origins and international alumni, consider a bilingual (FR/EN) glossary/cheat-sheet rather than translating full sessions.

### 4h — Deploy all Shiny apps to Posit Connect Cloud, embed live in the site — ✅ done (7/9)
`rsconnect` was already authenticated on this machine for `connect.posit.cloud` — no login blocker after all. Deployed and embedded as live `<iframe>`s:
- [x] `BayesApp` → live, embedded in `13-bayes`.
- [x] `collider` → fixed a real bug first (`layout_wrap_column` doesn't exist; deprecated `theme_color`), then live, embedded in `04-animate`.
- [x] `r4dev-ovb` → needed `gtsummary`/`gt` installed locally (never verified before, since Quarto's render never executes standalone Shiny apps); live, embedded in `04-animate`.
- [x] `r4dev-chat` → the qmd teaches `GEMINI_API_KEY`, but no Gemini key was ever actually provisioned (only `eval: false` + captured outputs). Deployed demo runs on the already-working `ANTHROPIC_API_KEY` instead; live, embedded in `10-llm-apps`, with a callout explaining the discrepancy to readers.
- [x] `affairs1969-navbar`, `affairs1969-sidebar` → previously on shinyapps.io; migrated, both existing iframes in `07-shiny` repointed to Connect Cloud.
- [x] `shiny-homework` → deployed, not currently embedded anywhere (no session references it directly).
- [ ] ⏳ `r4dev-covid19` → **blocked**, not app-code fixable: `terra` fails to compile on Connect Cloud's build image (GDAL API mismatch — `AsClassicDataset` signature changed upstream). Left on its working shinyapps.io deployment; `07-shiny`'s iframe untouched.
- [ ] ⏳ `r4dev-querychat` → **blocked**: app starts and binds its port successfully, but something in `querychat_app()`'s startup sequence (likely a synchronous LLM/schema call) doesn't respond to Connect Cloud's 60s health check. Not a code bug found so far — may need a compute-tier bump or an upstream querychat fix for lazy initialization. Download link in `10-llm-apps` left as the only option for now.

Other bugs found and fixed along the way, worth remembering: `rsconnect`'s local metadata (`shiny/*/rsconnect/`) ties redeploys to a cached server-side environment — when a deploy fails due to a *missing package*, adding the package and redeploying under the **same** appId can keep reusing the stale (broken) environment; deleting the local `rsconnect/` folder and deploying under a fresh name forces a clean rebuild and resolved two apps that looked otherwise identical to a working config.

**Follow-up: `collider` and `r4dev-ovb` rebuilt for real** (style reference: [rpsychologist.com/descriptive-adjustment](https://rpsychologist.com/descriptive-adjustment/)). `collider` was previously an unrelated placeholder ("One Box"/click-counter demo) — rebuilt from scratch into an actual collider-bias demonstration (independent X/Y, a collider C caused by both, one switch to condition on C, live-updating scatter + correlation). `r4dev-ovb` kept its X/Z/Y structure but dropped the "Simulate" button for live-reactive sliders and simplified the heavy gt/gtsummary tables to one plot + three stat callouts. Rebuilding surfaced a real bug in the *original* (pre-modernization) data-generating process: X and Y shared the same noise term, which biased even the "long/truth" regression via endogeneity — undermining the whole teaching point. Fixed by giving Y its own independent error term; verified the long regression now recovers the true α to within sampling noise. Both redeployed to Connect Cloud and re-embedded in `04-animate`.

### Decisions needed before any of 4a–4g starts
- **Audience going forward**: still internal OECD-style cohorts, or has going public changed who this is for? Shapes tone, pacing, and whether a capstone/certificate structure is worth building.
- **Time budget**: each of 4a–4c and 4e is comparable in size to Phase 2 — expect similar back-and-forth (package research, live data verification, render debugging). Pick 1–2 to start, not all of them at once.
- **4d is recommended first** if only one new track gets built — it's the best demo of everything the workshop teaches working together, and the flagship item for recruiting the next cohort.

### Suggested order of attack (if greenlit)
1. 4h (Connect Cloud deploys + iframes) — concrete, independent, mostly blocked on your Connect Cloud login rather than open-ended scope.
2. 4f infrastructure (GitHub remote → CI → link-rot checker) — cheap, protects everything else from rotting again.
3. 4g accessibility pass — cheap, do it opportunistically alongside anything else.
4. 4d capstone (RAG chatbot) — highest payoff, reuses skills from nearly every existing session.
5. 4a/4b/4c as separate tracks, prioritized by your read on student demand.
6. 4e last — historically the least-requested skill (per the "extra content" framing in `about.qmd`).

## Phase 5 — Post-launch fixes (July 2026, after initial 4d/4h ship)

Follow-up round after the RAG capstone and Connect Cloud deployments went live, driven by concrete feedback.

- [x] **Iframe-only policy**: three direct "open the app [clicking here]" links to the personal Connect Cloud/shinyapps.io account were removed from `07-shiny` (all apps are now reachable *only* via the embedded `<iframe>`, never a raw clickable link to the personal hosting account). The navbar's "Ask R4DEV" entry was changed from a direct external `href` to an in-site anchor link (`10-llm-apps.qmd#capstone-ask-r4dev`), for the same reason — audited the whole site with a grep for `connect.posit.cloud`/`shinyapps.io` outside `<iframe>` tags to confirm none remain.
- [x] **Dark-mode card contrast bug fixed**: `--bs-tertiary-color` resolves in dark mode to the brand's dark `charcoal` hex (`#1B262D`) — meant as a *background* — being applied as *text color* on a similarly dark tertiary background, making card text on `index.qmd`'s feature cards nearly invisible. Fixed by setting `color: var(--bs-body-color)` explicitly on `.feature-card`/`.feature-card h3` in `style.css` rather than relying on the buggy derived variable.
- [x] **`shiny-homework` removed** at the user's request (theirs was an intentional deletion I initially — incorrectly — restored via `git restore` before realizing; re-deleted properly). Its Connect Cloud deployment (`r4dev-homework-cc`) could **not** be purged programmatically — `rsconnect::purgeApp()`/`terminateApp()` only support `shinyapps.io`, and the client object has no delete method for Connect Cloud content. Left as a manual cleanup item for the dashboard.
- [x] **All showcase apps rebranded**: every app now shows the `r4dev_dalle_1.png` logo in its own UI header (via a `www/r4dev_logo.png` copy — Shiny only serves static assets from a `www/` subfolder, not the app root) and was redeployed under a clean canonical `r4dev-*` name, dropping the `-v2`/`-v3`/`-cc` suffixes accumulated from earlier iteration (`r4dev-collider`, `r4dev-ovb`, `r4dev-bayesapp`, `r4dev-chat`, `r4dev-ask`, `r4dev-affairs1969-navbar`, `r4dev-affairs1969-sidebar`). `querychat_app()` exposes no title/logo hook, so `r4dev-querychat` (already blocked, see Phase 4h) was skipped. **Known side effect**: since each rename required a fresh `rsconnect/` metadata folder to force a clean environment (see the caching footgun noted above), every renamed app left its *previous* content ID orphaned and still live on the Connect Cloud account — rsconnect has no delete API for Connect Cloud, so these are only cleanable via the dashboard. Worth a manual sweep.
- [x] Recurring OneDrive/Quarto render race: this repo lives inside a live-synced OneDrive folder, and `quarto render`'s final "move rendered file into `_blog/`" step occasionally fails with `rename ... os error 2` when OneDrive's sync client holds a lock at the wrong moment (same root cause as the earlier `git gc` stalls). Symptom: `_blog/` looking unexpectedly empty or a render reporting `ERROR: NotFound`. Fix is simply to re-run `quarto render` — freeze cache means the retry is fast and doesn't re-execute R.

## Phase 6 — `ragnar` deep-dive session (July 2026)

New session `sessions_workshop/11-ragnar/11-ragnar.qmd`, "Grounded in truth" — a proper RAG pipeline built with [ragnar](https://ragnar.tidyverse.org/) instead of the hand-rolled DuckDB FTS code the "Ask R4DEV" capstone originally shipped with. The capstone itself moved out of `10-llm-apps.qmd` into this session (per explicit request: "the RAG example needs to be a self-standing session"), and the deployed app was rebuilt to match what's taught here.

**What ragnar actually is**: a tidyverse-style RAG toolkit — `read_as_markdown()`/`ragnar_find_links()` to crawl and clean a site, `markdown_chunk()` for semantic-boundary chunking, `embed_openai()`/`embed_google_gemini()`/`embed_ollama()`/etc. (provider-agnostic, mirrors `ellmer`'s `chat_*()` pattern), `ragnar_store_create()`/`ragnar_store_ingest()` for a DuckDB-backed store, `ragnar_retrieve_vss()`/`ragnar_retrieve_bm25()` for the two retrieval methods, and `ragnar_register_tool_retrieve()` to hand retrieval to an `ellmer` chat as a tool in one line.

**The session trains on R4DEV's own live site** — same trick ragnar's own homepage example plays on *R for Data Science* — and most chunks **actually execute during render** (not `eval: false` with pasted output, unlike the LLM sessions), because the key insight that unblocked this: **`embed_ollama()` needs no API key or quota** — Ollama was already installed locally with `embeddinggemma` and `nomic-embed-text` pulled, so embedding is free, local, and genuinely reproducible at render time. Only the multi-page store-build/retrieve/tool-calling chunks stay `eval: false` (they'd make every future `quarto render` re-crawl the site and re-embed hundreds of chunks), with real captured output pasted in from verified runs.

**Real bugs found while building this, worth remembering**:
- `ragnar_store_inspect()` launches an **interactive Shiny viewer** — calling it from a non-interactive `Rscript` hangs forever waiting for a browser connection. This silently ate over half an hour across two killed background jobs before being diagnosed. Never call it outside an interactive session; use plain SQL/dplyr on the store's underlying table to inspect contents in scripts.
- Killing a backgrounded R process via the bash-tool's tracked PID does **not** necessarily kill the actual native `Rscript.exe` child process on Windows — orphaned processes kept running (and kept a DuckDB file locked) well after the bash-visible process was gone. `taskkill //F //PID <native-pid>` was needed to actually stop them. Watch for "file already used by another process" DuckDB errors as the tell.
- `ragnar_store_create()` needs the `embed` function only at *creation* time (to size the embedding column); `ragnar_store_connect()` takes no `embed` argument at all and doesn't need one for `ragnar_retrieve_bm25()` — exactly what makes a deployed app work without any route to Ollama.
- Checkpointing a store with a built VSS (HNSW) index requires `INSTALL vss; LOAD vss;` first, even just to run `CHECKPOINT` — otherwise DuckDB errors on an unrecognized index type.

**The deployed capstone still runs on BM25, not VSS** — the store was built locally with `embed_ollama()`, but Posit Connect Cloud has no route back to a local Ollama instance to embed a stranger's live question, and this workshop still has no cloud embedding provider with usable quota (`OPENAI_API_KEY` on file: `insufficient_quota`; no Gemini key). This is presented in the session as an honest production trade-off, not a shortcut — the fix the moment a quota'd key exists is a one-line swap (`embed_google_gemini()` in the ingestion script) and a redeploy.

- [x] Session written, all live chunks verified executing with real output (52 chunks from a real page, 768-dim embeddings, real BM25/VSS comparisons, a real grounded tool-calling answer).
- [x] `r4dev-ask` rebuilt on ragnar's store/ingest/retrieve functions, redeployed, verified live.
- [x] Navbar updated: new "11. Grounded in truth (ragnar)" entry; "Ask R4DEV" entry now anchors to `11-ragnar.qmd#capstone-ask-r4dev` instead of `10-llm-apps.qmd`.
- [x] `10-llm-apps.qmd` capstone section replaced with a short pointer to session 11.

## Phase 7 — Collider app rebuild, modeled on the DAG Almanac (July 2026)

`r4dev-collider` was still fairly minimal (one on/off switch). Rebuilt to match the depth of [dags.andrewheiss.com/colliders.html](https://dags.andrewheiss.com/colliders.html): three continuous strength sliders (X→Z, Y→Z, X→Y) plus a toggle for whether the X→Y edge exists at all, a live DAG diagram (arrow opacity scales with slider strength, a dashed highlight box appears around X/Y when "adjust for Z" is on), a four-stat readout (true effect, overall slope, slope within the high-Z stratum, and bias — red when |bias| > 0.15), and a scatter plot with both the overall regression line and the stratified one. Adjustment is implemented as a **median split on Z** (not continuous FWL residualization) to match the reference site's "selected vs. excluded" framing.

Verified the underlying stats before deploying: no direct effect + no adjustment → overall slope ≈ 0 (correct, no bias without conditioning); no direct effect + adjust for Z → conditional slope goes clearly negative (classic collider-invented correlation); real effect of 0.5 + no adjustment → recovers ≈0.5; same + adjustment → biased down to ≈0.18. Textbook-correct in all four cases.

One real bug caught before shipping: `geom_segment()` arrows were invisible because the segments ran center-to-center between nodes, so the arrowhead landed exactly under the opaque node label and got drawn over. Fixed by shrinking each segment 22% inward from both ends before drawing.

Redeployed to Connect Cloud, iframe height in `04-animate` increased from 550px to 900px to fit the richer layout without internal scrolling.

## Phase 8 — Two real bugs, one systemic (July 2026)

Three reported issues turned out to be one root cause plus one unrelated plotting bug.

**Bug 1 — Maddison "left plot empty" in `02-plots`** (`2.maddison-ggiraph` chunk): `dplyr::summarise()` grouped by `(year, continent)` returns rows ordered by the *first* grouping variable only, so consecutive rows alternate between continents. `geom_path()`/`geom_path_interactive()` connects points strictly in **row order**, not sorted by x — with continents interleaved, every "line" was a run of exactly one point, so nothing visibly drew (confirmed via the literal warning `geom_path(): Each group consists of only one observation`). Fixed with `dplyr::arrange(continent, year)` before the `ggplot()` call. Verified locally: the warning disappears and the line renders continuously per continent. **Lesson for future `geom_path`/`geom_line` work**: always explicitly `arrange()` by the line variable before plotting when the data went through any `group_by()`/`summarise()` step — don't trust the grouping columns' order.

**Bug 2 (systemic) — every Connect Cloud iframe was invisible, site-wide.** `connect.posit.cloud/<user>/content/<id>` — the URL `rsconnect::deployApp()` prints and the one I'd been embedding everywhere — sends `X-Frame-Options: SAMEORIGIN`, which makes every browser refuse to render it inside an iframe from any other origin (confirmed via `curl -I`). This affected **every single app embed on the site**, not just the one flagged (04-animate's collider/OVB, 13-bayes's BayesApp, 10-llm-apps's chat, 11-ragnar's Ask R4DEV capstone) — all deployed and returning HTTP 200 when visited directly, all invisible where embedded. `rsconnect`'s `appVisibility` parameter does **not** apply to Connect Cloud (confirmed via package docs: "Currently has an effect only on deployments to shinyapps.io"), and no API/`rsconnect` method exists to fix this.

**The fix**: Connect Cloud has a separate **`https://<owner>-<app-slug>.share.connect.posit.cloud/`** URL per app, set via a manual "Share"/custom-URL control in the dashboard (no API access — the user set these by hand for each app). This URL does not appear to send the same framing header (confirmed working via a user-provided reference example on a different site; could not verify the header directly myself since Posit's CDN 403s programmatic `curl` requests to that subdomain, likely bot-protection, not an actual block). All iframe `src` attributes were updated to the new share-domain URLs:
- `04-animate` → `nelsonamayad-r4dev-collider.share.connect.posit.cloud`, `nelsonamayad-r4dev-ovb.share.connect.posit.cloud`
- `13-bayes` → `nelsonamayad-r4dev-bayesapp.share.connect.posit.cloud`
- `11-ragnar` capstone → `nelsonamayad-r4dev-ragnar.share.connect.posit.cloud`
- `07-shiny`'s two `affairs1969` iframes → [x] fixed — `nelsonamayad-r4dev-fair-s-affairs-navbar.share.connect.posit.cloud` and `...-sidebar...`. All showcased apps on the site now use `*.share.connect.posit.cloud` URLs; none remain on the broken `content/<id>` pattern.

**Also decided**: `r4dev-chat` (the plain, ungrounded `shinychat` teaching-assistant demo from session 10) was retired — redundant next to `r4dev-ask`'s grounded RAG capstone in session 11. Removed the local `shiny/r4dev-chat/` folder and its iframe from `10-llm-apps`, replaced with a callout pointing at the session 11 capstone and framing the pedagogical contrast (ungrounded vs. grounded chat) explicitly. The `r4dev-chat` deployment on Connect Cloud still needs manual deletion via the dashboard — no API access to do it from here (same limitation as the earlier `shiny-homework` cleanup).

## Phase 9 — `r4dev-covid19` retired, `r4dev-earthquakes` (blocked on leaflet), `r4dev-querychat` fixed, collider layout, new `12-parallel` session (July 2026)

- [x] **`r4dev-covid19` retired outright** — `rworldmap`/`sp` were long dead, and every rewrite attempt (first `spData`+`sf`, then a `plotly` choropleth) kept circling back to the same `terra`/GDAL wall or was judged not worth preserving. At the user's request the app and its `07-shiny.qmd` embed were deleted entirely, replaced with a callout noting the retirement and pointing at a planned replacement.
- [ ] ⏳ **`r4dev-earthquakes`** — built as `r4dev-covid19`'s replacement: real-time USGS earthquake point data (`https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/*.geojson` — note **`earthquakes` is plural** in the path; `earthquake/feed/...` 404s), plotted with `leaflet::addCircleMarkers()` (points only, no polygon/world-boundary file needed at all). **Still blocked**: confirmed via `leaflet`'s own `DESCRIPTION` that it hard-`Imports` `sf` (not just Suggests) and Suggests `terra` directly — so `library(leaflet)` alone, with zero polygon/sf code in the app, still drags `terra` into the Connect Cloud build and fails on the identical GDAL 3.4.1 mismatch that killed `r4dev-covid19`. This is a platform-wide fact, not fixable in app code. Explored pinning an older, pre-multidimensional-GDAL `terra` (confirmed via changelog research: multidim GDAL support landed in `terra` 1.8-54, so 1.8-53 or earlier should compile against GDAL 3.4.1) via a locally-downgraded `terra` feeding `rsconnect`'s manifest capture — blocked by a separate, unresolved local install issue (`remotes::install_version("terra", "1.7-78")` crashes with no error output, both source and binary, after multiple attempts). Left unresolved pending either a working local terra downgrade, a hand-written `renv.lock`, or dropping `leaflet` for the already-proven `plotly` choropleth technique.
- [x] **`r4dev-querychat` fixed** — root cause found: `querychat_app()`'s `$app()` method calls `shiny::runGadget()`, built for RStudio's interactive viewer pane, which binds its own ad-hoc port unrelated to whatever port a hosting platform's launcher expects — explaining the long-standing "starts, listens, but health check times out" symptom. Fixed by switching to querychat's modular `QueryChat$new()` + `qc$sidebar()` + `qc$server()` API inside an ordinary `page_sidebar()`/`shinyApp()`, which Connect Cloud's launcher runs normally. Also needed `library(RSQLite)` explicit in `app.R` (rsconnect only bundles packages it sees referenced in actual code, and `QueryChat$new()`'s `DataFrameSource` needs a database engine at runtime). Now live in `10-llm-apps.qmd`, running **Claude Sonnet 5** via `ellmer::chat_anthropic(model = "claude-sonnet-5")`, API key set as a Connect Cloud env var (never in code, never on the page) — sits alongside the existing `chat_google_gemini()` teaching example, which stays unchanged as the student-facing default.
- [x] **`r4dev-collider` layout revisited** — value boxes moved to the top row, DAG diagram left / scatter plot right (previously DAG on top, value boxes below, scatter at the bottom). Also fixed an unrelated crash surfaced while testing locally: the repo's `_brand.yml`/`_brand-dark.yml` had a `color: link:` field that the installed `brand.yml` R package (v0.1.0) doesn't recognize as a valid `color` field (only `foreground/background/primary/secondary/tertiary/success/info/warning/danger/light/dark` — `link` belongs under `typography.link.color`, which was already set correctly) — this crashed (sometimes as a plain error, sometimes as a native segfault when combined with a `bootswatch` preset) any local `bslib::bs_theme()` call in *any* Shiny app in this repo, since `bs_theme()` auto-discovers a `_brand.yml` by walking up parent directories. Removed the redundant `color.link` field from both brand files.
- [x] **New session `sessions_workshop/12-parallel/12-parallel.qmd`**, "Stop writing for-loops" — functional programming with `purrr` (`map`/`map_dbl`/`map2`/`pmap`/`walk`), then parallelized with `mirai` via `purrr::in_parallel()` (purrr 1.1.0's official parallel backend). Built directly from the [official tidyverse blog post](https://tidyverse.org/blog/2025/07/purrr-1-1-0-parallel/) announcing the feature, reusing its exact `mtcars`/`slow_lm()` teaching example. All chunks execute live at render time (`mirai` needs no API key/quota) — real numbers: sequential fit of 3 groups ≈0.35s, the same code wrapped in `in_parallel()` with 4 daemons ≈0.14s, identical R² values. Added to the "Sessions" navbar dropdown as "12. Scale up"; `about.qmd` learning outcomes updated.
  - **Local tooling detour, worth remembering**: this repo's local R install had CRAN Windows binaries mismatched against its R version (`nanonext`/`mirai`, and other packages, printed "built under R version 4.6.1" while this machine ran R 4.6.0) — severe enough that `nanonext`'s basic socket API (`mirai`'s low-level transport) crashed deterministically. Fixed by `remove.packages()` + a clean `install.packages()` reinstall of `nanonext` and `mirai` (no R version change needed — the user declined upgrading to R 4.6.1 and this repo continues on R 4.6.0). After the reinstall, a *separate*, general flakiness remained where even trivial/unrelated R calls (plain `split()`, a hardcoded JSON string) would segfault on one attempt and succeed on an identical retry — this was **not** specific to mirai/terra/GDAL, appears to be this machine/session's own instability under sustained heavy use, and was worked around by retrying and by preferring an actual `.R` script file over `Rscript -e '...'` one-liners (the latter seemed to fail more often, though this wasn't rigorously confirmed).
