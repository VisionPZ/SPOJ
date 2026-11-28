#!/usr/bin/env python3
import random
from bisect import bisect_left, bisect_right
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RINK = 10000


class Reference:
    """Independent sweep-line solver, translated from the official OI solution."""

    def __init__(self, start, finish, polygons):
        self.sx, self.sy = start
        self.tx, self.ty = finish
        self.x = {0: start[0]}
        self.y = {0: start[1]}
        self.nxt = {0: 0}
        self.prv = {0: 0}
        self.n = 0
        for poly in polygons:
            r = len(poly)
            x1, y1 = poly[0]
            x2, y2 = poly[1]
            base = self.n
            if x1 != x2:
                self.x[base + 2] = x1
                self.y[base + 2] = y1
                self.x[base + 3] = x2
                self.y[base + 3] = y2
                for j in range(4, r + 1):
                    self.x[base + j] = poly[j - 1][0]
                    self.y[base + j] = poly[j - 1][1]
                self.x[base + 1] = poly[-1][0]
                self.y[base + 1] = poly[-1][1]
            else:
                self.x[base + 1] = x1
                self.y[base + 1] = y1
                self.x[base + 2] = x2
                self.y[base + 2] = y2
                for j in range(3, r + 1):
                    self.x[base + j] = poly[j - 1][0]
                    self.y[base + j] = poly[j - 1][1]
            for j in range(base + 1, base + r):
                self.nxt[j] = j + 1
            self.nxt[base + r] = base + 1
            self.n += r
        for i in range(self.n + 1):
            self.prv[self.nxt[i]] = i
        self.landing = [{}, {}]
        self.seen = {}
        self.q1 = []
        self.q2 = []
        self.depth = 0
        self.answer = None

    def left(self, x1, y1, x2, y2, px, py):
        return (y1 - py) * (x2 - x1) < (y1 - y2) * (px - x1)

    def right_corner(self, vertex, px, py):
        after = self.nxt[vertex]
        before = self.prv[vertex]
        first = (self.x[vertex] == px and self.y[vertex] == py and
                 not self.left(self.x[before], self.y[before], self.x[vertex], self.y[vertex],
                               self.x[after], self.y[after]))
        second = (self.x[after] == px and self.y[after] == py and
                  not self.left(self.x[vertex], self.y[vertex], self.x[after], self.y[after],
                                self.x[self.nxt[after]], self.y[self.nxt[after]]))
        return first or second

    def enqueue(self, direction, vertex):
        if vertex == 0 or self.seen.get(vertex, 65535) <= self.depth + direction:
            return
        self.seen[vertex] = self.depth + direction
        (self.q1 if direction == 1 else self.q2).append(vertex)

    def finish_x(self, direction, state, landing):
        if self.y[state] != self.ty:
            return
        edge_x = self.x[state]
        other_x = self.x[self.nxt[state]]
        if (edge_x > other_x) == direction:
            edge_x = other_x
        if direction:
            if self.tx > edge_x and (landing == 0 or self.tx <= self.x[landing]):
                self.answer = self.depth + 1
        elif self.tx < edge_x and (landing == 0 or self.tx >= self.x[landing]):
            self.answer = self.depth + 1

    def finish_y(self, direction, state, landing):
        if self.x[state] != self.tx:
            return
        edge_y = self.y[state]
        other_y = self.y[self.nxt[state]]
        if (edge_y > other_y) == direction:
            edge_y = other_y
        if direction:
            if self.ty > edge_y and (landing == 0 or self.ty <= self.y[landing]):
                self.answer = self.depth + 1
        elif self.ty < edge_y and (landing == 0 or self.ty >= self.y[landing]):
            self.answer = self.depth + 1

    def route_x(self, direction, state, landing):
        self.finish_x(direction, state, landing)
        if landing == 0 or self.answer is not None:
            return
        self.enqueue(1, landing)
        if self.y[landing] == self.y[state]:
            self.enqueue(1, self.prv[landing])
        elif self.y[self.nxt[landing]] == self.y[state]:
            self.enqueue(1, self.nxt[landing])
        if (self.x[state] < self.x[self.nxt[state]]) == direction:
            self.enqueue(2, self.nxt[state])
        else:
            self.enqueue(2, self.prv[state])

    def route_y(self, direction, state, landing):
        self.finish_y(direction, state, landing)
        if landing == 0 or self.answer is not None:
            return
        self.enqueue(1, landing)
        if self.x[landing] == self.x[state]:
            self.enqueue(1, self.prv[landing])
        elif self.x[self.nxt[landing]] == self.x[state]:
            self.enqueue(1, self.nxt[landing])
        if (self.y[state] > self.y[self.nxt[state]]) == direction:
            self.enqueue(2, self.prv[state])
        else:
            self.enqueue(2, self.nxt[state])

    def sweep(self, vertical):
        active = {}
        keys = []
        starts = {}
        ends = {}
        for q in range(1, self.n + 1):
            if (q % 2 == 1) != vertical:
                continue
            after = self.nxt[q]
            first_coord = self.y[q] if vertical else self.x[q]
            second_coord = self.y[after] if vertical else self.x[after]
            starts.setdefault(min(first_coord, second_coord), []).append(q)
            ends.setdefault(max(first_coord, second_coord), []).append(q)

        def find(pos, direction):
            if direction:
                k = bisect_right(keys, pos)
                return active[keys[k]] if k < len(keys) else 0
            k = bisect_left(keys, pos) - 1
            return active[keys[k]] if k >= 0 else 0

        event_lines = set(starts) | set(ends)
        event_lines.add(self.sy if vertical else self.sx)
        for line in sorted(event_lines):
            for q in starts.get(line, []):
                coord = self.x[q] if vertical else self.y[q]
                active[coord] = q
                keys.append(coord)
                keys.sort()
            if vertical and line == self.sy:
                j = find(self.sx + 1, False)
                if j and self.right_corner(j, self.sx, self.sy):
                    j = find(self.x[j], False)
                if j and self.y[j] < self.y[self.nxt[j]]:
                    j = find(self.x[j], False)
                self.route_x(False, 0, j)
                j = find(self.sx - 1, True)
                if j and self.right_corner(j, self.sx, self.sy):
                    j = find(self.x[j], True)
                if j and self.y[j] > self.y[self.nxt[j]]:
                    j = find(self.x[j], True)
                self.route_x(True, 0, j)
            if (not vertical) and line == self.sx:
                j = find(self.sy + 1, False)
                if j and self.right_corner(j, self.sx, self.sy):
                    j = find(self.y[j], False)
                if j and self.x[j] > self.x[self.nxt[j]]:
                    j = find(self.y[j], False)
                self.route_y(False, 0, j)
                j = find(self.sy - 1, True)
                if j and self.right_corner(j, self.sx, self.sy):
                    j = find(self.y[j], True)
                if j and self.x[j] < self.x[self.nxt[j]]:
                    j = find(self.y[j], True)
                self.route_y(True, 0, j)
            for q in starts.get(line, []) + ends.get(line, []):
                if vertical:
                    if self.y[q] == line:
                        self.landing[1][self.prv[q]] = find(self.x[q], self.y[q] > self.y[self.nxt[q]])
                    else:
                        self.landing[0][self.nxt[q]] = find(self.x[q], self.y[q] > self.y[self.nxt[q]])
                else:
                    if self.x[q] == line:
                        self.landing[1][self.prv[q]] = find(self.y[q], self.x[q] < self.x[self.nxt[q]])
                    else:
                        self.landing[0][self.nxt[q]] = find(self.y[q], self.x[q] < self.x[self.nxt[q]])
            for q in ends.get(line, []):
                coord = self.x[q] if vertical else self.y[q]
                if active.get(coord) == q:
                    del active[coord]
                    keys.remove(coord)
            if self.answer is not None:
                return

    def solve(self):
        self.sweep(True)
        if self.answer is not None:
            return self.answer
        self.sweep(False)
        if self.answer is not None:
            return self.answer
        for i in range(1, self.n + 1):
            if self.left(self.x[self.prv[i]], self.y[self.prv[i]], self.x[i], self.y[i],
                         self.x[self.nxt[i]], self.y[self.nxt[i]]):
                self.landing[1][self.prv[i]] = i
                self.landing[0][i] = self.prv[i]
        while True:
            self.depth += 1
            q0 = self.q1
            self.q1 = self.q2
            self.q2 = []
            for state in q0:
                if state % 2 == 1:
                    self.route_y(self.y[state] > self.y[self.nxt[state]], state, self.landing[0].get(state, 0))
                    self.route_y(self.y[state] < self.y[self.nxt[state]], state, self.landing[1].get(state, 0))
                else:
                    self.route_x(self.x[state] > self.x[self.nxt[state]], state, self.landing[0].get(state, 0))
                    self.route_x(self.x[state] < self.x[self.nxt[state]], state, self.landing[1].get(state, 0))
                if self.answer is not None:
                    return self.answer
            if not self.q1 and not self.q2:
                return None


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    lines = []
    for _ in range(count):
        sx = int(tokens[cursor]); sy = int(tokens[cursor + 1]); cursor += 2
        fx = int(tokens[cursor]); fy = int(tokens[cursor + 1]); cursor += 2
        obstacle_count = int(tokens[cursor])
        cursor += 1
        polygons = []
        for _ in range(obstacle_count):
            r = int(tokens[cursor])
            cursor += 1
            poly = [(int(tokens[cursor + 2 * k]), int(tokens[cursor + 2 * k + 1])) for k in range(r)]
            cursor += 2 * r
            polygons.append(poly)
        answer = Reference((sx, sy), (fx, fy), polygons).solve()
        lines.append("NO" if answer is None else str(answer))
    return "\n".join(lines) + "\n"


