- `genreate-two-stream-5m.py`
  - 1d, 5-moment two-fluid (two counter-streaming species); more details are documented
    in the generator (and in the generated lua file)
  - post-processing
```bash
# plot the growth of field energy
pgkyl rt-two-stream-5m_fieldEnergy.bp sel -c0 pl --logy --saveas growth.png

# plot the 1d mass density, x-component of momentum, and energy of the two species at
# all frames, each frame (time) with a different color as indicated by the colorbar

pgkyl "rt-two-stream-5m_e1_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --nsubplotrow 3 --saveas e1-all-frames.png

pgkyl "rt-two-stream-5m_e2_[0-9]*.bp" \
  sel -c 0,1,4 collect pl --lineouts 1 \
  -x '$x$' --nsubplotrow 3 --saveas e2-all-frames.png

# plot Ex
pgkyl "rt-two-stream-5m_field_[0-9]*.bp" \
  sel -c0 collect pl --lineouts 1 \
  --saveas Ex-all-frames.png
```
