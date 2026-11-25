#!/usr/bin/env python3
import random
from itertools import permutations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def matching_oracle(blocks):
    answers = []
    for initial, final in blocks:
        size = len(initial)
        adjacency = []
        for left in range(size):
            row = []
            for right in range(size):
                target = final[right]
                complement = "".join("0" if bit == "1" else "1" for bit in target)
                if initial[left] == target or initial[left] == complement:
                    row.append(right)
            adjacency.append(row)
        match_right = [-1] * size

        def augment(left, seen):
            for right in adjacency[left]:
                if seen[right]:
                    continue
                seen[right] = True
                if match_right[right] == -1 or augment(match_right[right], seen):
                    match_right[right] = left
                    return True
            return False

        possible = True
        for left in range(size):
            if not augment(left, [False] * size):
                possible = False
                break
        answers.append("YES" if possible else "NO")
    return "\n".join(answers) + "\n"


def brute_oracle(blocks):
    answers = []
    for initial, final in blocks:
        size = len(initial)
        possible = False
        for order in permutations(range(size)):
            if all(initial[column] == final[order[column]] or
                   initial[column] == "".join("0" if bit == "1" else "1" for bit in final[order[column]])
                   for column in range(size)):
                possible = True
                break
        answers.append("YES" if possible else "NO")
    return "\n".join(answers) + "\n"


def oracle(text):
    words = text.split()
    cursor = 0
    block_count = int(words[cursor])
    cursor += 1
    blocks = []
    for _ in range(block_count):
        rows = int(words[cursor])
        columns = int(words[cursor + 1])
        cursor += 2
        grids = []
        for _ in range(2):
            grid = [words[cursor + row * columns + column] for row in range(rows)
                    for column in range(columns)]
            cursor += rows * columns
            signatures = []
            for column in range(columns):
                signature = "".join("1" if grid[row * columns + column] == "BLUE" else "0"
                                    for row in range(rows))
                signatures.append(signature)
            grids.append(signatures)
        blocks.append((grids[0], grids[1]))
    return matching_oracle(blocks)


SAMPLE = """2
3 4
BLUE RED BLUE RED
RED BLUE BLUE RED
BLUE BLUE BLUE BLUE

BLUE RED BLUE RED
RED RED BLUE BLUE
BLUE BLUE BLUE BLUE
2 2
BLUE BLUE
BLUE RED

RED RED
RED RED
"""
SAMPLE_OUT = """YES
NO
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_oracle([(["0"], ["0"])]) == "YES\n"
assert brute_oracle([(["0"], ["1"])]) == "YES\n"
assert brute_oracle([(["00", "01"], ["00", "00"])]) == "NO\n"
assert brute_oracle([(["01", "10"], ["10", "01"])]) == "YES\n"
rng_check = random.Random(19)
for _ in range(120):
    rows = rng_check.randint(1, 4)
    columns = rng_check.randint(1, 5)
    initial = ["".join(rng_check.choice("01") for _ in range(rows)) for _ in range(columns)]
    final = list(initial)
    rng_check.shuffle(final)
    for column in final:
        if rng_check.random() < 0.5:
            final[final.index(column)] = "".join("0" if bit == "1" else "1" for bit in column)
    blocks = [(initial, final)]
    assert matching_oracle(blocks) == brute_oracle(blocks)


def render(blocks):
    lines = [str(len(blocks))]
    for initial_grid, final_grid in blocks:
        rows = len(initial_grid)
        columns = len(initial_grid[0])
        lines.append(f"{rows} {columns}")
        for grid in (initial_grid, final_grid):
            for row in range(rows):
                lines.append(" ".join("BLUE" if grid[row][column] == "1" else "RED"
                                      for column in range(columns)))
            if grid is initial_grid:
                lines.append("")
    return "\n".join(lines) + "\n"


def write_case(name, blocks):
    text = render(blocks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_grid(rows, columns, rng):
    return [["1" if rng.random() < 0.5 else "0" for _ in range(columns)] for _ in range(rows)]


def build():
    write_case("2_edges", [
        ([["1"]], [["1"]]),
        ([["1"]], [["0"]]),
        ([["1", "0"], ["0", "1"]], [["0", "1"], ["1", "0"]]),
        ([["1", "1"], ["1", "0"]], [["0", "0"], ["0", "0"]]),
    ])
    rng = random.Random(20261126)
    wide = random_grid(100, 100, rng)
    transformed = [list(column) for column in zip(*wide)]
    rng.shuffle(transformed)
    final_grid = [list(row) for row in zip(*transformed)]
    write_case("3_wide", [(wide, final_grid)])
    random_blocks = []
    for _ in range(20):
        rows = rng.randint(1, 8)
        columns = rng.randint(1, 8)
        initial = random_grid(rows, columns, rng)
        final = random_grid(rows, columns, rng)
        random_blocks.append((initial, final))
    write_case("4_random", random_blocks)
    io_blocks = []
    for _ in range(100):
        initial = random_grid(100, 100, rng)
        final = random_grid(100, 100, rng)
        io_blocks.append((initial, final))
    write_case("5_io", io_blocks)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
