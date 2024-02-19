#!/bin/bash
url="$1"
curl -sL "$url" -H 'Accept: application/json' | jq '{"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "title": .title, "text": (.note // .description), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)}'

curl -sL "${url}/discussions.json" -H 'Accept: application/json' | jq '[.[].notes.[]] | map({"id": .id, "user": (.author.name // .assignees[0].name), "userPicture": (.author.avatar_url // .assignees[0].avatar_url), "text": (.note // .description), "created": .created_at, "updated": (if .created_at != .updated_at then .updated_at else null end)})'
