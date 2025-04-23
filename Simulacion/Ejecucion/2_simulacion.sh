#!/bin/bash

# Script de automatización para el flujo de trabajo completo de SANDER
# Este script ejecuta las etapas de minimización, calentamiento, equilibración y producción
# y registra métricas de rendimiento en tiempo real

# Nombre del archivo de registro
LOG_FILE="sander_performance.log"
START_TIME_GLOBAL=$(date +%s)

# Función para crear archivos de entrada
create_input_files() {
    echo "Creando archivos de entrada para las simulaciones..."
    
    # Archivo de minimización
    cat > min.in <<EOF
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

    # Archivo de calentamiento
    cat > heat.in <<EOF
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

    # Archivo de equilibración
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

    # Archivo de producción MD
    cat > md.in <<EOF
Producción de la dinámica molecular
&cntrl
  imin=0, irest=1, ntx=5,
  nstlim=500000, dt=0.002,
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
}

# Función para inicializar el archivo de registro
initialize_log() {
    echo "=== Registro de rendimiento de SANDER - $(date) ===" > $LOG_FILE
    echo "Sistema: $(uname -a)" >> $LOG_FILE
    echo "CPU: $(grep "model name" /proc/cpuinfo | head -n 1 | cut -d':' -f2 | sed 's/^[ \t]*//')" >> $LOG_FILE
    echo "Memoria total: $(free -h | grep Mem | awk '{print $2}')" >> $LOG_FILE
    echo "" >> $LOG_FILE
    echo "┌─────────────────────────────────────────────────────────────────────────┐" >> $LOG_FILE
    echo "│                 RESUMEN DE LA SIMULACIÓN MOLECULAR                      │" >> $LOG_FILE
    echo "├──────────────┬──────────┬────────────┬────────────┬────────────────────┤" >> $LOG_FILE
    echo "│    Etapa     │  Tiempo  │ CPU (prom) │ Mem (prom) │     Estado         │" >> $LOG_FILE
    echo "├──────────────┼──────────┼────────────┼────────────┼────────────────────┤" >> $LOG_FILE
}

