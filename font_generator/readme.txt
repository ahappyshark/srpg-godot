Prerequisites:
- an image file with all your font characters
- a .json file with the font information



Install the tool:
Just copy the extracted files into your Godot project. 






Use the tool:
Make sure your font image file and the .json file are in the project directory as well.

Open the font_generator.tscn file in the Godot editor. 
Select the root node and go to the Inspector tab. 
There add your .json file (also in the project directory) and click on  Create Font Button. 
If you've described the font correctly in the json file you should now see a new fnt file in your project directory.
Use this file as a font resource for your projects theme etc.

You can use the example.json provided as a template for your own font.

IMPORTANT: If the .fnt doesn't show up immediately in Godot, tab out of the editor and tab back in. If it still doesn't show up, check the debug log for errors.





JSON explanation:

font_name: The name of your font
font_file_path: The complete (res://) path for the .fnt file to be created
texture_file_path: The image file to use (it's recommended to have the image file in the same directory as the fnt and json file - then you'll just have to use the file name)
font_size: The size of your font in pixels
is_bold: Is the font in bold?
is_italic: Is the font in italic?
line_height: Defines line height of the font in pixels
base: Defines the base line of the font in pixels
char_width: Defines the width of a texture cell
char_height: Defines the height of a texture cell
img_width: Defines the total width of the texture
img_height: Defines the total height of the texture
xadvance_default: Defines by how many pixels the text rendering routine should move per character by default
xadvances: An array of exceptions for xadvances_default. Each element is defined as follows:
    xadvance: The new value to advance by
    characters: An array of characters using this new xadnvance value
kerning: An array of character pairs with their own xadvance. This overrides xadvance_default and xadvances. A character pair is defined as follows:
    first: the first character in the pair
    second: the second character in the pair
    amount: By how much should the used xadvance change? -10 would mean 10 pxels to the left, 
            while 10 would mean 10 to the right. 0 would mean no change at all to the xadvance value.

    




Licence
Thanks for downloading this tool, created by Martin Senges.
It is licenced under the MIT Licence.



Copyright (c) 2024 Martin Senges

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

