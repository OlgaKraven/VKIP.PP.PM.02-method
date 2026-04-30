-- ============================================================================
-- Учебная инициализация PostgreSQL (XY = 42)
-- Соответствует образцу задания КОД 09.01.05-1-2026, Модуль 2 ДЭ ПУ.
-- Перед использованием:
--   1) замените XY (= 42) на номер своего рабочего места;
--   2) замените пароли на сгенерированные (openssl rand -base64 16).
-- ============================================================================

-- Чистая инициализация: удалить, если уже было
DROP DATABASE IF EXISTS corpdata_42;
DROP USER IF EXISTS client01;
DROP USER IF EXISTS client02;
DROP USER IF EXISTS client03;
DROP USER IF EXISTS client04;
DROP USER IF EXISTS client05;

CREATE DATABASE corpdata_42 ENCODING 'UTF8' LC_COLLATE 'C.UTF-8' LC_CTYPE 'C.UTF-8' TEMPLATE template0;

CREATE USER client01 WITH PASSWORD 'P@ss-word#1A';
CREATE USER client02 WITH PASSWORD 'P@ss-word#2B';
CREATE USER client03 WITH PASSWORD 'P@ss-word#3C';
CREATE USER client04 WITH PASSWORD 'P@ss-word#4D';
CREATE USER client05 WITH PASSWORD 'P@ss-word#5E';

\c corpdata_42

CREATE TABLE clients (
    id        SERIAL PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    reg_date  DATE          NOT NULL DEFAULT CURRENT_DATE
);

INSERT INTO clients(name, email) VALUES
    ('Anna Ivanova',   'anna@example.com'),
    ('Pavel Petrov',   'pavel@example.com'),
    ('Olga Sidorova',  'olga@example.com');

GRANT SELECT, INSERT  ON clients         TO client01, client02;
GRANT SELECT          ON clients         TO client03;
GRANT SELECT, UPDATE  ON clients         TO client04;
GRANT SELECT, DELETE  ON clients         TO client05;
GRANT USAGE, SELECT   ON SEQUENCE clients_id_seq TO client01, client02;

-- Контрольные запросы (можно запустить вручную):
-- SELECT current_database(), current_user, version();
-- SELECT * FROM clients;
-- \du
