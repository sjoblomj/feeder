#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" 's|<style.*<.style>||g' |
  jq '.html.body.main.section.div.ul.li // []' |
  jq 'map({"url": .a."+@href", "title": (.a.div | .[] | select(."+@class" == "list-capsule__text").h6."+content"), "time": (.a.div | .[] | select(."+@class" == "list-capsule__text").h5."+content"), "text": (.a.div | .[] | select(."+@class" == "list-capsule__text").h4."+content")})' |
  jq 'map(. + {"time": (.time | capture("(?<D>[0-9]+) (?<M>[JFMASONDanebrpyulgctov]{3}) (?<Y>[0-9]{4}) ?(?<h>[0-9]{2})?:?(?<m>[0-9]{2})?:?(?<s>[0-9]{2})? ?(?<tz>[A-Z]+)?"))}) | map(.time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring)) | map(.time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + (if ((.time.D | length) == 1) then "0" else "" end) + .time.D + "T" + (.time.h? // "00") + ":" + (.time.m? // "00") + ":" + (.time.s? // "00") + ".000Z"))' |
  jq 'map(. + {"id": .url, "url": ("https://www.globalsolarcouncil.org" + .url), "created": .time.iso, "updated": null} | del(.time))' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
