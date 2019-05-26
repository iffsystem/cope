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
import xml.dom.minidom

from argparse import ArgumentParser


#--- get arguments
def parser():

    usage = 'Usage: python {} GRID_FILE --DPI <value> --CON <value> --UNIT <name> --VMIN <value> --VMAX <value> --BASE <name> --HILLSHADE <name> --SLOPE <name> --OUT <name> [--OSS <file>] [--help]'\
            .format(__file__)
    argparser = ArgumentParser(usage=usage)
    argparser.add_argument('GRID_FILE', type=str,
                           help = '[necessary] set data as geotif file to overlay on pseudo red relief')
    argparser.add_argument('-dpi', '--DPI',
                           dest = 'dpi',
                           type = int,
                           default = 200,
                           required = True,
                           help = '[necessary] set dpi for drawing map')
    argparser.add_argument('-con', '--CON',
                           dest = 'con',
                           type = int,
                           default = 100,
                           required = True,
                           help = '[necessary] set contour interval [m] in drawing map')
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
    argparser.add_argument('-hs', '--HILLSHADE',
                           dest = 'hillshade',
                           type = str,
                           required = True,
                           help = '[necessary] set hillshade as geotiff file for making pseudo red relief')
    argparser.add_argument('-sl', '--SLOPE',
                           dest = 'slope',
                           type = str,
                           required = True,
                           help = '[necessary] set slope as geotiff file for making pseudo red relief')
    argparser.add_argument('-b', '--BASE',
                           dest = 'base',
                           type = str,
                           required = True,
                           help = '[necessary] set geotiff file for making contour lines')
    argparser.add_argument('-o', '--OUT',
                           dest = 'out',
                           type = str,
                           required = True,
                           help = '[necessary] set output directory name without extention for identified drainage data (geotiff and shape) ')
    argparser.add_argument('-oss', '--OSS',
                           dest = 'oss',
                           type= str,
                           help = '[option] set file name of open street map')
    args = argparser.parse_args()


    global FLIST,OUT,NUM_DATA,VMIN,VMAX,MY_DPI,DLT_CON,UNIT,BASETIF,HILLSHADE,SLOPE

    FLIST = []
    FLIST.append(format(args.GRID_FILE))

    NUM_DATA = len(FLIST)

    MY_DPI = format(args.dpi)
    DLT_CON = format(args.con)
    UNIT = format(args.unit)

    VMIN = format(args.vmin)
    VMAX = format(args.vmax)

    BASETIF = format(args.base)
    HILLSHADE = format(args.hillshade)
    SLOPE = format(args.slope)
    
    OUT = format(args.out)


    if args.oss:
        global OSS
        OSS = format(args.oss)
    else:
        OSS = None


getopt = parser()


TITLE = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   xx = xx.replace(".tif", "")
   TITLE.append((xx))

FIGFILE = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   xx = xx.replace("tif", "png")
   FIGFILE.append((xx))

FIGFILE2 = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   xx = xx.replace("tif", "jpg")
   FIGFILE2.append((xx))

KMLFILE = []
for i in range(0,len(FLIST)):
   xx = FLIST[i]
   xx = xx.replace("tif", "kml")
   KMLFILE.append((xx))

CBARFILE = 'colorbar.png'
CBARNAME = CBARFILE.replace(".png","")

CONTOURFILE = ['contour[10m].png','contour[100m].png','contour[1000m].png']
CONTOURNAME = []
for i in range(0,len(CONTOURFILE)):
   xx = CONTOURFILE[i]
   xx = xx.replace(".png","")
   CONTOURNAME.append((xx))


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


