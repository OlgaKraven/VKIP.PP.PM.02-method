# PostgreSQL — учебные конфиги

Содержимое:

- `init.sql` — создание БД `corpdata_42`, пяти пользователей и таблицы `clients` с разграничением прав по учебной матрице задания.
- `postgresql.conf.fragment` — параметры производительности и сетевые настройки, добавляемые к стандартному `postgresql.conf`.
- `pg_hba.conf.example` — правила доступа.
- `.env.example` — переменные подключения (хост, порт, пользователи).

## Применение

```bash
# 1. Установка СУБД
sudo apt install -y postgresql postgresql-contrib

# 2. Инициализация БД и пользователей
sudo -u postgres psql -f init.sql

# 3. Применить параметры производительности (вставить в основной конфиг)
sudo cp postgresql.conf.fragment /etc/postgresql/16/main/conf.d/00-tuning.conf

# 4. Заменить pg_hba.conf
sudo cp pg_hba.conf.example /etc/postgresql/16/main/pg_hba.conf

# 5. Перезапуск
sudo systemctl restart postgresql
```

## Замечания

- `XY` в скрипте подставлен как `42` — измените под номер вашего рабочего места.
- Пароли вида `P@ss-word#1A` — заглушки. Перед использованием сгенерируйте новые: `openssl rand -base64 16`.
- В `pg_hba.conf.example` подсеть `192.168.10.0/24` — замените на свою.
