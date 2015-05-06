#!/system/bin/sh

echo "Updating modules..."
for p in `find /efs -iname *.ko`; do
	m=`basename $p`
	if [ -f /system/lib/modules/$m ]; then
		echo "Updating $p"
		cp -f /system/lib/modules/$m $p
	else
		echo "Warning - can't update $p: module $m not found in /system/lib/modules/"
	fi
done