def createKML(num_data,fname,fileName,title,figfile,cbarfile,cbarname,contourfile,contourname,url,coord,coord_base):
  # This constructs the KML document from the CSV file.
  kmlDoc = xml.dom.minidom.Document()

  kmlElement = kmlDoc.createElementNS('http://earth.google.com/kml/2.2', 'kml')
  kmlElement.setAttribute('xmlns','http://earth.google.com/kml/2.2')
  kmlElement = kmlDoc.appendChild(kmlElement)
  folderElement = kmlDoc.createElement('Folder')
  folderElement = kmlElement.appendChild(folderElement)

  #--- Open in ScreenOverlay
  olnameElement = kmlDoc.createElement('open')
  valueText = kmlDoc.createTextNode('1')
  olnameElement.appendChild(valueText)
  folderElement.appendChild(olnameElement)

  #--- name
  nameElement = kmlDoc.createElement('name')
  valueText = kmlDoc.createTextNode(fname)
  nameElement.appendChild(valueText)
  folderElement.appendChild(nameElement)
  
  for i in range(0,len(contourfile)):
      #--- GroundOverlay for countour line
      olElement = kmlDoc.createElement('GroundOverlay')
      folderElement.appendChild(olElement)
      #--- name in GroundOverlay
      olnameElement = kmlDoc.createElement('name')
      valueText = kmlDoc.createTextNode('%s' % (contourname[i]))
      olnameElement.appendChild(valueText)
      olElement.appendChild(olnameElement)
      #--- Visibility in ScreenOverlay
      olnameElement = kmlDoc.createElement('visibility')
      valueText = kmlDoc.createTextNode('0')
      olnameElement.appendChild(valueText)
      olElement.appendChild(olnameElement)
      #--- Icon in GroundOverlay
      iconElement = kmlDoc.createElement('Icon')
      hrefElement = kmlDoc.createElement('href')
      valueText = kmlDoc.createTextNode('%s%s' % (url,contourfile[i]) )
      hrefElement.appendChild(valueText)
      iconElement.appendChild(hrefElement)
      olElement.appendChild(iconElement)
      #--- Icon in GroundOverlay
      latlonElement = kmlDoc.createElement('LatLonBox')
      # north
      nElement = kmlDoc.createElement('north')
      latlon = kmlDoc.createTextNode(str(coord_base[3]))
      nElement.appendChild(latlon)
      latlonElement.appendChild(nElement)
      # south
      sElement = kmlDoc.createElement('south')
      latlon = kmlDoc.createTextNode(str(coord_base[2]))
      sElement.appendChild(latlon)
      latlonElement.appendChild(sElement)
      # west
      wElement = kmlDoc.createElement('west')
      latlon = kmlDoc.createTextNode(str(coord_base[0]))
      wElement.appendChild(latlon)
      latlonElement.appendChild(wElement)
      # east
      eElement = kmlDoc.createElement('east')
      latlon = kmlDoc.createTextNode(str(coord_base[1]))
      eElement.appendChild(latlon)
      latlonElement.appendChild(eElement)
      # rotation
      rElement = kmlDoc.createElement('rotation')
      latlon = kmlDoc.createTextNode('0.0')
      rElement.appendChild(latlon)
      latlonElement.appendChild(rElement)
      #
      olElement.appendChild(latlonElement)

  for i in range(0,int(num_data)):
        #--- GroundOverlay for data
        olElement = kmlDoc.createElement('GroundOverlay')
        folderElement.appendChild(olElement)
        #--- name in GroundOverlay
        olnameElement = kmlDoc.createElement('name')
        valueText = kmlDoc.createTextNode(title[i])
        olnameElement.appendChild(valueText)
        olElement.appendChild(olnameElement)

        #--- Visibility in ScreenOverlay
        if i == 0:
          jj = 1
        else:
          jj = 0

        olnameElement = kmlDoc.createElement('visibility')
        valueText = kmlDoc.createTextNode(str(jj))
        olnameElement.appendChild(valueText)
        olElement.appendChild(olnameElement)


        #--- Icon in GroundOverlay
        iconElement = kmlDoc.createElement('Icon')
        hrefElement = kmlDoc.createElement('href')
        valueText = kmlDoc.createTextNode('%s%s' % (url,figfile[i]) )
        hrefElement.appendChild(valueText)
        iconElement.appendChild(hrefElement)
        olElement.appendChild(iconElement)
        #--- Icon in GroundOverlay
        latlonElement = kmlDoc.createElement('LatLonBox')
        # north
        nElement = kmlDoc.createElement('north')
        latlon = kmlDoc.createTextNode(str(coord[3]))
        nElement.appendChild(latlon)
        latlonElement.appendChild(nElement)
        # south
        sElement = kmlDoc.createElement('south')
        latlon = kmlDoc.createTextNode(str(coord[2]))
        sElement.appendChild(latlon)
        latlonElement.appendChild(sElement)
        # west
        wElement = kmlDoc.createElement('west')
        latlon = kmlDoc.createTextNode(str(coord[0]))
        wElement.appendChild(latlon)
        latlonElement.appendChild(wElement)
        # east
        eElement = kmlDoc.createElement('east')
        latlon = kmlDoc.createTextNode(str(coord[1]))
        eElement.appendChild(latlon)
        latlonElement.appendChild(eElement)
        # rotation
        rElement = kmlDoc.createElement('rotation')
        latlon = kmlDoc.createTextNode('0.0')
        rElement.appendChild(latlon)
        latlonElement.appendChild(rElement)
        #
        olElement.appendChild(latlonElement)

  kmlFile = open(fileName[0], 'w')
  kmlFile.write(kmlDoc.toprettyxml('  ', newl = '\n', encoding = 'utf-8'))


