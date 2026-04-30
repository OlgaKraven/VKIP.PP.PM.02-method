# MySQL — учебные конфиги

Содержимое:

- `init.sql` — создание БД `corpdata_42`, пяти пользователей и таблицы `clients`.
- `my.cnf.fragment` — параметры производительности и сетевые настройки.
- `.env.example` — переменные подключения.

## Применение

```bash
sudo apt install -y mysql-server
sudo mysql_secure_installation

sudo mysql -u root -p < init.sql

# параметры производительности
sudo cp my.cnf.fragment /etc/mysql/mysql.conf.d/00-tuning.cnf
sudo systemctl restart mysql
```

> Замените `XY = 42` на номер своего рабочего места и пароли в `init.sql` на сгенерированные.
