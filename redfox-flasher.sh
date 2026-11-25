#!/usr/bin/env bash
set -e

REPO_KERNEL="ZXCPZHatert-RedFox-Dev-RMX3624/RMX3624-GKI-5.4-Kernel"
REPO_REC="ZXCPZHatert-RedFox-Dev-RMX3624/Red-Fox_RECOVERYRMX3624"
WORK_DIR="$HOME/RedFox-Builds"
mkdir -p "$WORK_DIR/backups"

while true; do
    clear
    echo "===================================================="
    echo "       🦊 REDFOX-FLASHER (RMX3624 / Arch Linux)      "
    echo "===================================================="
    echo "1) 📊 Живая диагностика телефона по ADB (Ядро, BBR, Яркость)"
    echo "2) 📥 Скачать свежие релизы с GitHub (Ядро v18 + Optimizer v1.4 + Recovery)"
    echo "3) 💾 Сделать резервную копию разделов (boot + vendor_boot + vbmeta)"
    echo "4) ⚡ Прошить ядро (boot_redfox_rev18_signed.img) через Fastboot"
    echo "5) 🛠️  Прошить Red-Fox Recovery (vendor_boot.img / recovery.img)"
    echo "6) 🔄 Перезагрузить телефон (System / Bootloader / Fastbootd / Recovery)"
    echo "7) 🚀 Проверить статус сборки Red-Fox Recovery в облаке"
    echo "8) 🚑 Прошить ядро (boot_redfox_rev18_signed.img) через BROM (spd_dump)
