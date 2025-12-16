PORTNAME=	zen-browser
DISTVERSION=	1.17.12b
CATEGORIES=	www wayland

MAINTAINER=	ports@FreeBSD.org
COMMENT=	Zen Browser - Firefox-based privacy-focused browser
WWW=		https://zen-browser.app

MASTER_SITES=	https://github.com/zen-browser/desktop/releases/download/${DISTVERSION}/
DISTFILES=	zen.source.tar.zst

LICENSE=	MPL20

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

USES=		tar:zst gmake python:3.11,build compiler:c17-lang \
		desktop-file-utils gl gnome localbase:ldflags pkgconfig 

USE_GL=		gl
USE_GNOME=	cairo gdkpixbuf2 gtk30

WRKSRC=		${WRKDIR}

# Add ALSA compatibility headers from files/ directory
CPPFLAGS+=	-I${FILESDIR}

# Use rust from ports (already built under /usr/ports)

CONFIGURE_ENV=  RUSTC=${LOCALBASE}/bin/rustc \
                CARGO=${LOCALBASE}/bin/cargo

MAKE_ENV=       RUSTC=${LOCALBASE}/bin/rustc \
                CARGO=${LOCALBASE}/bin/cargo \
                RUSTUP_HOME=nonexistent \
                CARGO_HOME=nonexistent \
                PATH=${LOCALBASE}/bin:${LOCALBASE}/sbin:/bin:/sbin:/usr/bin:/usr/sbin

do-configure:
	cd ${WRKSRC} && ./mach configure \
		--without-wasm-sandboxed-libraries \
		

do-build:
	cd ${WRKSRC} && ${SETENV} ${MAKE_ENV} ./mach build

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/lib/${PORTNAME}
	${MKDIR} ${STAGEDIR}${PREFIX}/bin

.include <bsd.port.mk>
