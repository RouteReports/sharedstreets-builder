# SharedStreets Builder

The SharedStreets Builder application converts OpenStreetMap data to [SharedStreets protocol buffer tiles](https://github.com/sharedstreets/sharedstreets-ref-system).

SharedStreets uses this tool to generate and maintain a complete global OSM-dervied tile set. Users can operate the tool directly on their OSM or use a pregenerated global tileset provided by SharedStreets.

Support for non-OSM data sources has been moved to the [sharedstreets-conflator](https://github.com/sharedstreets/sharedstreets-conflator) tool.

**Notes**

The builder application is built on Apache Flink. If memory requirements exceed available space, Flink uses a disk-based cache for processing. Processing large OSM data sets may require several hundred gigabytes of free disk space.

**Roadmap**

- [*v0.1:*](https://github.com/sharedstreets/sharedstreets-builder/releases/tag/0.1-preview) OSM support
- *v0.2:* Add OSM metadata support for support ways per [#9](https://github.com/sharedstreets/sharedstreets-builder/issues/9)
- [*v0.3:*](https://github.com/sharedstreets/sharedstreets-builder/releases/tag/0.3) add heirarchical filterfing for roadClass per [sharedstreets-ref-system/#20](https://github.com/sharedstreets/sharedstreets-ref-system/issues/20#issuecomment-381010861)

## Local Development

### Using Docker container

The Docker image entrypoint is defined at `docker-entrypoint.sh`

Make sure you have [Docker](https://www.docker.com/community-edition) installed. Then build and run the image:

```
docker build -t shst .
docker run --rm \
    -v /tmp \
    -v /data \
    -v $PWD/out/:/out/ \
    shst \
    <MEMORY> \
    <PBF_FILE_URL>
```

When running the image, you'll note the mounted volumes:
- `/tmp`: for storage of intermediate files (Flink uses systems [`tmp` dir by default](https://github.com/sharedstreets/sharedstreets-builder/issues/15#issue-318844697))
- `/data`: where the fetched contents of the OSM PBF file are written. The `data/$filename` is provided to the java command as input in `docker-entrypoint.sh`
- `$PWD/out/:/out/`: where the SharedStreets output files are written to inside and outside the container. The output location is provided to the java command as output in `docker-entrypoint.sh`

Example:
```
docker run --rm -v /tmp -v /data -v $PWD/out/:/out/ shst 1G 'https://github.com/sharedstreets/sharedstreets-builder/raw/master/data/nyc_test.pbf'
```

### Using Java directly

If you want to invoke sharedstreets builder directly, you first need to have fetched the desired OSM protobuff file and store it locally. You will also need to have a root disk with available space to store the output.

`java -jar ./sharedstreets-builder-0.3.jar --input data/[osm_input_file].pbf --output ./[tile_output_directory]
`

## Example datasets
These are OSM datasets found online that can be used for testing SharedStreets builder.

**City datasets**
- https://github.com/sharedstreets/sharedstreets-builder/raw/master/data/nyc_test.pbf
- https://s3.amazonaws.com/metro-extracts.nextzen.org/nashville_tennessee.osm.pbf
- https://s3.amazonaws.com/metro-extracts.nextzen.org/nashville_tennessee.osm.pbf

**Planet datasets**
Running locally to test SharedStreets builder is not an option, due to the size of these datasets.
- https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf
- https://osm-pds.s3.amazonaws.com/2021/planet-210510.osm.pbf

## Other info

### Known Gaps
1. As mentioned above, running the dataset locally against the planet is not feasible. There's an outstanding item to validate that the Docker image can run against "the world". It may fail due to memory issues, but the results of a test run on large EC2 instance is unknown.
1. Validating that metadata output of the SharedStreets builder is what we expect has not been done. There are questions about the hardcoded "tile z-level" and if that is what we want to generate.
1. More generally, testing the metadata output of the SharedStreets builder is unknown/undocumented.

### Resources
These additional resources were useful when understanding and debugging Flink JVM memory issues while trying to run larger and larger datasets against SharedStreets builder.

- [Too few memory segments provided exception](http://apache-flink-user-mailing-list-archive.2336050.n4.nabble.com/Too-few-memory-segments-provided-exception-td2176.html)
- [JVM Memory Handling for Docker](https://medium.com/@madhupathy/jvm-memory-handling-for-java-based-dockerized-microservices-7568c16f1e65)
- [How to Configure Java Heap Size Inside a Container](https://www.baeldung.com/ops/docker-jvm-heap-size)
- [Flink Process Memory docs](https://ci.apache.org/projects/flink/flink-docs-master/docs/deployment/memory/mem_setup/)
