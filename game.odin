package demo

import rl "vendor:raylib"
import "core:fmt"
import "core:mem"
import "gal"

/*
==================================
            Program
==================================
*/


ProgramState :: enum u8 {
    MAIN, // Game Main menu Screen
    GAME, // Game Loop
    BASIC, // Shows Game Controls
    COMPLETED,  // Indicates Level Completion
    WON, // Indicates when Level is Finished
}

// ID's for sprites
SpriteID :: enum u8 {
    NONE,
    PLAYER,
    WALL,
    DOOR,
    KEY,
    CRATE,
    DOT,
}

SpriteTexture :: struct {
    texture : rl.Texture2D,
}

GameAction :: struct {
    object_layer: [ROWS][COLS]int,
    player_row : i32,
    player_col : i32, 
}

// Common Colors
black := gal.set_color("black")
white := gal.set_color("ray-white")
gray := gal.set_color("gray")

// Game Variables
camera : rl.Camera2D
current_state : ProgramState
floor_layer : [10][20]int
object_layer : [10][20]int
player_has_key : bool 
sprites : [SpriteID]SpriteTexture
level_index : int
player_pos : rl.Vector2
player_row, player_col: i32
mouse_scroll_value : f32
game_state_stack : [dynamic]GameAction

grid_width : i32 = COLS * TILE_SIZE
grid_height : i32 = ROWS * TILE_SIZE
startX : i32 = (screen_width - grid_width) / 2
startY : i32 = (screen_height - grid_height) / 2

/*
==================================
            Camera
==================================
*/

get_current_player_pos :: proc() -> rl.Vector2 {
    for i:= 0; i< ROWS; i+=1 {
        for j:=0; j< COLS; j+=1 {
            if object_layer[i][j] == 4 {
                return gal.make_vector2(cast(f32)i, cast(f32)j)
            }
        }
    }
    return gal.make_vector2(0, 0)
}

get_map_center :: proc() -> rl.Vector2 {
    map_width := ROWS * TILE_SIZE
    map_height := COLS * TILE_SIZE
    return gal.make_vector2(cast(f32) map_width/2, cast(f32)map_height/2)
}

init_camera :: proc() {
    player_pos = get_current_player_pos()
    camera.target = gal.make_vector2(
        player_pos.x * TILE_SIZE + TILE_SIZE/2 - CAMERA_VIEW_WIDTH/2,
        player_pos.y * TILE_SIZE + TILE_SIZE/2 - CAMERA_VIEW_HEIGHT/2
    )
    camera.offset = gal.make_vector2(
        CAMERA_VIEW_WIDTH/2 + 160, 
        CAMERA_VIEW_HEIGHT/2 + 160
    )
    camera.rotation = 0
    camera.zoom = 1.0
}


update_camera :: proc() {
    target_x := player_pos.x * TILE_SIZE + TILE_SIZE/2 - CAMERA_VIEW_WIDTH/2
    target_y := player_pos.y * TILE_SIZE + TILE_SIZE/2 - CAMERA_VIEW_HEIGHT/2
    
    camera.target.x = gal.lerp(camera.target.x, target_x, 0.1)
    camera.target.y = gal.lerp(camera.target.y, target_y, 0.1)
}

/*
==================================
            SOKOBAN
==================================
*/


init_level :: proc(level_index: i32) {
    switch(level_index) {
        case 1:
            level1()
        case 2:
            level2()
        case 3:
            level3()
        case 4:
            level4()
        case 5:
            level5()
        case 6:
            level6()
        case 7:
            level7()
    }
}

