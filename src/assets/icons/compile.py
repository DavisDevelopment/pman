#!/usr/bin/env python3

import os, sys, json
import xml.etree.ElementTree as ET
path = os.path

cwd = os.getcwd()
svgPath = path.join(cwd, 'svg')

def get(name):
    f = open(name, 'r', 1)
    r = f.read()
    f.close()
    return r

def put(name, data):
    f = open(name, 'w', 1)
    f.write( data )
    f.close()

def getAllIconPaths():
    l = os.listdir( svgPath )
    return [path.join(svgPath, name) for name in l]

def iconPath( p ):
    tree = ET.parse( p )
    root = tree.getroot()
    return root.find('{http://www.w3.org/2000/svg}path')

def parse():
    ipaths = getAllIconPaths()
    data = {}
    for n in ipaths:
        key = path.splitext(path.basename( n ))[0]
        print( key )
        p = iconPath( n )
        value = p.get( 'd' ).strip()
        data[key] = value
    str_data = json.dumps(data, indent=3)
    put('icon_data.json', str_data)
    print('Done')

parse()
