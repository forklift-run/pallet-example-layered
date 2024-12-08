#!/usr/bin/env -S bash -u

path="$1"          # path of a pallet or repo, e.g. `github.com/PlanktoScope/pallet-standard`
version_query="$2" # version query, e.g. `edge` or `main`; pseudoversions are not supported (yet)

version="$(forklift inspector resolve-git-repo "$path@$version_query")"
retval=$?
echo "$version" >&2
if [ "$retval" != 0 ]; then
  exit "$retval"
fi
echo "$version"
