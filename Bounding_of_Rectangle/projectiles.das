require daslib/media
require math

require utils
require room

struct Projectile
    pos: float2
    ang: float
    vel: float2
    spd: float
    rad: float
    mask: string
    dmg: float
    qdel: bool

var projectiles: array<Projectile?>
var private _removeQueue: array<Projectile?>


def projectiles_init()
    for p in projectiles
        projectiles_remove(p)
    _projectiles_destroy()


def projectiles_new(pos: float2; ang: float; spd: float; dmg: float; mask: string)
    var p: Projectile? = new Projectile
    p.pos = pos
    p.ang = ang
    p.spd = spd
    p.vel = float2(cos(ang), sin(ang))
    p.rad = 8.0
    p.mask = mask
    p.dmg = dmg
    p.qdel = false
    projectiles |> push(p)


def projectiles_remove(var p: Projectile?)
    p.qdel = true
    _removeQueue |> push(p)


def private _projectiles_destroy()
    for p in _removeQueue
        let index: int = projectiles |> find_index(p)
        // если индекс не был найден, возвращает 4294967295. Костыльная, но быстрая проверка.
        if index < MAX_INT
            projectiles |> erase(index)
    _removeQueue |> clear()


def projectiles_collision(pos: float2; radius: float; health: float; mask: string): float
    var dmg: float = 0.0
    for p in projectiles
        if !p.qdel && !(p.mask == mask) && circle_vs_circle(p.pos, p.rad, pos, radius) < 0.0
            dmg += p.dmg
            projectiles_remove(p)
            if dmg >= health
                break
    return dmg


def projectiles_update(dt: float)
    if events["enteredRoom"]
        projectiles_init()

    for p in projectiles
        p.pos += p.vel * p.spd * dt
        if room_get_tile(p.pos).id == 1
            projectiles_remove(p)

    _projectiles_destroy()


def projectiles_draw()
    for p in projectiles
        fill_circle(p.pos.x, p.pos.y, p.rad, 0xFFFFFF)
