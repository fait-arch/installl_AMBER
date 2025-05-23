#!/bin/bash

# 1_preparacion.sh - Script para automatizar la preparación de estructuras para simulación molecular


# Función para registrar el tiempo y uso de recursos
log_performance() {
    local stage=$1
    local start_time=$2
    local end_time=$3
    local duration=$(echo "$end_time - $start_time" | bc)
    
    # Obtener estadísticas de CPU y memoria
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    local mem_usage=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')
    
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $stage - Duración: ${duration}s - CPU: ${cpu_usage}% - Memoria: ${mem_usage}" >> preparacion_performance.log
}

# Crear archivo de registro
echo "# Registro de rendimiento de preparación molecular" > preparacion_performance.log
echo "# Iniciado en: $(date +'%Y-%m-%d %H:%M:%S')" >> preparacion_performance.log
echo "# Sistema: $(uname -a)" >> preparacion_performance.log
echo "-------------------------------------------------------------" >> preparacion_performance.log
echo "Timestamp - Etapa - Duración - CPU - Memoria" >> preparacion_performance.log
echo "-------------------------------------------------------------" >> preparacion_performance.log

# Verificar que los archivos necesarios existen
if [ ! -f "receptor.pdb" ] || [ ! -f "ligand.pdb" ]; then
    echo "ERROR: No se encontraron los archivos receptor.pdb y/o ligand.pdb"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: Archivos de entrada no encontrados" >> preparacion_performance.log
    exit 1
fi

# Etapa 1: Preparación del Receptor
echo "=== ETAPA 1: PREPARACIÓN DEL RECEPTOR ==="
start_time=$(date +%s)

echo "Ejecutando pdb4amber para procesar el receptor..."
pdb4amber -i receptor.pdb -o receptor_amber.pdb
status=$?

if [ $status -ne 0 ]; then
    echo "ERROR: El procesamiento del receptor ha fallado con código de error $status"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: pdb4amber falló con código $status" >> preparacion_performance.log
    exit 1
fi

end_time=$(date +%s)
log_performance "Preparación del Receptor" $start_time $end_time
echo "Preparación del receptor completada en $((end_time - start_time)) segundos"

# Etapa 2: Preparación del Ligando
echo "=== ETAPA 2: PREPARACIÓN DEL LIGANDO ==="
start_time=$(date +%s)

echo "Ejecutando antechamber para procesar el ligando..."
antechamber -i ligand.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -s 2
status=$?

if [ $status -ne 0 ]; then
    echo "ERROR: El procesamiento del ligando con antechamber ha fallado con código de error $status"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: antechamber falló con código $status" >> preparacion_performance.log
    exit 1
fi

echo "Ejecutando parmchk2 para generar parámetros del ligando..."
parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
status=$?

if [ $status -ne 0 ]; then
    echo "ERROR: La generación de parámetros con parmchk2 ha fallado con código de error $status"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: parmchk2 falló con código $status" >> preparacion_performance.log
    exit 1
fi

end_time=$(date +%s)
log_performance "Preparación del Ligando" $start_time $end_time
echo "Preparación del ligando completada en $((end_time - start_time)) segundos"

# Etapa 3: Creación del Complejo
echo "=== ETAPA 3: CREACIÓN DEL COMPLEJO ==="
start_time=$(date +%s)

echo "Creando archivo de entrada para tleap..."
# Corrección: El formato correcto para el archivo de entrada de tleap
cat > complejo_tleap.in <<EOF
source leaprc.protein.ff19SB
source leaprc.gaff

receptor = loadPdb receptor_amber.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod

complex = combine {receptor ligando}
savepdb complex complex.pdb

quit
EOF

echo "Ejecutando tleap para crear el complejo..."
tleap -f complejo_tleap.in
status=$?

if [ $status -ne 0 ]; then
    echo "ERROR: La creación del complejo ha fallado con código de error $status"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: tleap para el complejo falló con código $status" >> preparacion_performance.log
    exit 1
fi

end_time=$(date +%s)
log_performance "Creación del Complejo" $start_time $end_time
echo "Creación del complejo completada en $((end_time - start_time)) segundos"

# Etapa 4: Solvatación del Complejo
echo "=== ETAPA 4: SOLVATACIÓN DEL COMPLEJO ==="
start_time=$(date +%s)

echo "Creando archivo de entrada para solvatación..."
cat > solvatacion.in <<EOF
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

echo "Ejecutando tleap para solvatar el complejo..."
tleap -f solvatacion.in
status=$?

if [ $status -ne 0 ]; then
    echo "ERROR: La solvatación del complejo ha fallado con código de error $status"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: tleap para solvatación falló con código $status" >> preparacion_performance.log
    exit 1
fi

end_time=$(date +%s)
log_performance "Solvatación del Complejo" $start_time $end_time
echo "Solvatación del complejo completada en $((end_time - start_time)) segundos"

# Añadir resumen de la preparación completa
total_start_time=$(grep "Iniciado en" preparacion_performance.log | cut -d':' -f2- | xargs)
total_end_time=$(date +'%Y-%m-%d %H:%M:%S')
echo "-------------------------------------------------------------" >> preparacion_performance.log
echo "# Preparación completa" >> preparacion_performance.log
echo "# Inicio: $total_start_time" >> preparacion_performance.log
echo "# Fin: $total_end_time" >> preparacion_performance.log
echo "# Duración total: $(( $(date +%s) - $(date -d "$total_start_time" +%s) )) segundos" >> preparacion_performance.log

echo "=== PREPARACIÓN MOLECULAR COMPLETA ==="
echo "Se ha generado un registro de rendimiento en 'preparacion_performance.log'"
echo "Archivos generados:"
echo "- receptor_amber.pdb: Receptor procesado"
echo "- ligando.mol2: Ligando procesado"
echo "- ligando.frcmod: Parámetros del ligando"
echo "- complex.pdb: Complejo receptor-ligando"
echo "- complex.prmtop: Topología del complejo solvatado"
echo "- complex.inpcrd: Coordenadas del complejo solvatado"
echo "- complex_solvated.pdb: Complejo solvatado en formato PDB"
