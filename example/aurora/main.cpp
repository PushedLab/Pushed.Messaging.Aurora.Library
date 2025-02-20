/**
 * SPDX-FileCopyrightText: Copyright 2023 Open Mobile Platform LLC <community@omp.ru>
 * SPDX-License-Identifier: BSD-3-Clause
 */
// #include <flutter/flutter_aurora.h>
// #include <flutter/flutter_compatibility_qt.h>
// #include "generated_plugin_registrant.h"

// int main(int argc, char *argv[])
// {
//     aurora::Initialize(argc, argv);
//     aurora::EnableQtCompatibility(); // <- Enable Qt
//     aurora::RegisterPlugins();
//     aurora::Launch();
//     return 0;
// }

// #include <flutter/flutter_aurora.h>
// #include <flutter/flutter_compatibility_qt.h> // Aurora C++ helpers
// #include <flutter/flutter_aurora_capi.h>      // Aurora C API
// #include "generated_plugin_registrant.h"
// #include <QtCore/QDebug>

// int main(int argc, char *argv[])
// {
//     // 1) Create a QGuiApplication (needed for event loop, DBus, etc.).

//     // 2) Aurora initialization calls:
//     aurora::Initialize(argc, argv);
//     aurora::EnableQtCompatibility();
//     aurora::RegisterPlugins();
//     // Note: DO NOT call aurora::Launch() here if you want no GUI.

//     // 3) Prepare "no-GUI" launch options using the C API:
//     FlutterAuroraLaunchOptions options;
//     FlutterAuroraLaunchOptionsInitDefault(&options, sizeof(options));
//     // Force-disables any GUI creation:
//     options.gui_type = FlutterAuroraGuiForceDisabled;
//     // (Optional) If you have a custom Dart entry point:
//     // options.dart_entry_point = "myBackgroundMain";

//     qDebug() << "Launching Flutter engine with NO GUI (headless).";

//     // 4) Actually launch the Flutter engine in headless mode:
//     FlutterAuroraLaunch(&options);

//     // 5) Keep the Qt event loop running,
//     // so that your push plugin, D-Bus calls, etc. continue to work.
//     return 0;
// }

#include <QtCore/QDebug>
#include <QCoreApplication>
#include <flutter/flutter_aurora.h>
#include <flutter/flutter_aurora_capi.h>
#include <flutter/flutter_compatibility_qt.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[])
{
    qDebug() << "Argument count (argc):" << argc;
    for (int i = 0; i < argc; ++i)
    {
        qDebug() << "argv[" << i << "] =" << argv[i];
    }

    bool noGui = false;
    for (int i = 1; i < argc; ++i)
    {
        if (qstrcmp(argv[i], "/no-gui") == 0 || qstrcmp(argv[i], "--no-gui") == 0)
        {
            noGui = true;
            break;
        }
    }
    // 1) Создаём Qt-приложение (даёт event loop, DBus и т.д.)
    QCoreApplication app(argc, argv);

    // 2) Инициализируем Aurora
    aurora::Initialize(argc, argv);
    aurora::EnableQtCompatibility();
    aurora::RegisterPlugins();

    // 3) Готовим опции запуска Flutter Aurora
    FlutterAuroraLaunchOptions options;
    FlutterAuroraLaunchOptionsInitDefault(&options, sizeof(options));

    if (noGui)
    {
        // При наличии "--no-gui" запускаем без GUI
        options.gui_type = FlutterAuroraGuiForceDisabled;
        qDebug() << "Launching Flutter with NO GUI (headless).";
    }
    else
    {
        // Иначе — с GUI
        options.gui_type = FlutterAuroraGuiForceEnabled;
        qDebug() << "Launching Flutter with a normal GUI.";
    }

    // 4) Запускаем Flutter с данными настройками
    FlutterAuroraLaunch(&options);

    // 5) Запускаем цикл событий Qt
    return app.exec();
}
