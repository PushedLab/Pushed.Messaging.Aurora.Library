---
id: aurora
title: Начало работы с Aurora
sidebar_label: Отправка пушей через Aurora
description: Отправка сообщений через транспорт Aurora
keywords: [Pushed, Push, пуш-сообщения, компания Мультифактор, Pushed Messaging, Aurora]
---

:::danger Настройка мобильного приложения
Для получения Push-уведомлений устройство должно быть зарегистрировано в существующем Аврора Центре.
Используйте <a href="https://docs.auroraos.ru/files/5.1.0-2/%D0%A0%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE%20%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D1%82%D0%B5%D0%BB%D1%8F%20%C2%AB%D0%90%D0%B2%D1%80%D0%BE%D1%80%D0%B0%20%D0%A6%D0%B5%D0%BD%D1%82%D1%80%C2%BB%205.1.0%20%D0%A7%D0%B0%D1%81%D1%82%D1%8C%207.%20%D0%9F%D1%80%D0%B8%D0%BB%D0%BE%D0%B6%D0%B5%D0%BD%D0%B8%D0%B5%20%C2%AB%D0%90%D0%B2%D1%80%D0%BE%D1%80%D0%B0%20%D0%A6%D0%B5%D0%BD%D1%82%D1%80%C2%BB%20%D0%B4%D0%BB%D1%8F%20%D0%9E%D0%A1%20%D0%90%D0%B2%D1%80%D0%BE%D1%80%D0%B0.pdf" target="_blank"> **раздел 2.1.1 руководства пользователя**</a> для регистрации мобильного устройства в Аврора Центр.
:::

## Отправка сообщений через транспорт Aurora

Для отправки пушей потребуется получить конфигурационный yaml-файл от соответствующего Аврора Центра и загрузить его в Личном Кабинете MULTIPUSHED в настройках приложения.

Пример содержимого yaml-файла ниже.
```yaml
push_notification_system:
  project_id: "PROJECT_ID_PLACEHOLDER"
  push_public_address: "https://API_BASE_URL_PLACEHOLDER"
  api_url: "https://API_BASE_URL_PLACEHOLDER/push/public/api/v1/"
  client_id: "CLIENT_ID_PLACEHOLDER"
  scopes: "SCOPES_PLACEHOLDER"
  audience: "AUDIENCE_URLS_PLACEHOLDER"
  token_url: "https://API_BASE_URL_PLACEHOLDER/auth/public/oauth2/token"
  private_key: "PRIVATE_KEY_PLACEHOLDER"
  key_id: "KEY_ID_PLACEHOLDER"

```
    
Для отправки сообщений через транспорт Aurora нужно указать <a href="../docs/api#схема-отправки-пушей" target="_blank">схему отправки</a> при публикации сообщения в <a href="../docs/api#отправка-пуш-сообщений" target="_blank">сервисе PUB</a>.

1. Получите конфигурационный yaml-файл Аврора Центр
2. Включите Aurora на вкладке "Настройки" и приложите файл (см. скриншот)

<img src="/img/aurora/admin-enable-aurora.png" alt="Включить Aurora" width="800px"/>

3. Нажмите "Сохранить"
