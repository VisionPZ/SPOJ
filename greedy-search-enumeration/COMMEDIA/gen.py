#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOLVABLE = "Puzzle can be solved."
UNSOLVABLE = "Puzzle is unsolvable."


def oracle_case(side, tiles):
    slot_count = side ** 3
    blank_index = tiles.index(0)
    sequence = [slot_count if value == 0 else value for value in tiles]
    inversions = 0
    for left in range(slot_count):
        for right in range(left + 1, slot_count):
            if sequence[left] > sequence[right]:
                inversions += 1
    parity = inversions & 1
    x = blank_index % side
    y = (blank_index // side) % side
    z = blank_index // (side * side)
    blank_parity = (x + y + z) & 1
    solved_parity = (3 * (side - 1)) & 1
    return SOLVABLE if (parity + blank_parity) & 1 == solved_parity else UNSOLVABLE


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        side = int(tokens[cursor]); cursor += 1
        tiles = [int(value) for value in tokens[cursor:cursor + side ** 3]]
        cursor += side ** 3
        answers.append(oracle_case(side, tiles))
    return "\n".join(answers) + "\n"


def format_case(side, tiles):
    rows = []
    for layer in range(side):
        start = layer * side * side
        rows.append(" ".join(str(value) for value in
                             tiles[start:start + side * side]))
    return str(side) + "\n" + "\n".join(rows) + "\n"


def solved_tiles(side):
    return list(range(1, side ** 3)) + [0]


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE_IN = """2
2
1 2 3 4
5 7 6 0
2
2 1 3 5
4 6 0 7
"""
assert oracle(SAMPLE_IN) == UNSOLVABLE + "\n" + SOLVABLE + "\n"


def build():
    random.seed(314159)
    edge = []
    edge.append(solved_tiles(1))
    edge.append(solved_tiles(2))
    swapped = solved_tiles(3)
    swapped[0], swapped[1] = swapped[1], swapped[0]
    edge.append(swapped)
    cyclic = solved_tiles(3)
    cyclic[0], cyclic[1], cyclic[2] = cyclic[1], cyclic[2], cyclic[0]
    edge.append(cyclic)
    write("2_edges", str(len(edge)) + "\n" +
          "".join(format_case(side, tiles) for side, tiles in
                  [(1, edge[0]), (2, edge[1]), (3, edge[2]), (3, edge[3])]))

    wide = []
    for side in (7, 8, 9, 10):
        tiles = solved_tiles(side)
        random.shuffle(tiles)
        wide.append((side, tiles))
    write("3_wide", str(len(wide)) + "\n" +
          "".join(format_case(side, tiles) for side, tiles in wide))

    random_cases = []
    for _ in range(16):
        side = random.randint(2, 5)
        tiles = solved_tiles(side)
        random.shuffle(tiles)
        random_cases.append((side, tiles))
    write("4_random", str(len(random_cases)) + "\n" +
          "".join(format_case(side, tiles) for side, tiles in random_cases))

    io_cases = []
    for _ in range(250):
        side = 3
        tiles = solved_tiles(side)
        random.shuffle(tiles)
        io_cases.append((side, tiles))
    write("5_io", str(len(io_cases)) + "\n" +
          "".join(format_case(side, tiles) for side, tiles in io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
