#!/usr/bin/env python3
"""Verify generated routes, fragments, assets, and per-page metadata offline."""
from html.parser import HTMLParser
from pathlib import Path
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent / "dist"


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids = set()
        self.links = []
        self.meta = {}
        self.h1 = 0
        self.title = ""
        self.in_title = False
        self.canonical = None
        self.duplicates = []
        self.feed(path.read_text())

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if "id" in attrs:
            if attrs["id"] in self.ids:
                self.duplicates.append(attrs["id"])
            self.ids.add(attrs["id"])
        self.h1 += tag == "h1"
        if tag == "title":
            self.in_title = True
        if tag == "meta":
            self.meta[attrs.get("name", attrs.get("property"))] = attrs.get("content")
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonical = attrs.get("href")
        for attribute in ("href", "src"):
            if attrs.get(attribute):
                self.links.append(attrs[attribute])

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title += data


def check():
    from build import PAGES
    expected = {ROOT / route / "index.html" for route, *_ in PAGES} | {ROOT / "404.html"}
    missing = expected - set(ROOT.rglob("*.html"))
    errors = [f"Missing page: {path}" for path in missing]
    pages = {path.resolve(): Page(path) for path in ROOT.rglob("*.html")}
    titles = set()
    count = 0
    for path, page in pages.items():
        if page.h1 != 1 or not page.title or page.title in titles:
            errors.append(f"{path}: expected one h1 and a unique title")
        titles.add(page.title)
        if page.duplicates:
            errors.append(f"{path}: duplicate IDs {page.duplicates}")
        if not page.canonical or not page.canonical.startswith(("https://", "http://")):
            errors.append(f"{path}: missing absolute canonical")
        for key in ("description", "og:title", "og:description", "og:url", "twitter:title", "twitter:description", "twitter:card"):
            if not page.meta.get(key):
                errors.append(f"{path}: missing {key}")
        if page.meta.get("og:title") != page.title or page.meta.get("twitter:title") != page.title:
            errors.append(f"{path}: social titles do not match page title")
        if page.meta.get("og:description") != page.meta.get("description") or page.meta.get("twitter:description") != page.meta.get("description"):
            errors.append(f"{path}: social descriptions do not match page description")
        if path.name != "404.html":
            for key in ("og:image", "twitter:image"):
                if not page.meta.get(key, "").startswith(("https://", "http://")):
                    errors.append(f"{path}: missing absolute {key}")
        for link in page.links:
            parsed = urlsplit(link)
            if parsed.scheme or parsed.netloc:
                continue
            target = (path.parent / unquote(parsed.path)).resolve() if parsed.path else path
            if target.is_dir():
                target /= "index.html"
            if not target.is_relative_to(ROOT.resolve()) or not target.exists():
                errors.append(f"{path.relative_to(ROOT)}: broken local link {link}")
            elif parsed.fragment and target in pages and unquote(parsed.fragment) not in pages[target].ids:
                errors.append(f"{path.relative_to(ROOT)}: missing fragment in {link}")
            count += 1
    if not (ROOT / "assets/og.png").is_file():
        errors.append("Missing social preview image")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Verified {len(pages)} pages, {count} local links/assets, fragments, and metadata.")
    return 0


if __name__ == "__main__":
    raise SystemExit(check())
