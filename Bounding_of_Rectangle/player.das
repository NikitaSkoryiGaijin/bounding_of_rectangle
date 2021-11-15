require daslib/media
require math

require utils
require room
require projectiles
require pickups

struct Player
    id: string
    pos: float2
    ang: float
    vel: float2
    spd: float
    rad: float
    hp: float
    hpmax: float
    atkcd: float
    atkrate: float
    atkdmg: float
    clr: uint

var player: Player? = new Player


def player_init()
    player.id = "player"
    player.pos = float2(roomHSizeX * tileSize + tileHSize, tileSize + tileHSize)
    player.ang = 0.0
    player.vel = float2(0.0, 0.0)
    player.spd = 200.0
    player.rad = 24.0
    player.hpmax = 100.0
    player.hp = player.hpmax
    player.atkcd = 0.0
    player.atkrate = 0.4
    player.atkdmg = 10.0
    player.clr = 0xFFFFFF


def player_update(dt: float)
    var v: float2
    if get_key(VK_W)
        v.y -= 1.0
    if get_key(VK_A)
        v.x -= 1.0
    if get_key(VK_S)
        v.y += 1.0
    if get_key(VK_D)
        v.x += 1.0
    player.vel = normalize(v) * player.spd * dt

    player.pos += player.vel
    player.pos = room_collision(player.pos, player.rad)

    if player.atkcd <= 0.0
        if get_mouse_button(MB_LEFT)
            let a = angle(player.pos, get_mouse_position())
            projectiles_new(player.pos, a, 480.0, player.atkdmg, "player")
            player.atkcd += player.atkrate
    else
        player.atkcd -= dt

    let dmg = projectiles_collision(player.pos, player.rad, player.hp, "player")
    player.hp -= dmg
    if player.hp <= 0.0
        events["gameOver"] = true
        return

    let p = pickups_collision(player.pos, player.rad)
    if p.rad > 0.0 // костыль на костыле, но я уже устал
        player.hp += p.hp
        player.hpmax += p.hpmax
        player.atkcd *= p.atkcd
        player.atkdmg *= p.atkdmg

    if room_get_tile(player.pos).id == 3
        var pt: int2 = point_to_tile(player.pos, tileSize)
        let side: int2 = sign(int2(pt.x - roomHSizeX, pt.y - roomHSizeY))
        let x = abs(pt.x - (roomSizeX - 1)) + side.x
        let y = abs(pt.y - (roomSizeY - 1)) + side.y
        player.pos = float2(x * tileSize + tileHSize, y * tileSize + tileHSize)
        room_load(side, int2(x, y))
        events["enteredRoom"] = true
        timeout = 0.5


def player_draw()
    fill_rect(player.pos.x - player.rad, player.pos.y - player.rad,  player.rad * 2.0,  player.rad * 2.0, player.clr)


def player_draw_interface()
    fill_rect(player.pos.x - player.rad, player.pos.y - player.rad * 1.5, player.rad * 2.0, player.rad * 0.25, 0xFF0000)
    fill_rect(player.pos.x - player.rad, player.pos.y - player.rad * 1.5, player.rad * 2.0 * (player.hp / player.hpmax), player.rad * 0.25, 0x00FF00)
