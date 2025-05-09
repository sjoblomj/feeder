#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" | \
  jq '.feed.entry // []' | \
  jq 'map({"id": .id, "title": (.title["+content"]? // .title), "url": .link["+@href"], "text": ((.content["+content"] // .group.description // .summary?.div?.p) as $t | if ($t | type == "string") then $t else "" end), "user": .author.name, "created": .published, "updated": .updated})' | \
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
