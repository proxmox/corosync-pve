include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=corosync

CSVERSION=${DEB_VERSION_UPSTREAM}

BUILDDIR=${PACKAGE}-${CSVERSION}
CSSRC=upstream

QDEV_SRC=corosync-qdevice
QDEV_VERS=3.0.0
QDEV_BUILD=${QDEV_SRC}-${QDEV_VERS}
QDEV_DEBDOWNLOADRELEASe=4
QDEV_DEBRELEASE=4~bpo9

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell git rev-parse HEAD)

MAIN_DEB=corosync_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \

OTHER_DEBS=\
corosync-notifyd_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
corosync-doc_${DEB_VERSION}_all.deb \
libcfg7_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcmap4_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcorosync-common4_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcpg4_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libquorum5_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libsam4_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libvotequorum8_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcfg-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcmap-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcorosync-common-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcpg-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libquorum-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libsam-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libvotequorum-dev_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \

DBG_DEBS=\
corosync-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
corosync-notifyd-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcfg7-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcmap4-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcorosync-common4-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libcpg4-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libquorum5-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libsam4-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \
libvotequorum8-dbgsym_${DEB_VERSION}_${DEB_BUILD_ARCH}.deb \

QDEV_DEBS=\
corosync-qdevice_${QDEV_VERS}-${QDEV_DEBRELEASE}_${DEB_BUILD_ARCH}.deb \
corosync-qnetd_${QDEV_VERS}-${QDEV_DEBRELEASE}_${DEB_BUILD_ARCH}.deb \

QDEV_DBG_DEBS=\
corosync-qdevice-dbgsym_${QDEV_VERS}-${QDEV_DEBRELEASE}_${DEB_BUILD_ARCH}.deb \
corosync-qnetd-dbgsym_${QDEV_VERS}-${QDEV_DEBRELEASE}_${DEB_BUILD_ARCH}.deb \

DEBS=${MAIN_DEB} ${OTHER_DEBS} ${DBG_DEBS} ${QDEV_DEBS} ${QDEV_DBG_DEBS}

DSC=corosync-pve_${DEB_VERSION}.dsc

all: ${DEBS}
	echo ${DEBS}

${BUILDDIR}: submodule debian/changelog
	rm -rf $@ $@.tmp
	cp -a ${CSSRC} $@.tmp
	cp -a debian $@.tmp
	mv $@.tmp $@

.PHONY: deb
deb: ${DEBS}
${OTHER_DEBS} ${DBG_DEBS}: ${MAIN_DEB}
${MAIN_DEB}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -b -us -uc

.PHONY: qdev-deb
qdev-deb: ${QDEV_DEBS} ${QDEV_DBG_DEBS}
${QDEV_DEBS} ${QDEV_DBG_DEBS}: ${QDEV_SRC}
	rm -rf ${QDEV_BUILD} ${QDEV_BUILD}.tmp
	cp -a ${QDEV_SRC} ${QDEV_BUILD}.tmp
	cd ${QDEV_BUILD}.tmp; patch -p1 < ../qdev-patches/QDEVICE-switch-debian-compat-to-10.patch
	mv ${QDEV_BUILD}.tmp/debian/changelog ${QDEV_BUILD}.tmp/debian/changelog.org
	cat qdev-changelog.Debian ${QDEV_BUILD}.tmp/debian/changelog.org > ${QDEV_BUILD}.tmp/debian/changelog
	mv ${QDEV_BUILD}.tmp ${QDEV_BUILD}
	cd ${QDEV_BUILD}; dpkg-buildpackage -b -us -uc

.PHONY: dsc
dsc: ${DSC}
${DSC}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -S -us -uc -d -nc

.PHONY: submodule
submodule:
	test -f "${CSSRC}/INSTALL" || git submodule update --init ${CSSRC}

.PHONY: download-qdev
download-qdev:
	rm -rf ${QDEV_SRC} ${QDEV_SRC}.tmp
	git clone https://salsa.debian.org/ha-team/corosync-qdevice.git -b debian/${QDEV_VERS}-${QDEV_DEBDOWNLOADRELEASe} ${QDEV_SRC}.tmp
	rm -rf ${QDEV_SRC}.tmp/.git
	mv ${QDEV_SRC}.tmp ${QDEV_SRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product corosync-3 --dist stretch --arch ${DEB_BUILD_ARCH}

.PHONY: clean
distclean: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${BUILDDIR} ${QDEV_BUILD}
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
