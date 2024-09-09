package gal

import rl "vendor:raylib"

CURR_SCREEN_WIDTH := rl.GetScreenWidth()
CURR_SCREEN_HEIGHT := rl.GetScreenHeight()

// makes a Vector2
make_vector2 :: proc(x, y : f32) -> rl.Vector2 
{
    return {x, y}
}

// makes a Vector3
make_vector3 :: proc(x, y, z : f32) -> rl.Vector3 
{
    return {x, y,z}
}

// makes a Vector4 
make_vector4 :: proc(x, y, z, a: f32) -> rl.Vector4 
{
    return {x, y, z, a}
} 

// creates a Rectangle
make_rectangle :: proc(x, y, width, height : f32) -> rl.Rectangle 
{
    return {x, y, width, height}
}


// creates a Square
make_square :: proc(x, y, width : f32) -> rl.Rectangle 
{
    return {x, y, width, width}
}

/*
color list:
    light-gray,
    gray,
    dark-gray,
    yellow,
    gold,
    orange,
    pink,
    red,
    maroon,
    green,
    lime,
    dark-green,
    sky-blue,
    blue,
    dark-blue,
    purple,
    violet,
    dark-purple,
    beige,
    brown,
    dark-brown,
    white,
    black,
    magenta,
    ray-white,
    "" -> blank (transparent color)
*/
set_color :: proc(color : string) -> rl.Color 
{
    switch(color)
    {
        case "light-gray":
            return rl.LIGHTGRAY
        case "gray":
            return rl.GRAY       
        case "dark-gray":
            return rl.DARKGRAY   
        case "yellow":
            return rl.YELLOW     
        case "gold":
            return rl.GOLD
        case "orange":
            return rl.ORANGE
        case "pink":
            return rl.PINK 
        case "red":
            return rl.RED 
        case "maroon":
            return rl.MAROON 
        case "green":
            return rl.GREEN  
        case "lime":
            return rl.LIME  
        case "dark-green":
            return rl.DARKGREEN
        case "sky-blue":
            return rl.SKYBLUE
        case "blue":
            return rl.BLUE
        case "dark-blue":
            return rl.DARKBLUE
        case "purple":
            return rl.PURPLE 
        case "violet":
            return rl.VIOLET 
        case "dark-purple":
            return rl.DARKPURPLE 
        case "beige":
            return rl.BEIGE 
        case "brown":
            return rl.BROWN 
        case "dark-brown": 
            return rl.DARKBROWN 
        case "white":
            return rl.WHITE 
        case "black":
            return rl.BLACK
        case "magenta":
            return rl.MAGENTA
        case "ray-white":
            return rl.RAYWHITE
        case:
            return rl.BLANK
    }
}