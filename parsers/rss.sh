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
  echo "$sitedata" | \
    yq -p=xml -o=json | \
    jq '.rss.channel.item' | \
    jq 'map(. + {"time": (.pubDate | capture("[MTWFSonuedhriat]{3}, (?<D>[0-9]+) (?<M>[JFMASONDanebrpyulgctov]{3}) (?<Y>[0-9]{4}) ?(?<h>[0-9]{2})?:?(?<m>[0-9]{2})?:?(?<s>[0-9]{2})? ?(?<tz>[A-Z]+)?"))}) | map(.time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring)) | map(.time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + (if ((.time.D | length) == 1) then "0" else "" end) + .time.D + "T" + (.time.h? // "00") + ":" + (.time.m? // "00") + ":" + (.time.s? // "00") + ".000Z"))' | \
    jq 'map({"id": .link, "title": .title, "url": .link, "text": (.description? // .encoded), "user": (.creator["+content"]? // .creator // .author), "created": .time.iso, "updated": null})' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi
