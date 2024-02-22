#!/bin/bash
readarray sites < <(yq e -o=j -I=0 '.sites[]' sites.yaml )

for site in "${sites[@]}"; do
    name=$(echo "$site" | yq e '.name' -)
    icon=$(echo "$site" | yq e '.icon' -)
    url=$(echo  "$site" | yq e '.url'  -)
    parser=$(echo "$site" | yq e '.parser' -)
    insertValues=$(echo "$site" | yq e '.insertValues' -)

    case "$parser" in
        "rss")
            data=$(./rss.sh "$url");;
        "youtrack")
            data=$(./youtrack.sh "$url");;
        "gitlab")
            data=$(./gitlab.sh "$url");;
        "github")
            data=$(./github.sh "$url");;
        *)
            data="";;
    esac

    echo "$name"
    echo "$data"
    echo
    echo
#    echo "name: $name, icon: $icon, url: $url, parser: $parser, insertValues: $insertValues"
done

