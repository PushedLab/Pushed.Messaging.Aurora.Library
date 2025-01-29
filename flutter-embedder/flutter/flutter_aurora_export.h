#ifdef LIB_FLUTTER_AURORA_BUILD
#define FLUTTER_AURORA_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_AURORA_EXPORT
#endif
