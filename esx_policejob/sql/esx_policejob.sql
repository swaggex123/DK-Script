-- ESX police job (New ESX / ESX Legacy)

-- Job + grades
INSERT IGNORE INTO `jobs` (`name`, `label`) VALUES
('police', 'Police');

INSERT IGNORE INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`) VALUES
('police', 0, 'recruit', 'Recruit', 500),
('police', 1, 'officer', 'Officer', 800),
('police', 2, 'sergeant', 'Sergeant', 1100),
('police', 3, 'lieutenant', 'Lieutenant', 1400),
('police', 4, 'boss', 'Chief', 1800);

-- Society accounts / inventory / datastore
INSERT IGNORE INTO `addon_account` (`name`, `label`, `shared`) VALUES
('society_police', 'Police', 1);

INSERT IGNORE INTO `addon_inventory` (`name`, `label`, `shared`) VALUES
('society_police', 'Police', 1);

INSERT IGNORE INTO `datastore` (`name`, `label`, `shared`) VALUES
('society_police', 'Police', 1);

