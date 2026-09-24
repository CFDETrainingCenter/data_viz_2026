#!/usr/bin/env Rscript

# Build a GitHub Pages gallery from the numbered submission directories. PDFs
# are used only as the original entry records for the author credit below; the
# deployable site contains notebooks, supplied web code, and live links only.

source_root <- normalizePath(".", mustWork = TRUE)
output_root <- file.path(source_root, "docs")
asset_root <- file.path(output_root, "submissions")
logo_source <- file.path(source_root, "assets", "cfde-training-center-logo.png")

if (dir.exists(output_root)) unlink(output_root, recursive = TRUE)
dir.create(asset_root, recursive = TRUE)
if (!file.exists(logo_source)) stop("Missing logo asset: ", logo_source)
dir.create(file.path(output_root, "assets"), recursive = TRUE)
logo_copied <- file.copy(logo_source, file.path(output_root, "assets", basename(logo_source)), overwrite = TRUE)
if (!logo_copied) stop("Could not copy logo asset")

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

slugify <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9]+", "-", x)
  gsub("(^-|-$)", "", x)
}

extract_docx_link <- function(path) {
  scratch <- tempfile("docx-")
  dir.create(scratch)
  on.exit(unlink(scratch, recursive = TRUE), add = TRUE)
  utils::unzip(path, files = "word/_rels/document.xml.rels", exdir = scratch)
  rels <- file.path(scratch, "word", "_rels", "document.xml.rels")
  if (!file.exists(rels)) return(NA_character_)
  xml <- paste(readLines(rels, warn = FALSE), collapse = " ")
  hit <- regmatches(xml, regexpr('Target="https?[^\"]+"', xml))
  if (!length(hit) || !nzchar(hit)) return(NA_character_)
  sub('"$', "", sub('^Target="', "", hit))
}

copy_artifact <- function(source, destination_dir) {
  dir.create(destination_dir, recursive = TRUE, showWarnings = FALSE)
  target <- file.path(destination_dir, basename(source))
  ok <- file.copy(source, target, overwrite = TRUE)
  if (!ok) stop("Could not copy ", source)
  file.path("submissions", basename(destination_dir), basename(source))
}

render_notebook <- function(source, destination_dir) {
  dir.create(destination_dir, recursive = TRUE, showWarnings = FALSE)
  stem <- tools::file_path_sans_ext(basename(source))
  rendered <- file.path(destination_dir, paste0(stem, ".html"))
  jupyter_config <- file.path(tempdir(), "jupyter-config")
  dir.create(jupyter_config, recursive = TRUE, showWarnings = FALSE)
  status <- system2("python3", c("-m", "nbconvert", "--to", "html", "--output", stem,
    "--output-dir", shQuote(destination_dir), shQuote(source)), env = paste0("JUPYTER_CONFIG_DIR=", jupyter_config))
  if (status != 0L || !file.exists(rendered)) stop("Could not render notebook ", source)
  file.path("submissions", basename(destination_dir), basename(rendered))
}

folders <- list.dirs(source_root, recursive = FALSE, full.names = TRUE)
folders <- folders[grepl("^[0-9]{2}_", basename(folders))]
folders <- folders[order(basename(folders))]

# Verified from the "Full Name" field in each submitted entry record. Keeping
# this small editorial index avoids publishing the original entry PDFs.
authors <- c(
  "01" = "Shrramana Ganesh Sudhakar",
  "02" = "Upama Roy Chowdhury",
  "03" = "Abhinav Asthana",
  "04" = "Ujjalkumar Subhash Das",
  "05" = "Ehsan Saghapour",
  "06" = "Dalia Khaizaran",
  "07" = "Aaron Kanzer",
  "08" = "Munira Haque",
  "09" = "Marina Rice",
  "10" = "Chase Yakaboski",
  "11" = "S.M.A.S.A. Sewwandi",
  "12" = "Supriya Bidanta"
)

awards <- c(
  "01" = "Honorable mention",
  "02" = "Honorable mention",
  "03" = "Honorable mention",
  "04" = "Honorable mention",
  "05" = "Honorable mention",
  "06" = "Honorable mention",
  "07" = "2nd place",
  "08" = "Honorable mention",
  "09" = "3rd place",
  "10" = "Honorable mention",
  "11" = "Honorable mention",
  "12" = "1st place"
)