def render(cases):
    parts = [str(len(cases))]
    for sx, sy, fx, fy, polys in cases:
        parts.append(f"{sx} {sy}")
        parts.append(f"{fx} {fy}")
        parts.append(str(len(polys)))
        for poly in polys:
            parts.append(str(len(poly)))
            for x, y in poly:
                parts.append(f"{x} {y}")
    return "\n".join(parts) + "\n"


def rectangle(x1, y1, x2, y2):
    return [(x1, y1), (x1, y2), (x2, y2), (x2, y1)]


def lshape(x1, y1, x2, y2, xm, ym):
    return [(x1, y1), (x1, y2), (xm, y2), (xm, ym), (x2, ym), (x2, y1)]


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = """1
40 10
5 40
3
6
0 15
0 60
20 60
20 55
5 55
5 15
12
30 55
30 60
60 60
60 0
0 0
0 5
55 5
55 35
50 35
50 40
55 40
55 55
6
30 25
15 25
15 30
35 30
35 15
30 15
"""
assert oracle(SAMPLE) == "4\n"
assert oracle(render([(0, 0, 5, 0, [])])) == "1\n"
assert oracle(render([(0, 0, 5, 5, [])])) == "NO\n"
assert oracle(render([(40, 10, 5, 40, [
    [(0, 15), (0, 60), (20, 60), (20, 55), (5, 55), (5, 15)],
    [(30, 55), (30, 60), (60, 60), (60, 0), (0, 0), (0, 5), (55, 5), (55, 35),
     (50, 35), (50, 40), (55, 40), (55, 55)],
    [(30, 25), (15, 25), (15, 30), (35, 30), (35, 15), (30, 15)],
    rectangle(33, 33, 34, 44)])])) == "4\n"


