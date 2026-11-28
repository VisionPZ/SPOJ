#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    position = 1
    answers = []
    for _ in range(case_count):
        person_count = tokens[position]
        position += 1
        targets = [value - 1 for value in tokens[position:position + person_count]]
        position += person_count
        best = person_count
        for mask in range(1 << person_count):
            if all((mask >> person) & 1 or (mask >> targets[person]) & 1
                   for person in range(person_count)):
                size = mask.bit_count()
                if size < best:
                    best = size
        answers.append(str(best))
    return "\n".join(answers) + "\n"


def cycle_answer(cycle_length):
    return (cycle_length + 1) // 2


def cycle_case(cycle_length):
    text = f"1\n{cycle_length}\n"
    text += "".join(f"{index + 1}\n" for index in range(1, cycle_length))
    text += "1\n"
    return text


SAMPLE = """1
3
2
3
1
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 2 1 1\n".replace(" ", "\n")) == "1\n"
assert oracle("1 3 1 1 1\n".replace(" ", "\n")) == "1\n"
assert oracle(cycle_case(4)) == "2\n"
assert oracle(cycle_case(5)) == "3\n"
assert cycle_answer(4) == 2 and cycle_answer(5) == 3


def write(name, lengths):
    text = str(len(lengths)) + "\n"
    for cycle_length in lengths:
        text += f"{cycle_length}\n"
        text += "".join(f"{index + 1}\n" for index in range(1, cycle_length))
        text += "1\n"
    answers = [str(cycle_answer(length)) for length in lengths]
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


def write_small(name, graphs):
    blocks = []
    for targets in graphs:
        blocks.append(str(len(targets)) + "\n" + "".join(f"{target + 1}\n" for target in targets))
    text = str(len(blocks)) + "\n" + "".join(blocks)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write_small("2_edges", [[1, 1], [0, 0, 0], [1, 2, 0], [2, 2, 2, 2],
                            [1, 0, 3, 3, 0], [0, 2, 1, 0, 4, 5]])
    write("3_wide", [1000, 9999, 100000])
    write_small("4_random", [[rng.randrange(size) for _ in range(size)] for size in (8, 10, 12)])
    write("5_io", [100000, 99999, 100000, 99999, 100000, 100000, 99999, 100000, 99999, 100000])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [3])
build()
