$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$RepoKernel = "ZXCPZHatert-RedFox-Dev-RMX3624/RMX3624-GKI-5.4-Kernel"
$RepoRec    = "ZXCPZHatert-RedFox-Dev-RMX3624/Red-Fox_RECOVERYRMX3624"
$WorkDir    = Join-Path $PSScriptRoot "RedFox-Builds"
$ToolsDir   = Join-Path $PSScriptRoot "platform-tools"
New-Item -ItemType Directory -Force -Path $WorkDir, (Join-Path $WorkDir "backups") | Out-Null

function Ensure-PlatformTools {
    if ((Get-Command adb -ErrorAction SilentlyContinue) -and (Get-Command fastboot -ErrorAction SilentlyContinue)) {
        return
    }
    $adbExe = Join-Path $ToolsDir "adb.exe"
    if (-not (Test-Path $adbExe)) {
        Write-Host "Скачиваю официальный Google Platform-Tools (adb/fastboot)..." -ForegroundColor Yellow
        $zipPath = Join-Path $env:TEMP "platform-tools-windows.zip"
        Invoke-WebRequest -Uri "https://google.com" -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $PSScriptRoot -Force
        Remove-Item $zipPath -Force
    }
    $env:PATH = "$ToolsDir;$env:PATH"
}

Ensure-PlatformTools

while ($true) {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "       🦊 REDFOX-FLASHER (RMX3624 / Windows)        " -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "1) 📊 Живая диагностика телефона по ADB (Ядро, BBR, Яркость)"
    Write-Host "2) 📥 Скачать свежие релизы с GitHub (Ядро v16 + Optimizer v1.3 + Recovery)"
    Write-Host "3) 💾 Сделать резервную копию разделов (boot + vendor_boot + vbmeta)"
    Write-Host "4) ⚡ Прошить ядро (boot_redfox_rev16_signed.img) через Fastboot"
    Write-Host "5) 🛠️  Прошить Red-Fox Recovery (vendor_boot.img / recovery.img)"
    Write-Host "6) 🔄 Перезагрузить телефон (System / Bootloader / Fastbootd / Recovery)"
    Write-Host "7) 🚀 Проверить статус сборки Red-Fox Recovery в облаке"
    Write-Host "0) Выход"
    Write-Host "----------------------------------------------------"
    $Choice = Read-Host "Выберите действие [0-7]"

    switch ($Choice) {
        "1" {
            Write-Host "`n--- Диагностика RMX3624 ---" -ForegroundColor Green
            adb shell "su -c 'echo Модель: \$(getprop ro.product.model) (\$(getprop ro.product.device)); echo Ядро: \$(uname -r); echo Сеть TCP: \$(cat /proc/sys/net/ipv4/tcp_congestion_control); echo Яркость: \$(cat /sys/class/backlight/sprd_backlight/brightness) / \$(cat /sys/class/backlight/sprd_backlight/max_brightness); echo Батарея: \$(cat /sys/class/power_supply/battery/capacity)%'"
            Read-Host "`nНажмите Enter..."
        }
        "2" {
            Write-Host "`n--- Скачивание релизов в $WorkDir ---" -ForegroundColor Green
            $rel = Invoke-RestMethod -Uri "https://github.com"
            foreach ($asset in $rel.assets) {
                $dest = Join-Path $WorkDir $asset.name
                Write-Host "Загрузка $($asset.name)..."
                Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest
            }
            Write-Host "Готово! Файлы сохранены в $WorkDir" -ForegroundColor Cyan
            Read-Host "Нажмите Enter..."
        }
        "3" {
            $ts = Get-Date -Format "yyyyMMdd_HHmmss"
            $bdir = Join-Path $WorkDir "backups\$ts"
            New-Item -ItemType Directory -Force -Path $bdir | Out-Null
            Write-Host "`n--- Снятие дампов разделов в $bdir ---" -ForegroundColor Green
            adb shell "su -c 'SLOT=\$(getprop ro.boot.slot_suffix); dd if=/dev/block/by-name/boot\$SLOT of=/sdcard/boot_backup.img bs=4M; dd if=/dev/block/by-name/vendor_boot\$SLOT of=/sdcard/vendor_boot_backup.img bs=4M; dd if=/dev/block/by-name/vbmeta\$SLOT of=/sdcard/vbmeta_backup.img bs=4M'"
            adb pull /sdcard/boot_backup.img "$bdir\"
            adb pull /sdcard/vendor_boot_backup.img "$bdir\"
            adb pull /sdcard/vbmeta_backup.img "$bdir\"
            adb shell "rm -f /sdcard/*_backup.img"
            Write-Host "Бэкапы сохранены в $bdir" -ForegroundColor Cyan
            Read-Host "Нажмите Enter..."
        }
        "4" {
            $img = Join-Path $WorkDir "boot_redfox_rev16_signed.img"
            if (-not (Test-Path $img)) {
                Write-Host "Сначала скачайте файлы через пункт 2!" -ForegroundColor Red
            } else {
                Read-Host "Переведите телефон в режим Bootloader (Fastboot) и нажмите Enter..."
                fastboot flash boot "$img"
                fastboot reboot
            }
            Read-Host "Нажмите Enter..."
        }
        "5" {
            $vimg = Get-ChildItem -Path $WorkDir -Recurse -Include "vendor_boot.img","recovery.img" | Select-Object -First 1
            if (-not $vimg) {
                Write-Host "Образ vendor_boot.img / recovery.img не найден в $WorkDir." -ForegroundColor Red
            } else {
                Write-Host "Найден образ: $($vimg.FullName)"
                Read-Host "Переведите телефон в режим Bootloader (Fastboot) и нажмите Enter..."
                $part = $vimg.BaseName
                fastboot flash $part "$($vimg.FullName)"
                fastboot reboot recovery
            }
            Read-Host "Нажмите Enter..."
        }
        "6" {
            Write-Host "1) Обычная система  2) Bootloader  3) Fastbootd  4) Recovery"
            $rmode = Read-Host "Куда перезагрузить"
            switch ($rmode) {
                "1" { adb reboot; fastboot reboot }
                "2" { adb reboot bootloader; fastboot reboot bootloader }
                "3" { adb reboot fastboot; fastboot reboot fastboot }
                "4" { adb reboot recovery; fastboot reboot recovery }
            }
        }
        "7" {
            $runs = Invoke-RestMethod -Uri "https://github.com"
            foreach ($r in $runs.workflow_runs) {
                Write-Host "ID: $($r.id) | Статус: $($r.status) | Результат: $($r.conclusion) | Дата: $($r.created_at)"
            }
            Read-Host "`nНажмите Enter..."
        }
        "0" { exit }
    }
}
