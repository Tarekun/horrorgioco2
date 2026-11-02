## Tests for DocumentLog: which documents have been read, and saving it.

extends GutTest

var _log: DocumentLog
var _letter: ItemData
var _note: ItemData


func before_each() -> void:
	_log = DocumentLog.new()
	_letter = ItemData.new()
	_letter.id = &"doc_letter"
	_note = ItemData.new()
	_note.id = &"doc_note"


func test_a_document_starts_unread() -> void:
	assert_false(_log.is_read(_letter))


func test_marking_read_is_remembered() -> void:
	_log.mark_read(_letter)
	assert_true(_log.is_read(_letter))
	assert_false(_log.is_read(_note))


func test_marking_a_null_item_does_nothing() -> void:
	_log.mark_read(null)
	assert_false(_log.is_read(null))


func test_to_dict_lists_the_read_ids() -> void:
	_log.mark_read(_letter)
	assert_eq(_log.to_dict(), {"doc_letter": true} as Dictionary[String, bool])


func test_from_dict_restores_what_was_read() -> void:
	_log.from_dict({"doc_letter": true, "doc_note": false})
	assert_true(_log.is_read(_letter))
	assert_false(_log.is_read(_note))


func test_from_dict_replaces_the_previous_contents() -> void:
	_log.mark_read(_letter)
	_log.from_dict({"doc_note": true})
	assert_false(_log.is_read(_letter))
	assert_true(_log.is_read(_note))
