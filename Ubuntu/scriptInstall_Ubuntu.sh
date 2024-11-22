# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root (o usa sudo)"
  exit 1
fi

# Función para manejar errores
error_exit() {
  echo "Error: $1"
  exit 1
}

# Actualizar repositorios y sistema
echo "Actualizando repositorios y sistema..."
sudo apt update && sudo apt upgrade -y || error_exit "No se pudo actualizar el sistema"

# Instalar dependencias básicas
echo "Instalando dependencias básicas..."
sudo apt-get install -y cmake wget build-essential checkinstall \
  libncursesw5-dev libssl-dev libsqlite3-dev tk-dev \
  libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev \
  gfortran bison flex python-distutils-extra python-setuptools || error_exit "Error al instalar dependencias"

# Agregar el repositorio de Python deadsnakes
echo "Agregando el repositorio de Python..."
sudo add-apt-repository -y ppa:deadsnakes/ppa || error_exit "Error al agregar el repositorio de Python"
sudo apt update || error_exit "Error al actualizar los repositorios después de agregar Python"

# Instalar Python3
echo "Instalando Python3..."
sudo apt install -y python3 || error_exit "Error al instalar Python3"

# Descargar e instalar Miniconda
echo "Instalando Miniconda..."
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/Miniconda3-latest-Linux-x86_64.sh || error_exit "Error al descargar Miniconda"
bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p "$HOME/miniconda" || error_exit "Error al instalar Miniconda"
export PATH="$HOME/miniconda/bin:$PATH"

# Configurar entorno Miniconda
echo "Configurando Miniconda..."
source "$HOME/miniconda/bin/activate" || error_exit "Error al activar Miniconda"

# Descargar AmberTools y Amber
echo "Descargando AmberTools y Amber..."
# Sustituye las URLs de ejemplo por las URLs reales
# wget <URL_AmberTools24> -O /tmp/AmberTools24.tar.bz2 || error_exit "Error al descargar AmberTools"
# wget <URL_Amber24> -O /tmp/Amber24.tar.bz2 || error_exit "Error al descargar Amber"
# tar -xvf /tmp/AmberTools24.tar.bz2 -C $HOME || error_exit "Error al extraer AmberTools"
# tar -xvf /tmp/Amber24.tar.bz2 -C $HOME || error_exit "Error al extraer Amber"

# Instalar AmberTools y Amber
echo "Instalando AmberTools y Amber..."
cd "$HOME/amber24_src" || error_exit "No se encontró el directorio amber24_src"
mkdir -p build
cd build
./run_cmake || error_exit "Error al ejecutar run_cmake"
make install || error_exit "Error al ejecutar make install"

# Configurar entorno Amber
echo "Configurando el entorno Amber..."
source "$HOME/amber24/amber.sh" || error_exit "Error al configurar el entorno Amber"

echo "Proceso completado con éxito."