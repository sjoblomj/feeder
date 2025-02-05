#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" |
  jq '.html.body.div.div // [] | .[] | select(has("div")) | .div.main.div.div.div' |
  jq '[.[] | .article | map({"title": .h1.a."+content", "url": .h1.a."+@href", "text": .p[1], "created": .p[0].em.time."+@dateTime"})] | flatten' |
  jq 'map(. + {"id": .url, "url": ("https://auroramålet.se" + .url), "updated": null})' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
