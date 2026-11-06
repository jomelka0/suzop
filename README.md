# suzop — VPN-клиент подписок и ключей

**Flutter-приложение для Android и iOS.** Импорт подписок и ключей всех
форматов, реальный TCP-пинг серверов, «небесный» интерфейс с жидким
стеклом, три раздела со свайпами.

## Что работает полностью

- Парсинг ключей vless:// vmess:// trojan:// ss:// (SIP002 + legacy)
- Загрузка подписок по URL (base64 или plain-список)
- Реальный TCP-пинг всех серверов из приложения (dart:io)
- UI: 3 раздела со свайпами (Серверы / Подписка / Настройки)
- Кнопка просто зеленеет при подключении (без анимаций)
- Кнопка уезжает вверх при скролле вниз и возвращается
- Мини-статистика: время / скорость / объём данных
- Жидкое стекло: BackdropFilter + слоистые градиенты
- Сохранение подписок и серверов между запусками

## Что требует нативного ядра

- Реальный VPN-туннель на Android: нужно добавить ядро
  (libcore / Xray-core / sing-box .aar или wireguard-android) и
  прокинуть fd + конфиг — каркас в SuzopVpnService.kt готов.
- iOS: нужен Mac + Network Extension + аккаунт Apple Developer.
  Мост suzop/vpn совместим — реализуется в Swift.
- Kill Switch, split tunneling, автоподключение — переключатели
  в UI готовы, логика в нативной части (roadmap в комментариях).

## Как собрать

1. Установи Flutter SDK (flutter.dev) и Android Studio (Android SDK).
2. `flutter create . --org ai.suzop --project-name suzop` в папке
   проекта, затем скопируй файлы из архива поверх.
3. Положи android-файлы в android/app/src/main/... по путям.
4. Подключи телефон или открой эмулятор:

```bash
flutter pub get
flutter run
```

Сборка APK:

```bash
flutter build apk --release
```

Готовый APK: build/app/outputs/flutter-apk/app-release.apk

## Структура

```
suzop/
├── pubspec.yaml
├── README.md
├── .gitignore
├── lib/
│   ├── main.dart
│   ├── root_shell.dart
│   ├── state.dart
│   ├── theme.dart
│   ├── core/   (models, parsers, ping, subscription_fetch, vpn_bridge)
│   └── ui/     (servers_page, subscription_page, settings_page)
└── android/app/src/main/
    ├── AndroidManifest.xml
    └── kotlin/ai/suzop/app/  (MainActivity, VpnController, SuzopVpnService)
```

## Дальнейшие шаги до «как Happ / Shadowrocket»

1. Добавить ядро (рекомендация: sing-box — VLESS+VMess+Trojan+SS+WG
   одним движком, или libcore).
2. Реализовать startTunnel(): parseConfig(link) → запуск ядра → protect(fd).
3. Kill Switch: блокировать трафик при обрыве.
4. Split tunneling: выбор приложений → Builder.addApplication.
5. Автовыбор сервера: сортировка по TCP-ping.
6. iOS: Swift-адаптер Network Extension поверх тех же каналов.
