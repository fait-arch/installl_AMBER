# Etapa 2 Solvantar Complejo
Crear el archivo **solvatacion.in** o el visor 

```bash 
cat > solvatacion.in <<EOF
tleap
source leaprc.protein.ff19SB
source leaprc.gaff
source leaprc.water.tip3p 

# Cargar el receptor con el estado de protonación adecuado
receptor = loadPdb receptor_amber.pdb

# Cargar el ligando con la parametrización de GAFF
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod

# Cargar el complejo ya ensamblado
complex = combine {receptor ligando}

# Solvatación con agua TIP3P en una caja de 12 Å
solvatebox complex TIP3PBOX 12.0 

# Neutralización con Cl- y adición de Na+ y Cl- para 0.15 M de concentración salina
addions complex Cl- 6
addionsRand complex Na+ 0
addionsRand complex Cl- 0

# Guardar los archivos de parámetros y coordenadas
saveamberparm complex complex.prmtop complex.inpcrd
savepdb complex complex_solvated.pdb

quit

EOF
```

Ejecutar:
```bash
tleap -f solvatacion.in
```
