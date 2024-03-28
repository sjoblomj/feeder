#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="${2:-.*}"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

sitedata=$(curl --connect-timeout 10 -sL "$url" -H 'Accept: application/json')
if [ -z "$sitedata" ]; then
    sitedata="{}"
fi
base=$(echo "$sitedata" | \
    jq '{"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "title": .title, "text": (.note // .description), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)}' | \
    jq '[.]' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

sitedata=$(curl --connect-timeout 10 -sL "$url/discussions.json" -H 'Accept: application/json')
if [ -z "$sitedata" ]; then
    sitedata="[]"
fi
comments=$(echo "$sitedata" | \
    jq '[.[].notes.[]] | map({"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "text": (.note // .description), "title": (if .system == true then "System entry" else null end), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)})' | \
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
)

jq --argjson base "$base" --argjson comments "$comments" -n '$comments + $base'
