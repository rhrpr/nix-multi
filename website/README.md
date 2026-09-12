# Nix Multi website

A static product overview and documentation site for GitHub Pages. The site
uses Python's standard library to produce plain HTML, CSS, and JavaScript.
It does not evaluate or activate the Nix configuration.

## Develop locally

From the repository root, with Python 3.10 or newer:

```sh
python3 website/build.py
python3 website/check.py
python3 -m http.server 4173 --directory website/dist
```

Open http://localhost:4173. Re-run the build and refresh after editing.

- `content/`: hand-maintained HTML guides and landing page.
- `templates/base.html`: shared layout, navigation, and metadata.
- `assets/`: styles, progressive code-copy controls, favicon, and social card.
- `build.py`: route titles, descriptions, navigation, and static generation.
- `check.py`: verifies routes, local links, fragments, and metadata.
- `dist/`: generated output, ignored by Git.

Keep the guides consistent with the configuration revision being published.
In particular, the profile and setup documentation reflects the portable-profile
work in this checkout; publish that configuration work before or alongside the
site so new visitors can follow the guide against the default branch.

## Publish on GitHub Pages

1. Push the website and `.github/workflows/pages.yml` to `main` after review.
2. In the repository's **Settings → Pages → Build and deployment**, select
   **GitHub Actions** as the source.
3. Run the **Website** workflow from Actions, or push a website change to `main`.

The intended URL for this repository is **https://rhrpr.github.io/nix-multi/**.
The deploy job reports the actual live URL after successful publication.
Pull requests run the build and link checks without publishing.

The workflow uploads only `website/dist`, never the full configuration,
profile files, or secrets directory. No additional deployment secret is needed
after Pages is enabled; deployment uses the workflow's scoped GitHub token.

For a fork, the workflow derives the URL from the repository owner and name.
Update the site's GitHub source links for your fork. For a custom domain,
configure it in Pages settings and set the repository Actions variable
`PAGES_SITE_URL` to the complete public origin/base path. This controls canonical,
Open Graph, social image, sitemap, and 404 links. For local builds, use:

```sh
python3 website/build.py --site-url https://example.com
```

Deployment follows GitHub's [custom Pages workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).

## Content and design

The site presents the value of the work without invented customer claims,
pricing, or a purchase flow. It links visitors to the source and onboarding
guide. The social card was generated for this project. Typography uses Google
Fonts with local system fallbacks; the site remains readable without it.
