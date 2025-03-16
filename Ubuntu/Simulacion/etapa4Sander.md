# SANDER
sander es un programa que forma parte de AmberTools y se usa para dos cosas principales:

- *Minimización de energía:* Relaja la estructura molecular para encontrar la configuración de energía más baja.
- *Calentamiento:* Aumenta gradualmente la temperatura del sistema hasta alcanzar la temperatura objetivo.
- *Equilibración:* Estabiliza el sistema a la temperatura y presión deseadas, preparándolo para la simulación de producción.
- *Dinámica molecular (MD):* Simula el movimiento de los átomos en el tiempo, permitiendo estudiar el comportamiento de la molécula en condiciones realistas.


## Archivos de entrada y salida
1. Minimización de Energía
  - Archivos de entrada:
    min.in: Archivo de configuración que define los parámetros para la minimización de energía.
    complex.prmtop: Archivo de topología del sistema (contiene información sobre los átomos, enlaces, ángulos, cargas, etc.).
    complex.inpcrd: Archivo de coordenadas iniciales del sistema.
  - Archivos de salida:
    min.out: Archivo de texto que contiene un registro detallado de la minimización, incluyendo la energía del sistema en cada ciclo.
    min.rst: Archivo de reinicio con las coordenadas finales del sistema después de la minimización.
    min.nc: Trayectoria de la minimización en formato NetCDF (opcional, si se especifica en el archivo de entrada).

2. Calentamiento
  - Archivos de entrada:
    heat.in: Archivo de configuración que define los parámetros para la etapa de calentamiento.
    complex.prmtop: Archivo de topología del sistema.
    min.rst: Archivo de reinicio generado en la etapa de minimización (contiene las coordenadas minimizadas).
  - Archivos de salida:
    heat.out: Archivo de texto que contiene un registro detallado del calentamiento, incluyendo la temperatura y energía del sistema en cada paso.
    heat.rst: Archivo de reinicio con las coordenadas y velocidades finales después del calentamiento.
    heat.nc: Trayectoria del calentamiento en formato NetCDF (opcional, si se especifica en el archivo de entrada).

3. Equilibración
  - Archivos de entrada:
    equil.in: Archivo de configuración que define los parámetros para la etapa de equilibración.
    complex.prmtop: Archivo de topología del sistema.
    heat.rst: Archivo de reinicio generado en la etapa de calentamiento (contiene las coordenadas y velocidades después del calentamiento).
  - Archivos de salida:
    equil.out: Archivo de texto que contiene un registro detallado de la equilibración, incluyendo la temperatura, presión y energía del sistema en cada paso.
    equil.rst: Archivo de reinicio con las coordenadas y velocidades finales después de la equilibración.
    equil.nc: Trayectoria de la equilibración en formato NetCDF (opcional, si se especifica en el archivo de entrada).

4. Dinámica Molecular (Producción)
  - Archivos de entrada:
    md.in: Archivo de configuración que define los parámetros para la etapa de producción de la dinámica molecular.
    complex.prmtop: Archivo de topología del sistema.
    equil.rst: Archivo de reinicio generado en la etapa de equilibración (contiene las coordenadas y velocidades después de la equilibración).
  - Archivos de salida:
    md.out: Archivo de texto que contiene un registro detallado de la simulación de producción, incluyendo la temperatura, presión y energía del sistema en cada paso.
    md.rst: Archivo de reinicio con las coordenadas y velocidades finales después de la simulación de producción.
    md.nc: Trayectoria de la simulación de producción en formato NetCDF (opcional, si se especifica en el archivo de entrada).

| Etapa               | Archivos de Entrada                        | Archivos de Salida                |
|---------------------|--------------------------------------------|-----------------------------------|
| **Minimización**     | min.in, complex.prmtop, complex.inpcrd     | min.out, min.rst, min.nc          |
| **Calentamiento**    | heat.in, complex.prmtop, min.rst          | heat.out, heat.rst, heat.nc       |
| **Equilibración**    | equil.in, complex.prmtop, heat.rst        | equil.out, equil.rst, equil.nc    |
| **Dinámica Molecular** | md.in, complex.prmtop, equil.rst        | md.out, md.rst, md.nc             |



##  Minimización de energía
Crea un archivo llamado min.in con el siguiente contenido, se minimiza la energía del sistema con restricciones en los átomos de carbono alfa.
```bash
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
```
##  Calentamiento
Después de la minimización, el sistema debe calentarse gradualmente desde 0 K hasta la temperatura deseada (por ejemplo, 310 K). Crea un archivo de entrada llamado heat.in:
```bash
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
```
### Ejecución del comando:
```bash
sander -O -i heat.in -o heat.out -p complex.prmtop -c min.rst -r heat.rst -x heat.nc -ref min.rst
```

##  Equilibración
Una vez calentado, el sistema debe equilibrarse a la temperatura y presión deseadas. Crea un archivo de entrada llamado equil.in
```bash
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
```
### Ejecución del comando:
```bash
sander -O -i equil.in -o equil.out -p complex.prmtop -c heat.rst -r equil.rst -x equil.nc -ref heat.rst
```

##  Dinámica molecular (MD)
Crea un archivo llamado md.in con el siguiente contenido, se realiza una simulación de 1 ns (500,000 pasos de integración con 2 fs por paso).
```bash
cat > md.in <<EOF
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
```
### Ejecución del comando:
```bash
pmemd.cuda -O -i prod.in -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
```
