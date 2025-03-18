from pathlib import Path
import matplotlib.pyplot as plt
import postgkyl as pg

run = Path.cwd()

def getModelType():
    frame = 0
    models = ["5m", "10m"]
    for model in models:
        path = Path(f"rt_{model}_gem_gzero-field_{frame}.gkyl")
        if path.is_file():
            return model
    error = "Failed to find input file " + path
    assert False, error

frame = 0
model = getModelType()
filename = run / f"rt_{model}_gem_gzero-field_{frame}.gkyl"
filename = str(filename)

gdata = pg.GData(filename)

vals = gdata.get_values() # cell-center values, shape is Ny * Nx * Ncomponents
grid = gdata.get_grid() # cell corner coordinates
ndim = gdata.get_num_dims() # number of spatial dimensions

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
