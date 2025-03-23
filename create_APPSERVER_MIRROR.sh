#!/bin/bash

# Argumentos:
# $1 = nombreNasServer

# CLI url:
# https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/vboxmanage-checkmediumpwd.html

PATH="/cygdrive/c/Program Files/Oracle/VirtualBox:${PATH}"
export PATH

VMNAME=${1}
VMGROUP="/UFV/APP-SERVERS"
VMROOTPATH="C:\\UFV\\hosts\\UFV\\APP-SERVERS\\${VMNAME}"
DISKPATH="${VMROOTPATH}\\disks"
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\ubuntu-24.04.1-live-server-amd64.iso"
BOOTDISK="${DISKPATH}\\UFV_APPSERVER_Disk_Boot.vdi"
BOOTDISKSIZE=5000
DISK1="${DISKPATH}\\UFV_APPSERVER_Disk_SO_1.vdi"
DISK2="${DISKPATH}\\UFV_APPSERVER_Disk_SO_2.vdi"
DISK1SIZE=50000
NET_ADAPTER="Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)"
CPUS=4
RAM=2048

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
    echo "     - BOOTDISK: ${BOOTDISK}"
    echo "     - BOOTDISKSIZE: ${BOOTDISKSIZE}"
    echo "     - DISK1: ${DISK1}"
    echo "     - DISK2: ${DISK2}"
    echo "     - DISK1SIZE: ${DISK1SIZE}"
    echo "     - CPUS: ${CPUS}"
    echo "     - RAM: ${RAM}"
    
    read -p "¿Estás seguro de continuar? (si/no): " respuesta
   
    if [ "$respuesta" != "si" ]; then
        echo "Operación abortada."
        exit 2
    fi
fi

#BOOTDISK="${DISKPATH}\\UFV_APPSERVER_Disk_Boot.vdi"
#BOOTDISKSIZE=5000
#DISK1="${DISKPATH}\\UFV_APPSERVER_Disk_SO_1.vdi"
#DISK2="${DISKPATH}\\UFV_APPSERVER_Disk_SO_2.vdi"
#DISK1SIZE=50000
#NET_ADAPTER="Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)"
#CPUS=4
#RAM=2048

# Crear la máquina virtual
VBoxManage createvm --name "$VMNAME" --groups "$VMGROUP" --ostype "Ubuntu_64" --register

# Configurar ruta de almacenamiento
VBoxManage modifyvm "$VMNAME" --snapshotfolder "$SNAPSHOTPATH"

# Configurar recursos de la VM
VBoxManage modifyvm "$VMNAME" --memory $RAM --cpus $CPUS --vram 128

# Configurar red en modo puente
VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "$NET_ADAPTER"

# Crear y adjuntar disco duro
mkdir -p "$DISKPATH"

VBoxManage createhd --filename "$BOOTDISK" --size "$BOOTDISKSIZE" --format VDI
VBoxManage createhd --filename "$DISK1" --size "$DISK1SIZE" --format VDI
VBoxManage createhd --filename "$DISK2" --size "$DISK1SIZE" --format VDI
VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$BOOTDISK"
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium "$DISK1"
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 2 --device 0 --type hdd --medium "$DISK2"

# Adjuntar ISO de instalación
VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

# Configurar arranque desde CD
VBoxManage modifyvm "$VMNAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none


VBoxManage sharedfolder add "$VMNAME" --name "UFV" --hostpath "C:\UFV" --automount
