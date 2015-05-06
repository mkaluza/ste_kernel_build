#!/bin/bash

build="release debug"

if [ -z "$1" ]; then
	echo "Usage: $0 version [build]"
	exit 1
fi

rel=$1
[ -n "$2" ] && build="$2"

set -x 
set -e

for ver in $build; do
	dest=$PWD/rel/$rel/$ver

	[ ! -d $dest ] && continue
	cwm=$dest/.cwm
	cwm_zip=$dest/mk-kernel-$rel-$ver-CWM.zip
	rm -rf $cwm $cwm_zip
	mkdir -p $cwm

	cp -rl $PWD/CWM/META-INF $cwm/
	sed CWM/tpl/updater-script -e "s/__BUILD__/$ver/" > $cwm/META-INF/com/google/android/updater-script
	ln $dest/zImage $cwm/
	ln $dest/modules.zip $cwm/
	cd $cwm
	zip $cwm_zip -r META-INF zImage modules.zip
	cd -
done

