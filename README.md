# Data Visualization Competition 2026

A GitHub Pages gallery for the Common Fund Data Ecosystem (CFDE) Training Center's 2026 Data Visualization Competition submissions.

The gallery recognizes the first-, second-, and third-place entries alongside honorable mentions, and links visitors to the visualization, source code, notebook, supplied interactive, or submission artifact available for each entry.

## View the gallery

After GitHub Pages is enabled, the site is served from this repository's `docs/` directory. The gallery also links to the [CFDE Training Center](https://www.orau.org/cfde-trainingcenter/index.html).

## Build locally

Requirements:

- Base R
- Python 3 with Jupyter `nbconvert` installed (needed only to render the supplied notebooks)

From the repository root, run:

```sh
Rscript build_dashboard.R
```

This regenerates the deployable site in `docs/`. Open `docs/index.html` in a browser to preview it locally.

## Repository structure

```text
01_* through 12_*/     Supplied competition artifacts, organized by submission
assets/                Gallery branding assets
build_dashboard.R      Site generator
docs/                  Generated GitHub Pages site
```

`build_dashboard.R` assembles the gallery from the numbered submission directories. Depending on the material supplied for an entry, it can publish:

- A `NoviSurvey_Attachment_*` PDF submission artifact
- A rendered Jupyter notebook
- Supplied interactive web files
- A live visualization or source-code link

## Content handling

The gallery intentionally excludes the original `Novientry_*` survey-record PDFs, survey responses, and demographic material. Only the submission artifacts and links selected for the public gallery are included.

## Publishing with GitHub Pages

Push the repository to GitHub, then in **Settings → Pages**, choose deployment from the `main` branch and the `/docs` folder.
