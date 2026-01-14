#!/bin/bash

# Script de instalación automática de Discord para Fedora
# Uso: ./install-discord.sh [ruta-al-archivo-tar.gz]

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

echo -e "${GREEN}=== Instalador de Discord para Fedora ===${NC}\n"

# Verificar si se proporcionó un archivo tar.gz
if [ -z "$1" ]; then
    echo -e "${YELLOW}Buscando archivo de Discord en ~/Descargas...${NC}"
    DISCORD_TAR=$(find ~/Descargas -name "discord-*.tar.gz" | head -n 1)
    
    if [ -z "$DISCORD_TAR" ]; then
        echo -e "${RED}Error: No se encontró ningún archivo discord-*.tar.gz en ~/Descargas${NC}"
        echo "Uso: $0 [ruta-al-archivo-tar.gz]"
        exit 1
    fi
else
    DISCORD_TAR="$1"
fi

# Verificar que el archivo existe
if [ ! -f "$DISCORD_TAR" ]; then
    echo -e "${RED}Error: El archivo $DISCORD_TAR no existe${NC}"
    exit 1
fi

echo -e "${GREEN}Archivo encontrado: $DISCORD_TAR${NC}\n"

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Extrayendo Discord en directorio temporal...${NC}"

# Extraer el tar.gz
tar -xzf "$DISCORD_TAR" -C "$TEMP_DIR"

# Buscar la carpeta Discord dentro de la extracción
DISCORD_FOLDER=$(find "$TEMP_DIR" -type d -name "Discord" | head -n 1)

if [ -z "$DISCORD_FOLDER" ]; then
    echo -e "${RED}Error: No se encontró la carpeta Discord en el archivo${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Eliminar instalación anterior si existe
if [ -d "/usr/share/discord" ]; then
    echo -e "${YELLOW}Eliminando instalación anterior de Discord...${NC}"
    sudo rm -rf /usr/share/discord
fi

# Mover Discord a /usr/share/
echo -e "${YELLOW}Instalando Discord en /usr/share/discord...${NC}"
sudo mv "$DISCORD_FOLDER" /usr/share/discord

# Dar permisos de ejecución
sudo chmod +x /usr/share/discord/Discord

# Editar el archivo .desktop para corregir las rutas
echo -e "${YELLOW}Configurando lanzador de aplicación...${NC}"
sudo tee /usr/share/discord/discord.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Discord
StartupWMClass=discord
Comment=All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.
GenericName=Internet Messenger
Exec=/usr/share/discord/Discord
Icon=/usr/share/discord/discord.png
Type=Application
Categories=Network;InstantMessaging;
Terminal=false
StartupNotify=true
EOF

# Copiar el .desktop al directorio de aplicaciones
sudo cp /usr/share/discord/discord.desktop /usr/share/applications/

# Crear enlace simbólico para ejecutar desde terminal
if [ -L "/usr/local/bin/discord" ] || [ -f "/usr/local/bin/discord" ]; then
    sudo rm -f /usr/local/bin/discord
fi
sudo ln -s /usr/share/discord/Discord /usr/local/bin/discord

# Actualizar base de datos de aplicaciones
echo -e "${YELLOW}Actualizando base de datos de aplicaciones...${NC}"
sudo update-desktop-database

# Limpiar directorio temporal
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}✓ Discord instalado correctamente${NC}"
echo -e "${GREEN}✓ Puedes ejecutarlo desde el menú de aplicaciones o con el comando 'discord'${NC}\n"

# Preguntar si desea ejecutar Discord ahora
read -p "¿Deseas ejecutar Discord ahora? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[SsYy]$ ]]; then
    discord &
    echo -e "${GREEN}Discord iniciado${NC}"
fi
