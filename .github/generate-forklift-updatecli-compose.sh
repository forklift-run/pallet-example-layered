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
values_template_name="updatecli.pallet-upgrades.yqtempl"
for values_template in "$requirements_base"/**/"$values_template_name"; do
  subpath="${values_template#"$requirements_base/"}"
  pallet="${subpath%"/$values_template_name"}"
  values_interpolated="$(mktemp -t "updatecli-values-forklift-$type_singular-XXXXX.yml")"
  pallet="$pallet" \
    yq '(.. | select(tag == "!!str")) |= envsubst' "$values_template" >"$values_interpolated"
  policy="$(
    repo_root="$repo_root" pallet="$pallet" forklift_upgrade_file="$values_interpolated" \
      type_plural="$type_plural" type_singular="$type_singular" \
      yq '(.. | select(tag == "!!str")) |= envsubst' "$repo_root/$policy_template" |
      yq '. as $root | {} | .policies = [$root]'
  )"
  echo "$policy" |
    yq eval-all --inplace '.policies as $item ireduce ({}; .policies += $item )' \
      "$compose_file" -
done

echo
echo "Auto-generated compose file:"
cat "$compose_file"
