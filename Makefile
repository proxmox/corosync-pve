include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=corosync

CSVERSION=${DEB_VERSION_UPSTREAM}

BUILDDIR=${PACKAGE}-${CSVERSION}
CSSRC=upstream

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

DEBS=${MAIN_DEB} ${OTHER_DEBS} ${DBG_DEBS}

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

.PHONY: dsc
dsc: ${DSC}
${DSC}: ${BUILDDIR}
	cd ${BUILDDIR}; dpkg-buildpackage -S -us -uc -d -nc

.PHONY: submodule
submodule:
	test -f "${CSSRC}/INSTALL" || git submodule update --init ${CSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist bullseye --arch ${DEB_BUILD_ARCH}

.PHONY: clean
distclean: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${BUILDDIR}
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
