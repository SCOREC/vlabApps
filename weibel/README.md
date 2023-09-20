`genreate-weibel-1x2v-10m`

- 1d, 10-moment two-fluid (two streaming electrons)
  - more details are documented in the generator (and in the generated lua file)

- generating gkyl input files:
```bash
# using default parameters and save an gkyl input file called weibel-1x2v-10m.lua
python generate-weibel-1x2v-10m.py weibel-1x2v-10m.lua

# overriding default parameters, say, kx_de
python generate-weibel-1x2v-10m.py weibel-1x2v-10m.lua --kx_de 0.01

```

- post-processing
```bash
# plot the growth of field energy
pgkyl weibel-1x2v-10m_fieldEnergy.bp sel -c0 pl --logy --saveas growth.png

# plot the 1d mass density, x-component of momentum, and energy of the two species at
# all frames, each frame (time) with a different color as indicated by the colorbar

pgkyl "weibel-1x2v-10m_e1_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas e1-all-frames.png

pgkyl "weibel-1x2v-10m_e2_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas e2-all-frames.png

# plot Bz
pgkyl "weibel-1x2v-10m_field_[0-9]*.bp" \
  sel -c5 collect pl --lineouts 1 \
  -x '$x$' --clabel time --saveas Ex-all-frames.png
```
