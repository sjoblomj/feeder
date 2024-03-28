#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="${2:-.*}"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

sitedata=$(curl --connect-timeout 10 -sL "$url")
if [ -z "$sitedata" ]; then
  echo "[]"
else
  echo "$sitedata" | \
    yq -p=xml -o=json | \
    jq '.feed.entry | map({"id": .id, "title": .title, "url": .link.["+@href"], "text": .content.["+content"], "user": .author.name, "created": .published, "updated": .updated})' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi
