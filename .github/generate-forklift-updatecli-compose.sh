root=$(dirname "$(realpath "$BASH_SOURCE")")
template="$root/forklift.updatecli-compose.yml.yqtemplate"
values_dir="$1"
compose_file="$2"

echo '' >"$compose_file" # note: to set root-level values, instead copy a base file to $compose_file

for file in "$values_dir"/*.yml; do
  echo "Auto-generated policy for $file:"
  pallet="$(yq '.path' "$file")"
  policy="$(
    pallet="$pallet" values_file="${file#.github/}" \
      yq '(.. | select(tag == "!!str")) |= envsubst' "$template" |
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
