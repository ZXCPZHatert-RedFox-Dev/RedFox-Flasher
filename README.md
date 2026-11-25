# 🦊 RedFox-Flasher (RMX3624 — Linux & Windows)

Кроссплатформенная интерактивная утилита для управления, резервного копирования и прошивки **Realme C33 (`RMX3624`)** из-под Arch Linux и Windows 10/11.

## Возможности
- 📊 **Живая телеметрия по ADB:** проверка версии ядра, активного TCP BBR, шкалы подсветки `4095` и заряда батареи.
- 📥 **Автозагрузка релизов:** скачивание актуальных сборок `RMX3624-GKI-5.4-Kernel` (`v16.0-RedFox-Ultimate`), `RedFox-Optimizer-v1.3.zip` и `Red-Fox Recovery` напрямую с GitHub.
- 💾 **Резервное копирование:** автоматическое снятие дампов `boot`, `vendor_boot` и `vbmeta` активного слота.
- ⚡ **Прошивка в один клик:** установка подписанного ядра и `vendor_boot.img` через `fastboot`.

## Запуск на Windows 10 / 11
1. Скачайте репозиторий (кнопка **Code → Download ZIP**) и распакуйте архив.
2. Запустите двойным кликом **`redfox-flasher.bat`** (скрипт сам скачает официальные `adb` и `fastboot`, если они ещё не установлены).

## Установка на Arch Linux
```bash
gh repo clone ZXCPZHatert-RedFox-Dev-RMX3624/RedFox-Flasher
install -Dm755 RedFox-Flasher/redfox-flasher ~/.local/bin/redfox-flasher
redfox-flasher
```
