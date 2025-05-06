# Preparacion de Dinámica

## Diagrama de Flujo


## Automatización de Flujo de Trabajo Molecular (1_preparacion)
#### Resumen Ejecutivo
Este repositorio contiene un script automatizado para la preparación de complejos moleculares receptor-ligando utilizando herramientas de AMBER. El sistema automatiza todo el proceso desde la preparación inicial de estructuras hasta la solvatación del complejo, monitoreando simultáneamente el rendimiento computacional. Esto permite a los investigadores ahorrar tiempo, reducir errores manuales y obtener métricas precisas del costo computacional de cada etapa.

#### Manual de Usuario

##### Requisitos Previos

- Sistema operativo Linux/Unix o macOS
- Herramientas AMBER instaladas (`pdb4amber`, `antechamber`, `parmchk2`, `tleap`)
- Utilidades básicas: `bc`, `ps`

##### Archivos de Entrada

El script requiere dos archivos de entrada principales:

1. `receptor.pdb` - Estructura PDB de la proteína receptora
2. `ligand.pdb` - Estructura PDB del ligando

Ambos archivos deben estar ubicados en el directorio donde se ejecuta el script.

##### Ejecución

1. Dar permisos de ejecución al script:
   ```bash
   chmod +x 1_preparacion.sh
   ```

2. Ejecutar el script:
   ```bash
   ./1_preparacion.sh
   ```

#### Flujo de Trabajo
##### Parametros
El script ejecuta automáticamente las siguientes etapas:

1. **Preparación de Estructuras**
   - Procesamiento del receptor con `pdb4amber`
   - Parametrización del ligando con `antechamber` y `parmchk2`
   - Creación del complejo ligando-receptor

2. **Solvatación del Complejo**
   - Solvatación con agua TIP3P en una caja de 12 Å
   - Neutralización con iones Cl-
   - Adición de iones Na+ y Cl- para establecer concentración salina

##### Monitoreo de Recursos

Durante la ejecución, el script registra:
- Tiempo de ejecución de cada etapa
- Porcentaje de uso de CPU
- Uso de memoria RAM
- Información de progreso en tiempo real


##### Estructura y Parametrización

- `results/receptor_amber.pdb` - Receptor preparado
- `results/ligando.mol2` - Ligando parametrizado
- `results/ligando.frcmod` - Parámetros del campo de fuerza del ligando
- `results/complex.pdb` - Complejo receptor-ligando
- `results/complex_solvated.pdb` - Complejo solvatado
- `results/complex.prmtop` - Archivo de topología del complejo
- `results/complex.inpcrd` - Archivo de coordenadas del complejo

##### Monitoreo y Logs

- `logs/metrics.log` - Registro CSV de métricas de rendimiento
- `logs/[etapa].log` - Logs detallados de cada etapa

##### Datos de Salida
El script genera varios archivos de salida organizados en directorios específicos. A continuación se detalla cada uno de ellos:


###### Archivos de Preparación
- **`results/receptor_amber.pdb`**
  - Estructura del receptor con hidrógenos añadidos
  - Correcciones estructurales compatibles con AMBER
  - Listo para simulaciones moleculares
  
- **`results/ligando.mol2`**
  - Ligando convertido al formato MOL2
  - Incluye coordenadas atómicas del ligando
  - Contiene cargas parciales calculadas con el método BCC
  - Información sobre tipos de átomos asignados

- **`results/ligando.frcmod`**
  - Parámetros del campo de fuerza para el ligando
  - Compatible con el campo de fuerza GAFF
  - Incluye parámetros de enlaces, ángulos y diedros
  - Necesario para la correcta interacción ligando-receptor

###### Archivos del Complejo
- **`results/complex.pdb`**
  - Estructura 3D del complejo receptor-ligando
  - Representa la conformación inicial antes de solvatación
  - Útil para análisis estructural preliminar

- **`results/complex_solvated.pdb`**
  - Complejo solvatado en caja de agua TIP3P
  - Incluye moléculas de agua e iones añadidos
  - Representa el sistema listo para simulación de dinámica molecular

###### Archivos para Simulación
- **`results/complex.prmtop`**
  - Archivo de topología del complejo en formato AMBER
  - Contiene toda la información paramétrica del sistema:
    - Tipos de átomos
    - Cargas atómicas
    - Definición de enlaces y ángulos
    - Parámetros de interacción
  - Esencial para ejecutar simulaciones en AMBER
  
- **`results/complex.inpcrd`**
  - Archivo de coordenadas iniciales
  - Posiciones atómicas del sistema completo
  - Compatible con programas de simulación AMBER
  - Se utiliza junto con el archivo .prmtop para iniciar simulaciones

###### Archivos de Configuración Generados
- **`results/complejo_tleap.in`**
  - Script de entrada para tleap que genera el complejo
  - Incluye comandos para cargar receptor y ligando
  - Documenta el proceso de creación del complejo

- **`results/solvatacion.in`**
  - Script de entrada para tleap que solvata el sistema
  - Contiene configuraciones para solvatación y adición de iones
  - Útil como referencia para modificaciones futuras

