# suzop — roadmap

## Этап 1 — готово (в этом архиве)
- [x] UI-оболочка: свайпы, жидкое стекло, кнопка-статус
- [x] Парсеры всех форматов ключей
- [x] Реальный TCP-ping серверов
- [x] Импорт и обновление подписок
- [x] Каркас Android VPN-сервиса (tun-интерфейс)
- [x] Мосты Flutter <-> Kotlin (connect/disconnect/stats)

## Этап 2 — интеграция ядра
- [ ] Скачать sing-box .aar (github.com/SagerNet/sing-box) → android/app/libs
- [ ] startTunnel(): конфиг из link → ядро → protect(fd)
- [ ] Статистика скорости/объёма из API ядра
- [ ] Foreground-нотификация туннеля
- [ ] Запрос разрешения VPN (startActivityForResult → повтор connect)

## Этап 3 — функции как в Happ / Shadowrocket
- [ ] Kill Switch (блок трафика при обрыве)
- [ ] Split tunneling (приложения вне VPN)
- [ ] Автоподключение при старте системы
- [ ] Автовыбор самого быстрого сервера
- [ ] WireGuard-конфиги (.conf файлы)

## Этап 4 — iOS
- [ ] Mac + Xcode + аккаунт Apple Developer
- [ ] Network Extension (NEPacketTunnelProvider) на Swift
- [ ] Тот же мост suzop/vpn в Swift-адаптере
