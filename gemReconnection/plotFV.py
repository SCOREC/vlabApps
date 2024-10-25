from pathlib import Path
import matplotlib.pyplot as plt

import os
repoDir = os.environ['VLAB_REPODIR']
command = "cd ",repoDir,"/gemReconnection && git rev-parse HEAD"
ret = os.system(command)
print(ret)

import postgkyl as pg

run = Path.cwd()

def getModelType():
    frame = 0
    models = ["5m", "10m"]
    for model in models:
        path = Path(f"rt-{model}-gem_field_{frame}.bp")
        if path.is_file():
            return model
    error = "Failed to find input ADIOS file rt-5m-gem_field_0.bp or rt-10m-gem_field_0.bp."
    assert False, error

frame = 0
model = getModelType()
filename = run / f"rt-{model}-gem_field_{frame}.bp"
filename = str(filename)

gdata = pg.GData(filename)

vals = gdata.getValues() # cell-center values, shape is Ny * Nx * Ncomponents
grid = gdata.getGrid() # cell corner coordinates
ndim = gdata.getNumDims() # number of spatial dimensions

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
