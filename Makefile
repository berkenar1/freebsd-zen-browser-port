# ============================================================================
# BASIC PORT IDENTIFICATION (strict order required)
# ============================================================================
PORTNAME=		zen-browser
DISTVERSION=	1.17.15b
PORTREVISION=	0
PORTEPOCH=	1
CATEGORIES=	www wayland


# ============================================================================
# DISTRIBUTION FILES (must come right after CATEGORIES)
# ============================================================================
MASTER_SITES=		https://github.com/zen-browser/desktop/releases/download/${DISTVERSION}/
DISTFILES=		zen.source.tar.zst

# ============================================================================
# MAINTAINER INFORMATION
# ============================================================================
MAINTAINER=		ports@FreeBSD.org
COMMENT=		Zen Browser - Firefox-based privacy-focused browser
WWW=			https://zen-browser.app

# ============================================================================
# LICENSE
# ============================================================================
LICENSE=		MPL20
LICENSE_FILE=   ${WRKSRC}/LICENSE


LIB_DEPENS= 	libnspr4.so:devel/nspr \
		libnss3.so:security/nss \
		libgtk-3.so.0:x11-toolkits/gtk30 \
		libcairo.so.2:graphics/cairo \
		libpango-1.0.so.0:x11-toolkits/pango \
		libwayland-client.so.0:graphics/wayland \
		libfontconfig.so.1:x11-fonts/fontconfig \
		libfreetype.so.6:print/freetype2 \
		libharfbuzz.so.0:print/harfbuzz \
		libdbus-1.so.3:devel/dbus \
		libicu*.so:devel/icu \
		libpng16.so.16:graphics/png \
		libjpeg.so.*:graphics/jpeg-turbo \
		libsqlite3.so:databases/sqlite3 \
		libpipewire-0.3.so.0:audio/pipewire \
		libzstd.so:archivers/zstd \
                libdav1d.so:multimedia/dav1d \
                libaom.so:multimedia/aom \
                libjxl.so:graphics/jpeg-xl \
                libsrtp.so:net/libsrtp \
                libepoxy.so:graphics/libepoxy \
                libcups.so:print/cups \



CARGO_CARGO_BIN=        ${HOME}/.cargo/bin/cargo
CARGO_VENDOR_DIR=       ${WRKSRC}/cargo-crates
CARGO_CARGOLOCK=        ${WRKSRC}/Cargo.lock


.if exists(${.CURDIR}/Makefile.crates)
.include "${.CURDIR}/Makefile.crates"
.endif



# Work around bindgen not finding ICU headers
CONFIGURE_ENV+=	BINDGEN_CFLAGS="-I${LOCALBASE}/include"

LLVM_VERSION=	20
# ============================================================================
# DEPENDENCIES (must appear before USES)
# ============================================================================
BUILD_DEPENDS=	nspr>=4.32:devel/nspr \
		nss>=3.118:security/nss \
		icu>=76.1:devel/icu \
		libevent>=2.1.8:devel/libevent \
		harfbuzz>=10.1.0:print/harfbuzz \
		graphite2>=1.3.14:graphics/graphite2 \
		png>=1.6.45:graphics/png \
		dav1d>=1.0.0:multimedia/dav1d \
		libvpx>=1.15.0:multimedia/libvpx \
		${PYTHON_PKGNAMEPREFIX}sqlite3>0:databases/py-sqlite3@${PY_FLAVOR} \
		v4l_compat>0:multimedia/v4l_compat \
		nasm:devel/nasm \
		yasm:devel/yasm \
		zip:archivers/zip \
		alsa-lib>=1.2.14:audio/alsa-lib \
		${LOCALBASE}/share/wasi-sysroot/lib/wasm32-wasi/libc++abi.a:devel/wasi-libcxx20 \
		${LOCALBASE}/share/wasi-sysroot/lib/wasm32-wasi/libc.a:devel/wasi-libc@20 \
		wasi-compiler-rt20>0:devel/wasi-compiler-rt20


# ============================================================================
# BUILD FRAMEWORK
# ============================================================================



USES=		cargo \
		tar:zst \
		gmake \
		python:3.11,build \
		compiler:c++17-lang \
		cmake:noninja \
		pkgconfig \
		localbase:ldflags \
		gl \
		gnome \
		desktop-file-utils \
		libtool \
		xorg \
		gettext

USE_GL=		gl
USE_GNOME=	cairo gtk30


