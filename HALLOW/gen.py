#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    answers = []
    while position + 1 < len(tokens):
        child_count = tokens[position]
        neighbour_count = tokens[position + 1]
        position += 2
        if child_count == 0 and neighbour_count == 0:
            break
        sweets = tokens[position:position + neighbour_count]
        position += neighbour_count
        prefix = [0]
        for value in sweets:
            prefix.append(prefix[-1] + value)
        chosen = None
        for end in range(1, neighbour_count + 1):
            for start in range(end):
                if (prefix[end] - prefix[start]) % child_count == 0:
                    chosen = list(range(start + 1, end + 1))
                    break
            if chosen:
                break
        if chosen:
            answers.append(" ".join(str(index) for index in chosen))
        else:
            answers.append("no sweets")
    return "\n".join(answers) + "\n"


SAMPLE = """4 5
1 2 3 7 5
3 6
7 11 2 5 13 17
0 0
"""
assert oracle(SAMPLE) == "2 3 4\n1 2\n"
assert oracle("1 3\n2 4 6\n0 0\n") == "1\n"
assert oracle("3 3\n1 1 1\n0 0\n") == "1 2 3\n"
assert oracle("4 5\n1 2 3 7 5\n0 0\n") == "2 3 4\n"


def write(name, cases):
    text = ""
    for child_count, sweets in cases:
        text += f"{child_count} {len(sweets)}\n"
        text += " ".join(str(value) for value in sweets) + "\n"
    text += "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [(1, [2, 4, 6]), (3, [1, 1, 1]), (5, [1, 2, 3, 7, 5])])
    write("3_wide", [(child_count, [rng.randint(1, 100000) for _ in range(child_count)])
                     for child_count in range(1, 101)])
    write("4_random", [(rng.randint(2, 60), [rng.randint(1, 100000) for _ in range(rng.randint(2, 200))])
                       for _ in range(30)])
    big_size = 100000
    big_text = f"{big_size} {big_size}\n" + " ".join(["1"] * big_size) + "\n0 0\n"
    (ROOT / "in" / "5_io.txt").write_text(big_text)
    (ROOT / "out" / "5_io.out").write_text(" ".join(str(index) for index in range(1, big_size + 1)) + "\n")
    assert sum([1] * big_size) % big_size == 0


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(4, [1, 2, 3, 7, 5]), (3, [7, 11, 2, 5, 13, 17])])
build()
