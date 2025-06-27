`lapd`

- this application requires significant compute resources
  - with Gkyl (pre-G0 with GPU backend) each profile will run for ~4hrs on 1536 cores
  - On Anvil CPUs, running the application will consume approximetly 6144 SUs
- data source: https://github.com/ammarhakim/gkyl-paper-inp/tree/e49adc065f4e670607145b95fab8dc70b122a71c/2024_ApJ_LAPDReflection
- references:
  - Shi EL, Hammett GW, Stoltzfus-Dueck T, Hakim A. "Gyrokinetic continuum simulation of turbulence in a straight open-field-line plasma". Journal of Plasma Physics. 2017;83(3):905830304. doi:10.1017/S002237781700037X
  - Sayak Bose, Jason TenBarge, Troy Carter, Michael Hahn, Hantao Ji, James Juno, Daniel Wolf Savin, Shreekrishna Tripathi, and Stephen Vincena. "Experimental study of Alfvén wave reflection from an Alfvén-speed gradient relevant to the solar coronal holes". Submitted to ApJ https://arxiv.org/abs/2402.06193

- execution

```bash
gkyl LAPD.lua
```

- post-processing

```bash
# plot the growth of field energy
pgkyl ex_fieldEnergy.bp select -c0 plot --logy -x 'time' -y '\$|E_x|^2\$' --save
```
