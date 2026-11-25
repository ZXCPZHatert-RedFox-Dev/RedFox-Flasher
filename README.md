# 🦊 RedFox-Flasher (RMX3624 / Arch Linux)

Интерактивная CLI-утилита для управления, резервного копирования и прошивки **Realme C33 (`RMX3624`)** из-под Arch Linux.

## Возможности
- 📊 **Живая телеметрия по ADB:** проверка версии ядра, активного TCP BBR, сжатия ZRAM, шкалы подсветки `4095` и температуры CPU.
- 📥 **Автозагрузка релизов:** скачивание актуальных сборок `RMX3624-GKI-5.4-Kernel` (`v16.0-RedFox-Ultimate`), `RedFox-Optimizer` и `Red-Fox Recovery` напрямую с GitHub.
- 💾 **Резервное копирование:** автоматическое снятие дампов `boot`, `vendor_boot` и `vbmeta` активного слота.
- ⚡ **Прошивка в один клик:** установка подписанного ядра и `vendor_boot.img` через `fastboot`.

## Установка на Arch Linux
```bash
git clone https://github.com
install -Dm755 RedFox-Flasher/redfox-flasher ~/.local/bin/redfox-flasher
redfox-flasher
```
