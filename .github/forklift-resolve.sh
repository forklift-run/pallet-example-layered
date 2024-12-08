#!/usr/bin/env -S bash -uo pipefail

path="$1"          # path of a pallet or repo, e.g. `github.com/PlanktoScope/pallet-standard`
version_query="$2" # version query, e.g. `edge` or `main`; pseudoversions are not supported (yet)

version="$(forklift inspector resolve-git-repo "$path@$version_query" | tee /dev/stderr | tail -n 1)"
echo "$version"
