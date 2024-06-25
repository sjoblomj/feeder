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
    sed 's/<script>.*<\/script>//g' |
    yq --xml-skip-directives --xml-skip-proc-inst --xml-raw-token=false -p xml -o json '.' |
    jq '.html.body.main.section.div | .[] | select(."+@class" == "container") | .div.div' |
    jq 'map(.article.div | .[] | select(."+@class" == "box__text") | {"title": .h3.a."+@title", "url": .h3.a."+@href", "text": .p, "created": .div."+content"})' |
    jq 'map(. + {"created": (.created | capture("(?<D>[0-9]{2}) (?<M>[janurifebmsplgtokvdc]+) (?<Y>[0-9]{4})") | .M = (.M as $m | ["januari", "februari", "mars", "april", "maj", "juni", "juli", "augusti", "september", "oktober", "november", "december"] | index($m) + 1 | tostring) | (.Y + "-" + (if (.M | tonumber < 10) then "0" else "" end) + .M + "-" + (if ((.D | length) == 1) then "0" else "" end) + .D + "T" + (.h? // "00") + ":" + (.m? // "00") + ":" + (.s? // "00") + ".000Z"))})' |
    jq 'map(. + {"id": .url, "url": ("https://www.gotheborg.se" + .url), user: "SOIC", updated: null})' |
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi
