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

    usage = 'Usage: python {} GRID_FILE --DPI <value> --UNIT <name> --VMIN <value> --VMAX <value> --RELIEF <name> [--help]'\
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
    argparser.add_argument('-unit', '--UNIT',
                       dest = 'unit',
                       type = str,
                       required = True,
                       help = '[necessary] set unit name for making legend')
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
    argparser.add_argument('-relief', '--RELIEF',
                           dest = 'relief',
                           type = str,
                           required = True,
                           help = '[necessary] set relief as geotiff file for background')
    args = argparser.parse_args()


    global FLIST,NUM_DATA,VMIN,VMAX,MY_DPI,RELIEF,UNIT

    FLIST = []
    FLIST.append(format(args.GRID_FILE))

    NUM_DATA = len(FLIST)

    MY_DPI = format(args.dpi)
    UNIT = format(args.unit)

    VMIN = format(args.vmin)
    VMAX = format(args.vmax)

    RELIEF = format(args.relief)
    

getopt = parser()



FIGFILE2 = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   path = os.path.dirname(xx)
   
   xx = xx.replace(".tif", "_relief.png")
   FIGFILE2.append((xx))


CBARFILE = path + '/colorbar.png'


FNAME = FLIST[0]


def createColorMap():

  cdict = {'red':   ((0.0, 0, 0),
                     (0.30, 0, 0),
                     (0.50, 1, 1),
                     (0.70, 1, 1),
                     (0.85, 0.5, 0.5),
                     (1.0, 0.0, 0.0)),
           'green': ((0.0, 1, 1),
                     (0.30, 1, 1),
                     (0.50, 1, 1),
                     (0.70, 0, 0),
                     (0.85, 0, 0),
                     (1.0, 0.0, 0.0)),
           'blue':  ((0.0, 1, 1),
                     (0.30, 0, 0),
                     (0.50, 0, 0),
                     (0.70, 0, 0),
                     (0.85, 0.5, 0.5),
                     (1.0, 1.0, 1.0))}


  return mpl.colors.LinearSegmentedColormap('my_colormap',cdict,256)

def makeColorBar(Zmin, Zmax, cmap, imgfile, unit, my_dpi):
  # Make a figure and axes with dimensions as desired.
  fig = plt.figure(figsize=(8,1))
  ax1 = fig.add_axes([0.005, 1.65, 1., 0.15])
  norm = mpl.colors.Normalize(vmin=int(Zmin), vmax=int(Zmax))
  cb1 = mpl.colorbar.ColorbarBase(ax1, cmap=cmap,
                                  norm=norm,
                                  orientation='horizontal')
  cb1.set_label(unit,position=(0.98,0))
  plt.savefig(imgfile,
              format='png',
              bbox_inches="tight",
              dpi=int(my_dpi),
              pad_inches=0.1,
              transparent=False)


def visualize_data(num_data,flist,Vmin,Vmax,figfile2,cmap,my_dpi,coord,relief):

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

    
    
    #--- Draw data with background
    # initialize figure
    fig = plt.figure()

    plt.axes().get_yaxis().set_visible(False)
    plt.axes().get_xaxis().set_visible(False)
    
    masked_data1 = np.ma.masked_where(data1 < float(VMIN)+0.0000001, data1)
    masked_data2 = np.ma.masked_where(masked_data1 > float(VMAX), masked_data1)
    
    
    #--- open hillshade geotiff (EPSG:4326) & set data in Array
    ds2 = gdal.Open(relief)
    band2R = ds2.GetRasterBand(1)
    band2G = ds2.GetRasterBand(2)
    band2B = ds2.GetRasterBand(3)
    band2A = ds2.GetRasterBand(4)
    
                        
    dataR = band2R.ReadAsArray()
    dataG = band2G.ReadAsArray()
    dataB = band2B.ReadAsArray()
    dataA = band2A.ReadAsArray()
                        
    rgba = np.dstack((dataR,dataG,dataB,dataA))
                        
    
    #--- Draw pseudo red relief as back ground
    plt.imshow(rgba, extent=[Xmin, Xmax, Ymin, Ymax], alpha=1.0)
    
    plt.imshow(masked_data1, cmap=cmap, extent=[Xmin, Xmax, Ymin, Ymax], interpolation='nearest', alpha=0.9)
    
    plt.savefig(figfile2[i], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)

    

    plt.close(fig)

  return coord


def main():
  #--- color map
  cmap = createColorMap()

  #--- dump image files
  minmax = {}

  coord = []
  

  #--- make a Colorbar image file
  makeColorBar(VMIN, VMAX, cmap, CBARFILE, UNIT, MY_DPI)


  #--- visualize geotiff & get corner coordinate
  coord = visualize_data(NUM_DATA,FLIST,VMIN,VMAX,FIGFILE2,cmap,MY_DPI,coord,RELIEF)


if __name__ == '__main__':
  main()

  sys.exit()
