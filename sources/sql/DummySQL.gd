extends RefCounted
class_name DummySQL

#
var default_extension : String = ""
var error_message : String = ""
var foreign_keys : bool = false
var last_insert_rowid : int = 0
var path : String = ""
var query_result : Array = []
var query_result_by_reference : Array = []
var read_only : bool = false
var verbosity_level : int = 0

#
func backup_to(_destination : String) -> bool: return false
func close_db() -> bool: return false
func compileoption_used(_option_name : String) -> bool: return false
func create_function(_function_name : String, _function_reference : Callable, _number_of_arguments : int) -> bool: return false
func create_table(_table_name : String, _table_dictionary : Dictionary) -> bool: return false
func delete_rows(_table_name : String, _query_conditions : String) -> bool: return false
func drop_table(_table_name : String) -> bool: return false
func export_to_json(_export_path : String) -> bool: return false
func get_autocommit() -> int: return 0
func import_from_json(_import_path  : String) -> bool: return false
func insert_row(_table_name : String, _row_dictionary : Dictionary) -> bool: return false
func insert_rows(_table_name : String, _row_array : Array) -> bool: return false
func open_db() -> bool: return false
func query(_query_string : String) -> bool: return false
func query_with_bindings(_query_string : String, _param_bindings : Array) -> bool: return false
func restore_from(_source_path : String) -> bool: return false
func select_rows(_table_name : String, _query_conditions : String, _selected_columns : Array) -> Array: return []
func update_rows(_table_name : String, _query_conditions : String, _updated_row_dictionary : Dictionary) -> bool: return false
