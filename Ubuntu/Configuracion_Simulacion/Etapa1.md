#  Etapa 1 (Configuracion de Simulacion)

## Descripccion


## Paso (Tratamiento de datos)


###  Paso (Tratamiento del receptor)
-   receptor.pdb

###  Paso (Tratamiento del ligando)   
-   ligand.pdb

Convertir el archivo PDB del ligando a formato MOL2:
   ```bash
   antechamber -i ligando.pdb -fi pdb -o ligando.mol2 -fo mol2 -c bcc -at gaff
   ```
Generar el archivo de parámetros del ligando:
   ```bash
    parmchk2 -i ligando.mol2 -f mol2 -o ligando.frcmod
   ```


###   Paso (Resultados del tratamiento)
-  ligando.mol2
-  ligando.frcmod
-  receptor.pdb

## Paso (Contruir Complejo de proteína-ligando)

###   Configuracion del Ambiente
Abrir un editor de texto: Usa cualquier editor de texto en tu sistema para crear el archivo. Por ejemplo:

###   Crear el archivo en Linux:
   ```bash
   nano setup_tleap.in
   ```

####  Informacion del ambiente
Preparación del complejo ligando-receptor

Parametrización del ligando:
-  Utilizar el módulo Antechamber de AMBER 20.
-  Aplicar el campo de fuerza GAFF (General Amber Force Field).

Parametrización de la quinasa (proteína):
-  Usar el campo de fuerza ff19SB de AMBER.

Estado de protonación:
-  Determinar el estado de protonación a pH fisiológico (pH = 7) utilizando PDB2PQR.

Solvatación del complejo:
-  Solvatación con moléculas de agua pre-equilibradas modelo TIP3P.
-  Configurar la caja de solvatación con una distancia de 12 Å.
-  Neutralizar el sistema añadiendo 6 Cl⁻ y ajustar la concentración salina a 0.15 M utilizando Na⁺ y Cl⁻.


####  Contenido en el archivo:

   ```bash
    source leaprc.protein.ff19SB
    source leaprc.gaff

    receptor = loadpdb receptor.pdb
    ligando = loadmol2 ligando.mol2
    loadamberparams ligando.frcmod

    complex = combine {receptor ligando}
    solvatebox complex TIP3PBOX 12.0
    addions complex Na+ 0
    addions complex Cl- 0

    saveamberparm complex complex.prmtop complex.inpcrd
    quit
   ```

## NOTAS
###   Diagrama
```mermaid
flowchart TD
    A[Inicio: Configuración de Simulación] --> B[Tratamiento de Datos]
    B --> C[Procesar Receptor]
    C --> |Entrada: receptor.pdb| D[Salida: receptor.pdb]

    B --> E[Procesar Ligando]
    E --> |Entrada: ligand.pdb| F[Convertir a MOL2]
    F --> |Comando: antechamber| G[Resultado: ligando.mol2]
    G --> H[Generar Parámetros]
    H --> |Comando: parmchk2| I[Resultado: ligando.frcmod]

    B --> J[Consolidar Resultados]
    J --> |Resultados: receptor.pdb, ligando.mol2, ligando.frcmod| K[Avanzar a Construcción del Complejo]

    K --> L[Configuración del Ambiente]
    L --> M[Preparar Complejo Ligando-Receptor]
    M --> N[Parametrización del Ligando: GAFF]
    M --> O[Parametrización de la Quinasa: ff19SB]
    M --> P[Protonación: pH 7 con PDB2PQR]
    M --> Q[Solvatación: TIP3P + Caja 12 Å]
    Q --> R[Neutralización: Na⁺ y Cl⁻]

    L --> S[Crear Archivo setup_tleap.in]
    S --> T[Editar con nano]
    T --> U[Guardar Archivo]

    U --> V[Ejecutar tLEaP]
    V --> W[Generar complex.prmtop y complex.inpcrd]
    W --> X[Fin]

```

###   Diagrama  Entradas y Salida
```mermaid
   flowchart TD
      A[Inicio: Entradas] --> B[Archivo receptor.pdb]
      A --> C[Archivo ligand.pdb]
      
      B --> |Parametrización| D[ligando.mol2]
      C --> |Parametrización| D

      D --> E[Generar Parámetros: ligando.frcmod]
      E --> F[Construir Complejo: receptor + ligando]
      F --> G[Configurar Solvatación y Neutralización]

      G --> H[Salida: complex.prmtop]
      G --> I[Salida: complex.inpcrd]
      H --> J[Fin]
      I --> J
```

###   Preguntas
-  ¿Qué es un .mol2?

Es un archivo que describe la estructura molecular en formato MOL2, incluyendo coordenadas atómicas y tipos de átomos.

-  ¿Por qué se necesitan los archivos de parámetros "ligando.mol2, ligando.frcmod, receptor.pdb"?

Estos archivos contienen las descripciones necesarias para realizar simulaciones con precisión.

-  ¿Qué es GAFF?

Es el "General Amber Force Field", un campo de fuerza general usado para moléculas orgánicas en AMBER.

-  ¿Por qué las moléculas de agua no son deseadas?
   
Algunas moléculas de agua pueden ser eliminadas durante la preparación para evitar solapamientos o redundancias en el modelo.

-  ¿Por qué ajustar los hidrógenos?
   
Para garantizar que las configuraciones de enlace y carga sean correctas en función del pH fisiológico.

-  ¿Qué herramienta se puede usar para ajustar los hidrógenos y las moléculas de agua?

PDB2PQR es una herramienta comúnmente usada para este propósito.

-  ¿Por qué configurar los parámetros físicos y químicos?

Para asegurar la estabilidad y realismo de la simulación en condiciones experimentales.

-  ¿Por qué usar un ambiente biológico pequeño?

Para reducir la complejidad computacional sin comprometer la precisión en el área de interés.

-  ¿Por qué usar un ambiente acuoso?

Un ambiente acuoso simula condiciones biológicas reales y asegura que las interacciones moleculares se comporten de manera fisiológicamente relevante.

-  ¿Además de TIP3PBOX, qué otros patrones existen?

Existen patrones como SPC/E, TIP4P, y otros modelos de agua con diferentes características para simulaciones específicas.

###   SCRIPT
###   Referencias

