#!/bin/bash

# Argumentos:
# $1 = nombreNasServer

PATH="/cygdrive/c/Program Files/Oracle/VirtualBox:${PATH}"
export PATH

VMNAME=${1}
VMGROUP="/UFV/NAS"
VMROOTPATH="C:\\UFV\\hosts\\UFV\\NAS\\${VMNAME}"
DISKPATH="${VMROOTPATH}\\disks"
SNAPSHOTPATH="${VMROOTPATH}\\snaps"
ISO_PATH="C:\\UFV\\isos\\TrueNAS-SCALE-24.10.0.2.iso"

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

echo "Empezando proceso de creacion"



DISK_SIZE_10GB=10240  # Tamaño en MB (10GB)
DISK_SIZE_12GB=12288  # Tamaño en MB (12GB)

DISK_SIZE=20000
NUM_DISKS=40
NUM_CONTROLLERS=3  # Número de controladoras
DISKS_PER_CONTROLLER=20

# Tipos de controladoras compatibles con VirtualBox
CONTROLLER_TYPES=("ide" "sata" "sas")

# Comprobando directorios de VM:
if [ -d ${VMROOTPATH} ]; then
	echo "La ruta seleccionada ${VMROOTPATH} ya existe. Chequee su configuracion en VirtualBox"
	exit 3
fi
mkdir "${VMROOTPATH}"
mkdir "${DISKPATH}"
mkdir "${SNAPSHOTPATH}"

# Crear la máquina virtual
echo "Creando máquina virtual $VMNAME en el grupo $VMGROUP..."
VBoxManage createvm --name "$VMNAME" --ostype "Debian_64" --register --groups "$VMGROUP"

# Configurar memoria y CPU
echo "Configurando memoria y CPU..."
VBoxManage modifyvm "$VMNAME" --memory 4096 --cpus 8 --vram 128

# Configurar rutas de logs y snapshots
echo "Configurando rutas de logs y snapshots..."
VBoxManage modifyvm "$VMNAME" --snapshotfolder "$SNAPSHOTPATH"

# Configurar red con adaptador puente
echo "Configurando red en modo puente..."
VBoxManage modifyvm "$VMNAME" --nic1 bridged --bridgeadapter1 "Killer(R) Wi-Fi 6 AX1650i 160MHz Wireless Network Adapter (201NGW)"

# Agregar almacenamiento
echo "Creando almacenamiento para el SO de VM..."
VBoxManage createhd --filename "$DISKPATH/${VMNAME}_SO_1.vdi" --size 40000 --format VDI

# Crear y configurar controladoras
for c in $(seq 0 $((NUM_CONTROLLERS - 1))); do
    CONTROLLER_NAME="Controller_$c"
    CONTROLLER_TYPE=${CONTROLLER_TYPES[$c]}
    echo "Agregando $CONTROLLER_NAME de tipo $CONTROLLER_TYPE..."
    VBoxManage storagectl "$VMNAME" --name "$CONTROLLER_NAME" --add "$CONTROLLER_TYPE"
done

# Asociar disco principal y la ISO en la controladora IDE
VBoxManage storageattach "$VMNAME" --storagectl "Controller_0" --port 0 --device 0 --type hdd --medium "$DISKPATH/${VMNAME}_SO_1.vdi"
VBoxManage storageattach "$VMNAME" --storagectl "Controller_0" --port 1 --device 0 --type dvddrive --medium "$ISO_PATH"

# Crear y asociar discos adicionales
mkdir -p "$DISKPATH"

for i in $(seq 1 $NUM_DISKS); do
    CONTROLLER_INDEX=$(( (i - 1) / DISKS_PER_CONTROLLER + 1 ))
    PORT_INDEX=$(( (i - 1) % DISKS_PER_CONTROLLER ))
    CONTROLLER_NAME="Controller_$CONTROLLER_INDEX"
    DISK_FILE="$DISKPATH/${VMNAME}_${CONTROLLER_NAME}_${PORT_INDEX}_DISK_${i}.vdi"

    echo "Creando disco $DISK_FILE..."
    
    #if [ $i -le 20 ]; then
    #    DISK_SIZE=20000
    #else
    #    DISK_SIZE=20000
    #fi
    
    VBoxManage createhd --filename "$DISK_FILE" --size $DISK_SIZE --format VDI

    echo "Asociando disco $DISK_FILE a $CONTROLLER_NAME en el puerto $PORT_INDEX..."
    VBoxManage storageattach "$VMNAME" --storagectl "$CONTROLLER_NAME" --port $PORT_INDEX --device 0 --type hdd --medium "$DISK_FILE"
done

echo "Proceso completado."
