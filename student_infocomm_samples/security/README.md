# Защита от НСД — учебные материалы

Содержимое:

- `password_policy.md` — учебная парольная политика и команды настройки.
- `audit.sh` — bash-скрипт быстрого аудита Linux-хоста (открытые порты, SUID, неактивные учётки, политика паролей, обновления).
- `windows_hardening.md` — чек-лист базового hardening Windows-хоста.

## Применение

```bash
# Linux: аудит хоста
sudo bash audit.sh ./report
```

```powershell
# Windows: пройти чек-лист из windows_hardening.md
```

В отчёт по практике включается:

- результат `audit.sh` (или его эквивалент для Windows) в `report/SecurityScan_XX/`;
- сводная таблица отклонений и рекомендаций по каждой проверке.
