package io.sharedstreets.tools.builder;

import io.sharedstreets.data.SharedStreetsGeometry;
import io.sharedstreets.tools.builder.osm.model.Way;
import io.sharedstreets.tools.builder.tiles.JSONTileOutputFormat;
import io.sharedstreets.tools.builder.tiles.ProtoTileOutputFormat;
import io.sharedstreets.tools.builder.tiles.TilableData;
import io.sharedstreets.tools.builder.transforms.Intersections;
import io.sharedstreets.tools.builder.osm.OSMDataStream;
import io.sharedstreets.tools.builder.transforms.BaseSegments;
import io.sharedstreets.tools.builder.transforms.SharedStreetData;
import io.sharedstreets.tools.builder.util.geo.TileId;
import org.apache.commons.cli.*;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.functions.ReduceFunction;
import org.apache.flink.api.java.DataSet;
import org.apache.flink.api.java.ExecutionEnvironment;
import org.apache.flink.api.common.ExecutionConfig;
import org.apache.flink.configuration.ConfigConstants;
import org.apache.flink.configuration.Configuration;

import org.apache.flink.api.java.tuple.Tuple1;
import org.apache.flink.api.java.tuple.Tuple2;
import org.slf4j.LoggerFactory;
import org.slf4j.Logger;

import java.io.File;
import java.util.ArrayList;


public class ProcessPBF {

    static Logger LOG = LoggerFactory.getLogger(ProcessPBF.class);

    public static boolean DEBUG_OUTPUT = true;

    public static void main(String[] args) throws Exception {

        // create the command line parser
        CommandLineParser parser = new DefaultParser();

        // create the Options
        Options options = new Options();

        options.addOption( OptionBuilder.withLongOpt( "input" )
                .withDescription( "path to input OSM PBF file" )
                .hasArg()
                .withArgName("INPUT-FILE")
                .create() );

        options.addOption( OptionBuilder.withLongOpt( "output" )
                .withDescription( "path to output directory (will be created)" )
                .hasArg()
                .withArgName("OUTPUT-DIR")
                .create() );

        options.addOption( OptionBuilder.withLongOpt( "zlevel" )
                .withDescription( "tile z-level (default 12)" )
                .hasArg()
                .withArgName("Z-LEVEL")
                .create() );

        options.addOption( OptionBuilder.withLongOpt( "roadClass" )
                .withDescription( "road class (default 6)" )
                .hasArg()
                .withArgName("Z-LEVEL")
                .create() );


        String inputFile = "";

        String outputPath = "";

        Integer zLevel = 12 ;

        Integer roadClass = 6 ;

        try {
            // parse the command line arguments
            CommandLine line = parser.parse( options, args );

            if( line.hasOption( "input" ) ) {
                // print the value of block-size
                inputFile = line.getOptionValue( "input" );
            }

            if( line.hasOption( "output" ) ) {
                // print the value of block-size
                outputPath = line.getOptionValue( "output" );
            }

            if(line.hasOption("zlevel")){
                zLevel = Integer.parseInt(line.getOptionValue("zlevel"));
            }

            if(line.hasOption("roadClass")){
                roadClass = Integer.parseInt(line.getOptionValue("roadClass"));
            }
        }
        catch( Exception exp ) {
            System.out.println( "Unexpected exception:" + exp.getMessage() );
            return;
        }

        File file = new File(inputFile);
        if(!file.exists()) {
            System.out.println( "Input file not found: "  + inputFile);
            return;
        }

        if(!file.getName().endsWith(".pbf")) {
            System.out.println( "Input file must end with .pbf: "  + inputFile);
            return;
        }

        File directory = new File(outputPath);

        if(directory.exists()) {
            System.out.println( "Output directory already exists: "  + outputPath);
            return;
        }

        Configuration conf = new Configuration();
        conf.setFloat(ConfigConstants.TASK_MANAGER_MEMORY_FRACTION_KEY, 0.5f);
        final ExecutionEnvironment env = ExecutionEnvironment.createLocalEnvironment(conf);
        ExecutionConfig execConfig = env.getConfig();
        //execConfig.setParallelism(54);

        // load osm data from PBF input
        OSMDataStream dataStream = new OSMDataStream(inputFile, env);

        // list of way classes for export tiles (must be in sequential order from least to most filtered)
        ArrayList<Way.ROAD_CLASS> filteredClasses = new ArrayList<>();

        if(roadClass.intValue() == Way.ROAD_CLASS.ClassUnclassified.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassUnclassified);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassTertiary.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassTertiary);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassSecondary.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassSecondary);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassPrimary.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassPrimary);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassTrunk.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassTrunk);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassMotorway.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassUnclassified);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassResidential.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassResidential);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassService.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassService);

        else if(roadClass.intValue() == Way.ROAD_CLASS.ClassOther.getValue())
            filteredClasses.add(Way.ROAD_CLASS.ClassOther);

        for(Way.ROAD_CLASS filteredClass : filteredClasses) {

            OSMDataStream.FilteredWays filteredWays = dataStream.getFilteredWays(filteredClass);

            // create OSM intersections
            Intersections intersections = new Intersections(filteredWays);

            // build internal model for street network
            BaseSegments segments = new BaseSegments(filteredWays, intersections);

            // build SharedStreets references, geometries, intersections and metadata
            SharedStreetData streets = new SharedStreetData(segments);

            ProtoTileOutputFormat outputFormat = new ProtoTileOutputFormat<Tuple2<TileId, TilableData>>(outputPath, filteredClass);

            streets.mergedData(zLevel).output(outputFormat);
        }

        env.execute();

    }

}


