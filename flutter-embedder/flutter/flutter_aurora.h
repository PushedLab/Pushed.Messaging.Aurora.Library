#ifndef FLUTTER_SHELL_PLATFORM_PUBLIC_AURORA_H_
#define FLUTTER_SHELL_PLATFORM_PUBLIC_AURORA_H_

#include <functional>

#include <glib.h>
#include <plugin_registrar.h>

#include "flutter_aurora_export.h"

namespace aurora {

// ========== types ==========

// Types display orientations.
enum DisplayOrientation {
  kPortrait = 0,
  kLandscape = 90,
  kPortraitFlipped = 180,
  kLandscapeFlipped = 270,
};

// Statusbar visibility mode in portrait orientation
enum StatusbarVisibilityMode {
  // Using system setting value. Default behaviour.
  kBySystemSettings = 0,

  // Statusbar always hide
  kHide = 1,

  // Statusbar always visible. Ignore system settings value.
  kForceVisible = 2,
};

// ========== application ==========

// Flutter application initialization, services registration.
FLUTTER_AURORA_EXPORT
void Initialize(int argc, char* argv[]);

// Launching Flutter application after registering plugins.
FLUTTER_AURORA_EXPORT
void Launch();

// Terminate the Flutter application with the specified exit code.
FLUTTER_AURORA_EXPORT
void Exit(int exit_code);

// Getting a class [PluginRegistrar] for registering plugins.
FLUTTER_AURORA_EXPORT
flutter::PluginRegistrar* GetPluginRegistrar();

// ========== events ==========

// Subscribe to keyboard opening event.
FLUTTER_AURORA_EXPORT
void SubscribeKeyboardVisibilityChanged(
    const std::function<void(bool)>& callback);

// Subscribe to keyboard height change event.
FLUTTER_AURORA_EXPORT
void SubscribeOrientationChanged(
    const std::function<void(DisplayOrientation)>& callback);

// Adds a GSource to a context so that it will be executed within that context.
// Used to connect Qt signal / slot.
FLUTTER_AURORA_EXPORT
void AttachEventSource(GSource* source);

// ========== methods ==========

// The method returns Application 'ID'.
FLUTTER_AURORA_EXPORT
std::string GetApplicationID();

// The method returns Application 'Orgname'.
FLUTTER_AURORA_EXPORT
std::string GetOrganizationName();

// The method returns Application 'Appname'.
FLUTTER_AURORA_EXPORT
std::string GetApplicationName();

// This method returns the keyboard height.
FLUTTER_AURORA_EXPORT
double GetKeyboardHeight();

FLUTTER_AURORA_EXPORT
std::vector<const char*> GetDartEntryPointArgs();

// The method deploys the application.
FLUTTER_AURORA_EXPORT
void MaximizeWindow();

// The method minimizes the application.
FLUTTER_AURORA_EXPORT
void MinimizeWindow();

// This method returns the device orientation.
FLUTTER_AURORA_EXPORT
DisplayOrientation GetOrientation();

// This method returns the width of the device screen.
FLUTTER_AURORA_EXPORT
int32_t GetDisplayWidth();

// This method returns the height of the device screen.
FLUTTER_AURORA_EXPORT
int32_t GetDisplayHeight();

// This method returns true if system statusbar is visible on screen.
FLUTTER_AURORA_EXPORT
bool IsStatusbarVisible();

// This method returns the value of statusbar visibility mode. Default value is
// StatusbarVisibilityMode::kBySystemSettings. This method is thread safe.
FLUTTER_AURORA_EXPORT
StatusbarVisibilityMode GetStatusbarVisibilityMode();

// Set statusbar visibility mode. This method is thread safe.
FLUTTER_AURORA_EXPORT
void SetStatusbarVisibilityMode(StatusbarVisibilityMode mode);

}  // namespace aurora

#endif  // FLUTTER_SHELL_PLATFORM_PUBLIC_AURORA_H_
