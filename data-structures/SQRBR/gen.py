#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_expressions(pair_count, fixed_positions):
    from functools import lru_cache
    fixed = set(fixed_positions)
    total_positions = 2 * pair_count

    @lru_cache(maxsize=None)
    def walks(position, balance):
        if position > total_positions:
            return 1 if balance == 0 else 0
        result = 0
        if balance > 0:
            result += walks(position + 1, balance - 1)
        if balance < pair_count:
            result += walks(position + 1, balance + 1)
        if position in fixed:
            return walks(position + 1, balance + 1) if balance < pair_count else 0
        return result

    return walks(1, 0)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        pairs = int(tokens[cursor]); cursor += 1
        fixed = int(tokens[cursor]); cursor += 1
        positions = [int(tokens[cursor + index]) for index in range(fixed)]
        cursor += fixed
        answers.append(str(count_expressions(pairs, positions)))
    return "\n".join(answers) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE_IN = """5
1 1
1
1 1
2
2 1
1
3 1
2
4 2
5 7
"""
SAMPLE_OUT = "1\n0\n2\n3\n2\n"
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert count_expressions(19, list(range(1, 20))) == 1


def build():
    random.seed(1234)
    edges = [
        (1, [1]), (1, [2]), (2, [1]), (2, [2]), (2, [3]),
        (3, [1]), (3, [2]), (3, [3, 5]), (4, [2, 4, 6, 8]),
    ]
    text = str(len(edges)) + "\n" + "".join(
        f"{pairs} {len(positions)}\n" + " ".join(map(str, positions)) + "\n"
        for pairs, positions in edges)
    write("2_edges", text)

    wide = [(19, list(range(1, 20))), (19, list(range(2, 39, 2))),
            (18, [1]), (18, [36])]
    text = str(len(wide)) + "\n" + "".join(
        f"{pairs} {len(positions)}\n" + " ".join(map(str, positions)) + "\n"
        for pairs, positions in wide)
    write("3_wide", text)

    random_cases = []
    for _ in range(40):
        pairs = random.randint(1, 9)
        positions = sorted(random.sample(range(1, 2 * pairs + 1),
                                         random.randint(1, pairs)))
        random_cases.append((pairs, positions))
    text = str(len(random_cases)) + "\n" + "".join(
        f"{pairs} {len(positions)}\n" + " ".join(map(str, positions)) + "\n"
        for pairs, positions in random_cases)
    write("4_random", text)

    io_cases = []
    for _ in range(400):
        pairs = random.randint(1, 9)
        positions = sorted(random.sample(range(1, 2 * pairs + 1),
                                         random.randint(1, pairs)))
        io_cases.append((pairs, positions))
    text = str(len(io_cases)) + "\n" + "".join(
        f"{pairs} {len(positions)}\n" + " ".join(map(str, positions)) + "\n"
        for pairs, positions in io_cases)
    write("5_io", text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
