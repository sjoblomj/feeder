#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

sitedata=$(curl --connect-timeout 10 -sL "$url")
if [ -z "$sitedata" ]; then
  echo "[]"
else
  echo "$sitedata" |
    yq --xml-skip-directives --xml-skip-proc-inst --xml-raw-token=false -p xml -o json '.' |
    jq '.html.body.div | .[]' |
    jq 'select(.div?.h1?."+content"? == "From our blog")' |
    jq '.div.div.div.div' |
    jq 'map({"id": .a."+@href", "title": .a.h2?."+content", "url": .a."+@href", "created": .a.div?[0]?."+content"?})' |
    jq 'map(. + {"time": (.created | capture("(?<M>[JFMASONDanebrpyulgctov]{3}) (?<D>[0-9]+), (?<Y>[0-9]{4})"))}) | map(.time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring)) | map(.time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + (if ((.time.D | length) == 1) then "0" else "" end) + .time.D))' |
    jq 'map(. + {"url": ("https://planetwild.com" + .url), "created": (.time.iso + "T00:00:00.000Z"), "user": "Planet Wild", "userPicture": null, "text": null, "updated": null})' |
    jq 'map(. | del(.time))' |
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi
