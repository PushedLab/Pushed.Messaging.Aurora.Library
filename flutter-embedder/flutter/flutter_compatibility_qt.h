#ifndef LIB_FLUTTER_EMBEDDER_COMPATIBILITY_H
#define LIB_FLUTTER_EMBEDDER_COMPATIBILITY_H

#include <QCoreApplication>

namespace aurora {

namespace details {

int processQtEvents(void* app) {
  static_cast<QCoreApplication*>(app)->processEvents();
  return G_SOURCE_CONTINUE;
}

}  // namespace details

/**
 * Add support for Qt signals and slots in a Flutter applications.
 *
 * This function should only be called after the flutter application
 * has been initialized.
 *
 * The developer must manually link Qt5::Core to the application in
 * the `./aurora/CMakeLists.txt` file, since this library does not
 * link directly with Qt5::Core.
 */
void EnableQtCompatibility() {
  static int argc = 1;
  static char* argv[] = {""};
  static QCoreApplication app(argc, argv);

  GSource* source = g_timeout_source_new(150);
  g_source_set_priority(source, G_PRIORITY_LOW);
  g_source_set_callback(source, details::processQtEvents, &app, nullptr);

  AttachEventSource(source);
}

}  // namespace aurora

#endif /* LIB_FLUTTER_EMBEDDER_COMPATIBILITY_H */
