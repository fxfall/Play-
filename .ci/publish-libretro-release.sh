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

create_zip() {
    archive="$1"
    input_file="$2"

    if command -v zip >/dev/null 2>&1; then
        zip -j -9 "$archive" "$input_file"
    elif command -v 7z >/dev/null 2>&1; then
        archive_abs="$(cd "$(dirname "$archive")" && pwd)/$(basename "$archive")"
        (cd "$(dirname "$input_file")" && 7z a -tzip -mx=9 "$archive_abs" "$(basename "$input_file")")
    elif command -v 7z.exe >/dev/null 2>&1; then
        archive_abs="$(cd "$(dirname "$archive")" && pwd)/$(basename "$archive")"
        (cd "$(dirname "$input_file")" && 7z.exe a -tzip -mx=9 "$archive_abs" "$(basename "$input_file")")
    elif command -v powershell.exe >/dev/null 2>&1 \
          && command -v cygpath >/dev/null 2>&1; then
        archive_win="$(cygpath -w "$archive")"
        input_win="$(cygpath -w "$input_file")"
        powershell.exe -NoProfile -NonInteractive -Command \
            "Compress-Archive -LiteralPath '$input_win' -DestinationPath '$archive_win' -CompressionLevel Optimal -Force"
    else
        echo "no ZIP creation tool is available" >&2
        return 127
    fi
}

create_zip "$asset" "$core_path"

if [[ -z "${GITHUB_REF_NAME:-}" || -z "${GITHUB_REPOSITORY:-}" || -z "${GH_TOKEN:-}" ]]; then
    echo "GitHub release environment is not available" >&2
    exit 1
fi

if command -v gh >/dev/null 2>&1; then
    gh_command=gh
elif command -v gh.exe >/dev/null 2>&1; then
    gh_command=gh.exe
else
    echo "GitHub CLI is not available" >&2
    exit 127
fi

if "$gh_command" release view "$GITHUB_REF_NAME" --repo "$GITHUB_REPOSITORY" >/dev/null 2>&1; then
    "$gh_command" release upload "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" --clobber
else
    "$gh_command" release create "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" \
        --title "Play! Libretro $GITHUB_REF_NAME" \
        --generate-notes \
    || "$gh_command" release upload "$GITHUB_REF_NAME" "$asset" \
        --repo "$GITHUB_REPOSITORY" --clobber
fi
