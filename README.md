# Сервис пуш-уведомлений для Aurora OS - MultiPushed

## Получение учетных данных
   - Направьте запрос в техническую поддержку: `dev-support@omp.ru`
   - Получите:
     - `applicationId`
     - Конфигурационный файл `.yaml`
     - Адрес экземпляра Aurora Center

---


## Настройка запуска приложения

1. Добавьте Qt-совместимость и обработку фонового режима **`Main.cpp`**:

```cpp
#include <flutter/compatibility.h>
#include <QtCore/QDebug>
#include <QCoreApplication>
#include <flutter/flutter_aurora.h>
#include <flutter/flutter_aurora_capi.h>
#include <flutter/flutter_compatibility_qt.h>
#include "generated_plugin_registrant.h"

int main(int argc, char* argv[]) {
    bool noGui = false;
    for (int i = 1; i < argc; ++i) {
        if (qstrcmp(argv[i], "--no-gui") == 0) {
            noGui = true;
            break;
        }
    }

    aurora::Initialize(argc, argv);
    aurora::EnableQtCompatibility();
    aurora::RegisterPlugins();

    FlutterAuroraLaunchOptions options;
    FlutterAuroraLaunchOptionsInitDefault(&options, sizeof(options));

    options.gui_type = noGui 
        ? FlutterAuroraGuiForceDisabled
        : FlutterAuroraGuiForceEnabled;

    FlutterAuroraLaunch(&options);

    return 0;
}
```
2. Добавьте разрешения в файл **`aurora/desktop/YOUR_APP_NAME.desktop`**:

```ini
[X-Application]
Permissions=PushNotifications;Internet
```

---

## Обработка фоновых уведомлений
1. Добавьте фоновый обработчик entry-point для изолята:

```cpp
@pragma('vm:entry-point')
Future<void> backgroundMessage(Map<dynamic,dynamic> message) async {
    print("Background message: $message");
    // Ваша логика обработки
}
```
2. Инициализация плагина
```cpp
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await PushedMessaging().init(
    backgroundMessage, // ваш обработчик
    applicationId: 'ВАШ_APPLICATION_ID',
  );

  runApp(const MyApp());
}
```
