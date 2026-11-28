#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

DIRECTION = {"N": 0, "E": 1, "S": 2, "W": 3}
STEP_X = [0, 1, 0, -1]
STEP_Y = [1, 0, -1, 0]
TURN_ORDER = (3, 0, 1, 2)


def parse(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(case_count):
        corridor_count = int(tokens[cursor]); cursor += 1
        corridors = []
        for _ in range(corridor_count):
            kind = tokens[cursor]; cursor += 1
            first = int(tokens[cursor]); second = int(tokens[cursor + 1]); third = int(tokens[cursor + 2])
            cursor += 3
            if kind == "H":
                corridors.append(("H", min(second, third), max(second, third), first))
            else:
                corridors.append(("V", first, min(second, third), max(second, third)))
        start_x = int(tokens[cursor]); start_y = int(tokens[cursor + 1])
        direction = tokens[cursor + 2]; cursor += 3
        cases.append((corridors, start_x, start_y, direction))
    return cases


def corridors_at(corridors, pos_x, pos_y):
    result = []
    for index, corridor in enumerate(corridors):
        if corridor[0] == "H":
            _, low, high, fixed = corridor
            if fixed == pos_y and low <= pos_x <= high:
                result.append(index)
        else:
            _, fixed, low, high = corridor
            if fixed == pos_x and low <= pos_y <= high:
                result.append(index)
    return result


def directions_at(corridors, pos_x, pos_y):
    can_go = [False, False, False, False]
    for corridor in corridors:
        if corridor[0] == "H":
            _, low, high, fixed = corridor
            if fixed == pos_y and low <= pos_x <= high:
                if pos_x < high:
                    can_go[1] = True
                if pos_x > low:
                    can_go[3] = True
        else:
            _, fixed, low, high = corridor
            if fixed == pos_x and low <= pos_y <= high:
                if pos_y < high:
                    can_go[0] = True
                if pos_y > low:
                    can_go[2] = True
    return can_go


def oracle_case(corridors, start_x, start_y, letter):
    pos_x, pos_y = start_x, start_y
    heading = DIRECTION[letter]
    visited = set(corridors_at(corridors, pos_x, pos_y))
    steps = 0
    while True:
        can_go = directions_at(corridors, pos_x, pos_y)
        chosen = -1
        for offset in TURN_ORDER:
            candidate = (heading + offset) % 4
            if can_go[candidate]:
                chosen = candidate
                break
        assert chosen != -1, "explorer has no move"
        pos_x += STEP_X[chosen]
        pos_y += STEP_Y[chosen]
        heading = chosen
        visited.update(corridors_at(corridors, pos_x, pos_y))
        steps += 1
        assert steps < 500000, "oracle failed to return"
        if pos_x == start_x and pos_y == start_y:
            break
    return len(corridors) - len(visited)


def oracle(text):
    answers = []
    for corridors, start_x, start_y, letter in parse(text):
        answers.append(str(oracle_case(corridors, start_x, start_y, letter)))
    return "\n".join(answers) + "\n"


SAMPLE = """2
6
H 0 6 0
H 2 1 6
V 1 0 4
V 5 3 0
V 3 0 2
H 1 2 4
6 0 W
1
V 0 -5 5
0 0 S
"""
assert oracle(SAMPLE) == "1\n0\n"

SQUARE = """1
4
H 0 0 10
H 10 0 10
V 0 0 10
V 10 0 10
5 0 W
"""
assert oracle(SQUARE) == "0\n"

TWO_LOOPS = """1
8
H 0 0 10
H 10 0 10
V 0 0 10
V 10 0 10
H 0 20 30
H 10 20 30
V 20 0 10
V 30 0 10
5 0 W
"""
assert oracle(TWO_LOOPS) == "4\n"

SINGLE = """1
1
V 3 -7 9
3 2 N
"""
assert oracle(SINGLE) == "0\n"


def write_text(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def write(name, maps):
    lines = [str(len(maps))]
    for corridors, start in maps:
        lines.append(str(len(corridors)))
        for kind, first, second, third in corridors:
            if kind == "H":
                lines.append(f"H {third} {first} {second}")
            else:
                lines.append(f"V {first} {second} {third}")
        lines.append(f"{start[0]} {start[1]} {start[2]}")
    write_text(name, "\n".join(lines) + "\n")


def make_grid(vertical_xs, horizontal_ys, extent, start):
    corridors = []
    for x_coord in vertical_xs:
        corridors.append(("V", x_coord, -extent, extent))
    for y_coord in horizontal_ys:
        corridors.append(("H", -extent, extent, y_coord))
    return corridors, start


def valid_start(corridors, pos_x, pos_y):
    return len(corridors_at(corridors, pos_x, pos_y)) == 1


def build():
    edges = []
    edges.append(([("V", 0, -3, 5)], (0, 1, "S")))
    edges.append(([("V", 0, -3, 5)], (0, -3, "N")))
    edges.append(([("H", -4, 8, 0)], (8, 0, "W")))
    edges.append(([("H", -4, 8, 0)], (-2, 0, "E")))
    edges.append(([("V", -9, 0, 6), ("V", 9, 0, 6)], (-9, 2, "N")))
    edges.append(([("H", 0, 4, -5), ("H", 0, 4, 5), ("V", 2, -5, 5)], (2, -4, "N")))
    edges.append(([("V", 0, -32767, 32767), ("V", 100, -10, 10)], (0, 12345, "S")))
    write("2_edges", edges)

    wide1 = make_grid([4 * k for k in range(-70, 70)], [4 * k for k in range(-70, 70)], 300, (300, -280, "W"))
    wide2 = make_grid(list(range(-40, 41, 2)), list(range(-60, 61, 2)), 80, (-41, 0, "E"))
    write("3_wide", [wide1, wide2])

    random.seed(3407)
    random_maps = []
    for _ in range(12):
        vertical_xs = random.sample(range(-25, 26), random.randint(1, 7))
        horizontal_ys = random.sample(range(-25, 26), random.randint(1, 7))
        corridors = []
        for x_coord in vertical_xs:
            low = random.randint(-25, 0)
            high = random.randint(1, 25)
            corridors.append(("V", x_coord, low, high))
        for y_coord in horizontal_ys:
            low = random.randint(-25, 0)
            high = random.randint(1, 25)
            corridors.append(("H", low, high, y_coord))
        choices = []
        for corridor in corridors:
            if corridor[0] == "V":
                _, fixed, low, high = corridor
                for y_coord in range(low, high + 1):
                    if valid_start(corridors, fixed, y_coord):
                        choices.append((fixed, y_coord, "N" if y_coord < high else "S"))
            else:
                _, low, high, fixed = corridor
                for x_coord in range(low, high + 1):
                    if valid_start(corridors, x_coord, fixed):
                        choices.append((x_coord, fixed, "E" if x_coord < high else "W"))
        assert choices
        random_maps.append((corridors, random.choice(choices)))
    write("4_random", random_maps)

    io_maps = []
    for case_index in range(20):
        vertical_xs = [x_coord + case_index % 3 for x_coord in range(-30, 31, 6)]
        horizontal_ys = list(range(-24, 25, 6))
        corridors = []
        for x_coord in vertical_xs:
            corridors.append(("V", x_coord, -40 - case_index % 5, 40))
        for y_coord in horizontal_ys:
            corridors.append(("H", -40, 40, y_coord))
        io_maps.append((corridors, (40, -24, "W")))
    write("5_io", io_maps)


def worked_example():
    corridors, start_x, start_y, letter = parse(SAMPLE)[0]
    pos_x, pos_y = start_x, start_y
    heading = DIRECTION[letter]
    visited = set(corridors_at(corridors, pos_x, pos_y))
    turns = []
    while True:
        can_go = directions_at(corridors, pos_x, pos_y)
        chosen = next((heading + offset) % 4 for offset in TURN_ORDER if can_go[(heading + offset) % 4])
        if chosen != heading:
            turns.append((pos_x, pos_y, "NESW"[heading], "NESW"[chosen]))
        pos_x += STEP_X[chosen]
        pos_y += STEP_Y[chosen]
        heading = chosen
        visited.update(corridors_at(corridors, pos_x, pos_y))
        if (pos_x, pos_y) == (start_x, start_y):
            break
    unvisited = sorted(set(range(len(corridors))) - visited)
    return ("sample corridors: 6\n"
            f"visited ids: {sorted(visited)}\n"
            f"unvisited ids: {unvisited}\n"
            f"turn points (x, y, from, to): {turns}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_text("1_sample", SAMPLE)
build()
print(worked_example())
