#!/bin/bash

## Run sharedstreets builder
##
## Usage:
##   docker-entrypoint.sh XMX OSM_PBF_URL
##   docker-entrypoint.sh 1G 'https://github.com/sharedstreets/sharedstreets-builder/raw/master/data/nyc_test.pbf'
##
## Arguments:
##   XMX            Maximum heap size (memory pool allocation for the JVM)
##   OSM_PBF_URL    URL of the OSM pbf file

set -eubm

usage() {
  grep -E '^## ?' "${BASH_SOURCE[0]}" | cut -c4-
}

generateShst() {
    local xmx="$1"
    local osmURL="$2"
    local osmFile
    osmFile="$(basename -- "$osmURL")"
    inputLocation="/data/$osmFile"
    outputLocation="/out/shst/tiles/osm/latest/${osmFile%.*}"

    # Download osm file to data directory
    echo "INFO: Downloading osm file to $osmFile"
    curl -L "$osmURL" -o "$inputLocation" --fail && \
        echo "INFO: Starting conversion OSM data $(find "$inputLocation" -printf "%p (size %s bytes)") to SharedStreets data $outputLocation"

    # Note: This errors out before running if the output file already exists
    java -Xmx"$xmx" -jar app/sharedstreets-builder.jar --input "$inputLocation" --output "$outputLocation"
}

main() {

    # Need at least 2 required args
    if [[ "$#" -ne 2 ]]; then
        usage
        exit 2
    fi

    generateShst "$@"

}

main "$@"
