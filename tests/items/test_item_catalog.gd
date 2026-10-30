## Tests for the item catalog and the item definitions in assets/data/items/.

extends GutTest


func test_finds_items_by_id() -> void:
	var rounds: ItemData = ItemCatalog.find(&"pistol_ammo")
	assert_not_null(rounds)
	assert_eq(rounds.display_name, "Pistol rounds")
	assert_eq(rounds.category, ItemData.Category.AMMO)


func test_an_unknown_id_finds_nothing() -> void:
	assert_null(ItemCatalog.find(&"nonexistent"))


func test_every_definition_is_named_after_its_id() -> void:
	var files: PackedStringArray = ResourceLoader.list_directory(ItemCatalog.ITEMS_DIR)
	assert_gt(files.size(), 0)
	for file: String in files:
		var item := load(ItemCatalog.ITEMS_DIR + file) as ItemData
		assert_not_null(item, "%s is not an ItemData" % file)
		if item:
			assert_eq(String(item.id), file.get_basename(), file)
			assert_eq(ItemCatalog.find(item.id), item, file)


func test_every_item_has_a_name_and_a_description() -> void:
	for item: ItemData in ItemCatalog.all().values():
		assert_false(item.display_name.is_empty(), "%s has no name" % item.id)
		assert_false(item.description.is_empty(), "%s has no description" % item.id)
