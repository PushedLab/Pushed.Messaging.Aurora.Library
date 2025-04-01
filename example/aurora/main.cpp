#include <QtCore/QDebug>
#include <QCoreApplication>
#include <flutter/flutter_aurora.h>
#include <flutter/flutter_aurora_capi.h>
#include <flutter/flutter_compatibility_qt.h>
#include "generated_plugin_registrant.h"

int main(int argc, char *argv[])
{

    bool noGui = false;
    for (int i = 1; i < argc; ++i)
    {
        if (qstrcmp(argv[i], "--no-gui") == 0)
        {
            noGui = true;
            break;
        }
    }

    // 2) Инициализируем Aurora
    aurora::Initialize(argc, argv);
    aurora::EnableQtCompatibility();
    aurora::RegisterPlugins();

    // 3) Инициализируем приложение с GUI или без
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
    return 0;
}
