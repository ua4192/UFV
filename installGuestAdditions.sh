#!/bin/bash

# Argumentos:
# $1 = nombreNasServer

PATH="/cygdrive/c/Program Files/Oracle/VirtualBox:${PATH}"
export PATH

VMNAME=${1}
VMGROUP="/UFV/APP-SERVERS"
VMROOTPATH="C:\\UFV\\hosts\\UFV\\APP-SERVERS\\${VMNAME}"
DISKPATH="${VMROOTPATH}\\disks"
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\ubuntu-24.04.1-live-server-amd64.iso"

if [ "$#" -ne 1 ]; then
    echo "Numero de argumentos invalidos: ${0} serverName"
    exit 1
else
    echo "Advertencia: Se creara el server llamado ${1} con esta configuracion:"
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

# Montar el ISO de Guest Additions
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"

# Ejecutar el instalador de Guest Additions
VBoxManage guestcontrol "$VMNAME" run --exe "C:\Windows\System32\cmd.exe" --username "Administrator" --password "Airbusds2024!" -- cmd /c "start /wait D:\\VBoxWindowsAdditions.exe /S"


