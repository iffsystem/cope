#!/usr/bin/env python
# -*- coding: utf8 -*-
import sys
import os
import csv
import numpy as np
from PIL import Image
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import colors

from osgeo import gdal
gdal.UseExceptions()

from argparse import ArgumentParser


#--- get arguments
def parser():

    usage = 'Usage: python {} GRID_FILE --DPI <value> --VMIN <value> --VMAX <value> [--help]'\
            .format(__file__)
    argparser = ArgumentParser(usage=usage)
    argparser.add_argument('GRID_FILE', type=str,
                           help = '[necessary] set geotiff file to draw data on relief')
    argparser.add_argument('-dpi', '--DPI',
                           dest = 'dpi',
                           type = int,
                           default = 200,
                           required = True,
                           help = '[necessary] set dpi for drawing map')
    argparser.add_argument('-vmin', '--VMIN',
                           dest = 'vmin',
                           type = int,
                           required = True,
                           help = '[necessary] set minimum value for making legend')
    argparser.add_argument('-vmax', '--VMAX',
                           dest = 'vmax',
                           type = int,
                           required = True,
                           help = '[necessary] set maximum value for making legend')
    args = argparser.parse_args()


    global FLIST,NUM_DATA,VMIN,VMAX,MY_DPI

    FLIST = []
    FLIST.append(format(args.GRID_FILE))

    NUM_DATA = len(FLIST)

    MY_DPI = format(args.dpi)
    
    VMIN = format(args.vmin)
    VMAX = format(args.vmax)

getopt = parser()





FIGFILE = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   xx = xx.replace(".tif", ".png")
   FIGFILE.append((xx))


FNAME = FLIST[0]


def createColorMap():

  
  cdict_o = {'red':  ((0.00, 1, 1),
                     (1.00, 1, 1)),
           'green': ((0.0, 0.55, 0.55),
                     (1.00, 0.55, 0.55)),
           'blue':  ((0.0, 0, 0),
                     (1.00, 0, 0))}

  return mpl.colors.LinearSegmentedColormap('my_colormap',cdict_o,256)


def visualize_data(num_data,flist,Vmin,Vmax,figfile,cmap,my_dpi,coord):

  for i in range(0,num_data):
    #--- open geotiff & set data in Array
    ds = gdal.Open(flist[i])
    band = ds.GetRasterBand(1)
    data1 = band.ReadAsArray()


    #--- get corner coordinates
    width = ds.RasterXSize
    height = ds.RasterYSize
    gt = ds.GetGeoTransform()

    Xmin = gt[0]
    Ymin = gt[3] + width*gt[4] + height*gt[5]
    Xmax = gt[0] + width*gt[1] + height*gt[2]
    Ymax = gt[3]

    coord = (Xmin, Xmax, Ymin, Ymax)

    #--- get min/max
    Zmin = data1.min()
    Zmax = data1.max()
    if Zmin is None or Zmax is None:
            (Zmin,Zmax) = band.ComputeRasterMinMax(1)

    
    #--- Draw data without background
    # initialize figure
    fig = plt.figure()

    plt.axes().get_yaxis().set_visible(False)
    plt.axes().get_xaxis().set_visible(False)
    
    masked_data1 = np.ma.masked_where(data1 < float(VMIN)+0.0000000001, data1)
    
    masked_pix = np.ma.compressed(masked_data1)
    
    
    
    cell_area = gt[1] * -1.0*gt[5] # [m2/pixel]
    
    # NAN check
    if (masked_pix.size != masked_pix.size):
        total_area = 0.0 # [m2] (m2/pixel * pixel)
        
    elif (masked_pix.size is not 0):
        total_area = cell_area * masked_pix.size # [m2] (m2/pixel * pixel)
        
    else:
        total_area = 0.0
    
    total_area = total_area * 0.0010 *0.0010
        
    print 'check: min=%08f, max=%08f' % (data1.min(),data1.max())
    
    print "PIX ALL", masked_data1.size
    print "PIX boundary", masked_pix.size
    print "PIX RESOL", gt[1]
    print "MESH AREA ", cell_area
    print "DRAIANGE AREA", total_area
    
    
    #--- output clipped coordinates
    a = np.array([' : cell size [m]',' : number of all pixels [num]',' : number of drainage pixels [num]',' : cell area [m2]',' : drainage_area [km2]'])
    b = np.array([gt[1], masked_data1.size, masked_pix.size, cell_area, total_area])
    np.savetxt('data.txt',np.transpose((b,a)),fmt="%s %s",delimiter=' ')
    
    
    plt.imshow(masked_data1, cmap=cmap, vmin=VMIN, vmax=VMAX, extent=[Xmin, Xmax, Ymin, Ymax], interpolation='nearest', alpha=0.9)

    plt.savefig(figfile[i], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)

    plt.close(fig)
    
    
    
  return coord


def main():
  #--- color map
  cmap = createColorMap()

  #--- visualize geotiff & get corner coordinate
  coord = []
  coord = visualize_data(NUM_DATA,FLIST,VMIN,VMAX,FIGFILE,cmap,MY_DPI,coord)


if __name__ == '__main__':
  main()

  sys.exit()