BUILD_DEPENDS=	nspr>=4.32:devel/nspr \
		nss>=3.118:security/nss \
		icu>=76.1:devel/icu \
		libevent>=2.1.8:devel/libevent \
		harfbuzz>=10.1.0:print/harfbuzz \
		graphite2>=1.3.14:graphics/graphite2 \
		png>=1.6.45:graphics/png \
		dav1d>=1.0.0:multimedia/dav1d \
		libvpx>=1.15.0:multimedia/libvpx \
		${PYTHON_PKGNAMEPREFIX}sqlite3>0:databases/py-sqlite3@${PY_FLAVOR} \
		v4l_compat>0:multimedia/v4l_compat \
		nasm:devel/nasm \
		yasm:devel/yasm \
		zip:archivers/zip \
		alsa-lib>=1.2.14:audio/alsa-lib

# ============================================================================
# EXTRACTION & WORKING DIRECTORY
# ============================================================================

EXTRACT_CMD=		/usr/bin/bsdtar

WRKSRC=			${WRKDIR}

# ============================================================================
# COMPILER & BUILD FLAGS
# ============================================================================
CPPFLAGS+=		-I${FILESDIR} \
			-I${LOCALBASE}/include

# ============================================================================
# BUILD ENVIRONMENT & TOOLS
# ============================================================================
MAKE_ENV+=		PATH=${HOME}/.cargo/bin:${PATH}
CONFIGURE_ENV+=		PATH=${HOME}/.cargo/bin:${PATH} \
			BINDGEN_CFLAGS="-I${LOCALBASE}/include"

CARGO=		${HOME}/.cargo/bin/cargo
RUSTC=		${HOME}/.cargo/bin/rustc

CARGO_ENV+=	RUSTUP_TOOLCHAIN=stable
MAKE_ENV+=	RUSTUP_TOOLCHAIN=stable
CONFIGURE_ENV+=	RUSTUP_TOOLCHAIN=stable

MAKE_ENV+=	CARGO=${CARGO} RUSTC=${RUSTC}
CONFIGURE_ENV+=	CARGO=${CARGO} RUSTC=${RUSTC}

WASI_SYSROOT=           /usr/local/share/wasi-sysroot

# ============================================================================
# MOZILLA BUILD OPTIONS
# ============================================================================
MOZ_OPTIONS+=		--with-system-sqlite \
			--enable-pipewire \
			--enable-jemalloc \
			--disable-lto \
			--without-wasm-sandboxed-libraries  \
                    --with-wasi-sysroot=${WASI_SYSROOT}


CONFIGURE_ENV+=         WASI_SYSROOT=${WASI_SYSROOT}


CONFIGURE_ARGS+=	--with-system-sqlite \
			--enable-pipewire \
			--disable-lto


USE_GECKO=	gecko
USE_MOZILLA=	-sqlite


# Enable Mozilla's jemalloc (suppresses WIN32_REDIST_DIR warning)
MOZ_OPTIONS+=	--enable-jemalloc


USE_GL=		gl
USE_GNOME=	cairo gdkpixbuf2 gtk30




# ============================================================================
# PARALLEL JOBS
# ============================================================================
MAKE_JOBS=		2

# ============================================================================
# INSTALLATION METADATA
# ============================================================================
ZEN_ICON=		${PORTNAME}.png
ZEN_ICON_SRC=		${PREFIX}/lib/${PORTNAME}/browser/chrome/icons/default/default48.png


WRKSRC=		${WRKDIR}

# Add ALSA compatibility headers from files/ directory
CPPFLAGS+=	-I${FILESDIR}

# Use rust from ports and enable ccache

CONFIGURE_ENV=  RUSTC=${LOCALBASE}/bin/rustc \
                CARGO=${LOCALBASE}/bin/cargo \
                CCACHE=${LOCALBASE}/bin/ccache

MAKE_ENV=       RUSTC=${LOCALBASE}/bin/rustc \
                CARGO=${LOCALBASE}/bin/cargo \
                RUSTUP_HOME=nonexistent \
                CARGO_HOME=nonexistent \
                CCACHE=${LOCALBASE}/bin/ccache \
                CCACHE_DIR=${.CURDIR}/ccache \
                PATH=${LOCALBASE}/bin:${LOCALBASE}/sbin:/bin:/sbin:/usr/bin:/usr/sbin

# Enable ccache for faster rebuilds (use per-tree cache to avoid global /var/cache conflicts)
MOZ_OPTIONS+=	--with-ccache=${LOCALBASE}/bin/ccache


