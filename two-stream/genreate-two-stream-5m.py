import argparse

def restricted_value(dtype, lo=None, up=None):
    """Check if a value can be interpreated as a valid value of the specified type,
    dtype, and if the value is within the given inclusive range [lo, up].
    """
    def func(x, dtype=dtype, lo=lo, up=up):
        try:
            x = dtype(x)
        except ValueError:
            raise argparse.ArgumentTypeError(f"{x} not a floating-point literal")

        if lo is not None:
            try:
                lo = dtype(lo)
            except:
                raise ValueError(f"lo {lo} is not a valid value of type {dtype}")
            if x < lo:
                raise argparse.ArgumentTypeError(
                        f"{x} is smaller than the lower limit {lo}"
                        )

        if up is not None:
            try:
                up = dtype(up)
            except:
                raise ValueError(f"up {up} is not a valid value of type {dtype}")
            if x > up:
                raise argparse.ArgumentTypeError(
                        f"{x} is greater than the upper limit {up}"
                        )

        return x

    return func

parser = argparse.ArgumentParser(
    description=(
        "Generate gkyl input file of the 5-moment simulation of two-stream instability."
    )
)
parser.add_argument("filename", help="name of the gkyl lua input file to be generated")
parser.add_argument(
    "--vDrift__vTe",
    default=5.0,
    type=restricted_value(float, 0.1, 100.0),
    help="drift velocity / thermal velocity",
)
parser.add_argument(
    "--kx_de",
    default=0.1,
    type=restricted_value(float, 0.01, 100.0),
    help="wavenumber * Debye length",
)
parser.add_argument(
    "--pert",
    default=1e-3,
    type=restricted_value(float, 1e-10, 1.0),
    help="perturbation magnitude to the uniform background density",
)
parser.add_argument(
    "--tEnd_wpe",
    default=40.0,
    type=restricted_value(float, 5.0, 250.0),
    help="simulation time * plasma frequency",
)
parser.add_argument(
    "--nFrame",
    default=10,
    type=restricted_value(int, 1, 200),
    help="number of output frames excluding the initial condition",
)
parser.add_argument(
    "--Nx",
    default=128,
    type=restricted_value(int, 8, 2560),
    help="number of cells for discretization",
)
parser.add_argument(
    "--nProcs",
    default=1,
    type=restricted_value(int, 8, 2560),
    help="number of processors for parallel computing",
)
args = parser.parse_args()

print(f"\n{args}\n")

