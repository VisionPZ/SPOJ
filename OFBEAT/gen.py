#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def polygon_vertices(lengths):
    def walk(first_vertical):
        x = y = 0
        points = [(0, 0)]
        for i, step in enumerate(lengths):
            vertical = ((i % 2) == 0) == first_vertical
            if vertical:
                y += step
            else:
                x += step
            points.append((x, y))
        return points
    pts = walk(True)
    area = 0
    for i in range(len(pts) - 1):
        x1, y1 = pts[i]
        x2, y2 = pts[i + 1]
        area += x1 * y2 - x2 * y1
    return pts if area < 0 else walk(False)


def rasterize(pts):
    raw_x = sorted({p[0] for p in pts})
    raw_y = sorted({p[1] for p in pts})
    xs = [raw_x[0] - 1] + raw_x + [raw_x[-1] + 1]
    ys = [raw_y[0] - 1] + raw_y + [raw_y[-1] + 1]
    cells = set()
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            px = (xs[i] + xs[i + 1]) / 2
            py = (ys[j] + ys[j + 1]) / 2
            inside = False
            for k in range(len(pts) - 1):
                x1, y1 = pts[k]
                x2, y2 = pts[k + 1]
                if (y1 > py) != (y2 > py):
                    cross = (x2 - x1) * (py - y1) / (y2 - y1) + x1
                    if px < cross:
                        inside = not inside
            if inside:
                cells.add((i, j))
    return cells, xs, ys


def maximal_segments(cells, xs, ys):
    vertical = []
    for k in range(1, len(xs) - 1):
        spans = []
        for i, j in cells:
            if i == k - 1 or i == k:
                spans.append((j, j + 1))
        if not spans:
            continue
        spans.sort()
        lo, hi = spans[0]
        merged = []
        for a, b in spans[1:]:
            if a <= hi:
                hi = max(hi, b)
            else:
                merged.append((lo, hi))
                lo, hi = a, b
        merged.append((lo, hi))
        for a, b in merged:
            vertical.append((xs[k], ys[a], ys[b]))
    horizontal = []
    for j in range(1, len(ys) - 1):
        spans = []
        for i, cell_j in cells:
            if cell_j == j - 1 or cell_j == j:
                spans.append((i, i + 1))
        if not spans:
            continue
        spans.sort()
        lo, hi = spans[0]
        merged = []
        for a, b in spans[1:]:
            if a <= hi:
                hi = max(hi, b)
            else:
                merged.append((lo, hi))
                lo, hi = a, b
        merged.append((lo, hi))
        for a, b in merged:
            horizontal.append((ys[j], xs[a], xs[b]))
    return vertical, horizontal


ANSWER_CACHE = {}


def brute_answer(lengths):
    key = tuple(lengths)
    if key in ANSWER_CACHE:
        return ANSWER_CACHE[key]
    pts = polygon_vertices(lengths)
    cells, xs, ys = rasterize(pts)
    vsegs, hsegs = maximal_segments(cells, xs, ys)
    segs = [('V',) + s for s in vsegs] + [('H',) + s for s in hsegs]
    n = len(segs)
    close = [0] * n
    for i in range(n):
        for j in range(i + 1, n):
            if segs[i][0] == segs[j][0]:
                continue
            if segs[i][0] == 'V':
                vx, lo, hi = segs[i][1:]
                hy, hl, hr = segs[j][1:]
            else:
                vx, lo, hi = segs[j][1:]
                hy, hl, hr = segs[i][1:]
            if hl <= vx <= hr and lo <= hy <= hi:
                close[i] |= 1 << j
                close[j] |= 1 << i
    full = (1 << n) - 1
    degree = [bin(close[i] | (1 << i)).count("1") for i in range(n)]

    def covers(chosen):
        c = 0
        for i in range(n):
            if chosen >> i & 1 or (close[i] & chosen):
                c |= 1 << i
        return c

    for target in range(1, n + 1):
        found = [False]

        def dfs(chosen, count, start):
            if found[0]:
                return
            if count == target:
                if covers(chosen) == full:
                    if all(close[i] & chosen for i in range(n) if chosen >> i & 1):
                        found[0] = True
                return
            need = target - count
            if bin(full & ~covers(chosen)).count("1") > need * max(degree):
                return
            for i in range(start, n):
                if chosen >> i & 1:
                    continue
                dfs(chosen | (1 << i), count + 1, i + 1)
                if found[0]:
                    return
        dfs(0, 0, 0)
        if found[0]:
            ANSWER_CACHE[key] = target
            return target
    return None


def oracle(text):
    tokens = text.split()
    pos = 0
    cases = int(tokens[pos]); pos += 1
    answers = []
    for _ in range(cases):
        count = int(tokens[pos]); pos += 1
        lengths = [int(tokens[pos + k]) for k in range(count)]
        pos += count
        answers.append(str(brute_answer(lengths)))
    return "\n".join(answers) + "\n"