def pixelcoord(x, y, a, b, d, e, Xmin, Ymin):
  """Returns coordinates X Y from pixel"""
  xp = a * x + b * y + Xmin
  yp = d * x + e * y + Ymin
  return xp, yp

def make_contourline(basetif,dlt_con,my_dpi,contourfile,coord_base):
  #--- create contour line
  base = gdal.Open(basetif)
  bb = base.GetRasterBand(1)
  elevation = bb.ReadAsArray()
  
  ELmin = bb.GetMinimum()
  ELmax = bb.GetMaximum()
  if ELmin is None or ELmax is None:
            (ELmin,ELmax) = bb.ComputeRasterMinMax(1)


  width2 = base.RasterXSize
  height2 = base.RasterYSize
  gt2 = base.GetGeoTransform()

  Xmin_base = gt2[0]
  Ymin_base = gt2[3] + width2*gt2[4] + height2*gt2[5]
  Xmax_base = gt2[0] + width2*gt2[1] + height2*gt2[2]
  Ymax_base = gt2[3]

  coord_base = [Xmin_base, Xmax_base, Ymin_base, Ymax_base]
  
  # initialize figure
  plt.figure()
  
  CS = plt.contour(elevation,levels = range(0,int(ELmax),10),colors = 'black',linewidths = 0.05, extent=[Xmin_base, Xmax_base, Ymax_base, Ymin_base])

  plt.axes().get_yaxis().set_visible(False)
  plt.axes().get_xaxis().set_visible(False)
  
  plt.savefig(contourfile[0], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)
  print "contour[10m]:OK"

  # initialize figure
  plt.figure()

  CS = plt.contour(elevation,levels = range(0,int(ELmax),100),colors = 'magenta',linewidths = 0.2, extent=[Xmin_base, Xmax_base, Ymax_base, Ymin_base])

  
  plt.axes().get_yaxis().set_visible(False)
  plt.axes().get_xaxis().set_visible(False)

  plt.savefig(contourfile[1], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)
  print "contour[100m]:OK"
  
  # initialize figure
  plt.figure()

  CS = plt.contour(elevation,levels = range(0,int(ELmax),1000),colors = 'blue',linewidths = 0.4, extent=[Xmin_base, Xmax_base, Ymax_base, Ymin_base])
 
  
  plt.axes().get_yaxis().set_visible(False)
  plt.axes().get_xaxis().set_visible(False)

  plt.savefig(contourfile[2], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)
  print "contour[1000m]:OK"
  
  return coord_base


def visualize_data(num_data,flist,Vmin,Vmax,figfile,figfile2,cmap,my_dpi,coord,hillshade,slope):

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

    
    fig = plt.figure()

    plt.axes().get_yaxis().set_visible(False)
    plt.axes().get_xaxis().set_visible(False)

    #--- open hillshade geotiff (EPSG:4326) & set data in Array
    ds2 = gdal.Open(hillshade)
    band2 = ds2.GetRasterBand(1)
    data2 = band2.ReadAsArray()

    
    #--- open slope geotiff (EPSG:4326) & set data in Array
    ds3 = gdal.Open(slope)
    band3 = ds3.GetRasterBand(1)
    data3 = band3.ReadAsArray()
    
    
    
    #--- relief color
    cmap2=plt.cm.gist_gray
    cmap3=plt.cm.Reds

    #--- Draw pseudo red relief
    plt.imshow(data2, cmap=cmap2, vmin=0, vmax=255, extent=[Xmin, Xmax, Ymin, Ymax])
    plt.imshow(data3, cmap=cmap3, vmin=0, vmax=90, extent=[Xmin, Xmax, Ymin, Ymax], alpha=0.5)
        
    plt.savefig(figfile[i], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)
    plt.savefig(figfile2[i], dpi=int(my_dpi), transparent=True, bbox_inches="tight", pad_inches=0.0)

    plt.close(fig)
    
  return coord


def main():
  #--- color map
  cmap = createColorMap()

  #--- dump image files
  minmax = {}

  coord = []
  coord_base = []

  #--- make countour line by base MAP & get corner coordinate
  coord_base = make_contourline(BASETIF,DLT_CON,MY_DPI,CONTOURFILE,coord_base)


  #--- visualize geotiff & get corner coordinate
  coord = visualize_data(NUM_DATA,FLIST,VMIN,VMAX,FIGFILE,FIGFILE2,cmap,MY_DPI,coord,HILLSHADE,SLOPE)

  
  #--- create KML
  url = ''
  kml = createKML(NUM_DATA,FNAME,KMLFILE,TITLE,FIGFILE,CBARFILE,CBARNAME,CONTOURFILE,CONTOURNAME,url,coord,coord_base)


if __name__ == '__main__':
  main()

  sys.exit()
