#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

function get_page_data() {
  local uri="$1"
  get_xml_as_json "$uri" 's|this.suggestions.length.*this.suggestions.length - 1||g' |
    jq '.html.body.div // [] | .[] | select(has("main")) | .main.article.div' |
    jq '.[] | select(."+@class" | contains("hero-content")).div.[] | select(has("div")).div.[] | select(has("div")).div' |
    jq '. as $root | {
      "title": ($root.[] | select(."+@class" | contains("text-content") | not).div.h1."+content"),
      "time":  ($root.[] | select(."+@class" | contains("text-content") | not).div.date."+content"),
      "text":  ""#($root.[] | select(."+@class" | contains("text-content")).div as $textgrandparent | (if $textgrandparent | type == "object" then $textgrandparent else $textgrandparent.[] end) as $textparent | $textparent | select(has("section")).section.div.div.div[0].div.div.div.p | [.. ."+content"? // .br? // .] | flatten | map( if type == "object" then .br? // .strong? // . else . end ) | [.[] | select(. != null)] | join("<br />\n"))
    }' |
    jq '. + {"time": (.time | capture("(?<D>[0-9]+) (?<M>[JFMASONDanebrpyulgctov]{3})[a-z]* (?<Y>[0-9]{4}) ?(?<h>[0-9]{2})?:?(?<m>[0-9]{2})?:?(?<s>[0-9]{2})? ?(?<tz>[A-Z]+)?"))} | .time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring) | .time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + (if ((.time.D | length) == 1) then "0" else "" end) + .time.D + "T" + (.time.h? // "00") + ":" + (.time.m? // "00") + ":" + (.time.s? // "00") + ".000Z")' |
    jq '. + {"created": .time.iso} | del(.time)'
}

entries=$(get_xml_as_json "$url" 's|this.suggestions.length.*this.suggestions.length - 1||g' |
  jq '.html.body.div // [] | .[] | select(has("main")) | .main.section.article.div' |
  jq 'map({"url": (.div.div | .[] | select(."+@class" | contains("article-content")) | .div.a."+@href")})'
)

arr="[]"
while IFS= read -r line; do
  if [[ -n "$line" ]]; then
    data=$(get_page_data "$line")
    arr=$(jq --arg url "$line" --argjson data "$data" --argjson arr "$arr" -n '$arr + [$data + {"url": $url} | . + {"id": .url, "updated": null, "user": "Femern A/S"}]')
  fi
done <<< $(echo "$entries" | jq -r 'map(.url) | join("\n")')

echo "$arr" | filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
