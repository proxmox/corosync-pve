RELEASE=4.2

# source from http://www.corosync.org

CSVERSION=2.4.2
CSRELEASE=2
CSDIR=corosync-${CSVERSION}
CSSRC=corosync-${CSVERSION}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1 := corosync-pve_${CSVERSION}-${CSRELEASE}_${ARCH}.deb

DEB2 := libcorosync4-pve_${CSVERSION}-${CSRELEASE}_${ARCH}.deb \
	libcorosync-pve-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb

DEBS := $(DEB1) $(DEB2)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb: $(DEB1)
$(DEB2): $(DEB1)
${DEB1}: ${CSSRC}
	rm -rf ${CSDIR}
	tar xf ${CSSRC} 
	cp -a debian ${CSDIR}/debian
	echo "git clone git://git.proxmox.com/git/corosync-pve.git\\ngit checkout ${GITVERSION}" >  ${CSDIR}/debian/SOURCE

	cd ${CSDIR}; dpkg-buildpackage -b -us -uc

.PHONY: download
download:
	rm -rf ${CSSRC} ${CSSRC}.tmp ${CSDIR}
	# wget http://build.clusterlabs.org/corosync/releases/${CSSRC}
	git clone https://github.com/corosync/corosync.git  -b needle ${CSDIR}
	cd ${CSDIR}; git checkout v${CSVERSION}
	cd ${CSDIR}; ./autogen.sh
	tar czf ${CSSRC}.tmp ${CSDIR}
	mv ${CSSRC}.tmp ${CSSRC}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com upload -dist jessie -arch ${ARCH} -product pve

distclean: clean

.PHONY: clean
clean:
	rm -rf *_${ARCH}.deb *.changes *.dsc ${CSDIR} corosync_${CSVERSION}-${CSRELEASE}.tar.gz
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
