"""
PyCrown - Fast raster-based individual tree segmentation for LiDAR data
-----------------------------------------------------------------------
Copyright: 2018, Jan Zörner
Licence: GNU GPLv3
"""

from datetime import datetime

from pycrown import PyCrown


if __name__ == '__main__':

    TSTART = datetime.now()

    F_CHM = 'data/CHM.tif'
    F_DTM = 'data/DTM.tif'
    F_DSM = 'data/DSM.tif'
    F_LAS = 'data/POINTS.las'

    PC = PyCrown(F_CHM, F_DTM, F_DSM, F_LAS, outpath='result')

     # Smooth CHM with 5m median filter
    PC.filter_chm(1)

    # Tree Detection with local maximum filter
    PC.tree_detection(PC.chm, ws=1, hmin=1.)

    PC.clip_trees_to_bbox(inbuf=1)  # inward buffer of 1 metre

    # Crown Delineation
    PC.crown_delineation(algorithm='watershed_skimage', th_tree=1.,
                         th_seed=0.7, th_crown=0.55, max_crown=30.)

    # Correct tree tops on steep terrain
    PC.correct_tree_tops()

    # Calculate tree height and elevation
    PC.get_tree_height_elevation(loc='top')
    PC.get_tree_height_elevation(loc='top_cor')

    # Screen small trees
    PC.screen_small_trees(hmin=1., loc='top')

    # Convert raster crowns to polygons
    PC.crowns_to_polys_raster()
    #PC.crowns_to_polys_smooth(store_las=True)

    # Check that all geometries are valid
    PC.quality_control()

    # Export results
    #PC.export_raster(PC.chm, PC.outpath / 'chm.tif', 'CHM')
    #PC.export_tree_locations(loc='top')
    #PC.export_tree_locations(loc='top_cor')
    PC.export_tree_crowns(crowntype='crown_poly_raster')
    #PC.export_tree_crowns(crowntype='crown_poly_smooth')

    TEND = datetime.now()

    print(f"Number of trees detected: {len(PC.trees)}")
    print(f'Processing time: {TEND-TSTART} [HH:MM:SS]')