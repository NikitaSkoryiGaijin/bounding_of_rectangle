require daslib/media
require utils

require utils
require room
require player
require projectiles
require enemies
require pickups

def world_init()
    seed = random_seed(get_time_usec(int64(0)))
    timeout = 1.0

    room_init()
    player_init()
    projectiles_init()
    enemies_init()
    pickups_init()


def world_update(dt: float)
    timePassed += dt
    events |> clear()

    if timeout <= 0.0
        player_update(dt)
        projectiles_update(dt)
        enemies_update(dt)
        pickups_update(dt)
    else
        timeout -= dt

    if events["gameOver"] || get_key_down(VK_R)
        world_init()


def world_draw()
    room_draw()
    pickups_draw()
    projectiles_draw()
    player_draw()
    enemies_draw()

    player_draw_interface()
    enemies_draw_hp()

    text_out(0, 0, "Rooms cleared: " + string(roomsCleared), 0xFFFFFF)
    text_out(0, 16, "Enemies killed: " + string(enemiesKilled), 0xFFFFFF)

    if timeout > 0.0
        enable_alpha_blend()
        set_font_size(tileSize)
        text_out(roomCenter.x - float(tileSize) * 3.0, roomCenter.y - float(tileSize), "GET READY!", 0x44FFFFFF)
        set_font_size(16)
        disable_alpha_blend()
