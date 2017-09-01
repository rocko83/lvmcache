#!/bin/bash -x
export tempo=1
export VGNAME=linux
export LVNAME=root
export LOOPDEVICE=/dev/loop0
export ramcachefs=/ramcachefs
export tamanho=2048
function start() {
        mkdir -p $ramcachefs
        mount -t tmpfs -o size="$tamanho"m tmpfs $ramcachefs
        dd if=/dev/zero of=$ramcachefs/data bs=1M count=$tamanho
        losetup $LOOPDEVICE $ramcachefs/data
        vgextend $VGNAME $LOOPDEVICE
        PE=$(pvdisplay $LOOPDEVICE | grep "Total PE" | awk '{print $3}')
        DEZPC=$(expr $PE \/ 10)
        NOVENTAPC=$(expr $PE - $DEZPC)
        lvcreate -n meta0 -l $NOVENTAPC $VGNAME $LOOPDEVICE
        lvcreate -n meta0m -l $DEZPC $VGNAME $LOOPDEVICE
        lvconvert -y --type cache-pool --poolmetadata $VGNAME/meta0m $VGNAME/meta0
        lvconvert -y --type cache --cachepool $VGNAME/meta0 $VGNAME/$LVNAME
}
function ajuda() {
        echo criar/apagar
        echo $0 start
        echo $0 stop
}
function stop() {
        lvconvert -y --splitcache $VGNAME/$LVNAME
        lvremove $VGNAME/meta0
        lvremove $VGNAME/meta0m
        vgreduce $VGNAME $LOOPDEVICE
        vgreduce --remove-missing --force linux
        losetup -d $LOOPDEVICE
        umount $ramcachefs
}
if [ $# -eq 1 ]
then
        case $1 in
                start)  
                        start
                        ;;
                stop)   
                        stop
                        ;;
                *)
                        ajuda
                        ;;
        esac
else
        ajuda
fi
