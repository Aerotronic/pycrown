from osgeo import gdal
import numpy as np

DTMinput = "data/DTM/DTM.tif"
DSMinput = "data/DSM/DSM.tif"

DTMdataset = gdal.Open(DTMinput, gdal.GA_ReadOnly)
DTMarray = np.array(DTMdataset.GetRasterBand(1).ReadAsArray())
DTMarray = DTMarray.clip(0)

DSMdataset = gdal.Open(DSMinput, gdal.GA_ReadOnly)
DSMarray = np.array(DSMdataset.GetRasterBand(1).ReadAsArray())
DSMarray = DSMarray.clip(0)

truthmask = np.logical_and(DTMarray, DSMarray)
DSMprefinal = np.multiply(DSMarray, truthmask)

np.savetxt('truthmask.csv', truthmask, delimiter = ' , ')
np.savetxt('DTM.csv', DTMarray, delimiter = ' , ')
np.savetxt('DSM.csv', DSMarray, delimiter = ' , ')



#DSM_final = ("DTM Filled@1" AND "DSM@1") * "DSM@1"


