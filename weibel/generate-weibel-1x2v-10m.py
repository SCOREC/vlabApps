import argparse


def restricted_value(dtype, lo=None, up=None):
    """Check if a value can be interpreated as a valid value of the specified type,
    dtype, and if the value is within the given inclusive range [lo, up].
    """

    def func(x, dtype=dtype, lo=lo, up=up):
        try:
            x = dtype(x)
        except ValueError:
            raise argparse.ArgumentTypeError(f"{x} not a valid value of type {dtype}")

        if lo is not None:
            try:
                lo = dtype(lo)
            except:
                raise ValueError(f"lo {lo} not a valid value of type {dtype}")
            if x < lo:
                raise argparse.ArgumentTypeError(
                    f"{x} is smaller than the lower limit {lo}"
                )

        if up is not None:
            try:
                up = dtype(up)
            except:
                raise ValueError(f"up {up} not a valid value of type {dtype}")
            if x > up:
                raise argparse.ArgumentTypeError(
                    f"{x} is greater than the upper limit {up}"
                )

        return x

    return func


parser = argparse.ArgumentParser(
    description=(
        "Generate gkyl input file of the 10-moment simulation of weibel instability."
    )
)

parser.add_argument("filename", help="name of the gkyl lua input file to be generated")
parser.add_argument(
    "--vTe__c",
    "--vTe__lightSpeed",
    default=0.0,
    type=restricted_value(float, 0.001, 0.6),
    help="hermal velocity of either species / speed of light",
)
parser.add_argument(
    "--uxElc10__vTe",
    default=0.0,
    type=restricted_value(float, -10.0, 10.0),
    help="drift velocity / thermal velocity, first species, x-component",
)
parser.add_argument(
    "--uyElc10__vTe",
    default=3.0,
    type=restricted_value(float, -10.0, 10.0),
    help="drift velocity / thermal velocity, first species, x-component",
)
parser.add_argument(
    "--uxElc20__vTe",
    default=0.0,
    type=restricted_value(float, -10.0, 10.0),
    help="drift velocity / thermal velocity, second species, y-component",
)
parser.add_argument(
    "--uyElc20__vTe",
    default=-3.0,
    type=restricted_value(float, -10.0, 10.0),
    help="drift velocity / thermal velocity, second species, y-component",
)
parser.add_argument(
    "--kx_de",
    default=0.04,
    type=restricted_value(float, 0.001, 10.0),
    help=(
        "wavenumber * Debye length (based on total density of both streaming species "
        "and their identical temperature)",
    ),
)
parser.add_argument(
    "--pert",
    default=1e-6,
    type=restricted_value(float, 1e-10, 1.0),
    help="perturbation magnitude to the uniform background density",
)
parser.add_argument(
    "--tEnd_wpe",
    default=50.0,
    type=restricted_value(float, 5.0, 250.0),
    help=(
        "simulation time * plasma frequency (based on the total density of both "
        "streaming species)"
    ),
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

-- 1d 10-moment simulation of weibel instability in the x domain with two electron
-- species streaming in the y direction and an sinoidal B field perturbation along z.
--
-- 1. This input deck allows the user to specify the wavenumber, and then the domain
-- length is set to fit exactly one wavelength.
--
-- 2. One educational study is to vary the value of streaming velocities and/or the
-- wavenumber to compare the growth rates.

------------------------
-- SETTING PARAMETERS --
------------------------

-- Parameters that should not be changed
gasGamma = 3.0 -- adiabatic gas gamma, typically (f+3) / f where if is degree of freedom
-- Light speed is needed for any EM simulation.
lightSpeed = 1.0
epsilon0 = 1.0 -- vacuum permittivity

-- Properties of the streaming species (assumed to be electrons).
n = 1.0 -- total background number density of the two streaming species
me = 1.0 -- mass
qe = -1.0 -- charge

-- Physical parameters intended to be changed for parameter scanning
vTe = 0.1 -- thermal velocity
kx_de = {kx_de} -- wavenumber * Debye length
pert = {pert} 
uxElc10__vTe, uyElc10__vTe = {uxElc10__vTe}, {uyElc10__vTe} 
uxElc20__vTe, uyElc20__vTe = {uxElc20__vTe}, {uyElc20__vTe}

-- Computational paremters
nProcs = {nProcs} -- number of processors for parallel computing
tEnd_wpe = {tEnd_wpe} -- simulation time * plasma frequency
nFrame = {nFrame} -- number of output frames excluding the initial condition
Nx = {Nx} -- number of cells for discretization

-- Derived parameters
mu0 = 1 / lightSpeed^2 / epsilon0 -- vacuum permeability

nElc10, nElc20 = n * 0.5, n * 0.5 -- number densities of the two streaming species
T = me * vTe^2 -- the identical temperatures of the two streaming species
TElc10, TElc20 = T, T

uxElc10 = uxElc10__vTe * vTe -- drift velocity, first species, x-component
uyElc10 = uyElc10__vTe * vTe -- drift velocity, first species, y-component
uzElc10 = 0.0 -- drift velocity, first species, z-component

uxElc20 = uxElc10__vTe * vTe -- drift velocity, second species, x-component
uyElc20 = uyElc10__vTe * vTe -- drift velocity, second species, y-component
uzElc20 = 0.0 -- drift velocity, second species, z-component

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
log("%30s = %g, %g", "uxElc10 / vTe, uxElc10", uxElc10 / vTe, uxElc10)
log("%30s = %g, %g", "uyElc10 / vTe, uyElc20", uyElc10 / vTe, uyElc20)
log("%30s = %g, %g", "uxElc20 / vTe, uxElc10", uxElc20 / vTe, uxElc10)
log("%30s = %g, %g", "uzElc20 / vTe, uyElc20", uyElc20 / vTe, uyElc20)
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
local TenMoment = require "Eq.TenMoment"

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

   e1 = Moments.Species {{
      charge = qe,
      mass = me,
      equation = TenMoment {{}},
      equationInv = TenMoment {{ numericalFlux = "lax" }},
      init = function (t, xn)
         local x = xn[1]

         local rho = me * nElc10
         local ux, uy, uz = uxElc10, uyElc10, 0.0
         local p = nElc10 * TElc10

         local pxx = rho * ux * ux + p
         local pxy = rho * ux * uy
         local pxz = rho * ux * uz
         local pyy = rho * uy * uy + p
         local pyz = rho * uy * uz
         local pzz = rho * uz * uz + p

         return rho, rho*ux, rho*uy, rho*uz, pxx, pxy, pxz, pyy, pyz, pzz
      end,
   }},

   -- Electrons.
   e2 = Moments.Species {{
      charge = qe,
      mass = me,
      equation = TenMoment {{}},
      equationInv = TenMoment {{ numericalFlux = "lax" }},
      init = function (t, xn)
         local x = xn[1]

         local rho = me * nElc20
         local ux, uy, uz = uxElc20, uyElc20, 0.0
         local p = nElc20 * TElc20

         local pxx = rho * ux * ux + p
         local pxy = rho * ux * uy
         local pxz = rho * ux * uz
         local pyy = rho * uy * uy + p
         local pyz = rho * uy * uz
         local pzz = rho * uz * uz + p

         return rho, rho*ux, rho*uy, rho*uz, pxx, pxy, pxz, pyy, pyz, pzz
      end,
   }},

   field = Moments.Field {{
      epsilon0 = epsilon0,
      mu0 = mu0,
      init = function (t, xn)
         local x = xn[1]
         local Ex, Ey, Ez = 0, 0, 0
         local Bx, By = 0, 0
         local Bz = pert * math.sin(kx * x)
         local phiE, PhiB = 0, 0
         return Ex, Ey, Ez, Bx, By, Bz, phiE, phiB
      end,
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
