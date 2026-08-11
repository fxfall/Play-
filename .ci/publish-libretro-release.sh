#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <release-slug> <libretro-core-path>" >&2
    exit 2
fi

release_slug="$1"
core_path="$2"

if [[ ! -f "$core_path" ]]; then
    echo "libretro core does not exist: $core_path" >&2
    exit 1
fi

core_filename="$(basename "$core_path")"
core_stem="${core_filename%.*}"
core_ext="${core_filename##*.}"
asset="${core_stem}-${release_slug}.${core_ext}.zip"

rm -f "$asset"
zip -j -9 "$asset" "$core_path"

if [[ -z "${GITHUB_REF_NAME:-}" || -z "${GITHUB_REPOSITORY:-}" || -z "${GH_TOKEN:-}" ]]; then
    echo "GitHub release environment is not available" >&2
    exit 1
fi

if gh release view "$GITHUB_REF_NAME" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
    gh release upload "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" --clobber
else
    gh release create "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" \
        --title "Play! Libretro $GITHUB_REF_NAME" \
        --generate-notes \
    || gh release upload "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" --clobber
fi
