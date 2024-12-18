#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" | \
  jq '.html.body.div.main.div // []' |
  jq '.[] | select(."+@class" | startswith("press_wrapper")) | .div' |
  jq 'map({"title": (.div | .[] | select(."+@class" | startswith("PressArticle_header-container")) | .h2."+content"), "text": ([.div | .[] | select(."+@class" | startswith("PressArticle_paragraph-container")) | .p."+content"] | join("\n\n")), "created": (.div | .[] | select(."+@class" | startswith("PressArticle_date-container"))) | (.p[0]."+content" + "T" + .p[1]."+content" + ":00Z")})' |
  jq 'map(. + {"id": .created, "updated": null, "user": "Farmann Båtlag", "url": null})' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
