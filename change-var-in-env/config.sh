#!/bin/bash
# Nombre de la variable
VERSION_CACHE='VERSION_CACHE='

# Obtener el path en el que está alojado el archivo
COMMAND_PATH=$(dirname "$(readlink -f "$0")")
BASE_PATH=$(dirname "$COMMAND_PATH")
envLocalFile="$BASE_PATH/.env.local"

# Comprobar si el archivo destino ya existe
# if [ -e "$envLocalFile" ]; then
#     # Si el archivo destino existe, crear una copia de seguridad con la fecha actual
#     date=$(date +%Y-%m-%d_%H-%M-%S)
#     cp "$envLocalFile" "$envLocalFile.$date"
# fi

# No existe la variable la crea
if ! grep -E "^VERSION_CACHE=.*" $envLocalFile; then
    echo $VERSION_CACHE >> $envLocalFile
fi

# Datos de obtenidos de git para que el valor de la cache sea unico por despliegue
branch=$(git branch --show-current)
process=$(git rev-parse HEAD)
cacheVersion='v-'$branch'-'$process

# Modifica la variable
sed -i "s/^VERSION_CACHE=.*/$VERSION_CACHE$cacheVersion/g" $envLocalFile

 if [ $? -ne 0 ]; then
    echo "Error: no se ha podido actualizar $envLocalFile"
    exit 1
else
    echo "Variable $VERSION_CACHE del fichero $envLocalFile cambiada con exito"
    exit 0
fi
