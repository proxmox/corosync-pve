RELEASE=5.0

# source from http://www.corosync.org

CSVERSION=2.4.4
CSRELEASE=pve1
DEBRELEASE=3
CSDIR=corosync-${CSVERSION}
CSSRC=corosync_${CSVERSION}.orig.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell git rev-parse HEAD)

MAIN_DEB=corosync-pve_${CSVERSION}-${CSRELEASE}_all.deb

OTHER_DEBS=\
libcorosync4-pve_${CSVERSION}-${CSRELEASE}_all.deb \
corosync_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-notifyd_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-qdevice_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-qnetd_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-doc_${CSVERSION}-${CSRELEASE}_all.deb \
corosync-dev_${CSVERSION}-${CSRELEASE}_all.deb \
libcfg6_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcmap4_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcorosync-common4_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcpg4_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libquorum5_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libsam4_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libtotem-pg5_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libvotequorum8_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcfg-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcmap-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcorosync-common-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcpg-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libquorum-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libsam-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libtotem-pg-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libvotequorum-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \

DBG_DEBS=\
corosync-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-notifyd-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-qdevice-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
corosync-qnetd-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcfg6-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcmap4-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcorosync-common4-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libcpg4-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libquorum5-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libsam4-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libtotem-pg5-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
libvotequorum8-dbgsym_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \

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
	tar cf - ${DEBS} | ssh -X repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${CSDIR} *.debian.tar.xz
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
