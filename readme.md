If you're reading this, I regret to inform you you're about to have a bad day.
I don't really know how to code, and I certainly didn't at the time I wrote
this glue code. But I can type out the basic idea here and hopefully give you
a map to redo this effort properly.

The bash script 'wholestack.sh' is what does everything. It variously calls gdal, pdal
lastools, and pycrown to create a shapefile of tree crown oulines from lidar files.

That bash script is hopefully well commented, if not poorly written. Start there.

The github repo is a stright fork of the public pycrown repo, with one commit of my "aerocrown" folder from my local machine, and one additional commit of this readme on a new branch. The branch gets stuck, even on my system currently, at the correction step of aerocrown.py in the function PC.crowns_to_polys_raster(). So if the wholestack.sh script gets to that point, then your system is up to where I abandoned the project.

