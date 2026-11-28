#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_LENGTH = 8
MAX_VALUE = 32000


def exact_tables(digit):
    tables = [set() for _ in range(MAX_LENGTH)]
    repdigit = 0
    for length in range(1, MAX_LENGTH + 1):
        repdigit = repdigit * 10 + digit
        tables[length - 1].add(repdigit)
    for length in range(2, MAX_LENGTH + 1):
        target = tables[length - 1]
        for left in range(1, length):
            right = length - left
            for first in tables[left - 1]:
                for second in tables[right - 1]:
                    target.add(first + second)
                    target.add(first - second)
                    target.add(first * second)
                    if second != 0 and first % second == 0:
                        target.add(first // second)
    return tables


TABLES = {digit: exact_tables(digit) for digit in range(1, 10)}


def min_length(digit, value):
    tables = TABLES[digit]
    for length in range(1, MAX_LENGTH + 1):
        if value in tables[length - 1]:
            return length
    return 0


@lru_cache(maxsize=None)
def tree_values(digit, lengths):
    if len(lengths) == 1:
        value = 0
        for _ in range(lengths[0]):
            value = value * 10 + digit
        return frozenset([value])
    result = set()
    for split in range(1, len(lengths)):
        for first in tree_values(digit, lengths[:split]):
            for second in tree_values(digit, lengths[split:]):
                result.add(first + second)
                result.add(first - second)
                result.add(first * second)
                if second != 0 and first % second == 0:
                    result.add(first // second)
    return frozenset(result)


def compositions(length):
    yield (length,)
    if length == 1:
        return
    for first in range(1, length):
        for rest in compositions(length - first):
            yield (first,) + rest


def brute_tables(digit, limit):
    tables = [set() for _ in range(limit)]
    for length in range(1, limit + 1):
        for shape in compositions(length):
            tables[length - 1].update(tree_values(digit, shape))
    return tables


for digit in range(1, 10):
    brute = brute_tables(digit, 4)
    for length in range(1, 5):
        assert brute[length - 1] == TABLES[digit][length - 1], (digit, length)

assert min_length(5, 12) == 4
assert min_length(5, 55) == 2
assert min_length(5, 31168) == 0
assert min_length(1, 10) == 3
assert min_length(1, 11) == 2
assert min_length(9, 7) == 4


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        digit = int(tokens[cursor])
        cursor += 1
        number_count = int(tokens[cursor])
        cursor += 1
        for _ in range(number_count):
            value = int(tokens[cursor])
            cursor += 1
            length = min_length(digit, value)
            answers.append(str(length) if length else "NO")
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "1\n5\n2\n12\n31168\n"
assert oracle(SAMPLE_INPUT) == "4\nNO\n"


def write(name, cases):
    blocks = []
    for digit, values in cases:
        block = [str(digit), str(len(values))]
        block.extend(str(value) for value in values)
        blocks.append("\n".join(block))
    input_text = str(len(cases)) + "\n\n".join([""] + blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, [1]),
        (1, [32000]),
        (5, [5, 55, 555, 12, 31168]),
        (9, [1, 2, 3, 7, 99]),
        (2, [2, 22, 222, 2222]),
        (3, [32000, 31999, 1, 1111]),
        (8, [8, 88, 888, 8888]),
    ])
    wide = []
    for digit in range(1, 10):
        wide.append((digit, list(range(1, 11))))
        wide.append((digit, list(range(31991, 32001))))
    write("3_wide", wide)

    random.seed(2026)
    random_cases = []
    for _ in range(60):
        digit = random.randint(1, 9)
        values = [random.randint(1, MAX_VALUE) for _ in range(10)]
        random_cases.append((digit, values))
    write("4_random", random_cases)

    io_cases = []
    for case_index in range(20000):
        digit = case_index % 9 + 1
        values = [random.randint(1, MAX_VALUE) for _ in range(10)]
        io_cases.append((digit, values))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE_INPUT))
build()
