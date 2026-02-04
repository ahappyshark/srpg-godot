@tool
extends Node

#Based on the following doc:
#http://www.angelcode.com/products/bmfont/doc/file_format.html
#But using the non-binary version

@export_file("*.json") var font_data_json_path: String = "" 
@export var create_font_button: bool = false:
	set(value):
		create_font_button = value
		if(value):
			var json_data: Dictionary = load_font_data_json()
			#print(json_data)
			if(!json_data.is_empty()):
				create_font(json_data)
			else:
				printerr("Font Generator: Couldn't load font data from \"",font_data_json_path,"\".")
			create_font_button = false




func load_font_data_json() -> Dictionary:
	var json_file = FileAccess.open(font_data_json_path, FileAccess.READ)
	var json = JSON.new()
	var valid = json.parse(json_file.get_as_text())
	if valid == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_DICTIONARY:
			return data_received
		#No additional content checking. Use at own risk!
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", font_data_json_path, " at line ", json.get_error_line())
	return Dictionary()



func create_font(font_data: Dictionary) -> void:
	var file = FileAccess.open(font_data["font_file_path"], FileAccess.WRITE)
	var content: String = ""
	content += get_info_block(font_data["font_name"], font_data["font_size"], font_data["is_bold"], font_data["is_italic"]) +"\n"
	content += get_common_block(font_data["line_height"], font_data["base"], font_data["img_width"], font_data["img_height"]) + "\n"
	content += get_page_block(font_data["texture_file_path"]) + "\n"

	var char_array: Array = [
		" ", "!","\"","#","$","%","&","'","(",")","*","+",",","-",".","/","0","1","2","3","4","5","6","7","8","9",":",";","<","=",">","?","@",
		"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
		"[","\\","]","^","_","`",
		"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
		"{","|","}","~",
		
		"Ä","Ö","Ü","ß","ä","ö","ü",
		
		#proxied
		"\u201C","\u201D","\u201E", "\u201F", #german quotation marks
		
		"’" #acute accent
	]
	content += get_char_block(char_array, font_data["char_width"], font_data["char_height"], font_data["xadvance_default"], font_data["xadvances"], font_data["img_width"])
	content += get_kerning_pair_block(font_data["kerning"])
	file.store_string(content)
	file.close()


func get_file_header() -> PackedByteArray:
	var header: PackedByteArray = "BMF".to_ascii_buffer()
	header.append(3)
	return header

func get_info_block(font_name: String, font_size: int, is_bold: int, is_italic: int) -> String:
	var block: String = "info face=\"" + font_name + "\" size=" + str(font_size) + " bold=" + str(is_bold) + " italic=" + str(is_italic) + " charset=\"\" unicode=1 strechH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0"
	return block


func get_common_block(line_height:int, base:int, img_width:int, img_height:int) -> String:
	var block: String = "common lineHeight=" + str(line_height) + " base=" + str(base) + " scaleW=" + str(img_width) + " scaleH=" + str(img_height) + " pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0" 
	return block

func get_page_block(texture_file_path: String) -> String:
	var block: String = "page id=0 file=\"" + texture_file_path +"\""
	return block


func get_char_block(char_array:Array, char_width:int, char_height:int, xadvance_default:int, xadvances: Array, img_width: int) -> String:
	var block: String = "chars count=" + str(char_array.size()) +"\n"

	for i in range(char_array.size()):
		var char_proxy: String = char_array[i]
		if(char_proxy in ["\u201C","\u201D","\u201E", "\u201F"]):
			char_proxy = "\""
		if(char_proxy in ["’"]):
			char_proxy = "'"
		
		var pixel_estimate: int = (char_proxy.unicode_at(0) - " ".unicode_at(0)) * char_width
		var x = pixel_estimate % img_width
		var y = (pixel_estimate / img_width) * char_height
		var xadvance:int = xadvance_default
		for xa in xadvances:
			if(char_proxy in xa["characters"]):
				xadvance = xa["xadvance"]

		var line: String = "char id=" + str(char_array[i].unicode_at(0)) + " x=" + str(x) + " y=" + str(y) + " width=" +str(char_width) + " height=" + str(char_height) + " xoffset=0 yoffset=0 xadvance=" + str(xadvance) + " page=0 chnl=15 letter=\"" + char_array[i] +"\""
		block += line + "\n"
	return block



func get_kerning_pair_block(kerning_pair_array: Array) -> String:
	var block: String = "kernings count=" + str(kerning_pair_array.size()) +"\n"
	for kp in kerning_pair_array:
		var line: String = "kerning first=" +str(kp["first"].unicode_at(0)) + " second=" + str(kp["second"].unicode_at(0)) + " amount=" + str(kp["amount"])
		block += line + "\n"
	return block
