function make_item(text, id, title, author, url, published,  i) {
    text = trim(text)
    gsub(/\\/, "\\\\", text)
    gsub(/"/,  "\\\"", text)
    gsub(/\n/, "\\n",  text)
    gsub(/\t/, "    ", text)
    text = remove_non_printable_chars(text)

    i = "  {\n"
    i = i "    \"id\": \"" id "\",\n"
    i = i "    \"title\": \"" title "\",\n"
    i = i "    \"user\": \"" author "\",\n"
    i = i "    \"url\": \"" url "\",\n"
    i = i "    \"created\": \"" published "\",\n"
    i = i "    \"updated\": null,\n"
    i = i "    \"text\": \"" text "\"\n"
    i = i "  }"
    return i
}

function make_iso_date(year, month, day,  month_arr, month_nums) {
    if (month !~ /[0-9]+/) {
        split("jan feb mar apr may jun jul aug sep oct nov dec", month_arr)
        for (i in month_arr)
            month_nums[month_arr[i]] = i
        month = month_nums[tolower(substr(month, 1, 3))]
    }
    if (length(month) == 1)
        month = "0" month
    if (length(day) == 1)
        day = "0" day

    return year "-" month "-" day
}

function make_iso_datetime(year, month, day, hour, minute, second, milliseconds) {
    return combine_date_and_time(make_iso_date(year, month, day), hour, minute, second, milliseconds)
}

function combine_date_and_time(date, hour, minute, second, milliseconds) {
    return date "T" hour ":" minute ":" second "." milliseconds "Z"
}

function remove_non_printable_chars(text) {
    gsub(/[^[:print:]]/, "", text)
    return text
}

# Trims away any whitespace (i.e. space, tab, newlines, carrige-returns) from the left and right of given [string]
function trim(string) {
    sub(/^[ \t\r\n]+/,  "", string)
    sub( /[ \t\r\n]+$/, "", string)
    return string
}
