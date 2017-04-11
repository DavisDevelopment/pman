
import sys, os
path = os.path

def read( fn ):
    f = open(fn, 'r', 1)
    c = f.read()
    f.close()
    return c

def write(fn, d):
    f = open(fn, 'w', 1)
    f.write( d )
    f.close()

def main():

    code = read('./pack')
    code = ('#!/usr/bin/env node\n\n' + code)
    write('./pack', code)

if __name__ == "__main__":
    main()
