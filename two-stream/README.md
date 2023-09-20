- `genreate-two-stream-5m.py`
  - 1d, 5-moment two-fluid (two counter-streaming species); more details are documented
    in the generator (and in the generated lua file)
  - post-processing
```bash
# plot the growth of field energy
pgkyl rt-two-stream-5m_fieldEnergy.bp sel -c0 pl --logy
```