def cells_to_lengths(cells):
    sides = set()
    for x, y in cells:
        if (x, y - 1) not in cells:
            sides.add(((x + 1, y), (x, y)))
        if (x, y + 1) not in cells:
            sides.add(((x, y + 1), (x + 1, y + 1)))
        if (x - 1, y) not in cells:
            sides.add(((x, y), (x, y + 1)))
        if (x + 1, y) not in cells:
            sides.add(((x + 1, y + 1), (x + 1, y)))
    adjacency = {}
    for start, end in sides:
        adjacency.setdefault(start, []).append(end)
    start = min(adjacency)
    cycle = [start]
    prev = None
    cur = start
    for _ in range(len(sides) + 1):
        nxts = adjacency[cur]
        nxt = nxts[0] if len(nxts) == 1 else next((v for v in nxts if v != prev), nxts[0])
        if nxt == start:
            break
        cycle.append(nxt)
        prev, cur = cur, nxt
    else:
        return None
    edges = []
    for i in range(len(cycle)):
        x1, y1 = cycle[i]
        x2, y2 = cycle[(i + 1) % len(cycle)]
        dx = x2 - x1
        dy = y2 - y1
        assert dx == 0 or dy == 0
        magnitude = abs(dx) + abs(dy)
        positive = dy > 0 or dx > 0
        edges.append((0 if dx == 0 else 1, magnitude if positive else -magnitude))
    merged = []
    for axis, amount in edges:
        if merged and merged[-1][0] == axis:
            merged[-1] = (axis, merged[-1][1] + amount)
        else:
            merged.append((axis, amount))
    if len(merged) > 1 and merged[0][0] == merged[-1][0]:
        combined = (merged[0][0], merged[0][1] + merged[-1][1])
        merged = [combined] + merged[1:-1]
    return [amount for axis, amount in merged]


def random_cells(size, rng, fill=0.62):
    for _ in range(200):
        cells = {(x, y) for x in range(size) for y in range(size) if rng.random() < fill}
        if not cells:
            continue
        seen = {next(iter(cells))}
        stack = list(seen)
        while stack:
            x, y = stack.pop()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q in cells and q not in seen:
                    seen.add(q)
                    stack.append(q)
        if len(seen) != len(cells):
            continue
        outer = {(x, y) for x in range(-1, size + 1) for y in range(-1, size + 1)
                 if (x, y) not in cells}
        reached = {(-1, -1)}
        stack = [(-1, -1)]
        while stack:
            x, y = stack.pop()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + dx, y + dy)
                if q in outer and q not in reached:
                    reached.add(q)
                    stack.append(q)
        if any(c not in reached for c in outer
               if 0 <= c[0] < size and 0 <= c[1] < size):
            continue
        pinched = False
        for x in range(size + 1):
            for y in range(size + 1):
                sw = (x - 1, y - 1) in cells
                se = (x, y - 1) in cells
                nw = (x - 1, y) in cells
                ne = (x, y) in cells
                if (sw and ne and not se and not nw) or (se and nw and not sw and not ne):
                    pinched = True
        if pinched:
            continue
        if cells_to_lengths(cells) is None:
            continue
        return cells
    return None


def rotate_start(lengths, shift):
    return lengths[shift:] + lengths[:shift]


def make_case(cells, scale=1, shift=0):
    lengths = cells_to_lengths(cells)
    return [v * scale for v in rotate_start(lengths, shift)]


def write(name, cases):
    lines = [str(len(cases))]
    for lengths in cases:
        lines.append(str(len(lengths)))
        lines.append(" ".join(str(v) for v in lengths))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


SAMPLE = [2, 2, 2, 2, -4, 2, 1, 2, -3, 2, -2, -8, 4, -2]
assert brute_answer(SAMPLE) == 4
assert brute_answer([1, 1, -1, -1]) == 2
assert brute_answer([2, 1, -1, 1, -1, -2]) == 2


def build():
    cells = {(0, 0)}
    edges = [(2, 2, -2, -2),
             (3, 2, -1, 1, -2, -3),
             (2, 3, -3, 1, 1, -2, -1),
             (1, 1, -1, -1)]
    write("2_edges", [[2, 2, -2, -2],
                      [1, 1, -1, -1],
                      [2, 1, -1, 1, -1, -2],
                      [3, 3, -1, -2, -1, 2, -1, -3],
                      [100000, 100000, -100000, -100000],
                      [-1, -1, 1, 1],
                      [1, -1, -1, 1],
                      rotate_start([3, 3, -1, -2, -1, 2, -1, -3], 1),
                      rotate_start([3, 3, -1, -2, -1, 2, -1, -3], 3)])
    write("3_wide", [[100000, 100000, -100000, -100000],
                     [50000, 50000, -50000, -50000],
                     [30000, 20000, -10000, 10000, -20000, -10000,
                      10000, -10000, -10000, -10000],
                     [70000, 70000, -70000, -70000]])
    rng = random.Random(2026)
    random_cases = []
    for _ in range(120):
        cc = random_cells(3, rng)
        if cc:
            random_cases.append(make_case(cc, shift=rng.choice([0, 0, 0, 1, 3])))
    for _ in range(20):
        cc = random_cells(4, rng)
        if cc:
            random_cases.append(make_case(cc, shift=rng.choice([0, 0, 1, 3])))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20000):
        side = rng.randint(1, 2)
        cc = random_cells(side, rng)
        if cc:
            io_cases.append(make_case(cc, shift=rng.choice([0, 0, 1])))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
SAMPLE_TEXT = ("1\n14\n"
               "+2 +2 +2 +2 -4 +2 +1 +2 -3 +2 -2 -8 +4 -2\n")
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_TEXT))
build()
