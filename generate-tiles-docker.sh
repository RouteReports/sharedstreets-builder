#!/usr/bin/env bash
set -e
set -x

docker run --rm \
    -v $(pwd)/data:/data \
    -v $(pwd)/out:/out \
    shst-builder \
    2G greater-london-latest.osm.pbf
