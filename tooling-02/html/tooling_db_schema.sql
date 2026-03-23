-- phpMyAdmin SQL Dump
-- version 5.0.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 08, 2021 at 12:00 PM
-- Server version: 10.4.14-MariaDB
-- PHP Version: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `toolingdb`
--

CREATE DATABASE IF NOT EXISTS toolingdb;

Use toolingdb;
-- --------------------------------------------------------

--
-- Table structure for table `environments`
--

CREATE TABLE `environments` (
  `id` int(40) NOT NULL,
  `environment_type` varchar(40) NOT NULL,
  `environment_name` varchar(40) NOT NULL,
  `ip_address` varchar(40) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `environments`
--

INSERT INTO `environments` (`id`, `environment_type`, `environment_name`, `ip_address`) VALUES
(10, 'SIT', '[jenkins]', ' 172.31.42.57'),
(12, 'SIT', ' [nginx] ', '18.159.134.59'),
(13, 'SIT', ' [sonarqube] ', '172.31.16.34'),
(15, 'SIT', ' [artifact_repository] ', '35.158.126.155'),
(16, 'SIT', ' [artifactory] ', '172.31.47.215'),
(18, 'Pentest', ' [pentest-todo]', ' 18.185.240.182'),
(19, 'Pentest', ' [pentest-tooling]', ' 18.193.115.188'),
(27, 'Pre Prod', '[jenkins] ', '172.31.42.57'),
(28, 'Pre Prod', '[todo] ', '172.31.4.144'),
(29, 'Pre Prod', '[nginx] ', '18.159.134.59'),
(30, 'Pre Prod', '[nginx] ', '172.31.4.197'),
(31, 'Pre Prod', '[sonarqube] ', '172.31.16.34'),
(32, 'Pre Prod', '[database] ', '172.31.43.57'),
(34, 'Pre Prod', '[artifactory] ', '172.31.47.215'),
(36, 'UAT', ' [jenkins]', ' 172.31.42.57'),
(38, 'SIT', '[database] ', '172.31.43.57'),
(40, 'SIT', ' [todo] ', '172.31.4.144'),
(41, 'UAT', '[tooling]', '172.31.44.252');

-- --------------------------------------------------------

--
-- Table structure for table `tools`
--

CREATE TABLE `tools` (
  `id` int(50) NOT NULL,
  `tool_name` varchar(50) NOT NULL,
  `tool_type` varchar(50) NOT NULL,
  `url` varchar(50) NOT NULL,
  `image` longblob NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tools`
--

INSERT INTO `tools` (`id`, `tool_name`, `tool_type`, `url`, `image`) VALUES
(43, 'Prometheus', 'Monitor', 'https://Prometheus.com', 0x696d616765732f70726f6d6574686575732d353530783132302e706e67),
(45, 'Google', 'Cloud', 'https://google.com', 0x696d616765732f3538306235376663643939393665323462633433633531662e706e67),
(46, 'AWS', 'Cloud', 'https://aws.com', 0x696d616765732f33663033363230366563316434383663613639386239626634633134353430322e706e67),
(47, 'Grafana Labs', 'Monitor', 'https://grafana_labs.com', 0x696d616765732f646f776e6c6f6164202836292e706e67),
(48, 'Nagios', 'Monitor', 'https://nagios.com', 0x696d616765732f313435663565333763653665396363326266376661396232353531656464646320312e706e67),
(49, 'Splunk', 'Monitor', 'https://splunk.com', 0x696d616765732f53706c756e6b5f6c6f676f20312e706e67),
(50, 'Git', 'Version Control', 'https://git.com', 0x696d616765732f315f4f764d736d517330527a735f53637569547375576a7720322e706e67),
(51, 'Ansible', 'IAAC', 'https://ansible.com', 0x696d616765732f3438312d343831353838315f6275696c64696e672d68612d636c7573746572732d776974682d616e7369626c652d616e642d6f70656e737461636b2d616e7369626c652d72656d6f766562672d7072657669657720322e706e67),
(52, 'Puppet', 'IAAC', 'https://puppet.com', 0x696d616765732f7075707065742d766563746f722d6c6f676f2e706e67),
(53, 'Chef', 'IAAC', 'https://chef.com', 0x696d616765732f3538343765616631636566313031346330623565343834352e706e67),
(54, 'Saltstack', 'IAAC', 'https://saltstack.com', 0x696d616765732f53616c74737461636b2d696e74726f64756374696f6e2e706e67),
(55, 'Github', 'SCM', 'https://github.com', 0x696d616765732f3935352d393535383136335f7472616e73706172656e742d6769746875622d6c6f676f2e706e67),
(57, 'BitBucket', 'SCM', 'https://bitbucket.com', 0x696d616765732f6269746275636b65742d6c6f676f2e706e67),
(58, 'SonarCube', 'Code Quality', 'https://codequality.com', 0x696d616765732f736f6e6172717562652d6c6f676f2e706e67),
(59, 'Docker', 'Containrization', 'https://docker.com', 0x696d616765732f646f776e6c6f6164202837292e706e67),
(61, 'Kubernetes', 'Containrization', 'https://kubernetes.com', 0x696d616765732f6b756265726e657465732d6c6f676f20312e706e67),
(65, 'Circle Ci', 'Continous Integration', 'https://circleci.com', 0x696d616765732f34313539373230352d61353734343265612d373363342d313165382d393539312d36316635633833633765363620312e706e67),
(66, 'Travis Ci', 'Continous Integration', 'https://travisci.com', 0x696d616765732f6c6f676f2d74726176697363692d77696465315f6c636a68646620312e706e67),
(71, 'Jenkins', 'Continous Integration', 'https://jekins.com', 0x696d616765732f6a656e6b696e732d6c6f676f2d706e6720322e706e67),
(72, 'Codeship', 'Continous Integration', 'https://codeship.com', 0x696d616765732f636f6465736869702d6c6f676f2d686f72697a6f6e74616c2d7468756d626e61696c20312e706e67),
(73, 'TeamCity', 'Continous Integration', 'https://teamcity.com', 0x696d616765732f7465616d636974792d6c6f676f2d626c61636b2d616e642d776869746520312e706e67),
(74, 'Azure', 'Cloud', 'https://azure.com', 0x696d616765732f4d6963726f736f66745f417a7572652d4c6f676f202831292e706e67);

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `id` int(60) NOT NULL,
  `username` varchar(60) NOT NULL,
  `email` varchar(60) NOT NULL,
  `password` varchar(60) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `username`, `email`, `password`) VALUES
(1, 'john.doe', 'john.doe@mycompany.com', 'jD8!s3cret'),
(2, 'jane.smith', 'jane.smith@mycompany.com', 'J@n3Smitt'),
(3, 'michael.jones', 'michael.jones@mycompany.com', 'M1cha3l$'),
(4, 'sarah.lee', 'sarah.lee@mycompany.com', 'S@r4hRocks'),
(5, 'david.miller', 'david.miller@mycompany.com', 'D4v1dm0n'),
(6, 'kimberly.williams', 'kimberly.williams@mycompany.com', 'K1mb3rly!'),
(7, 'matthew.brown', 'matthew.brown@mycompany.com', 'M@ttBrown'),
(8, 'ashley.thomas', 'ashley.thomas@mycompany.com', 'Ash_T0mmy'),
(9, 'james.garcia', 'james.garcia@mycompany.com', 'J4m3s_G!'),
(10, 'jennifer.hernandez', 'jennifer.hernandez@mycompany.com', 'J3nn_H3rN'),
(11, 'jessica.davis', 'jessica.davis@mycompany.com', 'JessD@v1s'),
(12, 'joseph.lopez', 'joseph.lopez@mycompany.com', 'J0s3phL0p'),
(13, 'christopher.lewis', 'christopher.lewis@mycompany.com', 'Chr1sL3w1s'),
(14, 'amanda.clark', 'amanda.clark@mycompany.com', 'Am@ndaC1ark'),
(15, 'william.johnson', 'william.johnson@mycompany.com', 'W1lliamJ0hns0n'),
(99, 'Test', 'test@gmail.com', '12345'),
(16, 'elizabeth.roberts', 'elizabeth.roberts@mycompany.com', 'El1zabethR0b3rts'),
(17, 'robert.walker', 'robert.walker@mycompany.com', 'R0b3rtW@lk3r'),
(18, 'emily.allen', 'emily.allen@mycompany.com', 'Em1ly_All3n'),
(19, 'richard.wilson', 'richard.wilson@mycompany.com', 'R1ch4rdW1ls0n'),
(20, 'daniel.king', 'daniel.king@mycompany.com', 'D@n1elK1ng'),
(21, 'catherine.wright', 'catherine.wright@mycompany.com', 'C@th3r1neWr1ght'),
(22, 'charles.scott', 'charles.scott@mycompany.com', 'Ch@rlesSc0tt'),
(23, 'maria.anderson', 'maria.anderson@mycompany.com', 'M@r1aAnd3rs0n'),
(24, 'joseph.taylor', 'joseph.taylor@mycompany.com', 'J0s3phT@yl0r'),
(25, 'anthony.thomas', 'anthony.thomas@mycompany.com', 'Anth0nyT0m'),
(26, 'rachel.harris', 'rachel.harris@mycompany.com', 'R@ch3lH@rr1s'),
(27, 'kenneth.martin', 'kenneth.martin@mycompany.com', 'K3nn3thM@rt1n'),
(28, 'andrea.thompson', 'andrea.thompson@mycompany.com', 'Andr3aTh0mps0n'),
(29, 'joseph.young', 'joseph.young@mycompany.com', 'J0s3phY0ung'),
(30, 'daniel.hall', 'daniel.hall@mycompany.com', 'D@n1elH@ll'),
(31, 'laura.davis', 'laura.davis@mycompany.com', 'L@ur@D@v1s'),
(32, 'abraham.miller', 'abraham.miller@mycompany.com', 'Abr@h@mMill3r'),
(33, 'sarah.carter', 'sarah.carter@mycompany.com', 'S@r@hC@rt3r');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `environments`
--
ALTER TABLE `environments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `tools`
--
ALTER TABLE `tools`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `environments`
--
ALTER TABLE `environments`
  MODIFY `id` int(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `tools`
--
ALTER TABLE `tools`
  MODIFY `id` int(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=75;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `id` int(50) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
