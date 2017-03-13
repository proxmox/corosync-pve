RELEASE=5.0

# source from http://www.corosync.org

CSVERSION=2.4.2
CSRELEASE=pve2
DEBRELEASE=3
CSDIR=corosync-${CSVERSION}
CSSRC=corosync-${CSVERSION}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEBS=corosync-pve_${CSVERSION}-${CSRELEASE}_all.deb \
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
libvotequorum-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: ${DEBS}
${DEBS}: ${CSSRC}
	rm -rf ${CSDIR}
	tar xf ${CSSRC}
	mv ${CSDIR}/debian/changelog ${CSDIR}/debian/changelog.org
	cat changelog.Debian ${CSDIR}/debian/changelog.org > ${CSDIR}/debian/changelog
	cd ${CSDIR}; ln -s ../patches patches
	cd ${CSDIR}; quilt push -a
	cd ${CSDIR}; rm -rf .pc ./patches
	cd ${CSDIR}; dpkg-buildpackage -b -us -uc

.PHONY: download
download:
	rm -rf ${CSSRC} ${CSSRC}.tmp ${CSDIR}
	git clone https://anonscm.debian.org/git/debian-ha/corosync.git -b debian/${CSVERSION}-${DEBRELEASE} ${CSDIR}
	# wget http://build.clusterlabs.org/corosync/releases/${CSSRC}
	tar czf ${CSSRC}.tmp ${CSDIR}
	mv ${CSSRC}.tmp ${CSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf *.deb *.changes *.dsc *.buildinfo ${CSDIR} corosync_${CSVERSION}-${CSRELEASE}.tar.gz
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
