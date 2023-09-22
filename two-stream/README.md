`genreate-two-stream-5m.py`

- 1d, 5-moment two-fluid (two counter-streaming species)
  - more details are documented in the generator (and in the generated lua file)

- generating gkyl input file:
```bash
# using default parameters and save an gkyl input file called two-stream-5m.lua
python genreate-two-stream-5m.py two-stream-5m.lua
# or
python genreate-two-stream-5m.py two-stream-5m.lua --model 5-moment

# overriding default parameters, say, kx_de
python genreate-two-stream-5m.py two-stream-5m.lua --kx_de 0.01

# using default parameters but the vlasov model and saving an gkyl input file called
# two-stream-vlasov.lua
python genreate-two-stream-5m.py two-stream-vlasov.lua --model vlasov
```

- post-processing of 5-moment simulation results produced using the input file
  two-stream-5m.lua
```bash
# plot the growth of field energy
pgkyl two-stream-5m_fieldEnergy.bp sel -c0 pl --logy \
  -x 'time' -y 'integrated electric field energy, $\int E_x^2dx$' \
  --saveas two-stream-growth.png

# plot the 1d mass density, x-component of momentum, and energy of the two species at
# all frames, each frame (time) with a different color as indicated by the colorbar

pgkyl "two-stream-5m_e1_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas e1-all-frames.png

pgkyl "two-stream-5m_e2_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --clabel time --nsubplotrow 3 --saveas e2-all-frames.png

# plot Ex
pgkyl "two-stream-5m_field_[0-9]*.bp" \
  sel -c0 collect pl --lineouts 1 \
  -x '$x$' --clabel time --saveas Ex-all-frames.png
```


- post-processing of vlasov simulation results produced using the input file
  two-stream-vlasov.lua
```bash
# plot the growth of field energy
pgkyl two-stream-vlasov_fieldEnergy.bp sel -c0 pl --logy \
  -x 'time' -y 'integrated electric field energy, $\int E_x^2dx$' \
  --saveas two-stream-vlasov-growth.png

# plot the 1d number density, x-component of momentum, and energy of the electron
# species at all frames, each frame (time) with a different color as indicated by the
# colorbar

pgkyl two-stream-vlasov_elc_M0_[0-9]*.bp \
  interp -b ms -p 1 \
  collect pl --lineouts 1 \
  -x '$x$' -y density --clabel time \
  --saveas elc-density-all-frames.png

pgkyl two-stream-vlasov_elc_M1i_[0-9]*.bp \
  interp -b ms -p 1 \
  collect pl --lineouts 1 \
  -x '$x$' -y momentum --clabel time \
  --saveas elc-momentum-all-frames.png

pgkyl two-stream-vlasov_elc_M2_[0-9]*.bp \
  interp -b ms -p 1 \
  collect pl --lineouts 1 \
  -x '$x$' -y pressure --clabel time \
  --saveas elc-energy-all-frames.png

# plot Ex
pgkyl two-stream-vlasov_field_[0-9]*.bp \
  interp -b ms -p 1 \
  sel -c0 \
  collect pl --lineouts 1 \
  -x '$x$' -y Ex --clabel time \
  --saveas Ex-all-frames.png
```
