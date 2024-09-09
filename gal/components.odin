package gal

import rl "vendor:raylib"

TextButton :: struct 
{
    text: 			cstring,
	rect: 			rl.Rectangle,
	color: 			rl.Color,
	outline_color: 	rl.Color,
	text_color: 	rl.Color,
	pos: 			[2]i32,
	font_size: 		i32, 
	isClicked: 		bool,
}

make_textbutton :: proc(
    text: cstring, rect: rl.Rectangle, color: rl.Color,
	outline_color: rl.Color, text_color: rl.Color, pos: [2]i32, 
    font_size: 	i32, is_clicked := false
) -> TextButton 
{
    return {text, rect, color, outline_color, text_color, pos, font_size, is_clicked}
}

draw_button :: proc(b : TextButton) -> bool 
{
    rl.DrawRectangleRec(b.rect, b.color)
	rl.DrawRectangleLines(cast(i32)b.rect.x, cast(i32)b.rect.y, cast(i32)b.rect.width, cast(i32)b.rect.height, b.outline_color)
	rl.DrawText(b.text, b.pos.x, b.pos.y, b.font_size, b.text_color)

    if rl.CheckCollisionPointRec(rl.GetMousePosition(), b.rect) && rl.IsMouseButtonPressed(.LEFT) == true
    {
		return !b.isClicked
	}
	return b.isClicked
}

draw_title_screen :: proc(title : cstring, font_size : i32 = 100, x := CURR_SCREEN_WIDTH, y := CURR_SCREEN_HEIGHT) 
{
	rl.DrawText(title, x/2 + font_size, y/2 + font_size, font_size, set_color("ray-white"))
}