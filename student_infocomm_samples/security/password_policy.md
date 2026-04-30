# Учебная парольная политика

## Минимальные требования

| Параметр | Значение |
|----------|----------|
| Минимальная длина | 8 символов |
| Сложность | буквы разных регистров + цифры + спецсимволы |
| Срок действия | 90 дней |
| Минимальный возраст | 1–7 дней |
| Запрет повторов | последние 5 паролей |
| Лок-аут | 5 неудач за 15 минут → блокировка на 15 минут |
| Запрет пустых паролей | да |
| Хранение в системе | хеш (`scram-sha-256` для PG, `caching_sha2_password` для MySQL) |
| Хранение в коде/конфиге | **запрещено**, только переменные окружения / Vault |

## Linux — настройка

```bash
sudo apt install -y libpam-cracklib
echo 'password requisite pam_cracklib.so retry=3 minlen=8 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1' \
     | sudo tee /etc/pam.d/common-password.local

# срок действия для пользователя
sudo chage -M 90 -m 7 -W 14 dbadmin_42

# блокировка после 5 неудачных попыток (через pam_tally2/pam_faillock)
sudo grep -E 'pam_(tally2|faillock)' /etc/pam.d/common-auth || \
echo 'auth required pam_faillock.so deny=5 unlock_time=900' \
     | sudo tee -a /etc/pam.d/common-auth

# запретить пустой пароль и root по SSH
sudo sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/'           /etc/ssh/sshd_config
sudo systemctl restart ssh
```

## Windows — настройка

```cmd
net accounts /minpwlen:8 /maxpwage:90 /minpwage:1 /uniquepw:5
net accounts /lockoutthreshold:5 /lockoutduration:15 /lockoutwindow:15
```

или через `secpol.msc`:
**Параметры безопасности → Политики учётных записей → Политика паролей / Политика блокировки учётных записей**.

## Проверка пароля

```bash
echo 'StrongP@ssw0rd' | cracklib-check
```

```powershell
# заведомо слабый пароль:
echo "qwerty" | Out-File -Encoding ASCII pwd.txt
# В реальности — использовать KeePass/1Password.
```

## Генерация надёжных паролей

```bash
openssl rand -base64 16
pwgen -s 16 5
head -c 16 /dev/urandom | base64
```

```powershell
Add-Type -AssemblyName System.Web
[System.Web.Security.Membership]::GeneratePassword(16, 4)
```
