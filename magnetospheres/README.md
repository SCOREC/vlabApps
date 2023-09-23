- `generate-magnetosphere-3d-10m.py`:
  - 3d, 10-moment two-fluid modeling
  - presently, default parameters are set to fit Ganymede's magnetosphere

- generate a script that runs on `1x2x2=4` processors and stops at time 1, with time
  intervals 0.1 between output frames
```bash
python generate-magnetosphere-3d-10m.py \
  magnetosphere-3d-10m.lua \
  --nProcs 1 2 2 \
  --tEnd 1 --tPerFrame 0.1
```

- make simple plots
```bash
# plot the all ion moments at the 1st time frame; note that the most commonly used

# spatial slice is the xz-plane slice (at a fixed y coordinate). Also, the default grid
# is a cube of resoluton `96*96*96` and is the domain is centered at the origin
# `(0,0,0)`, thus the slicing index `48` would give slices acorss the origin

# make 2d slice in the xy plane, or, more accuately, the 48th slice along the z
# direction (i.e., iz=48)
pgkyl magnetosphere-3d-10m_ion_1.bp sel \
  --z2 48 \
  pl -a -x x -y y \
  --saveas ion-frame-1-xy.png
# make 2d slice in the xz plane, or, more accuately, the 48th slice along the y
# direction (i.e., iy=48)
pgkyl magnetosphere-3d-10m_ion_1.bp sel \
  --z1 48 \
  pl -a -x x -y z \
  --saveas ion-frame-1-xz.png
# make 2d slice in the yz plane, or, more accuately, the 48th slice along the x
# direction (i.e., ix=48)
pgkyl magnetosphere-3d-10m_ion_1.bp \
  sel --z0 48 \
  pl -a -x y -y z \
  --saveas ion-frame-1-yz.png




# plot EM fields (Ex, Ey, Ez, Bx, By, Bz) at the 1st time frame
pgkyl magnetosphere-3d-10m_field_1.bp \
  sel --z1 48 --comp 0,1,2,3,4,5 \
  pl -a -x x -y z \
  --saveas field-frame-1-xz.png
```
