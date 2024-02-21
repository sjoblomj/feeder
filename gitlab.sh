#!/bin/bash
maxelems="$1"
url="$2"

base=$(curl -sL "$url" -H 'Accept: application/json' | jq '{"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "title": .title, "text": (.note // .description), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)}')

comments=$(curl -sL "${url}/discussions.json" -H 'Accept: application/json' | jq --arg maxelems "$maxelems" '[.[].notes.[]] | map({"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "text": (.note // .description), "title": (if .system == true then "System entry" else null end), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)}) | sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]')

jq --argjson arr1 "$base" --argjson arr2 "$comments" -n '[$arr1] + $arr2 | sort_by(.created) | reverse'
