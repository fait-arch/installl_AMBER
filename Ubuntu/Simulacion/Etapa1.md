### *Paso 1: Preparación del receptor*

#### *1.1 Verificar el archivo receptor.pdb:*
   - Asegúrate de que el archivo receptor.pdb tenga un formato válido.
   - Utiliza herramientas como pdb4amber para limpiar y preparar el receptor.
```bash
pdb4amber -i receptor.pdb -o receptor_clean.pdb
```
   - Esto corregirá errores comunes como nombres de átomos no estándar y eliminará heteroátomos (excepto aquellos necesarios).

#### *1.2 Añadir hidrógenos al receptor:*
   - Si el archivo PDB no tiene hidrógenos, usa *LEaP* para añadirlos:
```bash
tleap
source leaprc.protein.ff14SB
receptor = loadpdb receptor_clean.pdb
savepdb receptor receptor_prepared.pdb
quit
```
- El archivo receptor_prepared.pdb incluirá hidrógenos faltantes según el campo de fuerza cargado.

#### *1.3 Verificar visualmente:*
   - Abre receptor_prepared.pdb con un visualizador molecular como *PyMOL* o *Chimera*:
```bash
pymol receptor_prepared.pdb
```
   - Asegúrate de que los hidrógenos estén correctamente posicionados.

### *Paso 2: Preparación del ligando*

#### *2.1 Verificar el archivo ligando.mol2:*
   - Asegúrate de que el archivo .mol2 contenga la topología y cargas del ligando. Si no estás seguro, puedes generarlo desde un archivo PDB utilizando *Antechamber*:
```bash
antechamber -i ligando.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -s 2
```
   - Esto generará un archivo ligando.mol2 con cargas AM1-BCC.


#### *2.2 Generar el archivo de parámetros (ligando.frcmod):*
   - Utiliza *parmchk2* para generar los parámetros de fuerza:
```bash
parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
```
   - Verifica que el archivo ligando.frcmod no tenga errores.

#### *2.3 Verificar el ligando en LEaP:*
   - Abre LEaP y carga el ligando:
   ```bash
     tleap
     source leaprc.gaff
     ligando = loadmol2 ligando.mol2
     loadamberparams ligando.frcmod
     desc ligando
     quit
   ```
   - El comando desc ligando debe mostrar:
     - Nombre de la unidad.
     - Número de átomos.
     - Átomos principales definidos.

#### *2.4 Inspección visual:*
   - Abre el archivo ligando.mol2 en un visualizador para confirmar la estructura y posiciones de los átomos:
   ```bash
     pymol ligando.mol2
   ```

---

### *Paso 3: Combinar receptor y ligando*

#### *3.1 Cargar ambos en LEaP:*
   - Ahora que el receptor y el ligando están preparados, combínalos en LEaP:
   ```bash
     tleap
     source leaprc.protein.ff14SB
     source leaprc.gaff

     receptor = loadpdb receptor_prepared.pdb
     ligando = loadmol2 ligando.mol2
     loadamberparams ligando.frcmod

     complex = combine {receptor ligando}
     desc complex
     quit
     
   ```

#### *3.2 Verificar la combinación:*
   - El comando desc complex debe mostrar información sobre el nuevo sistema, incluyendo:
     - El número de residuos y átomos (que debe ser la suma del receptor, ligando e hidrógenos).
   - Guarda la estructura combinada para inspeccionarla:
     bash
     savepdb complex complex.pdb
     

---

### *Paso 4: Solvatar y añadir iones*

#### *4.1 Solvatar el sistema:*
   - Añade una caja de agua al sistema para simular un entorno acuoso:
   ```bash
     solvatebox complex TIP3PBOX 12.0
   ```

#### *4.2 Añadir iones:*
   - Neutraliza el sistema añadiendo iones positivos y negativos:
   ```bash 
     addions complex Na+ 0
     addions complex Cl- 0
   ```

#### *4.3 Guardar parámetros:*
   - Guarda los archivos de entrada para la simulación:
   ```bash 
     saveamberparm complex complex.prmtop complex.inpcrd
     savepdb complex complex_solvated.pdb
     
   ``` 

---

### *Paso 5: Verificación final*

#### *5.1 Inspección visual:*
   - Abre el archivo complex_solvated.pdb en un visualizador molecular y verifica:
     - El receptor y el ligando están correctamente posicionados.
     - Hay moléculas de agua alrededor del complejo.
     - Los iones están presentes.

#### *5.2 Prueba de simulación:*
   - Realiza una minimización de energía con *sander* o *pmemd* para confirmar que el sistema es estable:
   ```bash 
pmemd -O -i min.in -p complex.prmtop -c complex.inpcrd -o min.out -r min.rst
     
   ``` 
   - Revisa el archivo min.out para asegurarte de que no hay errores.

---

Si sigues este flujo y verificas cada paso, tendrás un sistema bien preparado y listo para simulación. Si surge algún problema, compártemelo para ajustarlo.
