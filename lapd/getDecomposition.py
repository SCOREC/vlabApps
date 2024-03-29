#!/env/python
import sys
import numpy as np
import time

cellsPerRank=1800
z2r=3

def getCutsBrute(num_cells_r, num_cells_z, debug=False):
    cuts = getCutsFloat(num_cells_r,num_cells_z)
    def int_ceil(x):
        return int(np.ceil(x))
    #TODO define better bounds
    max_cuts_r = int_ceil(cuts[0])+1
    max_cuts_z = int_ceil(cuts[1])+1
    min_cuts_r = np.max([1,int_ceil(max_cuts_r/2)])
    min_cuts_z = np.max([1,int_ceil(max_cuts_z/2)])

    if debug: 
        print(min_cuts_r, min_cuts_z, max_cuts_r, max_cuts_z)

    num_cells = num_cells_r * num_cells_r * num_cells_z

    def cells_per_rank_diff(num_cuts_r,num_cuts_z):
        cpr = num_cells / ( num_cuts_r * num_cuts_r * num_cuts_z )
        diff = np.abs(cpr - cellsPerRank)
        return diff

    start = time.time()

    arr = np.array([ [cells_per_rank_diff(i,j),int(i),int(j)] 
             for i in range(min_cuts_r,max_cuts_r)
             for j in range(min_cuts_z,max_cuts_z) ], dtype=np.int32)

    minDiffIdx = np.argmin(arr[:,0])
    min_diff = arr[minDiffIdx,0]
    min_cut = arr[minDiffIdx,1:]
    end = time.time()

    if debug: 
        print("time {} seconds".format(end-start))
        print(min_diff, min_cut)

    return min_cut

def getCutsFloat(nr, nz, debug=False):
    cells = nr * nr * nz
    ncr = ((cells / cellsPerRank) / z2r) ** (1. / 3)
    ncz = 3 * ncr
    if debug:
        totRanks = ncr * ncr * ncz
        print("target ranks {} ncz {} ncr {} ranks {} cellsPerRank {}"
            .format(cells / cellsPerRank, ncz, ncr, totRanks, cells / totRanks))

    return (ncr, ncz)

def getCuts(num_cells_r, num_cells_z, debug=False):
    return getCutsBrute(num_cells_r, num_cells_z, debug)

if __name__ == "__main__":
    nr=int(sys.argv[1])
    nz=int(sys.argv[2])
    cuts = getCutsBrute(nr,nz)
    print(cuts[0], cuts[1])

def testSmall():
    nr = 16
    nz = 150
    cuts = getCuts(nr, nz, True)
    assert( np.array_equal(cuts,[2, 5]) )

def testLarge():
    nr = 64
    nz = 700
    cuts = getCuts(nr, nz, True)
    print(cuts)
    assert( np.array_equal(cuts,[8, 25]) )

