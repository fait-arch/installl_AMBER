#!/bin/bash

# AMBER Molecular Dynamics Automation Script - VERSION CORREGIDA
# This script automates the entire process of preparing a protein-ligand complex
# and running molecular dynamics simulations using AMBER tools

# Check if input files exist
if [ ! -f receptor.pdb ] || [ ! -f ligand.pdb ]; then
  echo "Error: receptor.pdb or ligand.pdb not found!"
  echo "Please make sure these files are in the current directory."
  exit 1
fi

echo "============================================================="
echo "STEP 1: PREPARING INPUT STRUCTURES"
echo "============================================================="

# Prepare receptor structure
echo "Preparing receptor structure..."
pdb4amber -i receptor.pdb -o receptor_amber.pdb
if [ ! -f receptor_amber.pdb ]; then
  echo "Error: Failed to create receptor_amber.pdb"
  exit 1
fi

# Prepare ligand structure
echo "Preparing ligand structure..."
antechamber -i ligand.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -s 2
if [ ! -f ligando.mol2 ]; then
  echo "Error: Failed to create ligando.mol2"
  exit 1
fi

parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
if [ ! -f ligando.frcmod ]; then
  echo "Error: Failed to create ligando.frcmod"
  exit 1
fi

# Create complex
cat >complex_tleap.in <<EOF
receptor = loadPdb receptor_amber.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod
complex = combine {receptor ligando}
savepdb complex complex.pdb
quit
EOF
tleap -f complex_tleap.in
if [ ! -f complex.pdb ]; then
  echo "Error: Failed to create complex.pdb"
  exit 1
fi

echo "============================================================="
echo "STEP 2: SOLVATING THE COMPLEX"
echo "============================================================="

# Solvate complex
cat >solvatacion.in <<EOF
source leaprc.protein.ff19SB
source leaprc.gaff
source leaprc.water.tip3p 
receptor = loadPdb receptor_amber.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod
complex = combine {receptor ligando}
solvatebox complex TIP3PBOX 12.0 
addions complex Cl- 6
addionsRand complex Na+ 0
addionsRand complex Cl- 0
saveamberparm complex complex.prmtop complex.inpcrd
savepdb complex complex_solvated.pdb
quit
EOF

tleap -f solvatacion.in
if [ ! -f complex.prmtop ] || [ ! -f complex.inpcrd ]; then
  echo "Error: Failed to create complex.prmtop or complex.inpcrd"
  exit 1
fi

echo "============================================================="
echo "STEP 3: MINIMIZATION"
echo "============================================================="

# Create minimization input file
cat >min.in <<EOF
Minimización del sistema
&cntrl
  imin=1, ntx=1, irest=0,
  maxcyc=10000, ncyc=4000,
  ntb=1, cut=11.0,
  ntc=2, ntf=2, igb=0,
  ntr=1, restraint_wt=10.0, restraintmask='@CA',
  nmropt=0,
  ntr=1,
/
EOF
# Run minimization
echo "Running energy minimization..."
sander -O -i min.in -o min.out -p complex.prmtop -c complex.inpcrd -r min.rst -ref complex.inpcrd
if [ ! -f min.rst ]; then
  echo "Error: Minimization failed!"
  exit 1
fi

echo "============================================================="
echo "STEP 4: HEATING"
echo "============================================================="

# Create heating input file
cat >heat.in <<EOF
Calentamiento de 0 K a 310 K en 500 ps
&cntrl
  imin=0, irest=0, ntx=1,
  nstlim=250000, dt=0.002,
  tempi=0.0, temp0=310.0,
  ntb=1, cut=11.0,
  ntc=2, ntf=2,
  ntp=0,
  ntpr=1000, ntwx=1000, ntwr=1000,
  ntt=3, gamma_ln=1.0,
  iwrap=1,
/
EOF
# Run heating
echo "Running heating phase..."
sander -O -i heat.in -o heat.out -p complex.prmtop -c min.rst -r heat.rst -x heat.nc -ref min.rst
if [ ! -f heat.rst ]; then
  echo "Error: Heating phase failed!"
  exit 1
fi

echo "============================================================="
echo "STEP 5: EQUILIBRATION"
echo "============================================================="

# Create equilibration input file
cat >equil.in <<EOF
Equilibración a 310 K y 1 atm
&cntrl
  imin=0, irest=1, ntx=5,
  nstlim=250000, dt=0.002,
  temp0=310.0,
  ntb=2, pres0=1.0, taup=2.0,
  ntp=1,
  ntc=2, ntf=2,
  cut=11.0,
  ntpr=1000, ntwx=1000, ntwr=1000,
  ntt=3, gamma_ln=1.0,
  iwrap=1,
/
EOF

# Run equilibration
echo "Running equilibration phase..."
sander -O -i equil.in -o equil.out -p complex.prmtop -c heat.rst -r equil.rst -x equil.nc -ref heat.rst
if [ ! -f equil.rst ]; then
  echo "Error: Equilibration phase failed!"
  exit 1
fi

echo "============================================================="
echo "STEP 6: PRODUCTION MD"
echo "============================================================="

# Create production MD input file
cat >md.in <<EOF
Producción de la dinámica molecular
&cntrl
  imin=0, irest=1, ntx=5,
  nstlim=500000000, dt=0.002, // 500.000
  temp0=310.0,
  ntb=2, pres0=1.0, taup=2.0,
  ntp=1,
  ntc=2, ntf=2,
  cut=11.0,
  ntpr=1000, ntwx=1000, ntwr=1000,
  ntt=3, gamma_ln=1.0,
  iwrap=1,
  nmropt=0,
/
EOF
# Check if CUDA version is available
if command -v pmemd.cuda &>/dev/null; then
  echo "Running production MD using GPU acceleration (pmemd.cuda)..."
  pmemd.cuda -O -i prod.in -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
else
  echo "Running production MD using CPU (pmemd)..."
  echo "Note: For better performance, consider using pmemd.cuda if a GPU is available."
  sander -O -i prod.in -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
fi

if [ ! -f md.rst ]; then
  echo "Error: Production MD failed!"
  exit 1
fi

echo "============================================================="
echo "WORKFLOW COMPLETED SUCCESSFULLY!"
echo "============================================================="
echo "Summary of generated files:"
echo "- Complex structure: complex_solvated.pdb"
echo "- Minimization results: min.out, min.rst"
echo "- Heating results: heat.out, heat.rst, heat.nc"
echo "- Equilibration results: equil.out, equil.rst, equil.nc"
echo "- Production MD results: md.out, md.rst, md.nc"
echo ""
echo "You can now analyze the MD trajectory using tools like cpptraj or VMD."
