-- ============================================================================
-- Учебная инициализация MySQL (XY = 42)
-- Перед использованием замените XY и пароли на сгенерированные.
-- ============================================================================

DROP DATABASE IF EXISTS corpdata_42;
CREATE DATABASE corpdata_42 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS 'client01'@'192.168.10.%';
DROP USER IF EXISTS 'client02'@'192.168.10.%';
DROP USER IF EXISTS 'client03'@'192.168.10.%';
DROP USER IF EXISTS 'client04'@'192.168.10.%';
DROP USER IF EXISTS 'client05'@'192.168.10.%';

CREATE USER 'client01'@'192.168.10.%' IDENTIFIED BY 'P@ss-word#1A';
CREATE USER 'client02'@'192.168.10.%' IDENTIFIED BY 'P@ss-word#2B';
CREATE USER 'client03'@'192.168.10.%' IDENTIFIED BY 'P@ss-word#3C';
CREATE USER 'client04'@'192.168.10.%' IDENTIFIED BY 'P@ss-word#4D';
CREATE USER 'client05'@'192.168.10.%' IDENTIFIED BY 'P@ss-word#5E';

USE corpdata_42;

CREATE TABLE clients (
    id        INT          AUTO_INCREMENT PRIMARY KEY,
    name      VARCHAR(100) NOT NULL,
    email     VARCHAR(120) NOT NULL UNIQUE,
    reg_date  DATE         NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO clients(name, email) VALUES
    ('Anna Ivanova',   'anna@example.com'),
    ('Pavel Petrov',   'pavel@example.com'),
    ('Olga Sidorova',  'olga@example.com');

GRANT SELECT, INSERT  ON corpdata_42.clients TO 'client01'@'192.168.10.%', 'client02'@'192.168.10.%';
GRANT SELECT          ON corpdata_42.clients TO 'client03'@'192.168.10.%';
GRANT SELECT, UPDATE  ON corpdata_42.clients TO 'client04'@'192.168.10.%';
GRANT SELECT, DELETE  ON corpdata_42.clients TO 'client05'@'192.168.10.%';

FLUSH PRIVILEGES;

-- Контроль:
-- SELECT user, host FROM mysql.user WHERE user LIKE 'client%';
-- SHOW GRANTS FOR 'client03'@'192.168.10.%';