# Curated destination links for finalist entries. Supplied PDF attachments are
# published as explicit submission artifacts; Novientry survey-record PDFs are not.
entry_links <- list(
  "12" = list(
    code = "https://github.com/CFDETrainingCenter/dv_ion-transport",
    visualization = "https://cfdetrainingcenter.github.io/dv_ion-transport/"
  )
)

entries <- lapply(folders, function(folder) {
  label <- sub("^[0-9]{2}_", "", basename(folder))
  number <- sub("_.*", "", basename(folder))
  slug <- paste0(number, "-", slugify(label))
  destination <- file.path(asset_root, slug)
  all_files <- list.files(folder, recursive = TRUE, full.names = TRUE, all.files = FALSE)

  notebooks <- all_files[grepl("\\.(ipynb|r|rmd|qmd)$", all_files, ignore.case = TRUE)]
  link_docs <- all_files[grepl("data viz link.*\\.docx$", basename(all_files), ignore.case = TRUE)]
  web_roots <- all_files[basename(all_files) %in% c("start_here.html", "index.html")]

  artifacts <- character()
  curated <- entry_links[[number]]
  attachment_pdfs <- all_files[grepl("^NoviSurvey_Attachment_.*\\.pdf$", basename(all_files), ignore.case = TRUE)]
  if (length(attachment_pdfs)) {
    pdf_actions <- vapply(seq_along(attachment_pdfs), function(i) {
      label <- if (i == 1L) "View submission" else "View submission attachment"
      class <- if (i == 1L) "action primary" else "action"
      sprintf('<a class="%s" href="%s" target="_blank" rel="noopener">%s <span>↗</span></a>',
        class, html_escape(copy_artifact(attachment_pdfs[i], destination)), label)
    }, character(1))
    artifacts <- c(artifacts, pdf_actions)
  }
  if (length(notebooks)) {
    artifacts <- c(artifacts, sprintf('<a class="action primary" href="%s" target="_blank" rel="noopener">View notebook <span>↗</span></a>',
      html_escape(render_notebook(notebooks[1], destination))))
  }
  if (!is.null(curated$code)) {
    artifacts <- c(artifacts, sprintf('<a class="action primary" href="%s" target="_blank" rel="noopener">View source code <span>↗</span></a>', html_escape(curated$code)))
  } else if (length(web_roots)) {
    web_dir <- dirname(web_roots[1])
    target_dir <- file.path(destination, "interactive")
    dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
    web_files <- list.files(web_dir, full.names = TRUE, all.files = FALSE)
    ok <- file.copy(web_files, target_dir, recursive = TRUE)
    if (any(!ok)) stop("Could not copy web files from ", web_dir)
    artifacts <- c(artifacts, sprintf('<a class="action primary" href="submissions/%s/interactive/%s" target="_blank" rel="noopener">Launch supplied interactive <span>↗</span></a>',
      html_escape(slug), html_escape(basename(web_roots[1]))))
  }
  external_link <- if (!is.null(curated$visualization)) curated$visualization else if (length(link_docs)) extract_docx_link(link_docs[1]) else NA_character_
  if (!is.na(external_link)) {
    artifacts <- c(artifacts, sprintf('<a class="action" href="%s" target="_blank" rel="noopener">Open live visualization <span>↗</span></a>', html_escape(external_link)))
  }

  list(number = number, title = label, author = authors[[number]], award = awards[[number]], artifacts = artifacts,
       types = c(if (length(notebooks)) "Notebook" else NULL,
                 if (!is.null(curated$code)) "Source code" else if (length(web_roots)) "Web code" else NULL,
                 if (!is.na(external_link)) "Live link" else NULL))
})

# Lead with the medal recipients, then alphabetize the honorable mentions.
award_order <- c("1st place", "2nd place", "3rd place", "Honorable mention")
entries <- entries[order(match(vapply(entries, `[[`, character(1), "award"), award_order),
                        tolower(vapply(entries, `[[`, character(1), "title")))]

