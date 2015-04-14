#!/usr/bin/env bash
# Generate a minimal filesystem for archlinux and load it into the local
# docker as "archlinux"
# requires root
set -e

export LANG="C.UTF-8"

ROOTFS=$(mktemp -d ${TMPDIR:-/var/tmp}/rootfs-archlinux-XXXXXXXXXX)
chmod 755 $ROOTFS
# mkdir -p $ROOTFS/usr/bin/ $ROOTFS/{dev,proc,root,etc,bin,tmp,sys,run} $ROOTFS/var/lib/pacman $ROOTFS/etc/pacman.d
mkdir -p $ROOTFS/var/lib/pacman $ROOTFS/etc/pacman.d

pack() {
	pacman --noconfirm --force -r $ROOTFS $@
}
pack -Sddy filesystem

pack -Udd \
	/home/matt/develop/arch-slim/packages/busybox/trunk/busybox-1.23.2-1-x86_64.pkg.tar.xz \
	/home/matt/develop/arch-slim/packages/glibc/trunk/glibc-2.21-2-x86_64.pkg.tar.xz

pack -Sdd \
	readline \
	ncurses \
	bash

#pack -Sdd bash
	# p11-kit \
	# libffi \
	# libtasn1

pack -Udd \
	./pacman-static/pacman-static-2015-5-x86_64.pkg.tar.xz 
	#/home/matt/develop/arch-slim/packages/openssl/trunk/openssl-1.0.2.a-1-x86_64.pkg.tar.xz \
	# /home/matt/develop/arch-slim/packages/ca-certificates/trunk/ca-certificates-utils-20150402-1-any.pkg.tar.xz \
	# /home/matt/develop/arch-slim/packages/ca-certificates/trunk/ca-certificates-20150402-1-any.pkg.tar.xz \
	# /home/matt/develop/arch-slim/packages/nss/trunk/ca-certificates-mozilla-3.18-3-x86_64.pkg.tar.xz \



cp /etc/resolv.conf $ROOTFS/etc/
cp ./mkimage-arch-pacman.conf $ROOTFS/etc/pacman.conf
arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/man/*' || true
arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/lib/systemd/system/* /usr/share/man/* /usr/share/i18n/* /usr/share/locale/* /usr/share/info/* /usr/share/doc/*' || true
arch-chroot $ROOTFS /bin/sh -c 'echo "Server = http://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

tar --numeric-owner --xattrs --acls -C $ROOTFS -c . | docker import - archlinux
docker run -t archlinux echo Success.
rm -rf $ROOTFS
