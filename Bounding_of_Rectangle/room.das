require daslib/media
require math
require random

require utils

// "array dimension must be constant"
// let roomSize: int2 = int2(13, 9)
let tileSize: int = SCREEN_HEIGHT / roomSizeY
let tileHSize: int = int(float(tileSize) * 0.5)
let roomSizeX: int = 13
let roomSizeY: int = 9
let roomHSizeX: int = int(float(roomSizeX) * 0.5)
let roomHSizeY: int = int(float(roomSizeY) * 0.5)
let tilesInRoom: int = (roomSizeX - 2) * (roomSizeY - 2) // не считая внешние стены
let roomCenter: float2 = float2(float(roomSizeX * tileSize) * 0.5, float(roomSizeY * tileSize) * 0.5)

struct Tile
    id: int
    solid: bool
    clr: uint = 0x333333

struct Room
    tileMap: Tile[roomSizeX][roomSizeY]

var room: Room? = new Room

var roomsCleared: int

let orthogonal = [[int2[4]
    int2(0, -1);
    int2(-1, 0);
    int2(1, 0);
    int2(0, 1)
]]

let adjacent = [[int3[8]
    int3(0, -1, 0);
    int3(-1, 0, 0);
    int3(1, 0, 1);
    int3(0, 1, 1);
    int3(-1, -1, 0);
    int3(1, -1, 0);
    int3(-1, 1, 0);
    int3(1, 1, 0)
]]


def room_init()
    roomsCleared = 0
    room_generate(int2(0, -1), int2(roomHSizeX, 1))


def room_get_tile(pt: float2): Tile
    let t: int2 = point_to_tile(pt, tileSize)
    return room_get_tile(t)


def room_get_tile(pt: int2): Tile
    if pt.x >= 0 && pt.x < roomSizeX && pt.y >= 0 && pt.y < roomSizeY
        return room.tileMap[pt.x][pt.y]
    return room.tileMap[0][0] // костыль. Потому что var Tile (если дефайнить рядом с room) это const??


//примитивная коллизия, которую я пытался ужать в минимальное количество строк кода (для красоты, хотя наверное оно и не особо красиво)
// P.S: отуствие неявного приведения из int в float еее
def room_collision(var pos: float2; rad: float): float2
    for i in range(0, 4)
        let tile: int2 = point_to_tile(pos, tileSize)
        let t = int2(tile.x + adjacent[i].x, tile.y + adjacent[i].y)
        if t.x >= 0 && t.x < roomSizeX && t.y >= 0 && t.y < roomSizeY
            if room_get_tile(t).solid && rectangle_vs_rectangle(float2(t * tileSize), float2(t * tileSize + int2(tileSize)), pos - float2(rad), pos + float2(rad))
                pos.x = adjacent[i].x == 0 ? pos.x : float((tile.x + adjacent[i].z) * tileSize) - rad * float(adjacent[i].x)
                pos.y = adjacent[i].y == 0 ? pos.y : float((tile.y + adjacent[i].z) * tileSize) - rad * float(adjacent[i].y)

    for i in range(4, 8)
        let tile: int2 = point_to_tile(pos, tileSize)
        let t = int2(tile.x + adjacent[i].x, tile.y + adjacent[i].y)
        if t.x >= 0 && t.x < roomSizeX && t.y >= 0 && t.y < roomSizeY
            if room_get_tile(t).solid
                var c: float2 // corner
                c.x = (float(tile.x) + 0.5) * float(tileSize) + float(tileSize * adjacent[i].x) * 0.5
                c.y = (float(tile.y) + 0.5) * float(tileSize) + float(tileSize * adjacent[i].y) * 0.5
                let a: float = angle(c, pos)
                let d: float = rad - dist(c, pos)
                if d > 0.0
                    pos.x += cos(a) * d
                    pos.y += sin(a) * d

    return pos


def room_completed()
    roomsCleared++
    for i in range(0, 4)
        let x = roomHSizeX + orthogonal[i].x * roomHSizeX
        let y = roomHSizeY + orthogonal[i].y * roomHSizeY
        if room.tileMap[x][y].id == 3
            room.tileMap[x][y].solid = false


def room_load(from: int2; pos: int2)
    room_generate(from, pos)


