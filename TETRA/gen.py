import math
import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)


def oracle(edges):
    """Place W at the origin, X on the x axis, Y in the xy plane, then solve Z.
    Volume comes from the triple product, area from cross products."""
    wx, wy, wz, xy, xz, yz = [float(e) for e in edges]
    if wx == 0.0:
        return "0.0000"
    foot_yx = (wx * wx + wy * wy - xy * xy) / (2.0 * wx)
    foot_yy_sq = max(0.0, wy * wy - foot_yx * foot_yx)
    foot_yy = math.sqrt(foot_yy_sq)
    if foot_yy == 0.0:
        return "0.0000"
    foot_zx = (wx * wx + wz * wz - xz * xz) / (2.0 * wx)
    foot_zy = (wz * wz - yz * yz - 2.0 * foot_zx * foot_yx + wy * wy) / (2.0 * foot_yy)
    height_z = math.sqrt(max(0.0, wz * wz - foot_zx * foot_zx - foot_zy * foot_zy))
    volume = abs(wx * foot_yy * height_z) / 6.0

    def cross_area(a, b, c):
        ux, uy, uz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
        vx, vy, vz = c[0] - a[0], c[1] - a[1], c[2] - a[2]
        return 0.5 * math.sqrt((uy * vz - uz * vy) ** 2 +
                              (uz * vx - ux * vz) ** 2 +
                              (ux * vy - uy * vx) ** 2)

    origin = (0.0, 0.0, 0.0)
    point_x = (wx, 0.0, 0.0)
    point_y = (foot_yx, foot_yy, 0.0)
    point_z = (foot_zx, foot_zy, height_z)
    surface = (cross_area(origin, point_x, point_y) + cross_area(origin, point_x, point_z) +
               cross_area(origin, point_y, point_z) + cross_area(point_x, point_y, point_z))
    return "%.4f" % (3.0 * volume / surface if surface > 0 else 0.0)


def write(name, cases):
    open("in/%s.txt" % name, "w").write(
        "%d\n%s\n" % (len(cases), "\n".join(" ".join(str(e) for e in c) for c in cases)))
    open("out/%s.out" % name, "w").write("".join(oracle(c) + "\n" for c in cases))


assert round(3.0 * math.sqrt(2.0) / 12.0 / math.sqrt(3.0), 4) == 0.2041

sample = [(1, 1, 1, 1, 1, 1), (1000, 999, 998, 5, 5, 6)]
write("1_sample", sample)

edges = [(1, 1, 1, 1, 1, 1), (2, 2, 2, 2, 2, 2), (1, 1, 1, 1, 1, 2),
         (1000, 1000, 1000, 1, 1, 1), (3, 4, 5, 4, 5, 6), (7, 7, 7, 7, 7, 7),
         (1, 2, 3, 4, 5, 6), (1000, 999, 998, 5, 5, 6), (2, 3, 4, 5, 6, 7),
         (10, 10, 10, 10, 10, 10), (1, 1, 1, 1, 1, 1), (999, 999, 999, 999, 999, 999)]
write("2_edges", edges)

rng = random.Random(3)


def valid(rng):
    while True:
        edges = [rng.randint(2, 1000) for _ in range(6)]
        wx, wy, wz, xy, xz, yz = edges
        ok = True
        for triple in [(wx, wy, xy), (wx, wz, xz), (wy, wz, yz), (xy, xz, yz)]:
            a, b, c = triple
            if a + b <= c or a + c <= b or b + c <= a:
                ok = False
        if ok:
            return edges


wide = [(1, 1, 1, 1, 1, 1), (1000, 999, 998, 5, 5, 6)] + [valid(rng) for _ in range(28)]
write("3_wide", wide)

cases = [valid(random.Random(100 + i)) for i in range(30)] + [valid(rng) for _ in range(30)]
write("4_random", cases)

io_cases = [valid(random.Random(2000 + i)) for i in range(20000)]
write("5_io", io_cases)
