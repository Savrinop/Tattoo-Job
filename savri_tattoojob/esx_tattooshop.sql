USE `essentialmode`;

ALTER TABLE `users`
	ADD COLUMN `tattoos` LONGTEXT
;

INSERT INTO `job_grades` (job_name, grade, name, label, salary, skin_male, skin_female) VALUES
  ('tattoo',0,'employe','Employé',250, '{}', '{}'),
  ('tattoo',1,'boss','Patron',250, '{}', '{}')
;

INSERT INTO `jobs` (name, label) VALUES
  ('tattoo','Salon de tatouage')
;

INSERT INTO `addon_account` (name, label, shared) VALUES
  ('tattooshop', 'Salon de tatouage', 1)
;

INSERT INTO `datastore` (name, label, shared) VALUES
	('tattooshop', 'Salon de tatouage', 1)
;

INSERT INTO `addon_inventory` (name, label, shared) VALUES
	('tattooshop', 'Salon de tatouage', 1)
;