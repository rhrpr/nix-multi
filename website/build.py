#!/usr/bin/env python3
"""Build the public website with Python's standard library; no Nix activation."""
import argparse
import html
from pathlib import Path
import shutil
from string import Template
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
PAGES = [
    ("", "home", "Nix Multi — One foundation for your machines", "A reusable Nix foundation for macOS, NixOS desktops, and virtual machines. Explore the architecture and make the configuration your own."),
    ("docs", "overview", "Documentation", "A practical guide to understanding, adapting, and running Nix Multi."),
    ("docs/getting-started", "getting-started", "Getting started", "Create your own profile, configure hardware and secrets, and validate before activation."),
    ("docs/architecture", "architecture", "Architecture", "How profiles, host definitions, system modules, and Home Manager fit together."),
    ("docs/platforms", "platforms", "Platforms & virtual machines", "Choose a macOS, NixOS, or virtual machine workflow and understand its requirements."),
    ("docs/workflows", "workflows", "Everyday workflows", "Development shells, validation, updates, secrets, and optional AI tooling."),
    ("docs/troubleshooting", "troubleshooting", "Troubleshooting", "Resolve common evaluation, activation, hardware, and VM setup problems."),
]


def build(site_url):
    site_url = site_url.rstrip("/")
    parsed = urlparse(site_url)
    if parsed.scheme not in {"https", "http"} or not parsed.netloc or parsed.query or parsed.fragment:
        raise ValueError("--site-url must be an absolute HTTP(S) URL without query or fragment")
    out = ROOT / "dist"
    if out.exists():
        shutil.rmtree(out)
    out.mkdir()
    shutil.copytree(ROOT / "assets", out / "assets")
    (out / ".nojekyll").touch()
    template = Template((ROOT / "templates/base.html").read_text())
    for route, source, label, description in PAGES:
        content_file = ROOT / "content" / f"{source}.html"
        root = "/".join([".."] * len(route.split("/"))) if route else "."
        body = content_file.read_text()
        if route:
            nav = "".join(
                f'<a href="{root}/{path}/"' + (' aria-current="page"' if route == path else '') + f'>{html.escape(name)}</a>'
                for path, _, name, _ in PAGES if path
            )
            body = f'<main id="main" class="docs-layout wrap"><aside class="docs-sidebar"><p>DOCUMENTATION</p><nav aria-label="Documentation">{nav}</nav><a class="source-link" href="https://github.com/rhrpr/nix-multi">Browse the source ↗</a></aside><article class="article">{body}</article></main>'
        canonical = f"{site_url}/{route + '/' if route else ''}"
        card = out / "assets/og.png"
        social = '<meta name="twitter:card" content="summary">'
        if card.exists():
            image_url = html.escape(f"{site_url}/assets/og.png", quote=True)
            social = f'<meta property="og:image" content="{image_url}"><meta property="og:image:alt" content="Nix Multi. One foundation for your machines."><meta name="twitter:card" content="summary_large_image"><meta name="twitter:image" content="{image_url}">'
        page = template.substitute(title=html.escape(label if not route else f"{label} — Nix Multi"), description=html.escape(description, quote=True), canonical=html.escape(canonical, quote=True), root=root, body=body, docs_current='aria-current="true"' if route else '', social_image=social)
        target = out / route / "index.html"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(page)
    missing = template.substitute(
        title="Page not found — Nix Multi", description="Find your way back to the Nix Multi website and documentation.",
        canonical=html.escape(f"{site_url}/404.html", quote=True), root=html.escape(site_url, quote=True),
        body=f'<main id="main" class="section wrap article"><p class="eyebrow">404 / A MISSING PATH</p><h1>This page is not here.</h1><p class="lead">The address may have changed. Start again from the documentation.</p><a class="button primary" href="{html.escape(site_url, quote=True)}/docs/">Open the docs →</a></main>',
        docs_current='', social_image='<meta name="twitter:card" content="summary">',
    )
    (out / "404.html").write_text(missing)
    urls = ''.join(f'<url><loc>{html.escape(site_url)}/{route + "/" if route else ""}</loc></url>' for route, *_ in PAGES)
    (out / "sitemap.xml").write_text(f'<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{urls}</urlset>')
    (out / "robots.txt").write_text(f"User-agent: *\nAllow: /\nSitemap: {site_url}/sitemap.xml\n")
    print(f"Built {len(list(out.rglob('*.html')))} pages in {out}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--site-url", default="https://rhrpr.github.io/nix-multi")
    build(parser.parse_args().site_url)