draw_layer :: proc(layer: [10][20]int) {
    for i : i32 = 0; i < ROWS; i+=1 {
        for j : i32 = 0; j < COLS; j+=1 {
            tile := layer[i][j]
            color : rl.Color

            if tile == 1 {
                color = rl.LIGHTGRAY
            } else if tile == 3 {
                color = rl.BLUE 
            } else if tile == 7 {
                rl.DrawTexture(sprites[.DOT].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            } else {
                continue
            }

            rl.DrawRectangle(startX + j * TILE_SIZE, startY + i * TILE_SIZE, TILE_SIZE, TILE_SIZE, color)
            rl.DrawRectangleLines(startX + j * TILE_SIZE, startY + i * TILE_SIZE, TILE_SIZE, TILE_SIZE, rl.BLACK)
        }
    }
}

draw_objects :: proc() {
    for i : i32 = 0; i < ROWS; i+=1 {
        for j : i32 = 0; j < COLS; j+=1 {
            tile := object_layer[i][j]

            if tile == 2 {
                rl.DrawTexture(sprites[.WALL].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            } else if tile == 4 {
                rl.DrawTexture(sprites[.PLAYER].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            } else if tile == 8 { 
                rl.DrawTexture(sprites[.CRATE].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            } else if tile == 5 {
                rl.DrawTexture(sprites[.DOOR].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            } else if tile == 6 {
                rl.DrawTexture(sprites[.KEY].texture, startX + j * TILE_SIZE, startY + i * TILE_SIZE,  rl.WHITE)
            }
        }
    }
}

sokoban_completed :: proc() -> bool {
    for i := 0; i < ROWS; i += 1 {
        for j := 0; j < COLS; j += 1 {
            if floor_layer[i][j] == 7 && object_layer[i][j] != 8 {
                return false
            }
        }
    }
    return true
}

/*
==================================
            INTERACTIONS
==================================
*/


mouse_interactions :: proc() {
    // Get the mouse position in screen coordinates
    mouse_pos : rl.Vector2 = rl.GetMousePosition()
    
    // Convert the screen coordinates to world coordinates
    world_mouse_pos := rl.GetScreenToWorld2D(mouse_pos, camera)
    
    // Calculate the grid cell the mouse is hovering over
    col := (cast(i32)world_mouse_pos.x - startX) / TILE_SIZE
    row := (cast(i32)world_mouse_pos.y - startY) / TILE_SIZE

    // Get the current player position
    for i := 0; i < ROWS; i += 1 {
        for j := 0; j < COLS; j += 1 {
            if object_layer[i][j] == 4 {
                player_row = cast(i32)i
                player_col = cast(i32)j
            }
        }
    }

    // Ensure the clicked position is within grid bounds
    if col >= 0 && col < COLS && row >= 0 && row < ROWS {
        if rl.IsMouseButtonDown(.LEFT) {
            door_is_near := (abs(player_row - row) <= 1 && abs(player_col - col) <= 1)
            
            if object_layer[row][col] == 5 && door_is_near && player_has_key {
                object_layer[row][col] = 0
                fmt.printf("You used the key to open the door!\n")
            } else if object_layer[row][col] == 5 {
                fmt.printf("The door is too far away or you don't have the key!\n")
            }
        } else if rl.IsMouseButtonDown(.RIGHT) {
            key_is_near := (abs(player_row - row) <= 1 && abs(player_col - col) <= 1)
            
            if object_layer[row][col] == 6 && key_is_near {
                player_has_key = true
                object_layer[row][col] = 0
                fmt.printf("You picked up a key!\n")
            } else if object_layer[row][col] == 6 {
                fmt.printf("The key is too far away!\n")
            }
        }
    }
}

deep_copy_array :: proc(src: [ROWS][COLS]int) -> [ROWS][COLS]int {
    dst: [ROWS][COLS]int
    for i: int = 0; i < ROWS; i+=1 {
        for j: int = 0; j < COLS; j+=1 {
            dst[i][j] = src[i][j]
        }
    }
    return dst
}

sokoban_interactions :: proc() {
    /*
    game_action : GameAction = {
        deep_copy_array(object_layer),
        player_row,
        player_col
    }
    append(&game_state_stack, game_action)
*/  
    // Get the current player position
    for i := 0; i < ROWS; i += 1 {
        for j := 0; j < COLS; j += 1 {
            if object_layer[i][j] == 4 {
                player_pos = rl.Vector2{cast(f32)i, cast(f32)j}
                player_row = cast(i32)i
                player_col = cast(i32)j
            }
        }
    }

    // Player Movement
    if rl.IsKeyPressed(.W) || rl.IsKeyPressed(.UP) {
        if player_row > 0 && (object_layer[player_row-1][player_col] == 0 || 
            (object_layer[player_row-1][player_col] == 8 && object_layer[player_row-2][player_col] == 0)) {
            // Move crate up
                if object_layer[player_row-1][player_col] == 8 {
                object_layer[player_row-2][player_col] = 8
                object_layer[player_row-1][player_col] = 0
            }
            object_layer[player_row][player_col] = 0
            object_layer[player_row-1][player_col] = 4
            player_row -= 1
        }
    } else if rl.IsKeyPressed(.S) || rl.IsKeyPressed(.DOWN) {
        if player_row < ROWS-1 && (object_layer[player_row+1][player_col] == 0 || 
            (object_layer[player_row+1][player_col] == 8 && object_layer[player_row+2][player_col] == 0)) {
            // Move crate down
            if object_layer[player_row+1][player_col] == 8 {
                object_layer[player_row+2][player_col] = 8
                object_layer[player_row+1][player_col] = 0
            }
            object_layer[player_row][player_col] = 0
            object_layer[player_row+1][player_col] = 4
            player_row += 1
        }
    } else if rl.IsKeyPressed(.A) || rl.IsKeyPressed(.LEFT) {
        if player_col > 0 && (object_layer[player_row][player_col-1] == 0 || 
            (object_layer[player_row][player_col-1] == 8 && object_layer[player_row][player_col-2] == 0)) {
            // Move crate left
            if object_layer[player_row][player_col-1] == 8 {
                object_layer[player_row][player_col-2] = 8
                object_layer[player_row][player_col-1] = 0
            }
            object_layer[player_row][player_col] = 0
            object_layer[player_row][player_col-1] = 4
            player_col -= 1
        }
    } else if rl.IsKeyPressed(.D) || rl.IsKeyPressed(.RIGHT) {
        if player_col < COLS-1 && (object_layer[player_row][player_col+1] == 0 || 
            (object_layer[player_row][player_col+1] == 8 && object_layer[player_row][player_col+2] == 0)) {
            // Move crate right
            if object_layer[player_row][player_col+1] == 8 {
                object_layer[player_row][player_col+2] = 8
                object_layer[player_row][player_col+1] = 0
            }
            object_layer[player_row][player_col] = 0
            object_layer[player_row][player_col+1] = 4
            player_col += 1
        }
    }

    // Check if all crates are on the dots
    sokoban_completed := true
    for i := 0; i < ROWS; i += 1 {
        for j := 0; j < COLS; j += 1 {
            if floor_layer[i][j] == 7 && object_layer[i][j] != 8 { 
                sokoban_completed = false
            }
        }
    }

    if sokoban_completed {
        fmt.printf("Sokoban puzzle completed! You win!\n")
        current_state = .COMPLETED
    }
}


/*
=================================
            BASIC 
=================================
*/

init :: proc() {
    sprites = {
        .NONE = {},
        .PLAYER = {rl.LoadTexture("assets/textures/player.png")},
        .WALL = {rl.LoadTexture("assets/textures/wall.png")},
        .DOOR = {rl.LoadTexture("assets/textures/door.png")},
        .KEY = {rl.LoadTexture("assets/textures/key.png")},
        .CRATE = {rl.LoadTexture("assets/textures/crate.png")},
        .DOT = {rl.LoadTexture("assets/textures/dot.png")},
    }
    current_state = .MAIN
    player_has_key = false
}

deinit :: proc() {
    rl.UnloadTexture(sprites[.PLAYER].texture)
    rl.UnloadTexture(sprites[.WALL].texture)
    rl.UnloadTexture(sprites[.DOOR].texture)
    rl.UnloadTexture(sprites[.KEY].texture)
}

draw :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(gal.set_color("black"))
    defer rl.EndDrawing()

    text := rl.TextFormat("Level %d", level_index)

    switch current_state {
        case .GAME:
            rl.BeginMode2D(camera)
            defer rl.EndMode2D()
            rl.DrawText(text, screen_width/2 - 600, screen_height/2 - 300, 50, rl.RAYWHITE)
            draw_layer(floor_layer)
            draw_layer(object_layer)
            draw_objects()

        case .MAIN:
            gal.draw_title_screen("Sokoban Demo!", 130)
            startbtn_rect := gal.make_rectangle(screen_width/2 - 100, screen_height/2 - 100, 200, 100)
            startbtn := gal.make_textbutton("START", startbtn_rect, gray, white, white,  
            {screen_width/2 - 85, screen_height/2 - 80}, 50)

            if gal.draw_button(startbtn) {
                current_state = .GAME
                level_index = 1
                init_level(cast(i32)level_index)
            }

            controlbtn_rect := gal.make_rectangle(screen_width/2 - 100, screen_height/2 + 50, 200, 100)
            controlbtn := gal.make_textbutton("CONTROLS", controlbtn_rect, gray, white, white,
            {screen_width/2 - 95, screen_height/2 + 80}, 35)

            if gal.draw_button(controlbtn) {
                current_state = .BASIC
            }

        case .COMPLETED:
            rl.DrawText("Level Complete!", screen_width / 2 - 150, screen_height / 2 - 100, 40, rl.GREEN)
            rl.DrawText("Press Enter to Continue", screen_width / 2 - 200, screen_height / 2, 30, rl.GRAY)

        case .WON:
            rl.DrawText("YOU WON THE GAME!", screen_width / 2 - 200, screen_height / 2 - 50, 50, rl.GREEN)
            rl.DrawText("Press Enter to Return to the Main Menu", screen_width / 2 - 250, screen_height / 2 + 50, 30, rl.GRAY)
        
        case .BASIC:
            returnbtn_rect := gal.make_rectangle(screen_width/2 - 600, screen_height/2 - 350, 50, 50)
            returnbtn := gal.make_textbutton("<-", returnbtn_rect, gray, white, white,
            {screen_width/2 - 590, screen_height/2 - 340}, 35)

            if gal.draw_button(returnbtn) {
                current_state = .MAIN
            }
            rl.DrawText("Controls", screen_width/2 - 200, screen_height/2 - 300, 75, white) 
            rl.DrawText("W - Move Up", screen_width/2 - 400, screen_height/2 - 200, 50, white) 
            rl.DrawText("A - Move Left", screen_width/2 - 400, screen_height/2 - 150, 50, white) 
            rl.DrawText("S - Move Down", screen_width/2 - 400, screen_height/2 - 100, 50, white) 
            rl.DrawText("D - Move Right", screen_width/2 - 400 , screen_height/2 - 50, 50, white) 
            rl.DrawText("Left Mouse Button - Interact with Door", screen_width/2 - 400, screen_height/2, 50, white) 
            rl.DrawText("Right Mouse Button - Pick up Item", screen_width/2 - 400, screen_height/2 + 50, 50, white) 
    }
}

update :: proc() {
    #partial switch current_state {
        case .GAME:        
            sokoban_interactions()
            mouse_interactions()

            /*
            if rl.IsKeyPressed(.Z) {
                undo_last_move()
            }
            */
            // Get mouse scroll movement
            mouse_scroll_value = rl.GetMouseWheelMove()

            if mouse_scroll_value != 0 {
                fmt.printf("Mouse scrolled: %f\n", mouse_scroll_value)
                camera.zoom += mouse_scroll_value * 0.1
                if camera.zoom < 0.5 {
                    camera.zoom = 0.5
                } else if camera.zoom > 1.5 {
                    camera.zoom = 1.5
                }
            }

            if sokoban_completed() {
                player_has_key = false
                current_state = .COMPLETED
            }

        case .COMPLETED:
            if rl.IsKeyPressed(.ENTER) {
                if level_index < 6 {
                    level_index += 1
                    init_level(cast(i32)level_index)
                    current_state = .GAME
                } else {
                    current_state = .WON 
                }
            }

        case .WON:
            if rl.IsKeyPressed(.ENTER) {
                current_state = .MAIN
            }
    }
}

main :: proc()
{
    when ODIN_DEBUG 
    {
        tracking_allocator: mem.Tracking_Allocator
        mem.tracking_allocator_init(&tracking_allocator, context.allocator)
        context.allocator = mem.tracking_allocator(&tracking_allocator)

        defer for _, entry in tracking_allocator.allocation_map 
        {
            fmt.printf("%v Tracking_Allocator: Memory leak\n", entry.location)
        }

        defer for entry in tracking_allocator.bad_free_array 
        {
            fmt.printf("%v Tracking_Allocator: Bad Free\n", entry.location)
        }
    }

    rl.InitWindow(screen_width, screen_height, title)
    rl.SetTargetFPS(60)  
    defer rl.CloseWindow()

    logo := rl.LoadImage("assets/logo.png")
    if logo.data != nil 
    {
        rl.SetWindowIcon(logo)
        defer rl.UnloadImage(logo)
    }
    
    init()
    init_camera()
    defer deinit()

    for !rl.WindowShouldClose() 
    {
        update()
        update_camera()
        draw()
    }
}