class_name XMLReader
# A high level class to allow for reading and parsing xml files.


var xml_dict := {}
var node_paths := []


# PARSERS ——————————————————————————————————————————————————————————————————————
func open_file(file_path:String) -> int:
	# Opens and parses an xml document that is stored in a file at `file_path`.
	xml_dict.clear()
	var parser = XMLParser.new()
	var ERR = parser.open(file_path)
	
	if ERR != OK:
		push_warning("XMLParser ERR %s" % ERR)
		return ERR
	
	self.parse(parser)
	return OK

func open_buffer(buffer:PoolByteArray) -> int:
	# Opens and parses an xml document that has been loaded into memory 
	# as a PoolByteArray.
	var parser = XMLParser.new()
	var ERR = parser.open_buffer(buffer)
	if ERR != OK:
		push_warning("XMLParser ERR %s, unable to read buffer" % ERR)
		return ERR
	
	self.parse(parser)
	return OK

func open_string(string:String) -> int:
	# Opens and parses an xml document that has been loaded into memory as a
	# String.
	return self.open_buffer(string.to_utf8())

func parse(parser:XMLParser) -> void:
	# Parses a xml document that has been opened with XMLParser and loads it
	# into a dictionary. This should only be used internally by open_file(), 
	# open_buffer(), and open_string(), but can be used if an instance of 
	# XMLParser is returned from some exogenous function.
	xml_dict.clear()
	node_paths.clear()
	
	var path := PoolStringArray()
	while parser.read() != ERR_FILE_EOF:
		match parser.get_node_type():
			parser.NODE_ELEMENT:
				var parent_node = get_element(path)
				var current_node = parser.get_node_name()
				path.append(current_node)
				parent_node[current_node] = {}
				
				node_paths.append([current_node, path])
				
				var num_attrs = parser.get_attribute_count()
				if num_attrs:
					var attrs = "%s_attrs" % current_node
					parent_node[current_node][attrs] = {}
					attrs = parent_node[current_node][attrs]
					for idx in range(num_attrs):
						attrs[parser.get_attribute_name(idx)] = parser.get_attribute_value(idx)
			
			parser.NODE_TEXT:
				var parent_node = get_element(path)
				parent_node["%s_text" % path[-1]] = parser.get_node_data()
			parser.NODE_ELEMENT_END:
# warning-ignore:narrowing_conversion
				path.resize(max(0, path.size() - 1))


# ELEMENT AND PATH GETTERS ————————————————————————————————————————————————————————
func get_element(path:Array, dict:Dictionary=xml_dict) -> Dictionary:
	# Returns the dictionary of child nodes of a node at path.
	var element = dict
	for key in path:
		element = element.get(key)
	return element

func find_element(node_name:String) -> PoolStringArray:
	# Returns the path to the first occurence of node_name. If the node does 
	# not exist, returns an empty PoolStringArray.
	for node in node_paths:
		if node[0] == node_name:
			return node[1]
	return PoolStringArray()

func find_all_element(node_name:String) -> Array:
	# Returns an array of paths (PoolStringArrays) to all of a given element.
	# If node_name does not exist, returns and empty Array.
	var paths := []
	for node in node_paths:
		if node[0] == node_name:
			paths.append(node[1])
	return paths


# QOL FUNCTIONS ————————————————————————————————————————————————————————————————
func prettify(delimeter:String="\t", dict:Dictionary=xml_dict) -> String:
	# Returns a "prettified" (readable) string of the xml dictionary.
	return JSON.print(dict, delimeter)

