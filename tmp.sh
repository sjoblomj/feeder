#!/bin/bash
output="";
maxelems=15;

readarray sites < <(yq e -o=j -I=0 '.sites[]' sites.yaml )

for site in "${sites[@]}"; do
    name=$(echo "$site" | yq e '.name' -)
    icon=$(echo "$site" | yq e '.icon' -)
    url=$(echo  "$site" | yq e '.url'  -)
    parser=$(echo "$site" | yq e '.parser' -)
    insertValues=$(echo "$site" | yq e '.insertValues' - | jq 'add? // {}')

    case "$parser" in
        "rss")
            data=$(./rss.sh $maxelems "$url");;
        "youtrack")
            data=$(./youtrack.sh $maxelems "$url");;
        "gitlab")
            data=$(./gitlab.sh $maxelems "$url");;
        "github")
            data=$(./github.sh $maxelems "$url");;
        *)
            data="";;
    esac

    echo "$name"
    if [[ "$insertValues" != "{}" ]]; then
        data=$(jq -n --argjson a "$data" --argjson b "$insertValues" '$a | map(. + $b)')
    fi
    #echo $data | jq
    delimiter=""
    if [[ "$output" != "" ]]; then
        delimiter=","
    fi
    #apa=$(echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$url" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "data": $data, "seenEntries": (. | map({"id": .id, "updated": .updated}))}')
    apa=$(echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$url" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "data": $data}')
    output="$output$delimiter$apa"
    #output="$output$delimiter"$(echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$url" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "data": $data, "seenEntries": (. | map({"id": .id, "updated": .updated}))}')
    #echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$url" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "data": $data, "seenEntries": (. | map({"id": .id, "updated": .updated}))}' > "$name"
    echo
    echo
#    echo "name: $name, icon: $icon, url: $url, parser: $parser, insertValues: $insertValues"
done

echo "[${output}]" > sitedata.json
