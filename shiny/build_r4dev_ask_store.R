# Rebuild the "Ask R4DEV" ragnar store from the PUBLISHED site.
#
# Run from the repo root, after publishing, whenever lesson content changes
# significantly:
#   Rscript shiny/build_r4dev_ask_store.R
# then redeploy shiny/r4dev-ask (see CLAUDE.md, "Shiny apps & deployment").
#
# Kept outside shiny/r4dev-ask/ on purpose: rsconnect scans every .R file in
# an app folder for dependencies, so a build script inside it would leak into
# the deployed app's manifest.
#
# Needs a local Ollama with `embeddinggemma` pulled (free, no API key). The
# deployed app only does BM25 retrieval, so it never needs Ollama itself.

library(ragnar)

site <- "https://nelsonamayad.github.io/R4DEV/"
out  <- "shiny/r4dev-ask/r4dev_ragnar.duckdb"
tmp  <- paste0(out, ".new")

# 1. Every lesson, track and orientation page, from the site's own sitemap
sitemap <- xml2::read_xml(paste0(site, "sitemap.xml"))
urls <- xml2::xml_text(xml2::xml_find_all(sitemap, "//*[local-name()='loc']"))
urls <- urls[grepl("/(sessions_[a-z]+|learn)/|/(index|start|about)\\.html$", urls)]
urls <- urls[!grepl("revealjs|03-feedback", urls)] # a slide deck and a Google Form
stopifnot(length(urls) >= 20)
message(length(urls), " pages to ingest")

# 2. Build into a temp file, so a failed run never clobbers the working store
unlink(tmp)
store <- ragnar_store_create(
  tmp,
  embed = ragnar::embed_ollama(model = "embeddinggemma")
)
ragnar_store_ingest(store, urls, build_index = TRUE)

# 3. A store with an HNSW (vss) index needs the extension loaded to checkpoint
DBI::dbExecute(store@con, "INSTALL vss; LOAD vss; CHECKPOINT;")
n <- DBI::dbGetQuery(store@con, "SELECT count(*) AS n, count(DISTINCT origin) AS pages FROM chunks")
print(n)
DBI::dbDisconnect(store@con, shutdown = TRUE)

file.rename(tmp, out)
message("Store written to ", out)
