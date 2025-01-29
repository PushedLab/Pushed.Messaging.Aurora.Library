#ifndef FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_
#define FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_

#include <stddef.h>

#include "flutter_aurora_export.h"

#if defined(__cplusplus)
extern "C" {
#endif

typedef enum {
  // The application initializes the graphics window and keyboard, but they
  // can be disabled via the '--no-gui' command line argument.
  FlutterAuroraGuiEnabled = 0,
  // The application will initialize the graphics window and the keyboard.
  FlutterAuroraGuiForceEnabled,
  // The application will not initialize the graphics window and keyboard.
  FlutterAuroraGuiForceDisabled,
} FlutterAuroraGuiType;

typedef struct {
  // The size of this struct. Must be sizeof(FlutterAuroraLaunchOptions).
  size_t struct_size;
  // The name of the custom entry point or NULL. If NULL is set, the entry point
  // specified by the --dart-entry-point command line argument will be chosen,
  // if no command line argument is specified, the 'main' entry point will be
  // chosen.
  const char* dart_entry_point;
  // The type of initialization of the graphics window and keyboard in the
  // application.
  FlutterAuroraGuiType gui_type;
} FlutterAuroraLaunchOptions;

/**
 * Initialize launch options with default values.
 *
 * @param options Pointer to launch options.
 * @param struct_size The size of the FlutterAuroraLaunchOptions struct.
 *                    Must be sizeof(FlutterAuroraLaunchOptions).
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraLaunchOptionsInitDefault(FlutterAuroraLaunchOptions* options,
                                           size_t struct_size);

/**
 * Launch the Flutter application using the specified options.
 *
 * @param options Pointer to launch options.
 *                Use the FlutterAuroraDefaultLaunchOptions() method to get the
 *                default options.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraLaunch(const FlutterAuroraLaunchOptions* options);

/**
 * Terminate the Flutter application with the specified exit code.
 *
 * @param exit_code The exit code with which the application process will
 *                  terminate.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraExit(int exit_code);

/**
 * Retrieve the dart entry point arguments.
 * This function populates the provided arguments count `argc` and argument
 * vector `argv`.
 *
 * @param argc Pointer to a variable that will be set to the number of
 *             arguments.
 * @param argv Pointer to the string array to which the argument strings will be
 *             set. There is no need to free up memory.
 */
FLUTTER_AURORA_EXPORT
void FlutterAuroraGetDartEntryPointArgs(int* argc, const char* const** argv);

#if defined(__cplusplus)
}
#endif

#endif  // FLUTTER_SHELL_PLATFORM_PUBLIC_FLUTTER_AURORA_CAPI_H_
