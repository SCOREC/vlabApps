#!/env/python
import sys
import numpy as np

nr=int(sys.argv[1])
nz=int(sys.argv[2])

cellsPerRank=1800
z2r=3

ncells=nr*nr*nz
ranks=np.ceil(ncells/cellsPerRank)
ncz=np.ceil(ranks/z2r)
ncr=np.ceil(np.sqrt(ranks/ncz))
totRanks=ncr*ncr*ncz
print("target ranks {} ncz {} ncr {} ranks {}".format(ranks, ncz, ncr, totRanks))

