#!/usr/bin/env bash

# Usage: ./generate-tiles-local.sh [tiles] [memory] [javabin] [jarfile]
tiles=${1:-greater-london-latest}
memory=${2:-2G}
javabin=${3:-/opt/homebrew/opt/openjdk@11/bin/java}
jarfile=${4:-build/libs/sharedstreets-builder-0.3.2.jar}

# Download OSM PBF
# wget https://download.geofabrik.de/europe/united-kingdom/england/greater-london-latest.osm.pbf -O data/greater-london-latest.osm.pbf

${javabin} -Xmx${memory} -jar ${jarfile} --input data/${tiles}.osm.pbf --output ${tiles}

