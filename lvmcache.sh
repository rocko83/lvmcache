#!/bin/bash -x
export tempo=1
export VGNAME=ubuntu-vg
export LVNAME=damatoluks
function looplivre() {
	seq 1 100 | \
	while read valor
	do
		retorno=$(losetup -a | grep -w /dev/loop$valor| wc -l)
		if [ $retorno -eq 0 ]
			then echo /dev/loop$valor
			break
		fi
	done
}
function criar() {
	temporario=$(mktemp -d)
	mount -t tmpfs -o size=$1m tmpfs $temporario
	dd if=/dev/zero of=$temporario/data bs=1M count=$1
	losetup $LOOPDEVICE $temporario/data
	vgextend $VGNAME $LOOPDEVICE
	PE=$(pvdisplay $LOOPDEVICE | grep "Total PE" | awk '{print $3}')
	DEZPC=$(expr $PE \/ 10)
	NOVENTAPC=$(expr $PE - $DEZPC)
	lvcreate -n meta0 -l $NOVENTAPC $VGNAME $LOOPDEVICE
	lvcreate -n meta0m -l $DEZPC $VGNAME $LOOPDEVICE
	lvconvert --type cache-pool --poolmetadata $VGNAME/meta0m $VGNAME/meta0
	lvconvert --type cache --cachepool $VGNAME/meta0 $VGNAME/$LVNAME
}
function ajuda() {
	echo criar/apagar
	echo $0 criar \<tamanho em megas\>
	echo $0 apagar \<mount point do tmpfs\>
	echo Exemplo:
	echo $0 criar 2048
	echo $0 apagar /tmp/tmp.345nsYquJt
}
function apagar() {
	lvconvert --splitcache $VGNAME/$LVNAME
	lvremove $VGNAME/meta0
	vgreduce $VGNAME $LOOPDEVICE
	losetup -d $LOOPDEVICE
	umount $1
}
if [ $# -eq 2 ] 
then
	case $1 in
		criar)
			export LOOPDEVICE=$(looplivre)
			criar $2
			;;	
		apagar)
			export LOOPDEVICE=$(losetup -a | grep $2 | awk -F : '{print $1}')
			apagar $2
			;;	
		*)
			ajuda
			;;	
	esac
else
	ajuda
fi
