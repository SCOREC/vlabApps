`lapd`

- this is a read only application
- see Shi EL, Hammett GW, Stoltzfus-Dueck T, Hakim A. Gyrokinetic continuum simulation of turbulence in a straight open-field-line plasma. Journal of Plasma Physics. 2017;83(3):905830304. doi:10.1017/S002237781700037X


- execution

```bash
gkyl LAPD3D5Mg2_coarseGrid.lua
```

- post-processing

```bash
# plot the growth of field energy
pgkyl ex_fieldEnergy.bp select -c0 plot --logy -x 'time' -y '\$|E_x|^2\$' --save
```
