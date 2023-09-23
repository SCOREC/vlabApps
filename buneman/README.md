`genreate-buneman-5m.py`

- 1d, 5-moment two-fluid (electron + ion)
  - more details are documented in the generator (and in the generated lua file)

- generating gkyl input file:
```bash
# using default parameters and save an gkyl input file called weibel-1x2v-10m.lua
python genreate-buneman-5m.py buneman-5m.lua

# overriding default parameters, say, kx_de
python genreate-buneman-5m.py buneman-5m.lua --kx_de 0.01

```

- post-processing
```bash
# plot the growth of field energy
pgkyl buneman-5m_fieldEnergy.bp sel -c0 pl --logy --saveas growth.png

# plot the 1d mass density, x-component of momentum, and energy of the two species at
# all frames, each frame (time) with a different color as indicated by the colorbar

pgkyl "buneman-5m_elc_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas elc-all-frames.png

pgkyl "buneman-5m_ion_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas ion-all-frames.png

# plot Ex
pgkyl "buneman-5m_field_[0-9]*.bp" \
  sel -c0 collect pl --lineouts 1 \
  -x '$x$' --clabel time --saveas Ex-all-frames.png
```
