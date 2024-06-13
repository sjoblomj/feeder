#!/bin/bash
output="";
maxelems=15;

function json_filters_to_jq_tests() {
    local filters
    filters=$(echo "$1" | \
        perl -pe 's/,//g, s/[\[{]/(/g, s/[}\]]/)/g'  | # Remove commas and replace brackets with parenthesis
        perl -pe '1 while s/"not":(\(([^()]++|(?1))*\))/ ($1) | not/g' | # Repeatedly turn '"not":(.*)' into '(.*) | not'
        perl -pe 's/"filter":"([^"]*)"/test("\1")/g' | # Replace '"filter":".*"' with 'test(".*")'
        perl -pe 's/(\()?"(or|and)":/ \2 \1/g'         # Put 'or' and 'and' outside their parenthesis
    )
    if [[ "$filters" == "()" ]]; then
        filters=""
    fi
    echo "$filters"
}

readarray sites < <(yq e -o=j -I=0 '.sites[]' sites.yaml )

for site in "${sites[@]}"; do
    name=$(   echo "$site" | yq e '.name'    -)
    icon=$(   echo "$site" | yq e '.icon'    -)
    url=$(    echo "$site" | yq e '.url'     -)
    parser=$( echo "$site" | yq e '.parser'  -)
    filters=$(echo "$site" | yq e '.filters' -           | jq -rc 'add? // {}')
    insertValues=$(echo "$site" | yq e '.insertValues' - | jq     'add? // {}')
    displayUrl=$(  echo "$site" | yq e '.displayUrl'   -)
    description=$( echo "$site" | yq e '.description'  -)

    filters=$(json_filters_to_jq_tests "$filters")

    if [[ "$displayUrl" == "null" ]]; then
        displayUrl="$url"
    fi

    echo "Fetching $name ..."

    if [ -f parsers/"$parser".sh ]; then
        data=$(./parsers/"$parser".sh "$url" "$filters" $maxelems)
    else
        echo "Unable to find parser '$parser'"
        data="[]"
    fi

    if [[ "$insertValues" != "{}" ]]; then
        data=$(jq -n --argjson a "$data" --argjson b "$insertValues" '$a | map(. + $b)')
    fi
    siteData=$(echo $data | jq --arg name "$name" --arg icon "$icon" --arg url "$displayUrl" --arg description "$description" --argjson data "$data" '{"name": $name, "icon": $icon, "url": $url, "description": $description, "data": $data}')

    delimiter=""
    if [[ "$output" != "" ]]; then
        delimiter=","
    fi
    output="$output$delimiter$siteData"
done

echo "[${output}]" > sitedata.json
