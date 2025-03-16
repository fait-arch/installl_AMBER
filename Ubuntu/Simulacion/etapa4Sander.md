# SANDER
sander es un programa que forma parte de AmberTools y se usa para dos cosas principales:


- *Minimización de energía:* Ayuda a "relajar" una estructura molecular, moviendo los átomos para encontrar una configuración donde la energía sea lo más baja posible.
- *Dinámica molecular (MD):* Simula el movimiento de los átomos en el tiempo, siguiendo las leyes de la física (las ecuaciones de Newton). Esto permite estudiar cómo se comporta la molécula en condiciones realistas.

##  Minimización de energía
Crea un archivo llamado min.in con el siguiente contenido, se minimiza la energía del sistema con restricciones en los átomos de carbono alfa.
```bash
cat > min1.mdin <<EOF
&cntrl
  imin=1, maxcyc=10000, ncyc=5000,
  ntb=1, ntp=1,
  ntx=1, irest=0,
  ntr=1, restraint_wt=10.0, restraintmask='@CA',
  temp0=310.0,
  ntt=3, gamma_ln=1.0,
  ntpr=1000, ntwx=1000, ntwv=1000, ntwe=1000,
  dt=0.002
/
EOF
```
### Ejecución del comando:
```bash
sander -O -i min1.mdin -o min1.out -p complex.prmtop -c complex.inpcrd -r min1.rst
```

##  Dinámica molecular (MD)
Crea un archivo llamado md.in con el siguiente contenido, se realiza una simulación de 1 ns (500,000 pasos de integración con 2 fs por paso).
```bash
cat > prod.mdin <<EOF
&cntrl
  imin=0,
  nstlim=500000, dt=0.002,
  ntc=2, ntf=2,
  ntb=2, ntp=1, cut=11.0,
  temp0=310.0, ntt=3, gamma_ln=1.0,
  ntpr=1000, ntwx=1000, ntwv=1000, ntwe=1000
/
EOF
```

### Ejecución del comando:
```bash
sander -O -i prod.mdin -o prod.out -p complex.prmtop -c equil.rst -r prod.rst -x prod.nc
```
