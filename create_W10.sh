#!/bin/bash

# Argumentos:
# $1 = nombreNasServer

PATH="/cygdrive/c/Program Files/Oracle/VirtualBox:${PATH}"
export PATH

VMNAME=${1}
VMGROUP="/UFV/W10"
VMROOTPATH="C:\\UFV\\hosts\\UFV\\W10\\${VMNAME}"
DISKPATH="${VMROOTPATH}\\disks"
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\windowsserver2019.iso"

if [ "$#" -ne 1 ]; then
	echo "Numero de argumentos invalidos: ${0} serverName"
	exit 1
else
	echo "Advertencia: Se creara el servidor NAS llamado ${1} con esta configuracion:"
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
DISK1SIZE=50000
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\windowsserver2019.iso"
NET_ADAPTER="Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)"
CPUS=4
RAM=2048

# Crear la máquina virtual
VBoxManage createvm --name "$VMNAME" --groups "$VMGROUP" --ostype "Windows2019_64" --register

# Configurar ruta de almacenamiento
VBoxManage modifyvm "$VMNAME" --snapshotfolder "$SNAPSHOTPATH"

# Configurar recursos de la VM
VBoxManage modifyvm "$VMNAME" --memory $RAM --cpus $CPUS --vram 128

# Configurar red en modo puente
VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "$NET_ADAPTER"

# Crear y adjuntar disco duro
mkdir -p "$DISKPATH"
VBoxManage createhd --filename "$DISK1" --size "$DISK1SIZE" --format VDI
VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK1"

# Adjuntar ISO de instalación
VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

# Configurar arranque desde CD
VBoxManage modifyvm "$VMNAME" --boot1 dvd --boot2 disk --boot3 none --boot4 none

# Iniciar la máquina virtual
#VBoxManage startvm "$VMNAME" --type gui

echo "Máquina virtual $VMNAME creada y configurada correctamente."
