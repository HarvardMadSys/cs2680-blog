#!/bin/sh
# Cloudflare Pages build. Set the project's build command to `./build.sh` and
# its output directory to `public`.
#
# Two things live here rather than in the dashboard's build-command box: the
# Hugo version check, which turns an obscure template error into a sentence
# that says what to do, and the baseURL, which has to differ between the
# production deployment and a preview.
set -eu

# The release that introduced the layouts/_partials, _shortcodes and _markup
# structure this site uses. Anything older does not fail loudly -- it renders
# pages with no layout applied -- so the check is worth its six lines.
MIN_VERSION=0.146.0
# What the site is developed and tested against, and what HUGO_VERSION should
# be set to. Cloudflare's build image installs Hugo 0.54.0 when that variable
# is unset, which is why this script exists at all.
PINNED_VERSION=0.164.0

have=$(hugo version | sed -n 's/.*hugo v\([0-9][0-9.]*\).*/\1/p')
oldest=$(printf '%s\n%s\n' "$have" "$MIN_VERSION" | sort -V | head -1)
if [ -z "$have" ] || [ "$oldest" != "$MIN_VERSION" ]; then
  echo "error: this site needs Hugo $MIN_VERSION or newer; found ${have:-none}." >&2
  echo "       On Cloudflare Pages, add an environment variable" >&2
  echo "       HUGO_VERSION=$PINNED_VERSION under Settings -> Environment variables." >&2
  exit 1
fi

# The production deployment is the only one that may claim the real hostname.
# A preview that emits <link rel=canonical> for blog.cs2680.com tells a crawler
# that the preview *is* the site. CF_PAGES_URL is the per-deployment hostname;
# it is unset when this script is run by hand, which then builds for production.
if [ "${CF_PAGES_BRANCH:-main}" = "main" ] || [ -z "${CF_PAGES_URL:-}" ]; then
  exec hugo --gc --minify
fi

# `-e preview` is what layouts/robots.txt reads to disallow crawling, and what
# turns off the CSS fingerprint and Google Analytics in _partials/head.html.
exec hugo --gc --minify -e preview -b "$CF_PAGES_URL"
