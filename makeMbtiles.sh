#!/bin/bash
set -eu                # Always put this in Bourne shell scripts
IFS="`printf '\n\t'`"  # Always put this in Bourne shell scripts

#Comment this out to actually make the mbtiles
# exit

#Get command line parameters
originalRastersDirectory="$1"
destinationRoot="$2"
chartType="$3"
sourceChartName="$4"
zoomRange="$5"

if [ "$#" -ne 5 ] ; then
  echo "Usage: $0 SOURCE_DIRECTORY destinationRoot chartType sourceChartName zoomRange" >&2
  exit 1
fi

#Where the links to the lastest version #will be stored (step 1)
linkedRastersDirectory="$destinationRoot/sourceRasters/$chartType/"

#Where expanded rasters are stored (step 2)
expandedRastersDirectory="$destinationRoot/expandedRasters/$chartType/"

#Where warped rasters are stored (step 2a)
warpedRastersDirectory="$destinationRoot/warpedRasters/$chartType/"

#Where clipped rasters are stored (step 3)
clippedRastersDirectory="$destinationRoot/clippedRasters/$chartType/"

#Where the polygons for clipping are stored
clippingShapesDirectory="$destinationRoot/clippingShapes/$chartType/"

#Where the tiles are stored
tilesDirectory="$destinationRoot/tiles/$chartType/"

#Where the mbtiles are stored
mbtilesDirectory="$destinationRoot/mbtiles/$chartType/"

if [ ! -d $originalRastersDirectory ]; then
    echo "$originalRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $linkedRastersDirectory ]; then
    echo "$linkedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $expandedRastersDirectory ]; then
    echo "$expandedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $clippedRastersDirectory ]; then
    echo "$clippedRastersDirectory doesn't exist"
    exit 1
fi

if [ ! -d $tilesDirectory ]; then
    echo "$tilesDirectory doesn't exist"
    exit 1
fi

if [ ! -d $mbtilesDirectory ]; then
    echo "$mbtilesDirectory doesn't exist"
    exit 1
fi

#Create the mbtiles file if it doesn't exist or is older than it's source image
# if [ ! -f  "$mbtilesDirectory/$sourceChartName.mbtiles" ] || [ "$warpedRastersDirectory/$sourceChartName.tif" -nt "$mbtilesDirectory/$sourceChartName.mbtiles" ];  then
  #Create tiles from the clipped raster 
  
    # (trying various utilities)
    #
    # python ~/Documents/github/parallel-gdal2tiles/gdal2tiles.py $clippedRastersDirectory/$clippedName.tif $tilesDirectory/$sourceChartName
    #
    # or
    #
    # python ~/Documents/github/parallel-gdal2tiles/gdal2tiles/gdal2tiles.py $clippedRastersDirectory/$clippedName.tif $tilesDirectory/$sourceChartName
    # ~/Documents/github/gdal2mbtiles/gdal2mbtiles.py -r cubic --resume $clippedRastersDirectory/$sourceChartName.tif $tilesDirectory/$sourceChartName
    #
    # or
    #
    ./memoize.py \
        python ./parallelGdal2tiles/gdal2tiles.py \
            -r lanczos \
            $warpedRastersDirectory/$sourceChartName.tif \
            $tilesDirectory/$sourceChartName
  
    #Optimize each tile for sharpness and then size using all CPUs
  
    #Get the number of online CPUs
    cpus=$(getconf _NPROCESSORS_ONLN)

    # I've commented this out for now.  Ideally, it'd be unnecessary.  For now it just saves time
    #   echo "Sharpen PNGs, using $cpus CPUS"
    #   Determine best method (sharpen vs. unsharp) and parameters
    # #   find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus gm mogrify -unsharp 2x1.5+1.7+0
    #   find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus gm mogrify -sharpen 0x.5
    #
    echo "Optimize PNGs with pngquant, using $cpus CPUS"
    find $tilesDirectory/$sourceChartName/ -type f -name "*.png" -print0 | xargs --null --max-args=1 --max-procs=$cpus pngquant -s2 -q 100 --ext=.png --force

    #Package them into an .mbtiles file
    ./memoize.py \
        python ./mbutil/mb-util \
            --scheme=tms \
            $tilesDirectory/$sourceChartName/ \
            $mbtilesDirectory/$sourceChartName.mbtiles

    #Set the date of this new mbtiles to the date of the image used to create it
    #touch -r "$warpedRastersDirectory/$sourceChartName.tif" "$mbtilesDirectory/$sourceChartName.mbtiles"
# fi