input_str = """
-- 1d 5-moment simulation of two-stream instability with two counter-streaming electron
-- species, with an immobile ion species (that is not evolved).
--
-- 1. Note that though the problem is essentially electrostatic, i.e., without any
-- magnetic fluctuations expected to develop, the model being used here is
-- electromagnetic. In this case, magnetic fluctuations will be no more than the machine
-- error. It is critical to note that using an EM model to mimic a ES problem does not
-- always work. It works in this case because it is 1d and there is no net current.
--
-- 2. This input deck allows the user to specify the wavenumber, and then the domain
-- length is set to fit exactly one wavelength.
--
-- 3. One educational study is to vary the value of vDrift and / or the wavenumber to
-- compare the growth rates.

------------------------
-- SETTING PARAMETERS --
------------------------

-- Parameters that should not be changed
gasGamma = 3.0 -- adiabatic gas gamma, typically (f+3) / f where if is degree of freedom
-- Light speed is needed for any EM simulation. A large value is chosen to minimize the
-- impact of the EM effects over ES effects.
lightSpeed = 100.0
epsilon0 = 1.0 -- vacuum permittivity

-- Properties of the streaming species (assumed to beelectron). Note that the following
-- values lead to Debye length and plasma frequency of numerical values 1.
vTe = 1.0 -- thermal velocity
n = 1.0 -- background number density
me = 1.0 -- mass
qe = -1.0 -- charge

-- Physical parameters intended to be changed for parameter scanning
vDrift__vTe = {vDrift__vTe} -- drift velocity / thermal velocity
kx_de = {kx_de} -- wavenumber * Debye length
pert = {pert} -- perturbation magnitude to the uniform background density

-- Computational paremters
nProcs = {nProcs} -- number of processors for parallel computing
tEnd_wpe = {tEnd_wpe} -- simulation time * plasma frequency
nFrame = {nFrame} -- number of output frames excluding the initial condition
Nx = {Nx} -- number of cells for discretization

-- Derived parameters
mu0 = 1 / lightSpeed^2 / epsilon0 -- vacuum permeability
vDrift = vDrift__vTe * vTe -- drift velocity
T = me * vTe^2 -- temperature
de = math.sqrt(epsilon0 / qe^2 * T / n) -- Debye length
kx = kx_de / de -- wavenumber
Lx = math.pi / kx -- domain length
wpe = math.sqrt(n * qe^2 / me / epsilon0) -- plasma frequency
tEnd = tEnd_wpe / wpe

-----------------------------------
-- SHOWING SIMULATION PARAMETERS --
-----------------------------------

local Logger = require "Logger"
local logger = Logger {{logToFile = True}}
local log = function(...) logger(string.format(...).."\\n") end

log("")
log("%30s = %g, %g", "Debye length, plasma frequency", de, wpe)
log("%30s = %g, %g", "vDrift / vTe, vDrift", vDrift / vTe, vDrift)
log("%30s = %g, %g", "kx * Debye length", kx * de, kx)
log("%30s = %g, %g", "tEnd * Plasma frequency", tEnd * wpe, tEnd)
log("%30s = %g", "perturbation level", pert)
log("%30s = %g", "Nx", Nx)
log("%30s = %g", "nFrame", nFrame)
log("%30s = %g", "tEnd / nFrame", tEnd / nFrame)
log("%30s = %g", "lightSpeed / vTe", lightSpeed / vTe)
log("")

----------------------------------------
-- CREATING AND RUNNING THE GKYL APPS --
----------------------------------------

local Moments = require("App.PlasmaOnCartGrid").Moments()
local Euler = require "Eq.Euler"

app = Moments.App {{

   tEnd = tEnd, -- end of simulation time
   nFrame = nFrame, -- number of output frames
   lower = {{0}}, -- lower limit of domain
   upper = {{Lx}}, -- upper limit of domain
   cells = {{Nx}}, -- number of cells to discretize the domain
   decompCuts = {{nProcs}}, -- domain decomposition
   periodicDirs = {{1}}, -- directions with periodic boundary conditions; 1:x, 2:y, 3:z
   timeStepper = "fvDimSplit", -- dimensional-splitting finite-volume algorithm
   logToFile = true,

   -- right-going species
   e1 = Moments.Species {{
      charge = qe,
      mass = me,
      equation = Euler {{ gasGamma = gasGamma }},
      equationInv = Euler {{ gasGamma = gasGamma, numericalFlux = "lax" }},
      init = function(t, xn)
         local x = xn[1]
         
         local rho = n * me
         local vx = vDrift
         local vy = 0
         local vz = 0
         local p = n * T * (1 + pert * math.cos(kx * x))
         local e = p / (gasGamma-1) + 0.5 * rho * (vx*vx + vy*vy + vz*vz)

         return rho, rho*vx, rho*vy, rho*vz, e
      end,
      evolve = true,
   }},

   -- left-going species
   e2 = Moments.Species {{
      charge = qe,
      mass = me,
      equation = Euler {{ gasGamma = gasGamma }},
      equationInv = Euler {{ gasGamma = gasGamma, numericalFlux = "lax" }},
      init = function(t, xn)
         local x = xn[1]
         
         local rho = n * me
         local vx = -vDrift
         local vy = 0
         local vz = 0
         local p = n * T
         local e = p / (gasGamma-1) + 0.5 * rho * (vx*vx + vy*vy + vz*vz)

         return rho, rho*vx, rho*vy, rho*vz, e
      end,
      evolve = true,
   }},

   field = Moments.Field {{
      epsilon0 = epsilon0,
      mu0 = mu0,
      init = function (t, xn)
         local x = xn[1]
         local Ex, Ey, Ez = 0, 0, 0
         local Bx, By, Bz = 0, 0, 0
         local phiE, PhiB = 0, 0
         return Ex, Ey, Ez, Bx, By, Bz, phiE, phiB
      end,
      evolve = true,
   }},

   emSource = Moments.CollisionlessEmSource {{
      species = {{"e1", "e2"}},
      timeStepper = "direct",
   }},   

}}

app:run()
""".format(
    **vars(args)
)

with open(args.filename, "w") as script_file:
    script_file.write(input_str)
