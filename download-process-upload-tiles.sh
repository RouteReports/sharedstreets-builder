#!/usr/bin/env bash
#
set -e
set -x

# Version tiles using a timestamp
DATE=$(date +%y%m%d)

declare -A osmPbfs
# osmPbfs["europe-latest.osm"]="https://download.geofabrik.de/europe-latest.osm.pbf"
# osmPbfs["north-america-latest.osm"]="https://download.geofabrik.de/north-america-latest.osm.pbf"

# Use more localised exports for faster processing
osmPbfs["britain-and-ireland-latest.osm"]="https://download.geofabrik.de/europe/britain-and-ireland-latest.osm.pbf"
osmPbfs["florida-latest.osm"]="https://download.geofabrik.de/north-america/us/florida-latest.osm.pbf"
osmPbfs["washington-latest.osm"]="https://download.geofabrik.de/north-america/us/washington-latest.osm.pbf"


for key in "${!osmPbfs[@]}"; do

    # Download latest OSM export
    wget --limit-rate=2M -O ./data/${key}.pbf ${osmPbfs[$key]}

    # Clean up any existing tiles
    rm -rf ./out/shst/tiles/osm/latest/${key}/ 

    # Generate tiles
    docker run --rm \
        -v $(pwd)/data:/data \
        -v $(pwd)/out:/out \
        shst-builder \
        24G \
        ${key}.pbf

    # Upload to S3
    aws s3 sync ./out/shst/tiles/osm/latest/${key}/ s3://rr-binaries/tiles/osm/planet-${DATE}/
done
