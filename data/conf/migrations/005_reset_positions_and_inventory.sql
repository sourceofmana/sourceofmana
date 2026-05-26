UPDATE character SET
	pos_x = 2176,
	pos_y = 2560,
	pos_map = 2608626462,
	respawn_x = 2176,
	respawn_y = 2560,
	respawn_map = 2608626462;

UPDATE equipment SET
	weapon = -1, weaponCustom = '',
	shield = -1, shieldCustom = '',
	ammunition = -1, ammunitionCustom = '',
	hands = -1, handsCustom = '',
	chest = -1, chestCustom = '',
	neck = -1, neckCustom = '',
	feet = -1, feetCustom = '',
	head = -1, headCustom = '',
	legs = -1, legsCustom = '',
	accessory1 = -1, accessory1Custom = '',
	accessory2 = -1, accessory2Custom = '';

DELETE FROM skill;

DELETE FROM item;
