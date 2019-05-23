include /usr/share/dpkg/architecture.mk

CSVERSION=3.0.1
CSRELEASE=pve1
DEBRELEASE=2
CSDIR=corosync-${CSVERSION}
CSSRC=corosync_${CSVERSION}.orig.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell git rev-parse HEAD)

MAIN_DEB=corosync_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \

OTHER_DEBS=\
corosync-notifyd_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
corosync-doc_${CSVERSION}-${CSRELEASE}_all.deb \
libcfg7_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcmap4_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcorosync-common4_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcpg4_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libquorum5_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libsam4_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libvotequorum8_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcfg-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcmap-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcorosync-common-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcpg-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libquorum-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libsam-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libvotequorum-dev_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \

DBG_DEBS=\
corosync-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
corosync-notifyd-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcfg7-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcmap4-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcorosync-common4-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libcpg4-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libquorum5-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libsam4-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \
libvotequorum8-dbgsym_${CSVERSION}-${CSRELEASE}_${DEB_BUILD_ARCH}.deb \

DEBS=${MAIN_DEB} ${OTHER_DEBS} ${DBG_DEBS}

DSC=corosync-pve_${CSVERSION}-${CSRELEASE}.dsc

all: ${DEBS}
	echo ${DEBS}

${CSDIR}: ${CSSRC} patches changelog.Debian
	rm -rf $@ $@.tmp
	mkdir $@.tmp
	tar -C $@.tmp --strip-components=1 -xf ${CSSRC}
	mv $@.tmp/debian/changelog $@.tmp/debian/changelog.org
	cat changelog.Debian $@.tmp/debian/changelog.org > $@.tmp/debian/changelog
	cd $@.tmp; ln -s ../patches patches
	cd $@.tmp; quilt push -a
	cd $@.tmp; rm -rf .pc ./patches
	mv $@.tmp $@

.PHONY: deb
deb: ${DEBS}
${OTHER_DEBS} ${DBG_DEBS}: ${MAIN_DEB}
${MAIN_DEB}: ${CSDIR}
	cd ${CSDIR}; dpkg-buildpackage -b -us -uc

.PHONY: dsc
dsc: ${DSC}
${DSC}: ${CSDIR}
	cd ${CSDIR}; dpkg-buildpackage -S -us -uc -d -nc

.PHONY: download
download:
	rm -rf ${CSSRC} ${CSSRC}.tmp ${CSDIR}
	git clone https://salsa.debian.org/ha-team/corosync.git -b debian/${CSVERSION}-${DEBRELEASE} ${CSDIR}
	tar czf ${CSSRC}.tmp ${CSDIR}
	mv ${CSSRC}.tmp ${CSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist buster --arch ${DEB_BUILD_ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${CSDIR} *.debian.tar.xz
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
