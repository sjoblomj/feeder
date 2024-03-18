#!bin/bash

function filter_and_shrink() {
    text=<&0
    filter="$1"
    maxelems="$2"
    maxtextlen="$3"

    jq --arg maxelems "$maxelems" --arg maxtextlen "$maxtextlen" --arg filter "$filter" 'map(select(.title + " " + .text | ascii_downcase | test($filter | ascii_downcase))) | map(. += {"text": (if ((.text | length) > ($maxtextlen | tonumber)) then .text[:($maxtextlen | tonumber)] + " ..." else .text end)}) | sort_by(.created) | reverse | [limit($maxelems | tonumber; .[])]'
}
