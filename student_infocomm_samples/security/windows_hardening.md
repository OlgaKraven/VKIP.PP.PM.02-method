# Базовый hardening Windows-хоста (учебный чек-лист)

## 1. Учётные записи

| Действие | Команда |
|----------|---------|
| Отключить «Гость» | `Disable-LocalUser -Name "Guest"` |
| Запретить пустой пароль | `secedit /export /cfg pol.cfg`, `LimitBlankPasswordUse=1` |
| Длина пароля ≥ 8, сложность вкл | `net accounts /minpwlen:8` + `secedit` `PasswordComplexity=1` |
| Лок-аут после 5 попыток | `net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15` |
| Удалить лишние учётки администраторов | `Get-LocalGroupMember Administrators` |

## 2. Службы

| Что отключить (если не нужно) |
|------------------------------|
| `RemoteRegistry` |
| `Telephony` |
| `Fax` |
| `XblAuthManager` / `XblGameSave` |
| `WSearch` (на серверах без интерактивного поиска) |

```powershell
Set-Service RemoteRegistry -StartupType Disabled
Stop-Service RemoteRegistry
```

## 3. Брандмауэр

```powershell
Set-NetFirewallProfile -Profile Domain,Public,Private `
                       -Enabled True `
                       -DefaultInboundAction Block `
                       -DefaultOutboundAction Allow

# RDP — только из LAN
Get-NetFirewallRule -DisplayGroup "Удаленный рабочий стол" |
    Set-NetFirewallRule -RemoteAddress 192.168.10.0/24
```

## 4. Журналы

```powershell
# увеличить лимит и время хранения
wevtutil sl Security /ms:1073741824    # 1 GB
wevtutil sl System   /ms:268435456     # 256 MB

# проверка аудита входа
auditpol /get /category:"Logon/Logoff"
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
```

## 5. Обновления

```powershell
Install-Module PSWindowsUpdate -Force -SkipPublisherCheck
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -AutoReboot:$false
```

## 6. RDP

| Параметр | Значение |
|----------|----------|
| NLA (Network Level Authentication) | Включён |
| Группы доступа | `Administrators` + `Remote Desktop Users` (с белым списком) |
| Шифрование | High |
| Время неактивности | 15–30 минут |

```powershell
Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
                 -Name "UserAuthentication" -Value 1
```

## 7. Защитник Windows

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Update-MpSignature
Start-MpScan -ScanType QuickScan
Get-MpComputerStatus
```

## 8. Контрольные команды для отчёта

```powershell
Get-LocalUser     | Select Name, Enabled, LastLogon       | Out-File users.txt
Get-Service       | Where-Object Status -eq 'Running'     | Out-File services.txt
Get-NetTCPConnection -State Listen                        | Out-File listen.txt
Get-NetFirewallRule -Enabled True | Select DisplayName,Direction,Action | Out-File fw.txt
Get-WinEvent -LogName Security -MaxEvents 50              | Out-File security_log.txt
secedit /export /cfg secpol.cfg
```

## 9. Точка восстановления

```powershell
Enable-ComputerRestore -Drive "C:\"
Checkpoint-Computer -Description "before-hardening" -RestorePointType "MODIFY_SETTINGS"
```
