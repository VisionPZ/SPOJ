#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.rstrip("\n").split("\n")
    cursor = 0
    answers = []
    while cursor < len(lines):
        header = lines[cursor].split()
        cursor += 1
        size = int(header[0])
        turns = int(header[1])
        if size == 0 and turns == 0:
            break
        perm = [int(value) - 1 for value in lines[cursor].split()]
        cursor += 1
        encoded = lines[cursor]
        cursor += 1

        def power_at(start):
            seen = {}
            cycle = []
            current = start
            while current not in seen:
                seen[current] = len(cycle)
                cycle.append(current)
                current = perm[current]
            length = len(cycle)
            entry = seen[current]
            return cycle[entry + (turns - entry) % length]

        original = [""] * size
        for index in range(size):
            original[power_at(index)] = encoded[index]
        answers.append("".join(original))
    return "\n".join(answers) + "\n"


SAMPLE = """5 3
2 3 1 5 4
helol
16 804289384
13 10 2 7 8 1 16 12 15 6 5 14 3 4 11 9
scssoet tcaede n
8 12
5 3 4 2 1 8 6 7
encoded?
0 0
"""
SAMPLE_OUT = """hello
second test case
encoded?
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2 1\n2 1\nba\n0 0\n") == "ab\n"
assert oracle("2 2\n2 1\nba\n0 0\n") == "ba\n"
assert oracle("3 1000000000\n2 3 1\nbca\n0 0\n") == "abc\n"


def write(name, cases):
    chunks = []
    for size, turns, perm, text in cases:
        chunks.append(f"{size} {turns}\n")
        chunks.append(" ".join(str(value) for value in perm) + "\n")
        chunks.append(text + "\n")
    chunks.append("0 0\n")
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, 1, [1], "z"),
        (2, 1, [2, 1], "ba"),
        (2, 1000000000, [2, 1], "ab"),
        (4, 0, [1, 2, 3, 4], "a b "),
    ])
    rng = random.Random(20261126)
    wide_perm = list(range(1, 81))
    rng.shuffle(wide_perm)
    alphabet = "abcdefghijklmnop qrstuvwxyz"
    wide_text = "".join(rng.choice(alphabet) for _ in range(80))
    write("3_wide", [(80, 10 ** 9, wide_perm, wide_text)])
    random_cases = []
    for _ in range(5):
        size = rng.randint(2, 40)
        perm = list(range(1, size + 1))
        rng.shuffle(perm)
        text = "".join(rng.choice(alphabet) for _ in range(size))
        random_cases.append((size, rng.randint(1, 10 ** 9), perm, text))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        size = 80
        perm = list(range(1, size + 1))
        rng.shuffle(perm)
        text = "".join(rng.choice(alphabet) for _ in range(size))
        io_cases.append((size, rng.randint(1, 10 ** 9), perm, text))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
