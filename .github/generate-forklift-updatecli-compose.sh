#!/usr/bin/env bash
shopt -s globstar

root=$(dirname "$(realpath "$BASH_SOURCE")")
repo_root="$1"       # this should be an absolute path to the root of the Git repository to update
policy_template="$2" # this should be relative to repo_root
type_plural="$3"     # this should be either `pallets` or `repositories`
compose_file="$4"    # this may be an absolute path outside repo_root or a relative path to cwd

echo '' >"$compose_file" # note: to set root-level values, instead copy a base file to $compose_file

case "$type_plural" in
"pallets" | "pallet")
  type_plural="pallets"
  type_singular="pallet"
  ;;
"repositories" | "repository")
  type_plural="repositories"
  type_singular="repository"
  ;;
esac

requirements_base="$repo_root/requirements/$type_plural"
for file in "$requirements_base"/**/updatecli.forklift-upgrades.yml; do
  subpath="${file#"$requirements_base/"}"
  pallet="${subpath%"/updatecli.forklift-upgrades.yml"}"
  policy="$(
    repo_root="$repo_root" pallet="$pallet" forklift_upgrade_file="$file" \
      type_plural="$type_plural" type_singular="$type_singular" \
      yq '(.. | select(tag == "!!str")) |= envsubst' "$repo_root/$policy_template" |
      yq '. as $root | {} | .policies = [$root]'
  )"
  #echo "Auto-generated policy for $type_singular $pallet:"
  #echo "$policy"
  #echo
  echo "$policy" |
    yq eval-all --inplace '.policies as $item ireduce ({}; .policies += $item )' \
      "$compose_file" -
done

echo
echo "Auto-generated compose file:"
cat "$compose_file"
