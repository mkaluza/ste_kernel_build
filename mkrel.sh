#!/bin/bash

build_root=/tmp/.build

set -x 
build=""
overlay=""

if [ -z "$1" ]; then
	echo "Usage: $0 version [build] [-- config_overlay]"
	exit 1
fi

rel=$1
shift
while [ -n "$1" ]; do
	if [ "$1" == "--" ]; then
		shift;
		break;
	fi
	build="$build $1"
	shift
done

if [ -n "$1" ]; then
	overlays="$@"
else
	overlays=""
fi

soft="$soft"

set -x 
set -o nounset
set -e

#prep
src=$PWD
base_dir=`readlink -f $0`
base_dir=`dirname $base_dir`

[ -z "$soft" ] && rm -rf $build_root
mkdir -p $build_root/{kernel,ramdisk}
kdir=$build_root/kernel
rddir=$build_root/ramdisk
if [ -z "$soft" ]; then
	git clone --shared --branch $rel $PWD $kdir/
	git clone --shared --branch master $(readlink -f $PWD/../ramdisk/) $rddir
fi

#initramfs
cd $rddir
rm -f *.cpio
make

cd $kdir

#cp $src/usr/u8500_initramfs_files/ramdisk-recovery.cpio $kdir/usr/u8500_initramfs_files/recovery
#cp $rddir/boot.cpio $kdir/usr/u8500_initramfs_files/boot.cpio
cp $rddir/*.cpio  $kdir/usr/u8500_initramfs_files/

[ ! -r source ] && ln -s ./ source
[ ! -r flash.sh ] && ln -s $src/flash.sh ./

[ -z "$build" ] && build=`ls arch/arm/configs/mk_*_defconfig | xargs -L 1 basename | sed -e "s/^mk_//" | sed -e "s/_defconfig$//"`
for ver in $build; do
	dest=$src/rel/$rel/$ver

	#FIXME niech doklada kolenjny numer?
	#[ -d $dest -a -z "${FORCE:-''}" ] && continue
	make mk_${ver}_defconfig
	if [ -n "$overlays" ]; then
		for o in $overlays; do
			cat $src/${o:-} >> .config
		done
	fi
	[ -z "$soft" ] && make clean
	make -j 5

	mkdir -p $dest/modules

	cp arch/arm/boot/zImage $dest

	cp `find -iname *.ko` $dest/modules

	cwm=$dest/.cwm
	cwm_zip=$dest/../mk-kernel-$rel-$ver-CWM.zip

	rm -rf $cwm $cwm_zip
	mkdir -p $cwm

	#update.zip
	cp -rl $base_dir/CWM/META-INF $cwm/
	ln -s $base_dir/CWM/efs $cwm/
	ln -s $base_dir/CWM/utils $cwm/
	sed $base_dir/CWM/tpl/updater-script -e "s/__BUILD__/$ver/" > $cwm/META-INF/com/google/android/updater-script
	ln $dest/zImage $cwm/
	ln -s $dest/modules $cwm/
	cd $cwm
	zip $cwm_zip -r META-INF zImage modules utils
	cd -
done

echo "Created $cwm_zip"
#git checkout $branch
