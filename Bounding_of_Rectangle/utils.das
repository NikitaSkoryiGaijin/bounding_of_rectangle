require daslib/media
require math

let MAX_INT: int = 2147483647
let SCREEN_WIDTH: int = get_screen_width()
let SCREEN_HEIGHT: int = get_screen_height()

var timePassed: float
var seed: int4
var events: table<string; bool>
var timeout: float

def dist(p0: float2; p1: float2): float
    return sqrt(pow(p0.x - p1.x, 2.0) + pow(p0.y - p1.y, 2.0))


def angle(p0: float2; p1: float2): float
    return atan2(p1.y - p0.y, p1.x - p0.x)


def point_to_tile(p: float2; tsize: int): int2
    return int2(int(p.x / float(tsize)), int(p.y / float(tsize)))


def point_vs_rectangle(pt: float2; p0: float2; p1: float2): bool
    if pt.x >= p0.x && pt.x <= p1.x && pt.y >= p0.y && pt.y <= p1.y
        return true
    return false


def circle_vs_circle(c0: float2; r0: float; c1: float2; r1: float): float
    return dist(c0, c1) - r0 - r1


def rectangle_vs_rectangle(p00: float2; p01: float2; p10: float2; p11: float2): bool
    if p00.x > p11.x || p01.x < p10.x
        return false
    if p00.y > p11.y || p01.y < p10.y
        return false
    return true


// def circle_vs_rectangle(c: float2; r: float; p0: float2; p1: float2)