9) 🔄 Цикл чистой установки GSI (Сток Boot -> Рекавери/Wipe -> Ядро RedFox rev18)
0) Выход"
    echo "----------------------------------------------------"
    read -rp "Выберите действие [0-9]: " CHOICE

    case "$CHOICE" in
        1)
            echo -e "\n--- Диагностика RMX3624 ---"
            adb shell "su -c '
                echo \"Модель: \$(getprop ro.product.model) (\$(getprop ro.product.device))\"
                echo \"Ядро: \$(uname -r)\"
                echo \"Сеть (TCP): \$(cat /proc/sys/net/ipv4/tcp_congestion_control)\"
                echo \"ZRAM: \$(cat /sys/block/zram0/comp_algorithm 2>/dev/null || echo n/a)\"
                echo \"Яркость: \$(cat /sys/class/backlight/sprd_backlight/brightness) / \$(cat /sys/class/backlight/sprd_backlight/max_brightness)\"
                echo \"Батарея: \$(cat /sys/class/power_supply/battery/capacity)% (\$(cat /sys/class/power_supply/battery/status))\"
                echo \"Температура CPU: \$(( \$(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))°C\"
            '" || echo "Телефон не найден по ADB!"
            read -rp "Нажмите Enter..."
            ;;
        2)
            echo -e "\n--- Скачивание релизов в $WORK_DIR ---"
            gh release download v18.0-RedFox-Ultimate --repo "$REPO_KERNEL" -D "$WORK_DIR" --clobber
            RUN_ID=$(gh run list --repo "$REPO_REC" --status success -L 1 --json databaseId -q '.[0].databaseId' 2>/dev/null || true)
            if [ -n "$RUN_ID" ]; then
                gh run download "$RUN_ID" --repo "$REPO_REC" -D "$WORK_DIR/recovery"
                echo "Готово! Образы ядра и рекавери сохранены в $WORK_DIR"
            else
                echo "Ядро скачано в $WORK_DIR (успешный артефакт рекавери ещё собирается)"
            fi
            read -rp "Нажмите Enter..."
            ;;
        3)
            TS=$(date +%Y%m%d_%H%M%S)
            BDIR="$WORK_DIR/backups/$TS"
            mkdir -p "$BDIR"
            echo -e "\n--- Снятие дампов разделов в $BDIR ---"
            adb shell "su -c '
                SLOT=\$(getprop ro.boot.slot_suffix)
                dd if=/dev/block/by-name/boot\$SLOT of=/sdcard/boot_backup.img bs=4M
                dd if=/dev/block/by-name/vendor_boot\$SLOT of=/sdcard/vendor_boot_backup.img bs=4M
                dd if=/dev/block/by-name/vbmeta\$SLOT of=/sdcard/vbmeta_backup.img bs=4M
            '"
            adb pull /sdcard/boot_backup.img "$BDIR/"
            adb pull /sdcard/vendor_boot_backup.img "$BDIR/"
            adb pull /sdcard/vbmeta_backup.img "$BDIR/"
            adb shell "rm -f /sdcard/*_backup.img"
            echo "Бэкапы успешно сохранены в $BDIR"
            read -rp "Нажмите Enter..."
            ;;
        4)
            IMG="$WORK_DIR/boot_redfox_rev18_signed.img"
            [ ! -f "$IMG" ] && gh release download v18.0-RedFox-Ultimate --repo "$REPO_KERNEL" -p "boot_redfox_rev18_signed.img" -D "$WORK_DIR" --clobber
            echo "Переведите телефон в режим Bootloader (Fastboot) и нажмите Enter..."
            read -r
            fastboot flash boot "$IMG" && fastboot reboot
            read -rp "Готово! Нажмите Enter..."
            ;;
        5)
            VIMG=$(find "$WORK_DIR" -name "vendor_boot.img" -o -name "recovery.img" | head -n 1)
            if [ -z "$VIMG" ]; then
                echo "Образ рекавери не найден в $WORK_DIR. Сначала скачайте его (пункт 2)."
            else
                echo "Найден образ: $VIMG"
                echo "Переведите телефон в режим Bootloader (Fastboot) и нажмите Enter..."
                read -r
                PART=$(basename "$VIMG" .img)
                fastboot flash "$PART" "$VIMG" && fastboot reboot recovery
            fi
            read -rp "Нажмите Enter..."
            ;;
        6)
            echo "1) Обычная система  2) Bootloader  3) Fastbootd  4) Recovery"
            read -rp "Куда перезагрузить: " RMODE
            case "$RMODE" in
                1) adb reboot || fastboot reboot ;;
                2) adb reboot bootloader || fastboot reboot bootloader ;;
                3) adb reboot fastboot || fastboot reboot fastboot ;;
                4) adb reboot recovery || fastboot reboot recovery ;;
            esac
            ;;
        7)
            gh run list --repo "$REPO_REC" -L 3
            read -rp "Нажмите Enter..."
            ;;
        8)
            echo "🚑 Прошивка ядра (boot_redfox_rev18_signed.img) через BROM (spd_dump)..."
            dd if=/dev/zero of=/tmp/clean_misc.bin bs=1M count=1 2>/dev/null
            if adb get-state 1>/dev/null 2>&1; then
                echo "🔌 Автоматически выключаю телефон через ADB (reboot -p)..."
                adb shell reboot -p 2>/dev/null || adb reboot -p 2>/dev/null
                sleep 4
                echo "👉 Телефон выключен! Теперь просто зажмите 2 кнопки (Громкость Вверх + Вниз) — spd_dump уже ждёт!"
            else
                echo "👉 Выключите телефон, затем зажмите 2 кнопки (Громкость Вверх + Вниз) и подключите кабель."
            fi
            cd ~/spd_tools/ums9230_bin && sudo ../spreadtrum_flash/spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec w misc /tmp/clean_misc.bin w boot_a /home/zxcpzhatert/RedFox-Builds/boot_redfox_rev18_signed.img reset
            rm -f /tmp/clean_misc.bin
            ;;
        9)
            echo "===================================================="
            echo "🔄 ЦИКЛ ЧИСТОЙ УСТАНОВКИ GSI ДЛЯ RMX3624"
            echo "===================================================="
            echo "Шаг 1: Прошиваем совместимый boot для входа в стоковый Recovery / Fastbootd..."
            dd if=/dev/zero of=/tmp/clean_misc.bin bs=1M count=1 2>/dev/null
            if adb get-state 1>/dev/null 2>&1; then
                adb shell reboot -p 2>/dev/null || adb reboot -p 2>/dev/null
                sleep 4
            fi
            echo "👉 Зажмите 2 кнопки (Громкость Вверх + Вниз) для прошивки boot под Recovery..."
            cd ~/spd_tools/ums9230_bin && sudo ../spreadtrum_flash/spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec w misc /tmp/clean_misc.bin w boot_a /home/zxcpzhatert/RedFox-Builds/boot_stock_recovery.img w boot_b /home/zxcpzhatert/RedFox-Builds/boot_stock_recovery.img reboot-recovery
            echo ""
            echo "✅ Телефон перезагружается в стоковый Recovery!"
            echo "👉 В меню Recovery сделайте Wipe Data / Factory Reset (и прошейте GSI через fastbootd, если нужно)."
            echo "👉 Когда закончите в Recovery — ВЫКЛЮЧИТЕ телефон (Power Off) и нажмите Enter здесь, чтобы вшить ядро RedFox rev18..."
            read -r
            echo "Шаг 2: Возвращаем ядро RedFox rev18-Ultimate в boot_a и boot_b..."
            echo "👉 Зажмите 2 кнопки (Громкость Вверх + Вниз) на выключенном телефоне..."
            cd ~/spd_tools/ums9230_bin && sudo ../spreadtrum_flash/spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec w misc /tmp/clean_misc.bin w boot_a /home/zxcpzhatert/RedFox-Builds/boot_redfox_rev18_signed.img w boot_b /home/zxcpzhatert/RedFox-Builds/boot_redfox_rev18_signed.img reset
            rm -f /tmp/clean_misc.bin
            echo "🎉 Готово! Ядро RedFox rev18 прошито, телефон запускается в новую систему!"
            ;;
        0) exit 0 ;;
    esac
done
