#!/bin/bash
output="";
maxelems=15;

readarray sites < <(yq e -o=j -I=0 '.sites[]' sites.yaml )

for site in "${sites[@]}"; do
    name=$(   echo "$site" | yq e '.name'   -)
    icon=$(   echo "$site" | yq e '.icon'   -)
    url=$(    echo "$site" | yq e '.url'    -)
    parser=$( echo "$site" | yq e '.parser' -)
    filters=$(echo "$site" | yq e '.filters.[]' - | jq -r 'add? // {}')
    insertValues=$(echo "$site" | yq e '.insertValues' - | jq 'add? // {}')

    echo "Fetching $name ..."

    case "$parser" in
        "rss")
            data=$(./rss.sh      $maxelems "$url" "$filters");;
        "youtrack")
            data=$(./youtrack.sh $maxelems "$url" "$filters");;
        "gitlab")
            data=$(./gitlab.sh   $maxelems "$url" "$filters");;
        "github")
            data=$(./github.sh   $maxelems "$url" "$filters");;
        *)
            data="";;
    esac

    if [[ "$insertValues" != "{}" ]]; then
        data=$(jq -n --argjson a "$data" --argjson b "$insertValues" '$a | map(. + $b)')
    fi
    siteData=$(echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$url" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "data": $data}')

    delimiter=""
    if [[ "$output" != "" ]]; then
        delimiter=","
    fi
    output="$output$delimiter$siteData"
done

echo "[${output}]" > sitedata.json
