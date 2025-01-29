#ifndef FLUTTER_SHELL_PLATFORM_AURORA_PUBLIC_FLUTTER_AURORA_EGL_API_H_
#define FLUTTER_SHELL_PLATFORM_AURORA_PUBLIC_FLUTTER_AURORA_EGL_API_H_

#include "flutter_aurora_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetEGLConfig(void** egl_config);

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetEGLDisplay(void** egl_display);

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetNativeDisplay(void** native_display);

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetEGLGetProcAddress(void** func);

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetEGLContextHandle(void** egl_context);

FLUTTER_AURORA_EXPORT
void FlutterAuroraGetEGLOffscreenContextHandle(void** egl_context);

FLUTTER_AURORA_EXPORT
float FlutterAuroraGetDevicePixelRatio(void);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_SHELL_PLATFORM_AURORA_PUBLIC_FLUTTER_AURORA_EGL_API_H_
