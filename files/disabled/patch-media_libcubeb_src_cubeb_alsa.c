--- media/libcubeb/src/cubeb_alsa.c
+++ media/libcubeb/src/cubeb_alsa.c
@@ -4,6 +4,18 @@
  * This program is made available under an ISC-style license.  See the
  * accompanying file LICENSE for details.
  */
+
+#include <stdlib.h>
+
+/* FreeBSD compatibility for missing ALSA error codes */
+#ifndef ESTRPIPE
+#define ESTRPIPE EPIPE
+#endif
+#ifndef EBADFD
+#define EBADFD EBADF
+#endif
+
+/* End of FreeBSD compatibility definitions */
 #undef NDEBUG
 #define _DEFAULT_SOURCE
 #define _BSD_SOURCE
