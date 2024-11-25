-- Active: 1726218852770@@127.0.0.1@3306
CREATE DATABASE IF NOT EXISTS `boxlang` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
USE `boxlang`;

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `age` int(11) NOT NULL DEFAULT 0,
  `email` varchar(255) NOT NULL DEFAULT "",
  `password` varchar(255) NOT NULL DEFAULT "",
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;