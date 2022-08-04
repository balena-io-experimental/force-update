#!/bin/bash

START=${START:-0}
SLEEP=${SLEEP:-10}

replace_newline_with_space() {
    echo $(tr '\n' ' ' < /dev/stdin)
}

get_newest_two_releases() {
    response=$(curl -s -X GET \
        "https://api.balena-cloud.com/v6/release?\$filter=belongs_to__application%20eq%20$BALENA_APP_ID&\$select=id&\$orderby=start_timestamp&\$top=2" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $BALENA_API_KEY")
    echo $response | jq -r '.d[].id' | replace_newline_with_space
}

get_current_release() {
    response=$(curl -s -X GET \
        "https://api.balena-cloud.com/v6/device?\$filter=startswith(uuid,'$BALENA_DEVICE_UUID')&\$select=should_be_running__release,is_running__release" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $BALENA_API_KEY")
    read should is < <(echo $response | jq -r '.d[] | .should_be_running__release.__id, .is_running__release.__id' | replace_newline_with_space)
    [ -n $should ] && echo "$is" || echo "$should"
}

pin_to_release() {
    curl -s -X PATCH \
        "https://api.balena-cloud.com/v6/device?\$filter=startswith(uuid,'$BALENA_DEVICE_UUID')" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $BALENA_API_KEY" \
        --data "{\"should_be_running__release\": $1}"
}

force_update() {
    curl -s -X POST \
        "$BALENA_SUPERVISOR_ADDRESS/v1/update" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $BALENA_SUPERVISOR_API_KEY" \
        --data '{"force": true}'
}

if [ ! $START -eq 1 ]; then
    echo "START not set to 1, sleeping with 'sleep infinity'"
    sleep infinity
else
    # Create update lock
    echo "Creating update lock..."
    touch /tmp/balena/updates.lock
    echo -e "Update lock created:\n $(ls /tmp/balena/)"
    
    # Get newest two releases for this device's fleet 
    # (assumes 2 releases are available and both relate to this reproduction)
    read newer older < <(get_newest_two_releases)

    # Get device's current release
    release=$(get_current_release)

    # Pin to whichever of the most recent 2 releases that's not the current release
    if [ $release -eq $newer ]; then
        echo "Pinning to release $older..."
        pin_to_release $older 1> /dev/null
    else 
        echo "Pinning to release $newer..."
        pin_to_release $newer 1> /dev/null
    fi

    # Force Supervisor to ignore locks and update to pinned release
    echo "Force updating through Supervisor API..."
    force_update

    echo "Operation complete. Sleeping with 'sleep infinity'..."
    sleep infinity
fi


