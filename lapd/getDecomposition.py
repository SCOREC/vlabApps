#!/env/python
import sys
import numpy as np

nr=int(sys.argv[1])
nz=int(sys.argv[2])

cellsPerRank=1800
z2r=3

cells = nr * nr * nz
ncr = ((cells / cellsPerRank) / z2r) ** (1. / 3)
ncz = 3 * ncr
totRanks = ncr * ncr * ncz
print("target ranks {} ncz {} ncr {} ranks {} cellsPerRank {}".format(cells / cellsPerRank, ncz,
    ncr, totRanks, cells / totRanks))

