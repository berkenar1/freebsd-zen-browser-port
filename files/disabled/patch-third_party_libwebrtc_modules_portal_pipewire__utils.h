--- third_party/libwebrtc/modules/portal/pipewire_utils.h
+++ third_party/libwebrtc/modules/portal/pipewire_utils.h
@@ -11,6 +11,9 @@
 #ifndef MODULES_PORTAL_PIPEWIRE_UTILS_H_
 #define MODULES_PORTAL_PIPEWIRE_UTILS_H_

+#if !defined(__FreeBSD__)
+#include <asm-generic/ioctl.h>
+#endif
 #include <errno.h>
 #include <stdint.h>
 #include <sys/ioctl.h>
 
