RELEASE=2.0

CSVERSION=1.4.1
CSRELEASE=1
CSDIR=corosync-${CSVERSION}
CSSRC=corosync-${CSVERSION}.orig.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

DEBS=									\
	corosync-pve_${CSVERSION}-${CSRELEASE}_${ARCH}.deb 		\
	libcorosync4-pve_${CSVERSION}-${CSRELEASE}_${ARCH}.deb 		\
	libcorosync-pve-dev_${CSVERSION}-${CSRELEASE}_${ARCH}.deb

all: ${DEBS}
	echo ${DEBS}

${DEBS}: ${CSSRC}
	echo ${DEBS}
	rm -rf ${CSDIR}
	tar xf ${CSSRC} 
	cp -a debian ${CSDIR}/debian
	cd ${CSDIR}; dpkg-buildpackage -rfakeroot -b -us -uc

.PHONY: download
download:
	rm -rf corosync-${CSVERSION} corosync-${CSVERSION}.orig.tar.gz
	git clone git://corosync.org/corosync.git corosync-${CSVERSION}/
	cd corosync-${CSVERSION}; git checkout -b local v${CSVERSION}
	cd corosync-${CSVERSION}; ./autogen.sh
	# do not delete .git, because configure use that to detect version
	tar czf corosync-${CSVERSION}.orig.tar.gz corosync-${CSVERSION}/

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/corosync*.deb
	rm -f /pve/${RELEASE}/extra/libcorosync*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf *_${ARCH}.deb *.changes *.dsc ${CSDIR} corosync_${CSVERSION}-${CSRELEASE}.tar.gz

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
