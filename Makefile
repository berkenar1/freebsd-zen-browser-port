PORTNAME=	zen-browser
DISTVERSION=	1.17.12b
PORTREVISION=	0
PORTEPOCH=	1
CATEGORIES=	www wayland

MAINTAINER=	ports@FreeBSD.org
COMMENT=	Zen Browser - Firefox-based privacy-focused browser
WWW=		https://zen-browser.app

MASTER_SITES=	https://github.com/zen-browser/desktop/releases/download/${DISTVERSION}/
DISTFILES=	zen.source.tar.zst

LICENSE=	MPL20

# Work around bindgen not finding ICU headers
CONFIGURE_ENV+=	BINDGEN_CFLAGS="-I${LOCALBASE}/include"

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

USE_GECKO=	gecko
USE_MOZILLA=	-sqlite

# Disable WASM sandboxing (wasi-sysroot not present on FreeBSD)
MOZ_OPTIONS+=	--without-wasm-sandboxed-libraries

# Enable Mozilla's jemalloc (suppresses WIN32_REDIST_DIR warning)
MOZ_OPTIONS+=	--enable-jemalloc

USES=		tar:zst gmake python:3.11,build compiler:c17-lang \
		desktop-file-utils gl gnome localbase:ldflags pkgconfig

USE_GL=		gl
USE_GNOME=	cairo gdkpixbuf2 gtk30

ZEN_ICON=		${PORTNAME}.png
ZEN_ICON_SRC=	${PREFIX}/lib/${PORTNAME}/browser/chrome/icons/default/default48.png

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
                PATH=${LOCALBASE}/bin:${LOCALBASE}/sbin:/bin:/sbin:/usr/bin:/usr/sbin

# Cargo configuration for consistent crate version resolution
# These settings ensure Cargo respects the workspace root Cargo.toml
# and resolves dependencies consistently across all workspace members.
CARGO_BUILD_JOBS?=	${MAKE_JOBS_NUMBER}
CARGO_ENV=	CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS} \
		CARGO_HOME=${WRKDIR}/.cargo \
		CARGO_TARGET_DIR=${WRKDIR}/.build/target

# Enable ccache for faster rebuilds
MOZ_OPTIONS+=	--with-ccache=${LOCALBASE}/bin/ccache

do-configure:
	cd ${WRKSRC} && ./mach configure 

# Sync Cargo.lock with workspace root Cargo.toml to fix version mismatches
# This target runs cargo update to ensure all crates are resolved consistently
# from the workspace root, preventing version conflicts that occur when
# changes are made only in subdirectory Cargo.toml files.
pre-configure:
	@${ECHO_MSG} "===> Syncing Cargo workspace dependencies"
	@if [ -f "${WRKSRC}/Cargo.toml" ] && [ -f "${WRKSRC}/Cargo.lock" ]; then \
		cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ${CARGO_ENV} \
			${LOCALBASE}/bin/cargo generate-lockfile --offline || \
			${ECHO_MSG} "Note: cargo generate-lockfile skipped (requires network or no changes needed)"; \
	fi

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
	@${ECHO_MSG} "===> Verifying Cargo workspace configuration"
	@if [ -f "${WRKSRC}/Cargo.toml" ]; then \
		${ECHO_MSG} "Root Cargo.toml found - workspace patches will take effect"; \
	else \
		${ECHO_MSG} "Warning: No root Cargo.toml found"; \
	fi

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

.include <bsd.port.mk>