cards <- vapply(entries, function(entry) {
  actions <- if (length(entry$artifacts)) paste(entry$artifacts, collapse = "") else '<span class="unavailable">No web, code, or notebook artifact supplied</span>'
  award_class <- if (entry$award == "1st place") "first" else if (entry$award == "2nd place") "second" else if (entry$award == "3rd place") "third" else "mention"
  sprintf('<article class="card"><span class="award %s">%s</span><h2>%s</h2><p class="author">By %s</p><div class="actions">%s</div></article>',
    award_class, html_escape(entry$award), html_escape(entry$title), html_escape(entry$author), actions)
}, character(1))

page <- sprintf('<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Data Visualization Competition 2026 Submissions</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Nunito+Sans:opsz,wght@6..12,400;6..12,600;6..12,700;6..12,800;6..12,900&display=swap" rel="stylesheet">
<style>
:root{--navy:#31385c;--purple:#744780;--purple-dark:#5f396a;--surface:#faf9fb;--ink:#31385c;--muted:#68708d;--line:#ded8e2}*{box-sizing:border-box}body{margin:0;background:var(--surface);color:var(--ink);font-family:"Nunito Sans",ui-rounded,system-ui,sans-serif;line-height:1.5}.brand{max-width:1200px;margin:0 auto;padding:30px 28px 26px}.brand-logo{display:block;width:min(100%%,370px);height:auto}.accent-banner{height:8px;background:var(--purple)}.hero{width:100%%;padding:34px max(28px,calc((100vw - 1200px)/2)) 38px}.hero h1{font-size:clamp(2.1rem,4.8vw,4.6rem);line-height:1.04;letter-spacing:-.04em;margin:0;width:100%%;font-weight:900}.main{max-width:1200px;margin:0 auto;padding:0 28px 72px}.toolbar{margin-bottom:24px}.count{font-weight:900;color:var(--navy)}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px}.card{background:#fff;border:1px solid var(--line);border-radius:5px;padding:23px;min-height:242px;display:flex;flex-direction:column;box-shadow:0 3px 10px rgba(49,56,92,.06)}.award{align-self:flex-start;border-radius:999px;padding:4px 9px;font-size:.72rem;font-weight:900;letter-spacing:.035em;text-transform:uppercase;background:#f1edf3;color:var(--purple-dark)}.award.first{background:#fff1be;color:#785200}.award.second{background:#edf0f3;color:#59616b}.award.third{background:#fae4ce;color:#8c4f12}.card h2{font-size:1.35rem;line-height:1.15;letter-spacing:-.02em;font-weight:900;margin:14px 0 6px}.author{color:var(--purple);font-weight:800;margin:0 0 22px}.actions{display:flex;flex-wrap:wrap;gap:8px;margin-top:auto}.action{font-size:.84rem;font-weight:900;text-decoration:none;color:var(--purple-dark);border:2px solid #c5a8cb;padding:7px 10px;border-radius:4px}.action:hover{background:#f5eff7}.action.primary{background:var(--purple);border-color:var(--purple);color:#fff}.action.primary:hover{background:var(--purple-dark);border-color:var(--purple-dark)}.unavailable{font-size:.85rem;color:var(--muted);font-weight:600}.note{color:var(--muted);font-size:.85rem;margin-top:32px;border-top:1px solid var(--line);padding-top:18px}@media(max-width:850px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:570px){.brand{padding:24px 20px}.brand-logo{width:100%%}.hero,.main{padding-left:20px;padding-right:20px}.hero{padding-top:28px}.grid{grid-template-columns:1fr}.card{min-height:210px}}
</style></head><body>
<header class="brand"><img class="brand-logo" src="assets/cfde-training-center-logo.png" alt="Common Fund Data Ecosystem Training Center"></header><div class="accent-banner" aria-hidden="true"></div>
<section class="hero"><h1>Data Visualization Competition 2026 Submissions</h1></section>
<main class="main"><div class="toolbar"><span class="count">%d submissions</span></div><section class="grid">%s</section><p class="note"><a href="https://www.orau.org/cfde-trainingcenter/index.html">https://www.orau.org/cfde-trainingcenter/index.html</a></p></main>
</body></html>', length(entries), paste(cards, collapse = "\n"))

writeLines(page, file.path(output_root, "index.html"), useBytes = TRUE)
writeLines("", file.path(output_root, ".nojekyll"))
message("Built ", length(entries), " submission cards in docs/index.html")
