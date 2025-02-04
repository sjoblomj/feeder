#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

function get_page_data() {
  local uri="$1"
  get_xml_as_json "$uri" |
    jq '.html.body.div.div.div[0].div[1].div[1].div.section // [] | .[] | select(has("div")) | .div.div.div.div | .[] | select(has("p"))' |
    jq '{"time": .p."+content", "title": (.div | .[] | select(has("h1")) | .h1."+content"), "text": (.div | .[] | select(has("+content")) | ."+content")}' |
    jq '. + {"time": (.time | capture("(?<D>[0-9]+) (?<M>[JFMASONDanebrpyulgctov]{3})[a-z]* (?<Y>[0-9]{4}) ?(?<h>[0-9]{2})?:?(?<m>[0-9]{2})?:?(?<s>[0-9]{2})? ?(?<tz>[A-Z]+)?"))} | .time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring) | .time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + (if ((.time.D | length) == 1) then "0" else "" end) + .time.D + "T" + (.time.h? // "00") + ":" + (.time.m? // "00") + ":" + (.time.s? // "00") + ".000Z")' |
    jq '. + {"created": .time.iso} | del(.time)'
}

entries=$(get_xml_as_json "$url" |
  jq '.html.body.div.div.div[0].div[1].div[1].div // [] | .[] | select(has("section") | not) | .div | [.[] | select(has("div") and (.div | has("div")))]' |
  jq 'map({"url": .div.div[0].a."+@href"})'
)

arr="[]"
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    data=$(get_page_data "$line")
    arr=$(jq --arg url "$line" --argjson data "$data" --argjson arr "$arr" -n '$arr + [$data + {"url": $url} | . + {"id": .url, "updated": null, "user": "Femern A/S"}]')
  fi
done <<< $(echo "$entries" | jq -r 'map(.url) | join("\n")')

echo "$arr" | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
