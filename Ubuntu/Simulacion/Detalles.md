# Preparacion de Dinámica


##  Diagrama de flujo

##  Descripccion de pasos 


##  Preparación De automatizacion:
- Crea una carpeta llamada ligandos y coloca todos tus archivos PDB de ligandos ahí
- Coloca tu archivo receptor.pdb en la carpeta principal
- Guarda el script anterior como ejecutar_simulaciones.sh
- Dale permisos de ejecución con chmod +x ejecutar_simulaciones.sh
- Ejecuta el script con ./ejecutar_simulaciones.sh

##  Script:
```bash
#!/bin/bash

# Script para automatizar el flujo de trabajo de dinámica molecular
# para múltiples ligandos con un mismo receptor

# Verificar que existe la carpeta de ligandos
LIGANDS_DIR="ligandos"
if [ ! -d "$LIGANDS_DIR" ]; then
    echo "Error: La carpeta de ligandos ($LIGANDS_DIR) no existe."
    exit 1
fi

# Verificar que existe el archivo del receptor
if [ ! -f "receptor.pdb" ]; then
    echo "Error: El archivo receptor.pdb no existe."
    exit 1
fi

# Preparar el receptor (solo se hace una vez)
echo "Preparando el receptor..."
pdb4amber -i receptor.pdb -o receptor_amber.pdb
mv receptor_amber.pdb receptor_clean.pdb

# Crear archivos de configuración necesarios
echo "Creando archivos de configuración..."

# Archivo de minimización
cat > min.in <<EOF
Minimización
&cntrl
  imin=1, maxcyc=10000, ncyc=5000,
  cut=12.0, ntb=1,
  ntpr=100, ntwx=100,
  ntwr=100,
/
EOF

# Archivo de calentamiento
cat > heat.in <<EOF
Calentamiento de 0 a 310 K
&cntrl
  imin=0, irest=0, ntx=1,
  nstlim=50000, dt=0.002,
  ntc=2, ntf=2,
  cut=12.0, ntb=1,
  ntpr=500, ntwx=500, ntwr=500,
  ntt=3, gamma_ln=1.0,
  tempi=0.0, temp0=310.0,
  nmropt=1,
  iwrap=1,
/
&wt TYPE='TEMP0', istep1=0, istep2=50000,
  value1=0.0, value2=310.0, /
&wt TYPE='END' /
EOF

# Procesar cada ligando en la carpeta
for LIGAND_PDB in $LIGANDS_DIR/*.pdb; do
    # Extraer el nombre del ligando sin extensión
    LIGAND_NAME=$(basename "$LIGAND_PDB" .pdb)
    echo "======================================================"
    echo "Procesando ligando: $LIGAND_NAME"
    echo "======================================================"
    
    # Crear carpeta para este ligando
    LIGAND_DIR="resultados_$LIGAND_NAME"
    mkdir -p "$LIGAND_DIR"
    cp receptor_clean.pdb "$LIGAND_DIR"
    cp "$LIGAND_PDB" "$LIGAND_DIR/ligando.pdb"
    
    # Entrar en la carpeta del ligando
    cd "$LIGAND_DIR"
    
    echo "1. Preparando ligando..."
    # Convertir ligando a mol2 y generar parámetros
    antechamber -i ligando.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -s 2
    parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
    
    echo "2. Creando complejo..."
    # Crear archivo tleap para generar complejo
    cat > complejo_tleap.in <<EOF
source leaprc.protein.ff19SB
source leaprc.gaff
receptor = loadPdb receptor_clean.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod
complex = combine {receptor ligando}
savepdb complex complex.pdb
quit
EOF
    
    # Ejecutar tleap para crear complejo
    tleap -f complejo_tleap.in
    
    echo "3. Solvantando complejo..."
    # Crear archivo tleap para solvatar complejo
    cat > solvatacion.in <<EOF
source leaprc.protein.ff19SB
source leaprc.gaff
source leaprc.water.tip3p 
receptor = loadPdb receptor_clean.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod
complex = loadpdb "complex.pdb"
solvatebox complex TIP3PBOX 12.0 
addions complex Cl- 6
addionsrand complex Na+ 0 Cl- 0.15
saveamberparm complex complex.prmtop complex.inpcrd
savepdb complex complex_solvated.pdb
quit
EOF
    
    # Ejecutar tleap para solvatar complejo
    tleap -f solvatacion.in
    
    echo "4. Minimizando sistema..."
    # Copiar archivo de minimización al directorio actual
    cp ../min.in .
    # Ejecutar minimización
    sander -O -i min.in -o min.out -p complex.prmtop -c complex.inpcrd -r min.rst -x min.nc
    
    echo "5. Calentando sistema..."
    # Copiar archivo de calentamiento al directorio actual
    cp ../heat.in .
    # Ejecutar calentamiento
    sander -O -i heat.in -o heat.out -p complex.prmtop -c min.rst -r heat.rst -x heat.nc -ref min.rst
    
    echo "6. Equilibrando sistema..."
    # Crear archivo de equilibración
    cat > equil.in <<EOF
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
    
    # Ejecutar equilibración
    sander -O -i equil.in -o equil.out -p complex.prmtop -c heat.rst -r equil.rst -x equil.nc -ref heat.rst
    
    echo "7. Ejecutando dinámica molecular productiva..."
    # Crear archivo de producción MD
    cat > prod.in <<EOF
Producción de la dinámica molecular
&cntrl
  imin=0, irest=1, ntx=5,
  nstlim=500000000, dt=0.002,
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
    
    # Ejecutar producción MD (usando GPU si está disponible)
    if command -v pmemd.cuda &> /dev/null; then
        pmemd.cuda -O -i prod.in -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
    else
        sander -O -i prod.in -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
    fi
    
    echo "¡Simulación completada para ligando $LIGAND_NAME!"
    
    # Volver a la carpeta principal
    cd ..
done

echo "¡Todas las simulaciones han sido completadas!"
```


## Referencias
- [Simple Simulation of Alanine Dipeptide](https://ambermd.org/tutorials/basic/tutorial0/index.php)
- [Gaussian field-based 3D-QSAR and molecular simulation studies to design potent pyrimidine–sulfonamide hybrids as selective BRAFV600E inhibitors](https://pubs.rsc.org/en/content/articlepdf/2022/ra/d2ra05751d)

