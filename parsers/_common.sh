#!bin/bash

function filter_and_shrink() {
    text=<&0
    filter="${1:-test(\".*\")}"
    maxelems="$2"
    maxtextlen="$3"

    jq "map(select(.title + \" \" + .text | ascii_downcase | $filter ))" |
        jq --arg maxtextlen "$maxtextlen" 'map(. += {"text": (if ((.text | length) > ($maxtextlen | tonumber)) then .text[:($maxtextlen | tonumber)] + " ..." else .text end)})' |
        jq --arg maxelems "$maxelems" 'sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]'
}