def inside(px, py, poly):
    crossings = 0
    count = len(poly)
    for k in range(count):
        x1, y1 = poly[k]
        x2, y2 = poly[(k + 1) % count]
        if x1 == x2 and x1 > px and min(y1, y2) < py < max(y1, y2):
            crossings += 1
    return crossings % 2 == 1


def separated(new_poly, old_polys):
    ax1, ax2 = min(v[0] for v in new_poly), max(v[0] for v in new_poly)
    ay1, ay2 = min(v[1] for v in new_poly), max(v[1] for v in new_poly)
    for poly in old_polys:
        bx1, bx2 = min(v[0] for v in poly), max(v[0] for v in poly)
        by1, by2 = min(v[1] for v in poly), max(v[1] for v in poly)
        if not (ax2 < bx1 - 1 or bx2 < ax1 - 1 or ay2 < by1 - 1 or by2 < ay1 - 1):
            return False
    return True


def random_case(rng, size):
    polys = []
    for _ in range(rng.randint(0, 3)):
        x1 = rng.randint(1, size - 4)
        y1 = rng.randint(1, size - 4)
        x2 = rng.randint(x1 + 2, size - 2)
        y2 = rng.randint(y1 + 2, size - 2)
        if rng.random() < 0.5:
            poly = rectangle(x1, y1, x2, y2)
        else:
            xm = rng.randint(x1 + 1, x2 - 1)
            ym = rng.randint(y1 + 1, y2 - 1)
            poly = lshape(x1, y1, x2, y2, xm, ym)
        if separated(poly, polys):
            polys.append(poly)
    points = []
    while len(points) < 2:
        px = rng.randint(0, size)
        py = rng.randint(0, size)
        if any(inside(px, py, poly) for poly in polys):
            continue
        points.append((px, py))
    return points[0][0], points[0][1], points[1][0], points[1][1], polys


