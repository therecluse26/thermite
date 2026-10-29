#!/usr/bin/env bash
# Points the NixOS module at a new release: writes nix/release.json with the AppImage's URL and
# hash, and commits it to main. The release workflow runs this after it publishes the release.
# nix/module.nix reads the file, so `nix flake update thermite` moves the window and the fan
# daemon to the same release.
#
# The commit goes through GitHub's contents API, on top of the newest main. So a push during
# the build is no problem, and the checkout stays as it is.
# Needs VERSION and TAG (from plan-release.sh), GITHUB_REPOSITORY (owner/repo), GH_TOKEN with
# contents: write, and the AppImage at release/thermite_<VERSION>_amd64.AppImage.
set -euo pipefail

cd "$(dirname "$0")/../.."
appimage="thermite_${VERSION:?}_amd64.AppImage"
repo=${GITHUB_REPOSITORY:?set GITHUB_REPOSITORY to owner/repo}
url="${GITHUB_SERVER_URL:-https://github.com}/$repo/releases/download/${TAG:?}/$appimage"
# The SRI form that fetchurl takes: "sha256-", then the digest in base64.
hash="sha256-$(openssl dgst -sha256 -binary "release/$appimage" | base64)"

jq -n --arg version "$VERSION" --arg url "$url" --arg hash "$hash" \
  '{$version, $url, $hash}' >nix/release.json
cat nix/release.json

# The contents API replaces a file only when it gets the blob sha of the file on main.
api="repos/$repo/contents/nix/release.json"
# [skip ci]: a push with the workflow's token starts no workflow anyway. This also stops one
# with any other token, which would otherwise make a release of this commit.
gh api --method PUT "$api" \
  -f branch=main \
  -f message="chore(nix): install the window from $TAG [skip ci]" \
  -f content="$(base64 -w0 nix/release.json)" \
  -f sha="$(gh api "$api?ref=main" --jq .sha)" \
  --jq '"Committed " + .commit.sha + " to main."'
