#!/usr/bin/env bash

set -e
set -x

# Usage: ./generate-tiles-local.sh [osmPbf] [xmx] [javabin] [jarfile]
osmPbf=${1:-greater-london-latest.osm.pbf}
xmx=${2:-2G}
javabin=${3:-/opt/homebrew/opt/openjdk@11/bin/java}
jarfile=${4:-build/libs/sharedstreets-builder-0.3.2.jar}


pbfName=$(basename $osmPbf .osm.pbf)

# Download OSM PBF
# wget https://download.geofabrik.de/europe/united-kingdom/england/greater-london-latest.osm.pbf -O data/greater-london-latest.osm.pbf

${javabin} -Xmx${xmx} -jar ${jarfile} --input data/${osmPbf} --output out/shst/tiles/osm/latest/${pbfName}
