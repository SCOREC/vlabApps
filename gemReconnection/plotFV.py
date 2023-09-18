from pathlib import Path
import matplotlib.pyplot as plt

import sys
sys.path.append("/export/gkeyllSoft/postgkyl")

import os
ret = os.system("cd /export/vlabApps/gemReconnection && git rev-parse HEAD")

import postgkyl as pg

run = Path.cwd()
pfx = "rt-5m-gem"
frame = 0

filename = run / f"{pfx}_field_{frame}.bp"
filename = str(filename)

gdata = pg.GData(filename)

vals = gdata.getValues() # cell-center values, shape is Ny * Nx * Ncomponents
grid = gdata.getGrid() # cell corner coordinates
ndim = gdata.getNumDims() # number of spatial dimensions

print(vals.shape)
print([g.shape for g in grid])
print(ndim)

assert len(vals.shape) == ndim+1 and len(grid) == ndim

icomp = 3
compName = r'$E_z^2$'
fileName = "E_z.png"

my_vals = vals[..., icomp]
x, y = grid

fig, ax = plt.subplots()

im = ax.pcolormesh(x, y, my_vals.T)
fig.colorbar(im, ax=ax)

ax.set_xlabel('x')
ax.set_ylabel('y')
ax.set_title(compName)
ax.set_aspect(1)

plt.savefig(fileName)
