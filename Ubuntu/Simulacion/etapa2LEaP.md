# Etapa 2 Solvantar Complejo


```bash
tleap
source leaprc.protein.ff19SB
source leaprc.gaff
source leaprc.water.tip3p 

receptor = loadPdb receptor_clean.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod
complex = loadpdb "complex.pdb"


solvatebox complex TIP3PBOX 12.0 
addions complex Na+ 
addions complex Cl- 6

saveamberparm complex complex.prmtop complex.inpcrd
savepdb complex complex_solvated.pdb

quit
```
