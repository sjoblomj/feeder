#!/bin/bash
currdir="$(dirname "$0")"
source "$currdir/_common.sh"

url="$1"
filter="$2"
maxelems="${3:-15}"
maxtextlen="${4:-4096}"

cookiejar=$(mktemp)
curl --cookie-jar "$cookiejar" --connect-timeout 10 -sL "$url" > /dev/null

sitedata=$(curl --cookie "$cookiejar" --connect-timeout 10 -sL "$url")
if [ -z "$sitedata" ]; then
  echo "[]"
else
  echo "$sitedata" |
    iconv -f utf-8 -t utf-8 -c |
    yq --xml-skip-directives --xml-skip-proc-inst --xml-raw-token=false -p xml -o json '.' |
    jq '.html.body.br.div.div | .[] | select(."+@class" == "contentright") | .br.div' |
    jq '(.h3 | map(."+content")) as $headers | .div | to_entries | map({"title": $headers[.key], "user": (.value.div | .[]? | select(."+@class" == "newsautor") | .a."+content"), "created": (.value.div | .[]? | select(."+@class" == "newsautor") | ."+content"[1] | capture("at (?<D>[0-9]{2}).(?<M>[0-9]{2}).(?<Y>[0-9]{4})") | .Y + "-" + .M + "-" + .D), "text": (.value.div | .[]? | select(."+@class" == "newstext") | [.. ."+content"? // empty] | flatten | join("<br />\n")), "url": (.value.div | .[]? | select(."+@class" == "newsdetails") | .a."+@href")})' |
    jq 'map(. + {"id": (.url | sub(".*id=(?<id>[0-9]+).*"; "\(.id)")), "updated": null, "created": (.created + "T00:00:00.000Z"), "url": ("https://www.siedler25.org/" + .url)})' |
    filter_and_shrink "$filter" "$maxelems" "$maxtextlen"
fi

rm -f "$cookiejar"
