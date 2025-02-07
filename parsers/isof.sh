#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" 's|!function.*||g' |
  jq '.html.body.div.div.main.div.div[1].div[1].div.div[0].div.div[1].div // [] | .[] | select(has("div")) | .div.ul.li' |
  jq 'map({"url": .h2.a."+@href", "title": .h2.a."+content", "text": .p[1]."+content", "created": .p[0].span[0]?.time."+@datetime"})' |
  jq 'map(. + {"id": .url, "url": ("https://www.isof.se" + .url), "created": (.created + "T00:00:000Z"), "updated": null})' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
