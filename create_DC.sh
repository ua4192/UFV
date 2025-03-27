#!/bin/bash

# Argumentos:
# $1 = nombreNasServer

PATH="/cygdrive/c/Program Files/Oracle/VirtualBox:${PATH}"
export PATH

VMNAME=${1}
VMGROUP="/UFV/DC"
VMROOTPATH="C:\\UFV\\hosts\\UFV\\DC\\${VMNAME}"
DISKPATH="${VMROOTPATH}\\disks"
AUXILIARY="${VMROOTPATH}\\auxiliary"
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\windowsserver2019.iso"
GUESTISO="C:\\Program Files\\Oracle\\VirtualBox\\VBoxGuestAdditions.iso"
NET_ADAPTER="Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)"
CPUS=8
RAM=4096
USER="administrator"
FULLUSERNAME="UFV Machine Admin"
PASSWORD="Airbusds2024!"
DOMAIN="UFV.org"
FQDN="${VMNAME}.${DOMAIN}"
SCRIPTPATH="E:\\UFV\\hosts\\UFV\\scripts"

# Carpeta compartida
SHARED_FOLDER_NAME="UFV"
SHARED_FOLDER_PATH="C:\\UFV"

# Validación de argumentos
if [ "$#" -ne 1 ]; then
    echo "Número de argumentos inválidos: ${0} serverName"
    exit 1
else
    echo "Advertencia: Se creará el servidor NAS llamado ${1} con esta configuración:"
    echo "     - VMNAME: ${VMNAME}"
    echo "     - VMGROUP: ${VMGROUP}"
    echo "     - VMROOTPATH: ${VMROOTPATH}"
    echo "     - DISKPATH: ${DISKPATH}"
    echo "     - SNAPSHOTPATH: ${SNAPSHOTPATH}"
    echo "     - ISO_PATH: ${ISO_PATH}"
    
    read -p "¿Estás seguro de continuar? (si/no): " respuesta
   
    if [ "$respuesta" != "si" ]; then
        echo "Operación abortada."
        exit 2
    fi
fi

DISK1="${DISKPATH}\\UFVDC_Disk_SO.vdi"
DISK1SIZE=50000  # Corregido el error

# Crear la máquina virtual
VBoxManage createvm --name "$VMNAME" --groups "$VMGROUP" --ostype "Windows2019_64" --register

# Configurar ruta de almacenamiento
VBoxManage modifyvm "$VMNAME" --snapshotfolder "$SNAPSHOTPATH"

# Configurar recursos de la VM
VBoxManage modifyvm "$VMNAME" --memory $RAM --cpus $CPUS --vram 128

# Configurar red en modo puente
VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "$NET_ADAPTER"

# Crear la carpeta de discos si no existe
mkdir -p "$DISKPATH"

# Crear y adjuntar disco duro
VBoxManage createhd --filename "$DISK1" --size "$DISK1SIZE" --format VDI
VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK1"

# Adjuntar ISO de instalación
VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

# Configurar arranque desde CD
VBoxManage modifyvm "$VMNAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Habilitar portapapeles bidireccional y arrastrar y soltar
VBoxManage modifyvm "$VMNAME" --clipboard-mode bidirectional
VBoxManage modifyvm "$VMNAME" --drag-and-drop bidirectional

# Configurar carpeta compartida
VBoxManage sharedfolder add "$VMNAME" --name "$SHARED_FOLDER_NAME" --hostpath "$SHARED_FOLDER_PATH" --automount

# Instalación desatendida
VBoxManage unattended install "$VMNAME" \
    --iso="$ISO_PATH" \
    --user="$USER" \
    --password="$PASSWORD" \
    --full-user-name="$FULLUSERNAME" \
    --install-additions \
    --additions-iso="$GUESTISO" \
    --no-install-txs \
    --locale=es_ES \
    --country=ES \
    --time-zone=Europe/Madrid \
    --hostname="$FQDN" \
    --post-install-command="${SCRIPTPATH}\\configure_DC.ps1"

echo "Máquina virtual $VMNAME creada y configurada correctamente."
