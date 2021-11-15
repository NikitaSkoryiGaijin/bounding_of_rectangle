require daslib/media
require math
require random

require utils
require room

struct Pickup
    pos: float2
    rad: float
    qdel: bool
    hp: float
    hpmax: float
    atkcd: float
    atkdmg: float

var pickups: array<Pickup?>
var private _removeQueue: array<Pickup?>
var fake: Pickup? = new Pickup

def pickups_init()
    for p in pickups
        pickups_remove(p)
    _pickups_destroy()


def pickups_new(pos: float2)
    var p: Pickup? = new Pickup
    p.pos = pos
    p.rad = float(tileSize) * 0.25
    p.qdel = false
    p.atkcd = 1.0
    p.atkdmg = 1.0
    if random_float(seed) < 0.33
        p.hp = 50.0
    elif random_float(seed) < 0.5
        p.hpmax = 25.0
    elif random_float(seed) < 0.75
        p.atkcd = 0.9
    else
        p.atkdmg = 1.25

    pickups |> push(p)


def pickups_remove(var p: Pickup?)
    p.qdel = true
    _removeQueue |> push(p)


def private _pickups_destroy()
    for p in _removeQueue
        let index: int = pickups |> find_index(p)
        // если индекс не был найден, возвращает 4294967295. Костыльная, но быстрая проверка.
        if index < MAX_INT
            pickups |> erase(index)
    _removeQueue |> clear()


def pickups_collision(pos: float2; rad: float): Pickup?
    for p in pickups
        if circle_vs_circle(p.pos, p.rad, pos, rad) < 0.0
            pickups_remove(p)
            return p
    return fake


def pickups_update(dt: float)
    if events["enteredRoom"]
        pickups_init()
    if events["roomCleared"]
        if random_float(seed) < 0.75
            for i in range(0, 2)
                for i in range(0, 4)
                    var a: float = float(i) * PI * 0.5
                    var d: float = float(i * tileSize)
                    var pos: float2 = roomCenter + float2(cos(a) * d, sin(a) * d)
                    if !room_get_tile(pos).solid
                        pickups_new(pos)
                        break

    _pickups_destroy()


def pickups_draw()
    for p in pickups
        fill_circle(p.pos.x, p.pos.y, p.rad, 0xA541C4)
