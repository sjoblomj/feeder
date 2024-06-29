#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_json "$url" |
  jq '. | map({"id": .id, "title": .title, "url": .url, "created": (.datetime + ".000Z"), updated: null, "text": ("Concert with " + (.lineup | join(", ")) + " in " + .venue.location + ".\n<br \/>\n<br \/>Tickets are" + if .sold_out then " " else " not " end  + "sold out."), "user": "Wardruna"}) | sort_by(.created)' |
  jq --arg maxelems "$maxelems" '[limit($maxelems | tonumber; .[])]' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
