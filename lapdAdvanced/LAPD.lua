-- Gkyl ------------------------------------------------------------------------
-- 3D test simulation of LAPD
--------------------------------------------------
readBProfile = true
if readBProfile then

   -- Load magnetic field data
   local lines = io.lines("High_vA_profile.txt") -- open file as lines
   local LAPDTable = {} -- new table with columns and rows as tables[n_column][n_row]=value
   for line in lines do -- row iterator
        local i = 1 -- first column
    	for value in (string.gmatch(line, "[^%s]+")) do  -- tab separated values
--      for value in (string.gmatch(line, '%d[%d.]*')) do -- comma separated values
    	     LAPDTable[i]=LAPDTable[i]or{} -- if not column then create new one
             LAPDTable[i][#LAPDTable[i]+1]=tonumber(value) -- adding row value
             i=i+1 -- column iterator
    	end
   end
   zLAPD = LAPDTable[1]
   BzLAPD = LAPDTable[2] -- In units of Gauss! Radial coords 2-11
   offsetBz = 1
-- End load data
end

-- Functions for finding nearest indicies in data and interpolating
local findNearestIndex = function(x, x0)
      local nx = #x
      local idxLo = 1
      while (x[idxLo+1] <= x0 and idxLo+1 < nx) do
       	  idxLo = idxLo + 1
      end
      local idxUp = idxLo + 1
      return idxLo, idxUp
end
local linearInterp = function(f, x, x0)
      local idxLo, idxUp = findNearestIndex(x, x0)
      local x0l = x0
      if (x0 > x[#x]) then
      	 x0l = x[#x]
      end
      local y = f[idxLo] + (x0l - x[idxLo]) * (f[idxUp] - f[idxLo]) / (x[idxUp] - x[idxLo])
      return y
end
local biLinearInterp = function(f, x, x0, y, y0, offset)
      local idxLoX, idxUpX = findNearestIndex(x, x0)
      local idxLoY, idxUpY = findNearestIndex(y, y0)
      idxLoYTab = idxLoY + offset -- deal with 2D LAPDTable indexing
      idxUpYTab = idxUpY + offset
      local x0l, y0l = x0, y0
      if (x0 > x[#x]) then
      	 x0l = x[#x]
      end
      if (y0 > y[#y]) then
      	 y0l = y[#y]
      end
      local f0 = f[idxLoYTab][idxLoX] + (x0l - x[idxLoX]) * (f[idxLoYTab][idxUpX] - f[idxLoYTab][idxLoX]) / (x[idxUpX] - x[idxLoX])
      local f1 = f[idxUpYTab][idxLoX] + (x0l - x[idxLoX]) * (f[idxUpYTab][idxUpX] - f[idxUpYTab][idxLoX]) / (x[idxUpX] - x[idxLoX])
      local y = f0 + (y0l - y[idxLoY]) *  (f1 - f0) / (y[idxUpY] - y[idxLoY])
      return y
end
-- example Bz = biLinearInterp(LAPDTable, zLAPD, 0., rLAPD, 0.2, offsetBz)
----------------------------------------------



-- local Moments = require "Moments"
local Moments = G0.Moments
local Euler = G0.Moments.Eq.Euler
local Constants = require "Lib.Constants"
local Logger = require "Lib.Logger"

local logger = Logger {
   logToFile = true
}

local log = function(...)
   logger(string.format(...))
   logger("\n")
end

-- physical parameters
gasGamma = 5./3.
local cFac = 1000
-- Universal constant parameters.
local eps0, eV = Constants.EPSILON0*cFac, Constants.ELEMENTARY_CHARGE
local mu0      = Constants.MU0
local m_e, m_p  = Constants.ELECTRON_MASS, Constants.PROTON_MASS

-- epsilon0 = 8.854e-12*cFac
-- mu0 = 1.257e-6
-- eV = 1.6e-19
-- m_e = 9.11e-31
-- m_p = 1.67e-27

lightSpeed = 1/math.sqrt(mu0*eps0) -- speed of light

Te_Ti = 5.0 -- ratio of electron to ion temperature
elcTemp = 7.*eV
ionTemp = elcTemp / Te_Ti
n0 = 7.0e18 -- initial number density

ionMass = 4*m_p -- ion mass, Helium
ionCharge = 1*eV -- ion charge, singly ionized He
elcMass = ionMass/100. -- electron mass
elcCharge = -eV -- electron charge

if readBProfile then
   B0 = linearInterp(BzLAPD, zLAPD, 0.) / 1e4 -- convert to Tesla
else
   B0 = 1.
end
P0 = B0*B0 / (2*mu0) + n0*(elcTemp + ionTemp) -- pressure at antenna end

-- Alfven speeds
vAIon = B0/math.sqrt(mu0*n0*ionMass)
vAElc = B0/math.sqrt(mu0*n0*elcMass)

-- Thermal speeds
vtElc = math.sqrt(2.*elcTemp / elcMass) --electron thermal velocity
vtIon = math.sqrt(2.*ionTemp / ionMass) --ion thermal velocity

-- Ion beta
beta = vtIon^2 / vAIon^2

-- plasma and cyclotron frequencies
wpe = math.sqrt(ionCharge^2*n0/(eps0*elcMass))
wpi = math.sqrt(ionCharge^2*n0/(eps0*ionMass))
omegaCe = ionCharge*B0/elcMass
omegaCi = ionCharge*B0/ionMass

-- inertial length
de = vAElc/omegaCe
di = vAIon/omegaCi

-- gyroradii
rhoi = vtIon/omegaCi
rhoe = vtElc/omegaCe
rhos = math.sqrt(elcTemp/ionMass) / omegaCi

-- antenna params
J01 = 1.0e4   -- Amps/m^3.
driveFreq1 = 7.64e4
tAntOn1 = 0.
antRamp1 = 0.25/driveFreq1
tAntOff1 = 1.5/driveFreq1 - antRamp1
lAnt1 = 0.2178
kAnt1 = 2*math.pi/lAnt1
antZ1 = 0.
antOrientation1 = "x"

J02 = 0.   -- Amps/m^3.
driveFreq2 = 7.64e4
tAntOn2 = 0.
antRamp2 = 0.25/driveFreq2
tAntOff2 = 1.5/driveFreq2 - antRamp2
lAnt2 = 0.2178
kAnt2 = 2*math.pi/lAnt2
antZ2 = 10.
antOrientation2 = "y"


-- domain size and simulation time
Lr = 0.6
LzSt = -6.
LzEnd = 18.
Lz = LzEnd - LzSt

nr = 64
nz = 700

ncx = 4
ncy = 4
ncz = 6

tEnd = 150.0/omegaCi
nFrames = 150

cfl_frac = 1.0 -- CFL coefficient.
dz = Lz / nz
zFirstEdge = dz

tTransit = LzEnd / vAIon

field_energy_calcs = GKYL_MAX_INT -- Number of times to calculate field energy.
integrated_mom_calcs = GKYL_MAX_INT -- Number of times to calculate integrated moments.
dt_failure_tol = 1.0e-4 -- Minimum allowable fraction of initial time-step.
num_failures_max = 20 -- Maximum allowable number of consecutive small time-steps.

log("%50s = %g", "n0", n0)
log("%50s = %g", "mi/me", ionMass / elcMass)
log("%50s = %g", "wpe/OmegaCe", wpe / omegaCe)
log("%50s = %g", "proton beta", beta)
log("%50s = %g", "vAIon", vAIon)
log("%50s = %g", "Alfven transit time in OmegaCi", tTransit*omegaCi)
log("%50s = %g", "vte/c", vtElc / lightSpeed)
log("%50s = %g", "vti/c", vtIon / lightSpeed)
log("%50s = %g", "electron plasma frequency (wpe) ", wpe)
log("%50s = %g", "electron cyclotron frequency (OmegaCe) ", omegaCe)
log("%50s = %g", "ion plasma frequency (wpi) ", wpi)
log("%50s = %g", "ion cyclotron frequency (OmegaCi) ", omegaCi)
log("%50s = %g", "electron inertial length (de) ", de)
log("%50s = %g", "ion inertial length (di) ", di)
log("%50s = %g", "electron gyroradius (rhoe) ", rhoe)
log("%50s = %g", "ion gyroradius (rhoi) ", rhoi)
log("%50s = %g", "ion sound gyroradius (rhos) ", rhos)
log("%50s = %g", "antenna one freqeucny (Hz) ", driveFreq1)
log("%50s = %g", "antenna one perpendicular wavelength (m) ", 2*math.pi/kAnt1)
log("%50s = %g", "Number of grid cells per di in z", nz/(Lz/di))
log("%50s = %g", "Number of grid cells per de in z", nz/(Lz/de))
log("%50s = %g", "Number of grid cells per di in x", nr/(2*Lr/di))
log("%50s = %g", "Number of grid cells per de in x", nr/(2*Lr/de))
log("%50s = %g", "tFinal ", tEnd)
log("%50s = %g", "End time in inverse ion cyclotron periods", tEnd*omegaCi)

momentApp = Moments.App.new {

   tEnd = tEnd,
   nFrame = nFrames,
   fieldEnergyCalcs = field_energy_calcs,
   integratedMomentCalcs = integrated_mom_calcs,
   dtFailureTol = dt_failure_tol,
   numFailuresMax = num_failures_max,
   lower = {-Lr, -Lr, LzSt}, -- configuration space lower left
   upper = {Lr, Lr, LzEnd}, -- configuration space upper right
   cells = {nr, nr, nz}, -- configuration space cells
   cflFrac = cfl_frac,

   -- decomposition for configuration space
   decompCuts = {ncx, ncy, ncz}, -- cuts in each configuration direction

   -- boundary conditions for configuration space
   periodicDirs = {}, -- periodic directions

   -- electrons
   elc = Moments.Species.new {
      charge = elcCharge, mass = elcMass,

      equation    = Euler.new { gasGamma = gasGamma },
      -- initial conditions
      init = function (t, xn)
	 local x, y, z = xn[1], xn[2], xn[3]
	 local r = math.sqrt(x*x + y*y)
	 local A = 1.
	 local ne = n0*A
	 local Te = elcTemp*A

	 local vdrift_x = 0.
         local vdrift_y = 0.
         local vdrift_z = 0.

	 local rhoe = ne*elcMass
         local exmom = vdrift_x*rhoe
	 local eymom = vdrift_y*rhoe
         local ezmom = vdrift_z*rhoe
	 local ere = ne*Te/(gasGamma-1) + 0.5*exmom*exmom/rhoe + 0.5*eymom*eymom/rhoe + 0.5*ezmom*ezmom/rhoe
	 
	 return rhoe, exmom, eymom, ezmom, ere
      end,
      evolve = true, -- Evolve species?
      bcx = { Moments.Species.bcWall, Moments.Species.bcWall },
      bcy = { Moments.Species.bcWall, Moments.Species.bcWall },
      bcz = { Moments.Species.bcCopy, Moments.Species.bcCopy },
   },

   -- ions
   ion = Moments.Species.new {
      charge = ionCharge, mass = ionMass,

      equation = Euler.new { gasGamma = gasGamma },
      -- initial conditions
      init = function (t, xn)
	 local x, y, z = xn[1], xn[2], xn[3]
	 local r = math.sqrt(x*x + y*y)
	 local A = 1.
	 local ni = n0*A
	 local Ti = ionTemp*A

       	 local vdrift_x = 0.
         local vdrift_y = 0.
	 local vdrift_z = 0.

	 local rhoi = ni*ionMass
         local ixmom = vdrift_x*rhoi
	 local iymom = vdrift_y*rhoi
         local izmom = vdrift_z*rhoi
	 local eri = ni*Ti/(gasGamma-1) + 0.5*ixmom*ixmom/rhoi + 0.5*iymom*iymom/rhoi + 0.5*izmom*izmom/rhoi
	 
	 return rhoi, ixmom, iymom, izmom, eri

      end,
      evolve = true, -- Evolve species?
      bcx = { Moments.Species.bcWall, Moments.Species.bcWall },
      bcy = { Moments.Species.bcWall, Moments.Species.bcWall },
      bcz = { Moments.Species.bcCopy, Moments.Species.bcCopy },
   },

   field = Moments.Field.new {
      epsilon0 = eps0, mu0 = mu0,
      mgnErrorSpeedFactor = 1.0,

      init = function (t, xn)
         local x, y, z = xn[1], xn[2], xn[3]
	 
         return  0.0, 0.0, 0.0, 0.0, 0.0, 0.0
      end,

      appliedCurrent = function (t, xn)
         local x, y, z = xn[1], xn[2], xn[3]
	 local r = math.sqrt(x*x + y*y)
	 local antTemp = 0.
	 local antSpat = 0.
	 local antSpatShape = 0.
	 local app_x = 0.
	 local app_y = 0.
	 local app_z1 = 0.
 	 local app_z2 = 0.
	 local t1 = 0.
	 local t2 = 0.

	 if t >= tAntOn1 then
	    t1 = t - tAntOn1
	    if (z < antZ1 + dz/2. and z >= antZ1 - dz/2.) then
	       antTemp1 = J01*math.sin(2.*math.pi*driveFreq1*t1)*math.sin(.5*math.pi*math.min(1,t1/antRamp1))^2.*math.cos(0.5*math.pi*math.min(1, math.max(0,(t1-tAntOff1)/antRamp1)))^2.
	       if antOrientation1 == "x" then
               	  antSpat1 =  math.sin(kAnt1*x)
	       	  antSpatShape1 = 0.5*(1 - math.tanh((math.abs(y) - lAnt1/2.)*10/lAnt1))*0.5*(1 - math.tanh((math.abs(x) - 2*lAnt1/3.)*10/lAnt1))
	       else
		  antSpat1 =  math.sin(kAnt1*y)
	       	  antSpatShape1 = 0.5*(1 - math.tanh((math.abs(x) - lAnt1/2.)*10/lAnt1))*0.5*(1 - math.tanh((math.abs(y) - 2*lAnt1/3.)*10/lAnt1))
	       end
	       app_z1 = antTemp1*antSpat1*antSpatShape1
           end
	 end

	 if t >= tAntOn2 then
	    t2 = t - tAntOn2
	    if (z < antZ2 + dz/2. and z >= antZ2 - dz/2.) then
	       antTemp2 = J02*math.sin(2.*math.pi*driveFreq2*t2)*math.sin(.5*math.pi*math.min(1,t2/antRamp2))^2.*math.cos(0.5*math.pi*math.min(1, math.max(0,(t2-tAntOff2)/antRamp2)))^2.
	       if antOrientation2 == "x" then
               	  antSpat2 =  math.sin(kAnt2*x)
	       	  antSpatShape2 = 0.5*(1 - math.tanh((math.abs(y) - lAnt2/2.)*10/lAnt2))*0.5*(1 - math.tanh((math.abs(x) - 2*lAnt2/3.)*10/lAnt2))
	       else
		  antSpat2 =  math.sin(kAnt2*y)
	       	  antSpatShape2 = 0.5*(1 - math.tanh((math.abs(x) - lAnt2/2.)*10/lAnt2))*0.5*(1 - math.tanh((math.abs(y) - 2*lAnt2/3.)*10/lAnt2))
	       end
  	       app_z2 = antTemp2*antSpat2*antSpatShape2
            end
	 end
	 
	 return app_x, app_y, app_z1 + app_z2
      end,
      evolveAppliedCurrent = true, -- Evolve applied current.


      externalFieldInit = function (t, xn)
      	 local x, y, z = xn[1], xn[2], xn[3]
	 local Bz = B0
	 if readBProfile then
	    Bz = linearInterp(BzLAPD, zLAPD, z) / 1e4
	 end
	 return 0., 0., 0., 0., 0., Bz
      end,


      evolve = true, -- Evolve species?
      bcx = { Moments.Field.bcReflect, Moments.Field.bcReflect },
      bcy = { Moments.Field.bcReflect, Moments.Field.bcReflect },
      bcz = { Moments.Field.bcReflect, Moments.Field.bcReflect },    
   },   
}
-- run application
momentApp:run()
