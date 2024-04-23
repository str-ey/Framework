CREATE DATABASE IF NOT EXISTS `es_extended`;

ALTER DATABASE `es_extended`
	DEFAULT CHARACTER SET UTF8MB4;
	
ALTER DATABASE `es_extended`
	DEFAULT COLLATE UTF8MB4_UNICODE_CI;

USE `es_extended`;

CREATE TABLE `items` (
    `name` varchar(50) NOT NULL,
    `label` varchar(50) NOT NULL,
    `rare` tinyint(4) NOT NULL DEFAULT 0,
    `can_remove` tinyint(4) NOT NULL DEFAULT 1,
    `weight` float NOT NULL DEFAULT 1,

    PRIMARY KEY (`name`)
);

CREATE TABLE `jobs` (
    `name` varchar(50) NOT NULL,
    `label` varchar(50) DEFAULT NULL,

    PRIMARY KEY (`name`)
);

INSERT INTO `jobs` (`name`, `label`) VALUES
    ('unemployed', 'Citoyen(ne)');

CREATE TABLE `job_grades` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `job_name` varchar(50) DEFAULT NULL,
    `grade` int(11) NOT NULL,
    `name` varchar(50) NOT NULL,
    `label` varchar(50) NOT NULL,
    `salary` int(11) NOT NULL,
    `skin_male` longtext NOT NULL,
    `skin_female` longtext NOT NULL,

    PRIMARY KEY (`id`)
);

INSERT INTO `job_grades` (`id`, `job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
    (1, 'unemployed', 0, 'unemployed', 'Chomeur', 50, '{}', '{}');

CREATE TABLE `players` (
    `idperso` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(60) NOT NULL,
    `license` varchar(60) DEFAULT NULL,
    `accounts` longtext DEFAULT NULL,
    `group` varchar(50) DEFAULT 'user',
    `inventory` longtext DEFAULT NULL,
    `job` varchar(20) DEFAULT 'unemployed',
    `job_grade` int(11) DEFAULT 0,
    `position` varchar(255) DEFAULT NULL,
    `status` longtext DEFAULT NULL,
    `skin` longtext DEFAULT NULL,
    `firstname` varchar(50) DEFAULT '',
    `lastname` varchar(50) DEFAULT '',
    `identity` varchar(50) DEFAULT NULL,
    `dateofbirth` varchar(25) DEFAULT '',
    `sex` varchar(10) DEFAULT '',
    `height` varchar(5) DEFAULT '',
    `ldn` varchar(50) NOT NULL DEFAULT '',
    `health` tinyint(3) UNSIGNED NOT NULL DEFAULT 200,

    PRIMARY KEY (`idperso`)
);