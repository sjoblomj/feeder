#!/bin/bash
maxelems="$1"
url="$2"

curl -sL "$url" | yq -p=xml -o=json | jq --arg maxelems "$maxelems" '.rss.channel.item | map(. + {"time": (.pubDate | capture("[MTWFSonuedhriat]{3}, (?<D>[0-9]+) (?<M>[JFMASONDanebrpyulgctov]{3}) (?<Y>[0-9]+) (?<h>[0-9]{2}):(?<m>[0-9]{2}):(?<s>[0-9]{2}) ?(?<tz>[A-Z]+)?"))}) | map(.time.M = (.time.M as $m | ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] | index($m) + 1 | tostring)) | map(.time.iso = (.time.Y + "-" + (if (.time.M | tonumber < 10) then "0" else "" end) + .time.M + "-" + .time.D + "T" + .time.h + ":" + .time.m + ":" + .time.s + ".000Z")) | map({"id": .link, "title": .title, "url": .link, "text": .description, "user": (.creator.["+content"]? // .creator), "created": .time.iso, "updated": null}) | sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]'
