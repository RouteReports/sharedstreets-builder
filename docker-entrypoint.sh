#!/bin/bash

## Run sharedstreets builder
##
## Usage:
##   docker-entrypoint.sh XMX OSM_FILE_NAME
##   docker-entrypoint.sh 1G 'nyc_test.pbf'
##
## Arguments:
##   XMX            Maximum heap size (memory pool allocation for the JVM)
##   OSM_FILE_NAME  Path to the OSM pbf file. This is assumed to be in the /data/ directory

set -eubm

usage() {
  grep -E '^## ?' "${BASH_SOURCE[0]}" | cut -c4-
}

generateShst() {
    local xmx="$1"
    local osmPath="$2"
    local osmFile="$(basename -- "$osmPath")"
    inputLocation="/data/$osmFile"
    outputLocation="/out/shst/tiles/osm/latest/${osmFile%.*}"

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
