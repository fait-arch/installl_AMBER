# SANDER
sander es un programa que forma parte de AmberTools y se usa para dos cosas principales:


- *Minimización de energía:* Ayuda a "relajar" una estructura molecular, moviendo los átomos para encontrar una configuración donde la energía sea lo más baja posible.
- *Dinámica molecular (MD):* Simula el movimiento de los átomos en el tiempo, siguiendo las leyes de la física (las ecuaciones de Newton). Esto permite estudiar cómo se comporta la molécula en condiciones realistas.

##  Minimización de energía
Crea un archivo llamado min.in con el siguiente contenido
```bash

```
### Ejecución del comando:
```bash
sander -O -i min.in -o min.out -p complex.prmtop -c complex.inpcrd -r min.rst -ref complex.inpcrd
```

##  Dinámica molecular (MD)
Crea un archivo llamado md.in con el siguiente contenido
```bash

```

### Ejecución del comando:
```bash
sander -O -i md.in -o md.out -p complex.prmtop -c min.rst -r md.rst -x md.nc 
```
