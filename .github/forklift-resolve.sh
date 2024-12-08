path="$1"          # path of a pallet or repo, e.g. `github.com/PlanktoScope/pallet-standard`
version_query="$2" # version query, e.g. `edge` or `main`

version="$(forklift inspector resolve-git-repo "$path@$version_query" | tail)"
echo "$version"
