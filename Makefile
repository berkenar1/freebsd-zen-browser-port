# ============================================================================
# BASIC PORT IDENTIFICATION (strict order required)
# ============================================================================
PORTNAME=		zen-browser
PORTVERSION=		1.17.15
#DISTVERSIONPREFIX=
DISTVERSION=		1.17.15b
#DISTVERSIONSUFFIX=
PORTREVISION=		1
PORTEPOCH=		1
CATEGORIES=		www wayland

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


.include "Makefile.crates"

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

# ============================================================================
# PARALLEL JOBS
# ============================================================================
MAKE_JOBS=		2

# ============================================================================
# INSTALLATION METADATA
# ============================================================================
ZEN_ICON=		${PORTNAME}.png
ZEN_ICON_SRC=		${PREFIX}/lib/${PORTNAME}/browser/chrome/icons/default/default48.png

# ============================================================================
# BUILD TARGETS
# ============================================================================
#post-extract:
#	@${FIND} ${WRKSRC} -name "Cargo.toml" -exec ${SED} -i '' \
		-e 's/edition\.workspace = true/edition = "2021"/g' \
		-e 's/version\.workspace = true/version = "0.1.0"/g' \
		-e 's/authors\.workspace = true/authors = ["Mozilla"]/g' \
		-e 's/license\.workspace = true/license = "MPL-2.0"/g' \
		-e 's/homepage\.workspace = true/homepage = "https:\/\/www.mozilla.org"/g' \
		-e 's/repository\.workspace = true/repository = "https:\/\/github.com\/mozilla\/gecko-dev"/g' \
		-e 's/description\.workspace = true/description = "Mozilla Firefox"/g' \
		-e 's/keywords\.workspace = true/keywords = ["mozilla", "firefox", "browser"]/g' \
		-e 's/categories\.workspace = true/categories = ["web-browsers"]/g' \
		-e 's/rust-version\.workspace = true/rust-version = "1.70"/g' \
		{} \;
#
#


post-extract:
	@${RM} -r ${WRKSRC}/third_party/sqlite3 \
	         ${WRKSRC}/third_party/zstd \
	         ${WRKSRC}/third_party/dav1d \
	         ${WRKSRC}/third_party/aom \
	         ${WRKSRC}/third_party/jpeg-xl \
	         ${WRKSRC}/third_party/libsrtp \
	         ${WRKSRC}/third_party/libepoxy



CONFIGURE_ENV+= PKG_CONFIG_PATH=${LOCALBASE}/libdata/pkgconfig
CPPFLAGS+=     -I${LOCALBASE}/include
LDFLAGS+=      -L${LOCALBASE}/lib




do-configure:


cd ${WRKSRC} && \
	${ECHO} "ac_add_options --without-wasm-sandboxed-libraries" > .mozconfig && \
	${ECHO} "ac_add_options --with-wasi-sysroot=${WASI_SYSROOT}" >> .mozconfig && \
	${SETENV} ${CONFIGURE_ENV} ${MAKE_ENV} \
	./mach configure


do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ./mach build

post-patch:
	@${ECHO_MSG} "===> Applying FreeBSD patches"
	@for p in ${FILESDIR}/patch-*; do \
		if [ -f "$$p" ]; then \
			${ECHO_MSG} "Applying $${p##*/}"; \
			${PATCH} -d ${WRKSRC} -p0 < $$p || exit 1; \
		fi; \
	done

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}
	${MKDIR} ${STAGEDIR}${PREFIX}/bin
	cd ${WRKSRC}/obj-*/dist/bin && \
		${FIND} . -type d -exec ${MKDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \; && \
		${FIND} . -type f -exec ${INSTALL_DATA} {} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \; && \
		${FIND} . -type f -perm +111 -exec ${INSTALL_PROGRAM} {} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}/{} \;
	${ECHO_CMD} '#!/bin/sh' > ${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${ECHO_CMD} 'exec ${PREFIX}/lib/${PORTNAME}/zen-bin "$$@"' >> ${STAGEDIR}${PREFIX}/bin/${PORTNAME}
	${CHMOD} +x ${STAGEDIR}${PREFIX}/bin/${PORTNAME}

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/share/pixmaps
	${LN} -sf ${ZEN_ICON_SRC} ${STAGEDIR}${PREFIX}/share/pixmaps/${ZEN_ICON}
	${MKDIR} ${STAGEDIR}${PREFIX}/share/applications
	${INSTALL_DATA} ${WRKDIR}/zen.desktop ${STAGEDIR}${PREFIX}/share/applications 2>/dev/null || true

.include <bsd.port.mk>
