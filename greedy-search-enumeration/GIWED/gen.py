#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(case_count):
        width = tokens[cursor]
        height = tokens[cursor + 1]
        carpet_count = tokens[cursor + 2]
        pipe_count = tokens[cursor + 3]
        cursor += 4
        blocked = [[False] * height for _ in range(width)]
        for _ in range(carpet_count):
            x1 = tokens[cursor]
            y1 = tokens[cursor + 1]
            x2 = tokens[cursor + 2]
            y2 = tokens[cursor + 3]
            cursor += 4
            for x in range(x1, x2):
                for y in range(y1, y2):
                    blocked[x][y] = True
        visited = [[False] * height for _ in range(width)]
        areas = []
        for start_x in range(width):
            for start_y in range(height):
                if visited[start_x][start_y] or blocked[start_x][start_y]:
                    continue
                visited[start_x][start_y] = True
                pending = [(start_x, start_y)]
                area = 0
                while pending:
                    x, y = pending.pop()
                    area += 1
                    for next_x, next_y in ((x - 1, y), (x + 1, y),
                                           (x, y - 1), (x, y + 1)):
                        if (0 <= next_x < width and 0 <= next_y < height
                                and not visited[next_x][next_y]
                                and not blocked[next_x][next_y]):
                            visited[next_x][next_y] = True
                            pending.append((next_x, next_y))
                areas.append(area)
        areas.sort(reverse=True)
        answers.append(str(sum(areas[:pipe_count])))
    return "\n".join(answers) + "\n"


SAMPLE = """2
10 10 0 1
10 10 1 1
3 3 4 4
"""
SAMPLE_OUT = """100
99
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n3 4 0 1\n") == "12\n"
assert oracle("1\n3 4 1 1\n0 0 3 1\n") == "9\n"
assert oracle("1\n4 4 2 2\n0 0 2 4\n2 0 4 4\n") == "0\n"


def write(name, cases):
    lines = [str(len(cases))]
    for width, height, carpets, pipes in cases:
        lines.append(f"{width} {height} {len(carpets)} {pipes}")
        for carpet in carpets:
            lines.append(" ".join(str(value) for value in carpet))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (3, 4, [], 1),
        (3, 4, [(0, 0, 3, 4)], 1),
        (4, 4, [(0, 0, 2, 4), (2, 0, 4, 4)], 2),
        (6, 6, [(2, 2, 3, 3), (3, 3, 4, 4)], 1),
        (10, 10, [(3, 3, 4, 4)], 5),
    ])

    rng = random.Random(20261126)

    def random_case(width, height, carpet_total, pipe_total):
        carpets = []
        for _ in range(carpet_total):
            x1 = rng.randrange(width - 1)
            y1 = rng.randrange(height - 1)
            x2 = rng.randrange(x1 + 1, width)
            y2 = rng.randrange(y1 + 1, height)
            carpets.append((x1, y1, x2, y2))
        return (width, height, carpets, pipe_total)

    write("3_wide", [random_case(16, 16, 10, 3) for _ in range(4)])
    write("4_random", [random_case(rng.randint(2, 14), rng.randint(2, 14),
                                   rng.randint(0, 8), rng.randint(1, 4))
                       for _ in range(12)])
    write("5_io", [random_case(rng.randint(2, 8), rng.randint(2, 8),
                               rng.randint(0, 5), rng.randint(1, 3))
                   for _ in range(30)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(10, 10, [], 1), (10, 10, [(3, 3, 4, 4)], 1)])
build()
