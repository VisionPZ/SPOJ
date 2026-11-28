#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def segment_set(rect):
    x1, y1, x2, y2 = rect
    parts = set()
    for y in range(y1, y2 + 1):
        for x in range(x1, x2):
            parts.add((0, x, y))
    for x in range(x1, x2 + 1):
        for y in range(y1, y2):
            parts.add((1, x, y))
    return parts


def brute_connected(left, right):
    return not segment_set(left).isdisjoint(segment_set(right))


def oracle_connected(left, right):
    xlo = max(left[0], right[0])
    xhi = min(left[2], right[2])
    ylo = max(left[1], right[1])
    yhi = min(left[3], right[3])
    if xlo > xhi or ylo > yhi:
        return False
    return (xhi - xlo + 1) * (yhi - ylo + 1) >= 2


def count_components(rects):
    total = len(rects)
    seen = [False] * total
    components = 0
    for start in range(total):
        if seen[start]:
            continue
        components += 1
        seen[start] = True
        stack = [start]
        while stack:
            current = stack.pop()
            base = rects[current]
            for other in range(total):
                if not seen[other] and oracle_connected(base, rects[other]):
                    seen[other] = True
                    stack.append(other)
    return components


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_total = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_total):
        rect_total = int(tokens[cursor]); cursor += 1
        rects = []
        for _ in range(rect_total):
            rect = tuple(int(tokens[cursor + offset]) for offset in range(4))
            cursor += 4
            rects.append(rect)
        answers.append(str(count_components(rects)))
    return "\n".join(answers) + "\n"


def cases_text(cases):
    parts = [str(len(cases))]
    for rects in cases:
        parts.append(str(len(rects)))
        for rect in rects:
            parts.append(" ".join(map(str, rect)))
    return "\n".join(parts) + "\n"


def write(name, cases):
    input_text = cases_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    (0, 3, 2, 6), (4, 5, 5, 7), (4, 2, 6, 4), (2, 0, 3, 2),
    (5, 3, 6, 4), (3, 2, 5, 3), (1, 4, 4, 7), (0, 0, 1, 4),
    (0, 0, 4, 1),
]
assert oracle(cases_text([SAMPLE])) == "2\n"
assert oracle(cases_text([[(0, 0, 3, 3), (1, 1, 2, 2)]])) == "1\n"
assert oracle(cases_text([[(0, 0, 1, 1), (1, 1, 2, 2)]])) == "2\n"
assert oracle(cases_text([[(0, 0, 1, 1), (1, 0, 2, 1)]])) == "1\n"
assert count_components([(0, 0, 1, 1)]) == 1

random.seed(37)
for _ in range(3000):
    left = tuple(random.randrange(6) for _ in range(4))
    right = tuple(random.randrange(6) for _ in range(4))
    if left[0] > left[2]: left = (left[2], left[1], left[0], left[3])
    if left[1] > left[3]: left = (left[0], left[3], left[2], left[1])
    if right[0] > right[2]: right = (right[2], right[1], right[0], right[3])
    if right[1] > right[3]: right = (right[0], right[3], right[2], right[1])
    assert brute_connected(left, right) == oracle_connected(left, right)


def build():
    edges = [
        [(0, 0, 1, 1)],
        [(0, 0, 3, 3), (1, 1, 2, 2)],
        [(0, 0, 1, 1), (1, 1, 2, 2)],
        [(0, 0, 1, 1), (1, 0, 2, 1)],
        [(0, 0, 1, 1), (0, 1, 1, 2)],
        [(0, 0, 1, 1), (5, 5, 6, 6)],
        [(0, 0, 2, 2), (0, 0, 2, 2)],
        [(9998, 9998, 10000, 10000), (9999, 9997, 10000, 9999)],
        [(0, 0, 1, 1), (1, 0, 2, 1), (1, 1, 2, 2), (2, 0, 3, 1)],
        [(0, 0, 2, 2), (3, 0, 4, 1), (0, 3, 1, 4)],
    ]
    write("2_edges", edges)

    dense = [(0, 0, 10000, 10000)] * 7000
    sparse = []
    for i in range(2000):
        x = (i % 100) * 100
        y = (i // 100) * 500
        sparse.append((x, y, x + 1, y + 1))
    write("3_wide", [dense, sparse])

    random.seed(188)
    general = []
    for _ in range(20):
        amount = random.randint(1, 250)
        spread = random.choice([12, 40, 300, 10000])
        rects = []
        for _ in range(amount):
            x1 = random.randint(0, 10000 - spread)
            y1 = random.randint(0, 10000 - spread)
            x2 = min(10000, x1 + random.randint(1, spread))
            y2 = min(10000, y1 + random.randint(1, spread))
            rects.append((x1, y1, x2, y2))
        general.append(rects)
    write("4_random", general)

    heavy = []
    for i in range(100000):
        if i % 3 == 0:
            heavy.append([(0, 0, 2, 2)])
        elif i % 3 == 1:
            heavy.append([(0, 0, 1, 1), (1, 0, 2, 1)])
        else:
            heavy.append([(0, 0, 1, 1), (5, 5, 6, 6)])
    write("5_io", heavy)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
