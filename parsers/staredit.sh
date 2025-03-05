#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" 's/<\/span>//g ; s/<span[^>]*>//g ; s/<br>/<br \/>/g' |
  jq '.html.body.div.div // [] | .[] | select(."+@class" == "page") | .div | .[] | select(."+@id" == "page_main_content") | .table.tr.td | .[1] | .div.div' |
  jq 'map({"title": (.div | .[] | select(."+@class" == "titleBox") | .div.a."+content"), "url": (.div | .[] | select(."+@class" == "titleBox") | .div.a."+@href"), "time": (.div | .[] | select(."+@class" == "titleBox") | .div."+content"), "user": (.div | .[] | select(."+@class" == "statusBox") | .div.img.a."+content"? // .div.a."+content"), "text": (.div | .[] | select(."+@class" == "infoBox2") | [.. ."+content"? //  empty] | flatten | join("<br />\n"))})' |
  jq --arg today "$(date +"%b %-d %Y" | sed 's/.*/\u&/')" 'map(. + {"time": (if .time | contains("Today") then .time | sub("Today"; $today) else .time end | capture("&nbsp (?<M>[JFMASONDanebrpyulgctov]{3}) (?<D>[0-9]+) (?<Y>[0-9]{4}), (?<h>[0-9]+):(?<m>[0-9]{2}) (?<clock>[ap]m)"))})' |
  jq 'map(. |= (if .time.clock == "am" then (if .time.h == "12" then .time.c = -12 else .time.c = 0 end) else .time.c = 12 end | .time.h = (((.time.h | tonumber) + .time.c) | tostring)))' |
  jq 'map(. |= (.time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring) | .time.iso = (.time.Y + "-" + (if .time.M | tonumber < 10 then "0" else "" end) + .time.M + "-" + (if .time.D | length == 1 then "0" else "" end) + .time.D + "T" + (if .time.h? | tonumber < 10 then "0" else "" end + .time.h? // "00") + ":" + (.time.m? // "00") + ":" + (.time.s? // "00") + ".000Z")))' |
  jq 'map(. + {"updated": null, "created": .time.iso, "id": (.url | capture("/topic/(?<id>.+)/") | .id), "url": ("http://staredit.net" + .url)} | del(.time))' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
