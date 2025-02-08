#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

get_xml_as_json "$url" 's|<style.*<.style>||g' |
  jq '.html.body.div.div.div // [] | .[] | select(."+@class" | contains("page__main")) | .div.div[1].div.div.div[2].div.div.div.div.div.div.div.div' |
  jq 'map(.div | .[] | select(."+@class" == "alpha-card__content")) as $contentdiv | $contentdiv' |
  jq 'map({"id": .div[2].a."+@href", "title": .h3.div, "text": .div[1], "created": .div[0].div})' |
  jq 'map(. + {"url": ("https://railsweden.lindholmen.se" + .id), "created": (.created + "T00:00:00.000Z"), "updated": null})' |
  filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
