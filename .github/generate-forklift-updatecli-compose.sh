root=$(dirname "$(realpath "$BASH_SOURCE")")
repo_root="$1"       # this should be an absolute path
policy_template="$2" # this should be relative to repo_root
values_dir="$2"      # this should be relative to repo_root
compose_file="$3"    # this may be an absolute path outside repo_root or a relative path to cwd

echo '' >"$compose_file" # note: to set root-level values, instead copy a base file to $compose_file

for file in "$repo_root/$values_dir"/*.yml; do
  echo "Auto-generated policy for $file:"
  pallet="$(yq '.path' "$file")"
  policy="$(
    pallet="$pallet" values_file="$file" repo_root="$repo_root" \
      yq '(.. | select(tag == "!!str")) |= envsubst' "$repo_root/$policy_template" |
      yq '. as $root | {} | .policies = [$root]'
  )"
  echo "$policy"
  echo
  echo "$policy" |
    yq eval-all --inplace '.policies as $item ireduce ({}; .policies += $item )' \
      "$compose_file" -
done

echo "Auto-generated compose file:"
cat "$compose_file"