def trace_example():
    walls = []
    for poly in [
        [(0, 15), (0, 60), (20, 60), (20, 55), (5, 55), (5, 15)],
        [(30, 55), (30, 60), (60, 60), (60, 0), (0, 0), (0, 5), (55, 5), (55, 35),
         (50, 35), (50, 40), (55, 40), (55, 55)],
        [(30, 25), (15, 25), (15, 30), (35, 30), (35, 15), (30, 15)],
    ]:
        for k in range(len(poly)):
            a = poly[k]
            b = poly[(k + 1) % len(poly)]
            if a[0] == b[0]:
                walls.append((0 if b[1] > a[1] else 1, a[0], min(a[1], b[1]), max(a[1], b[1])))
            else:
                walls.append((2 if b[0] < a[0] else 3, a[1], min(a[0], b[0]), max(a[0], b[0])))
    start = (40, 10)
    finish = (5, 40)
    queue = [(start, [])]
    seen = {start}
    directions = ((1, 0, "E"), (-1, 0, "W"), (0, 1, "S"), (0, -1, "N"))
    while queue:
        point, path = queue.pop(0)
        for kind, (dx, dy, label) in enumerate(directions):
            first = None
            for wall, coord, low, high in walls:
                if wall != kind:
                    continue
                along = point[1] if dx else point[0]
                if not low <= along <= high:
                    continue
                step = (coord - (point[0] if dx else point[1])) * (dx if dx else dy)
                if step <= 0:
                    continue
                if first is None or step < first:
                    first = step
            to_finish = None
            if dx and point[1] == finish[1]:
                to_finish = (finish[0] - point[0]) * dx
            if dy and point[0] == finish[0]:
                to_finish = (finish[1] - point[1]) * dy
            if to_finish is not None and to_finish > 0 and (first is None or to_finish <= first):
                print(" -> ".join([f"({start[0]},{start[1]})"] + path + [f"{label}({finish[0]},{finish[1]})"]))
                return
            if first is None:
                continue
            nxt = (point[0] + dx * first, point[1] + dy * first)
            if nxt not in seen:
                seen.add(nxt)
                queue.append((nxt, path + [f"{label}({nxt[0]},{nxt[1]})"]))


def example_path():
    trace_example()


def build():
    edges = [
        (0, 0, 5, 0, []),
        (0, 0, 5, 5, []),
        (0, 5, 8, 5, [rectangle(10, 0, 12, 10)]),
        (0, 5, 20, 5, [rectangle(10, 0, 12, 10)]),
        (0, 0, 10000, 10000, [rectangle(100, 100, 200, 200), rectangle(9800, 9800, 9900, 9900)]),
        (5000, 5000, 5001, 5000, []),
    ]
    write("2_edges", edges)

    wide_polys = []
    for k in range(2500):
        x = 4 + k * 3
        wide_polys.append(rectangle(x, 20, x + 1, 21))
    write("3_wide", [(0, 0, 10000, 0, wide_polys), (0, 10000, 10000, 10000, wide_polys)])

    rng = random.Random(2026)
    write("4_random", [random_case(rng, 14) for _ in range(300)])

    io_cases = []
    for k in range(20000):
        x = rng.randint(0, 9990)
        y = rng.randint(0, 9990)
        if k % 3 == 0:
            io_cases.append((x, y, min(10000, x + 5), y, []))
        elif k % 3 == 1:
            io_cases.append((x, y, x, min(10000, y + 5), []))
        else:
            io_cases.append((x, y, min(10000, x + 5), min(10000, y + 5), []))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE))
if __name__ == "__main__" and "--example" in __import__("sys").argv:
    example_path()
else:
    build()