###### Archivos de Monitoreo y Rendimiento
- **`logs/metrics.log`**
  - Archivo CSV con métricas de rendimiento
  - Columnas: Timestamp, Etapa, Tiempo de Ejecución, % CPU, RAM
  - Permite análisis cuantitativo del costo computacional
  - Útil para planificar futuros trabajos similares

- **`logs/[etapa].log`** (varios archivos)
  - Logs detallados para cada etapa del proceso
  - Contiene toda la salida estándar y de error
  - Incluye advertencias y mensajes informativos
  - Crucial para diagnóstico en caso de errores
#### Personalización

Para modificar parámetros de solvatación o campos de fuerza, editar las secciones relevantes en el script:
- Para campos de fuerza: modificar las líneas `source leaprc.*` 
- Para tamaño de caja: ajustar el valor en `solvatebox complex TIP3PBOX 12.0`
- Para concentración iónica: modificar los comandos `addions` y `addionsRand`


---


## Automatización SANDER Automation Tool (2_simulacion.sh)
#### Resumen Ejecutivo
Esta herramienta automatiza el flujo de trabajo completo para simulaciones de dinámica molecular utilizando SANDER (parte de AmberTools). Ejecuta secuencialmente las cuatro etapas estándar de simulación (minimización, calentamiento, equilibración y producción), monitorizando en tiempo real el rendimiento computacional y generando registros detallados del proceso. El script está diseñado para facilitar la reproducibilidad de las simulaciones y proporcionar métricas claras sobre el coste computacional de cada etapa.

####  Manual de Usuario
##### Archivos de Entrada
Archivos de topología y coordenadas iniciales (complex.prmtop y complex.inpcrd)

Instalación

##### Ejecución

1. Dar permisos de ejecución al script:
   ```bash
   chmod +x 2_simulacion.sh
   ```

2. Ejecutar el script:
   ```bash
   ./2_simulacion.sh
   ```

#### Flujo de Trabajo

##### Parametros
El script ejecuta automáticamente las siguientes etapas:
1. **El script ejecuta las siguientes etapas en secuencia:**
-  Verificación: Comprueba la existencia de los archivos necesarios y la disponibilidad de SANDER
-  Minimización: Relaja la estructura molecular para encontrar la configuración de menor energía
-  Calentamiento: Aumenta gradualmente la temperatura del sistema hasta 310K
-  Equilibración: Estabiliza el sistema a temperatura y presión constantes
-  Producción MD: Realiza la simulación de dinámica molecular

2. **Durante cada etapa, el script:**
-  Monitoriza el uso de CPU y memoria
-  Registra el tiempo de ejecución
-  Actualiza el archivo de registro en tiempo real
-  Verifica la finalización exitosa antes de continuar


##### Datos de Salida
###### Archivos de Registro
**sander_performance.log:** Registro detallado del tiempo de ejecución y recursos utilizados

###### Archivos de Simulación

1. **Minimización:**
min.out: Registro de la minimización
min.rst: Coordenadas minimizadas


2. **Calentamiento:**
heat.out: Registro del calentamiento
heat.rst: Coordenadas y velocidades después del calentamiento
heat.nc: Trayectoria del calentamiento


3. **Equilibración:**
equil.out: Registro de la equilibración
equil.rst: Coordenadas y velocidades después de la equilibración
equil.nc: Trayectoria de la equilibración


4. **Producción MD:**
md.out: Registro de la producción
prod.rst: Coordenadas y velocidades finales
prod.nc: Trayectoria de producción
md.info: Información adicional de la simulación




## Formatos de Archivo
| Extensión | Descripción | Uso |
|-----------|-------------|-----|
| `.pdb` | Formato de Protein Data Bank | Visualización 3D en programas como PyMOL, VMD |
| `.mol2` | Formato Molecular Tripos | Contiene información química detallada del ligando |
| `.frcmod` | Modificador de campo de fuerza | Define parámetros personalizados para AMBER |
| `.prmtop` | Topología de AMBER | Describe completa y paramétricamente el sistema |
| `.inpcrd` | Coordenadas de entrada | Posiciones iniciales para simulación |
| `.in` | Archivo de entrada | Define los parámetros de control para cada etapa de SANDER |
| `.out` | Archivo de salida | Contiene los registros y resultados detallados de la simulación |
| `.rst` | Archivo de reinicio | Almacena coordenadas y velocidades para continuar simulaciones |
| `.nc` | NetCDF | Almacena trayectorias de simulación en formato binario eficiente |
| `.info` | Información | Datos adicionales generados durante la etapa de producción |
| `.log` | Registro | Contiene métricas de rendimiento y tiempos de ejecución |




## Referencias
- [Simple Simulation of Alanine Dipeptide](https://ambermd.org/tutorials/basic/tutorial0/index.php)
- [Gaussian field-based 3D-QSAR and molecular simulation studies to design potent pyrimidine–sulfonamide hybrids as selective BRAFV600E inhibitors](https://pubs.rsc.org/en/content/articlepdf/2022/ra/d2ra05751d)

