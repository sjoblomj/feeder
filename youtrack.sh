#!/bin/bash
maxelems="$1"
url="$2"

if [[ $url =~ ^https://youtrack.jetbrains.com/(api/issues|issue)/(JBR-[0-9]+)/?$ ]]; then
    issuenumber="${BASH_REMATCH[2]}"
    url="https://youtrack.jetbrains.com/api/issues/$issuenumber"
else
    echo "Could not understand URL '$url'"
    exit 1
fi

base=$(curl -s "${url}?%24top=-1&fields=description,id,usesMarkdown,created,updated,summary,reporter(%40user),updater(%40user)%3B%40user%3AfullName,avatarUrl" --compressed -H "Accept: application/json" | jq '{"id": .id, "title": .summary, "text": .description, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "user": .reporter.fullName, "userPicture": .reporter.avatarUrl}')

comments=$(curl -s "${url}/activitiesPage?categories=CommentsCategory&reverse=true&fields=activities(added(author(name,avatarUrl),id,updated,created,text,usesMarkdown,files),timestamp)" -H "Accept: application/json" | jq --arg maxelems "$maxelems" '.activities | map(.added.[]) | map({"id": .id, "user": .author.name, "userPicture": .author.avatarUrl, "text": .text, "created": (if .created == null then null else .created / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "updated": (if .updated == null then null else .updated / 1000 | strftime("%Y-%m-%dT%H:%M:%SZ") end), "title": null}) | sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]')

jq --argjson arr1 "$base" --argjson arr2 "$comments" -n '[$arr1] + $arr2 | sort_by(.created) | reverse'