def room_generate(from: int2; pos: int2)
    // очистить комнату для генерации новой
    for i in range(0, roomSizeX)
        for j in range(0, roomSizeY)
            room.tileMap[i][j].id = 0
            room.tileMap[i][j].solid = false
            room.tileMap[i][j].clr = 0x333333

    // внешние стены
    for i in range(0, roomSizeX)
        room.tileMap[i][0].id = 1
        room.tileMap[i][0].solid = true
        room.tileMap[i][roomSizeY-1].id = 1
        room.tileMap[i][roomSizeY-1].solid = true
    for j in range(0, roomSizeY)
        room.tileMap[0][j].id = 1
        room.tileMap[0][j].solid = true
        room.tileMap[roomSizeX-1][j].id = 1
        room.tileMap[roomSizeX-1][j].solid = true

    // тайлы - камни
    let rocks: int = int(random_float(seed) * float(tilesInRoom) * 0.2)
    for i in range(0, rocks)
        let rx = 1 + int(random_float(seed) * float(roomSizeX - 2))
        let ry = 1 + int(random_float(seed) * float(roomSizeY - 2))
        room.tileMap[rx][ry].id = 1
        room.tileMap[rx][ry].solid = true
        room.tileMap[rx][ry].clr = 0x666666

    // тайлы на которых заспавнятся враги
    let enemies: int = 1 + int(float(roomsCleared) * 0.5) + int(random_float(seed) * float(roomsCleared) * 0.5)
    for i in range(0, enemies)
        let rx = 2 + int(random_float(seed) * float(roomSizeX - 3))
        let ry = 2 + int(random_float(seed) * float(roomSizeY - 3))
        room.tileMap[rx][ry].id = 4
        room.tileMap[rx][ry].solid = false
        room.tileMap[rx][ry].clr = 0x333333

    // двери-переходы должны задаваться гарантированно помимо двери из которой пришел
    var doors: int = 0
    var fromadj: int
    for i in range(0, 4)
        if random_float(seed) < 0.33
            let x = roomHSizeX + orthogonal[i].x * roomHSizeX
            let y = roomHSizeY + orthogonal[i].y * roomHSizeY
            room.tileMap[x][y].id = 3
            room.tileMap[x][y].solid = true
            room.tileMap[x][y].clr = 0xFFFF00
            room.tileMap[x-orthogonal[i].x][y-orthogonal[i].y].id = 0
            room.tileMap[x-orthogonal[i].x][y-orthogonal[i].y].solid = false
            room.tileMap[x-orthogonal[i].x][y-orthogonal[i].y].clr = 0x333333
            doors ++
    if doors == 0
        if from.x == -1 && from.y == 0
            let x = roomHSizeX + orthogonal[2].x * roomHSizeX
            let y = roomHSizeY + orthogonal[2].y * roomHSizeY
            room.tileMap[x][y].id = 3
            room.tileMap[x][y].solid = true
            room.tileMap[x][y].clr = 0xFFFF00
            room.tileMap[x-1][y].id = 0
            room.tileMap[x-1][y].solid = false
            room.tileMap[x-1][y].clr = 0x333333
        else
            let x = roomHSizeX + orthogonal[1].x * roomHSizeX
            let y = roomHSizeY + orthogonal[1].y * roomHSizeY
            room.tileMap[x][y].id = 3
            room.tileMap[x][y].solid = true
            room.tileMap[x][y].clr = 0xFFFF00
            room.tileMap[x+1][y].id = 0
            room.tileMap[x+1][y].solid = false
            room.tileMap[x+1][y].clr = 0x333333
    // откуда пришли
    let x = roomHSizeX - from.x * roomHSizeX
    let y = roomHSizeY - from.y * roomHSizeY
    room.tileMap[x][y].id = 3
    room.tileMap[x][y].solid = true
    room.tileMap[x][y].clr = 0xFFFF00

    // тайл игрока должен быть пустым
    room.tileMap[pos.x][pos.y].id = 0
    room.tileMap[pos.x][pos.y].solid = false
    room.tileMap[pos.x][pos.y].clr = 0x333333
    

def room_draw()
    for i in range(0, roomSizeX)
        for j in range(0, roomSizeY)
            if room.tileMap[i][j].solid
                fill_rect(i * tileSize, j * tileSize, tileSize, tileSize, room.tileMap[i][j].clr)
            else
                rect(i * tileSize, j * tileSize, tileSize, tileSize, room.tileMap[i][j].clr)
