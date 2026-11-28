#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_sg(board_length):
    cell_index = lambda row, col: row * board_length + col
    placements = []
    for col in range(board_length - 1):
        for omitted in range(4):
            block = [(0, col), (1, col), (0, col + 1), (1, col + 1)]
            placements.append(sum(1 << cell_index(*cell)
                                  for position, cell in enumerate(block)
                                  if position != omitted))

    @lru_cache(None)
    def grundy(mask):
        seen = set()
        for placement in placements:
            if not (mask & placement):
                seen.add(grundy(mask | placement))
        value = 0
        while value in seen:
            value += 1
        return value

    return grundy(0)


def table_sg(limit):
    empty_run = [0] * (limit + 1)
    one_end = [0] * (limit + 1)
    two_end = [0] * (limit + 1)

    def mex(seen):
        value = 0
        while value in seen:
            value += 1
        return value

    for length in range(1, limit + 1):
        seen = set()
        if length >= 2:
            for left in range(length - 1):
                right = length - left - 2
                seen.add(empty_run[left] ^ one_end[right])
                seen.add(one_end[left] ^ empty_run[right])
        empty_run[length] = mex(seen)

        seen = {empty_run[length - 1]}
        for left in range(length - 1):
            right = length - left - 2
            seen.add(one_end[left] ^ one_end[right])
            seen.add(two_end[left] ^ empty_run[right])
        one_end[length] = mex(seen)

        seen = {one_end[length - 1]}
        for left in range(length - 1):
            right = length - left - 2
            seen.add(one_end[left] ^ two_end[right])
            seen.add(two_end[left] ^ one_end[right])
        two_end[length] = mex(seen)

    return empty_run


TABLE = table_sg(800)
for length in range(0, 11):
    assert brute_sg(length) == TABLE[length]
assert TABLE[0] == 0
assert TABLE[1] == 0
assert TABLE[2] == 1


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for index in range(count):
        length = int(tokens[1 + index])
        value = brute_sg(length) if length <= 10 else TABLE[length]
        answers.append("X" if value else "Y")
    return "\n".join(answers) + "\n"


SAMPLE_IN = "2\n3\n4\n"
SAMPLE_OUT = "X\nY\n"
assert oracle(SAMPLE_IN) == SAMPLE_OUT


def write(name, lengths):
    text = str(len(lengths)) + "\n" + "".join(str(length) + "\n" for length in lengths)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    write("3_wide", [800, 799, 700, 600, 500, 400, 300, 200, 100, 50, 25])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 40) for _ in range(50)])
    write("5_io", [rng.randint(1, 12) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
