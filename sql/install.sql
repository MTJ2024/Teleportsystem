-- ==========================================================
-- MTJ Door System - DATABASE SCHEMA
-- Copyright © MTJScripts
-- ==========================================================

CREATE TABLE IF NOT EXISTS `mtj_doors` (
    `id`          INT(11) NOT NULL AUTO_INCREMENT,
    `label`       VARCHAR(120) NOT NULL DEFAULT 'Unbenannt',
    `interaction` LONGTEXT NOT NULL,
    `entry`       LONGTEXT NOT NULL,
    `exitp`       LONGTEXT NOT NULL,
    `access`      LONGTEXT NOT NULL,
    `visibility`  FLOAT NOT NULL DEFAULT 15.0,
    `enabled`     TINYINT(1) NOT NULL DEFAULT 1,
    `created_by`  VARCHAR(80) DEFAULT NULL,
    `created_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
