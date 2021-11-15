require daslib/media
require math
require random

require utils
require room
require player
require projectiles

struct Enemy
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
    atkrange: float
    qdel: bool

var enemies: array<Enemy?>
var removeQueue: array<Enemy?>
var enemiesKilled: int

def enemies_init()
    for e in enemies
        enemies_remove(e)
    _enemies_destroy()

    enemiesKilled = 0

    enemies_spawn()


def enemies_new(pos: float2)
    var e: Enemy? = new Enemy
    e.id = string(timePassed) + string(random_float(seed))
    e.pos = pos
    e.ang = 0.0
    e.vel = float2(0.0, 0.0)
    e.spd = 120.0 + float(enemiesKilled) * 1.0
    e.rad = 24.0
    e.hpmax = 20.0 + float(enemiesKilled) * 5.0
    e.hp = e.hpmax
    e.atkcd = 0.0
    e.atkrate = 1.0 * (1.0 - float(enemiesKilled) * 0.05)
    e.atkdmg = 10.0
    e.atkrange = 240.0
    e.qdel = false
    enemies |> push(e)


def enemies_remove(var e: Enemy?)
    e.qdel = true
    removeQueue |> push(e)


def private _enemies_destroy()
    for e in removeQueue
        let index: int = enemies |> find_index(e)
        enemies |> erase(index)
        enemiesKilled++
        if length(enemies) == 0
            events["roomCleared"] = true
            room_completed()
    removeQueue |> clear()


def enemies_collision(var pos: float2; rad: float; id: string): float2
    for e in enemies
        if !(id == e.id)
            let d:float = dist(pos, e.pos) - rad - e.rad
            if d < 0.0
                let a:float = angle(pos, e.pos)
                pos.x -= cos(a) * abs(d) * 0.5
                pos.y -= sin(a) * abs(d) * 0.5
                e.pos.x += cos(a) * abs(d) * 0.5
                e.pos.y += sin(a) * abs(d) * 0.5
    return pos


def enemies_spawn()
    for i in range(0, roomSizeX)
        for j in range(0, roomSizeY)
            if room.tileMap[i][j].id == 4
                enemies_new(float2(i * tileSize + int(float(tileSize) * 0.5), j * tileSize + int(float(tileSize) * 0.5)))


def enemies_update(dt: float)
    if events["enteredRoom"]
        enemies_spawn()

    for e in enemies
        var d: float = dist(e.pos, player.pos)
        e.ang = angle(e.pos, player.pos)
        
        if d > e.rad + player.rad
            e.vel = float2(cos(e.ang), sin(e.ang)) * e.spd * dt
            e.pos += e.vel
            e.pos = enemies_collision(e.pos, e.rad, e.id)
            e.pos = room_collision(e.pos, e.rad)

        if e.atkcd <= 0.0
            if d <= e.atkrange
                projectiles_new(e.pos, e.ang, 480.0, e.atkdmg, "enemy")
                e.atkcd += e.atkrate
        else
            e.atkcd -= dt

        let dmg: float = projectiles_collision(e.pos, e.rad, e.hp, "enemy")
        e.hp -= dmg
        if e.hp <= 0.0
            enemies_remove(e)

        

    _enemies_destroy()


def enemies_draw()
    for e in enemies
        fill_circle(e.pos.x, e.pos.y, e.rad, 0xDD2211)

def enemies_draw_hp()
    for e in enemies
        fill_rect(e.pos.x - e.rad, e.pos.y - e.rad * 1.5, e.rad * 2.0, e.rad * 0.25, 0xFF0000)
        fill_rect(e.pos.x - e.rad, e.pos.y - e.rad * 1.5, e.rad * 2.0 * (e.hp / e.hpmax), e.rad * 0.25, 0x00FF00)
