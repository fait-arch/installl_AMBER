# Etapa 1 Cargar estructuras

##  Datos de entrada
  - Receptor: Un ligando es una molécula que se une a una proteína.
  - Ligando: Un receptor es una proteína 
  - Complejo: Union del receptor con el ligando.

##  Preparación de datos de entrada

### Receptor
Añadimos la adición de hidrógenos  la corrección de la estructura para que sea compatible con AMBER.
```bash
pdb4amber -i receptor.pdb -o receptor_amber.pdb 
```

### Ligando
Pasamos al ligando a un archivo .mol2 ya que ste formato es más adecuado para describir moléculas pequeñas (como ligandos), incluirán las coordenadas de los átomos del ligando, las cargas parciales y la información sobre los tipos de átomos.

```bash
antechamber -i ligand.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -s 2
```

```bash
parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
```

### Complejo
Ahora con los archivos preparados tanto para el receptor como para el ligando, hay que crear el complejo ligando-receptor en Amber.

Crear el archivo **complejo_tleap.in** o el visor 
```bash
cat > complejo_tleap.in <<EOF
tleap
receptor = loadPdb receptor_amber.pdb
ligando = loadmol2 ligando.mol2
loadamberparams ligando.frcmod

complex = combine {receptor ligando}
savepdb complex complex.pdb

quit
EOF
```

Ejecutar:
```bash
tleap -f solvatar_tleap.in
```