# Función para monitorear recursos durante la ejecución
monitor_resources() {
    local pid=$1
    local stage=$2
    local cpu_usage=()
    local mem_usage=()
    
    # Monitorear el proceso mientras se ejecuta
    while kill -0 $pid 2>/dev/null; do
        local cpu=$(ps -p $pid -o %cpu | tail -n 1 | tr -d ' ')
        local mem=$(ps -p $pid -o %mem | tail -n 1 | tr -d ' ')
        
        cpu_usage+=($cpu)
        mem_usage+=($mem)
        
        # Actualizar el estado en tiempo real
        echo -ne "Ejecutando $stage... CPU: ${cpu}%, Memoria: ${mem}%   \r"
        
        sleep 1
    done
    
    # Calcular promedios
    local sum_cpu=0
    local sum_mem=0
    local count=${#cpu_usage[@]}
    
    for i in "${cpu_usage[@]}"; do
        sum_cpu=$(echo "$sum_cpu + $i" | bc -l)
    done
    
    for i in "${mem_usage[@]}"; do
        sum_mem=$(echo "$sum_mem + $i" | bc -l)
    done
    
    local avg_cpu=$(echo "scale=2; $sum_cpu / $count" | bc -l)
    local avg_mem=$(echo "scale=2; $sum_mem / $count" | bc -l)
    
    echo "$avg_cpu $avg_mem"
}

# Función para ejecutar una etapa de la simulación
run_stage() {
    local stage=$1
    local command=$2
    local status="Completado"
    
    echo "Iniciando etapa: $stage"
    echo "Comando: $command"
    
    # Registrar tiempo de inicio
    local start_time=$(date +%s)
    
    # Ejecutar el comando en segundo plano
    eval $command &
    local pid=$!
    
    # Monitorear recursos
    local resources=$(monitor_resources $pid "$stage")
    local avg_cpu=$(echo $resources | cut -d' ' -f1)
    local avg_mem=$(echo $resources | cut -d' ' -f2)
    
    # Esperar a que termine el proceso
    wait $pid
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        status="Error ($exit_code)"
    fi
    
    # Calcular tiempo de ejecución
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_fmt=$(printf "%dh:%dm:%ds" $((duration/3600)) $((duration%3600/60)) $((duration%60)))
    
    # Registrar en el archivo de log
    printf "│ %-12s │ %-8s │ %-10s │ %-10s │ %-18s │\n" "$stage" "$duration_fmt" "${avg_cpu}%" "${avg_mem}%" "$status" >> $LOG_FILE
    
    echo ""
    echo "Etapa $stage completada en $duration_fmt. CPU: ${avg_cpu}%, Memoria: ${avg_mem}%"
    echo "Estado: $status"
    echo ""
    
    return $exit_code
}

# Función para finalizar el registro
finalize_log() {
    local end_time_global=$(date +%s)
    local total_duration=$((end_time_global - START_TIME_GLOBAL))
    local total_duration_fmt=$(printf "%dh:%dm:%ds" $((total_duration/3600)) $((total_duration%3600/60)) $((total_duration%60)))
    
    echo "├──────────────┴──────────┴────────────┴────────────┴────────────────────┤" >> $LOG_FILE
    echo "│ Tiempo total de ejecución: $total_duration_fmt                            │" >> $LOG_FILE
    echo "└─────────────────────────────────────────────────────────────────────────┘" >> $LOG_FILE
    
    # Calcular estimación de coste computacional (ejemplo)
    local cpu_hours=$(echo "scale=2; $total_duration / 3600" | bc -l)
    echo "" >> $LOG_FILE
    echo "Estimación de coste computacional:" >> $LOG_FILE
    echo "- CPU-horas: $cpu_hours" >> $LOG_FILE
    echo "- Fecha finalización: $(date)" >> $LOG_FILE
}

# Función principal
main() {
    # Verificar la presencia de archivos necesarios
    if [ ! -f "complex.prmtop" ] || [ ! -f "complex.inpcrd" ]; then
        echo "Error: Archivos de topología (complex.prmtop) o coordenadas (complex.inpcrd) no encontrados."
        exit 1
    fi
    
    # Crear los archivos de entrada
    create_input_files
    
    # Inicializar el archivo de registro
    initialize_log
    
    # Verificar que SANDER está instalado
    if ! command -v sander &> /dev/null; then
        echo "Error: SANDER no está instalado o no se encuentra en el PATH."
        echo "│ GLOBAL       │    --    │     --     │     --     │ Error: SANDER no disponible │" >> $LOG_FILE
        finalize_log
        exit 1
    fi
    
    # Ejecutar minimización
    run_stage "Minimización" "sander -O -i min.in -o min.out -p complex.prmtop -c complex.inpcrd -r min.rst -ref complex.inpcrd"
    if [ $? -ne 0 ]; then
        echo "Error en la etapa de minimización. Abortando."
        finalize_log
        exit 1
    fi
    
    # Ejecutar calentamiento
    run_stage "Calentamiento" "sander -O -i heat.in -o heat.out -p complex.prmtop -c min.rst -r heat.rst -x heat.nc -ref min.rst"
    if [ $? -ne 0 ]; then
        echo "Error en la etapa de calentamiento. Abortando."
        finalize_log
        exit 1
    fi
    
    # Ejecutar equilibración
    run_stage "Equilibración" "sander -O -i equil.in -o equil.out -p complex.prmtop -c heat.rst -r equil.rst -x equil.nc -ref heat.rst"
    if [ $? -ne 0 ]; then
        echo "Error en la etapa de equilibración. Abortando."
        finalize_log
        exit 1
    fi
    
    # Ejecutar producción MD
    run_stage "Producción MD" "sander -O -i md.in -o md.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc -inf md.info"
    if [ $? -ne 0 ]; then
        echo "Error en la etapa de producción MD. Abortando."
        finalize_log
        exit 1
    fi
    
    # Finalizar el registro
    finalize_log
    
    echo "¡Proceso completo de simulación finalizado con éxito!"
    echo "Los resultados y métricas de rendimiento se han guardado en $LOG_FILE"
}

# Ejecutar la función principal
main