do-configure:
	${MKDIR} ${.CURDIR}/ccache || true
	@${ECHO_MSG} "===> Vendoring Rust dependencies via mach"
	cd ${WRKSRC} && \
		${ECHO} "# Generated by ports: apply MOZ_OPTIONS" > .mozconfig && \
		for opt in ${MOZ_OPTIONS}; do ${ECHO} "ac_add_options $$opt" >> .mozconfig; done
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${FILESDIR}/patch_rust_manifests.sh ${WRKSRC} || true && \
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ./mach vendor rust || true
	@${ECHO_MSG} "===> Configuring build"
	cd ${WRKSRC} && ${SETENV} ${CONFIGURE_ENV} ./mach configure
				

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ./mach build

post-patch:
	@${ECHO_MSG} "===> Applying FreeBSD patches automatically"
	@cd ${FILESDIR} && \
		for p in patch-*; do \
			if [ -f "$$p" ]; then \
				${ECHO_MSG} "  -> Applying $$p"; \
				if ${PATCH} -d ${WRKSRC} -p0 -N -E < "$$p" > /dev/null 2>&1; then \
					${ECHO_MSG} "     [OK]"; \
				elif [ $$? -eq 1 ]; then \
					${ECHO_MSG} "     [SKIPPED - already applied]"; \
				else \
					${ECHO_MSG} "===> FAILED: $$p"; \
					exit 1; \
				fi; \
			fi; \
		done
	@${ECHO_MSG} "===> All patches processed"

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}
	${MKDIR} ${STAGEDIR}${PREFIX}/bin
	# Copy built application to staging directory
	cd ${WRKSRC}/obj-*/dist/bin && \
		${FIND} . -type d -exec ${MKDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \; && \
		${FIND} . -type f -exec ${INSTALL_DATA} {} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \; && \
		${FIND} . -type f -perm +111 -exec ${INSTALL_PROGRAM} {} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \;
	# Create wrapper script
	${ECHO_CMD} '#!/bin/sh' > ${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${ECHO_CMD} 'exec ${PREFIX}/lib/${PORTNAME}/zen-bin "$$@"' >> ${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${CHMOD} +x ${STAGEDIR}${PREFIX}/bin/${PORTNAME}

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/pixmaps
	${LN} -sf ${ZEN_ICON_SRC} ${STAGEDIR}${PREFIX}/share/pixmaps/${ZEN_ICON}
	${MKDIR} ${STAGEDIR}${PREFIX}/share/applications
	${INSTALL_DATA} ${WRKDIR}/zen.desktop ${STAGEDIR}${PREFIX}/share/applications 2>/dev/null || true

# ============================================================================
# CARGO CRATES / MAKEFILE.CRATES
# ============================================================================
# Generate `Makefile.crates` from the vendored rust crates. This avoids
# requiring backend-generated Makefile.crates in the objdir and lets the
# FreeBSD port process proceed when third-party crates are present in
# ${WRKSRC}/third_party/rust (created by `./mach vendor rust`).
# Usage:
#   make makefile-crates
makefile-crates: extract
	@${ECHO_MSG} "===> Generating ${.CURDIR}/Makefile.crates from vendored crates"
	@${ECHO} "# Auto-generated cargo crates list" > ${.CURDIR}/Makefile.crates
	@${ECHO} "CARGO_CRATES= \" >> ${.CURDIR}/Makefile.crates
	@if [ -d "${WRKSRC}/third_party/rust" ]; then \
		cd ${WRKSRC}/third_party/rust && for d in */; do name=$${d%/}; ${ECHO} "		$${name} \" >> ${.CURDIR}/Makefile.crates; done; \
	elif [ -d "${WRKSRC}/cargo-crates" ]; then \
		cd ${WRKSRC}/cargo-crates && for d in */; do name=$${d%/}; ${ECHO} "		$${name} \" >> ${.CURDIR}/Makefile.crates; done; \
	else \
		${ECHO_MSG} "===> No vendored crates found under ${WRKSRC}/third_party/rust or ${WRKSRC}/cargo-crates"; exit 1; \
	fi
	@${ECHO} "" >> ${.CURDIR}/Makefile.crates
	@${ECHO_MSG} "===> ${.CURDIR}/Makefile.crates generated"
	@${ECHO_MSG} "===> (Note: you can also run './mach vendor rust' inside ${WRKSRC} to create third_party/rust)"

.include <bsd.port.mk>
