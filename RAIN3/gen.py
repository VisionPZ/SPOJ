#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def sequence(initial_state, initial_other, count):
    state = initial_state
    other = initial_other
    values = []
    for _ in range(count):
        state = (78901 + 31 * state) % 699037
        other = (23456 + 64 * other) % 2097151
        values.append((state % 100 + 1) * (other % 100 + 1))
    return values


def oracle(text):
    tokens = text.split()
    block_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(block_count):
        initial_state = int(tokens[cursor])
        initial_other = int(tokens[cursor + 1])
        day_count = int(tokens[cursor + 2])
        allowed_sum = int(tokens[cursor + 3])
        cursor += 4
        values = sequence(initial_state, initial_other, day_count)
        prefix = [0]
        for value in values:
            prefix.append(prefix[-1] + value)

        def can_stay(length):
            if length == 0:
                return True
            for start in range(day_count - length + 1):
                if prefix[start + length] - prefix[start] > allowed_sum:
                    return False
            return True

        low = 0
        high = day_count
        longest = 0
        while low <= high:
            middle = (low + high) // 2
            if can_stay(middle):
                longest = middle
                low = middle + 1
            else:
                high = middle - 1
        answers.append(str(longest))
    return "\n".join(answers) + "\n"


SAMPLE = """1
123456 123456 10 10000
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert sequence(123456, 123456, 10) == [4664, 1248, 267, 4900, 837, 4048, 990, 6935, 1155, 490]
assert oracle("1\n123456 123456 10 8000\n") == "1\n"
assert oracle("1\n123456 123456 10 0\n") == "0\n"
assert oracle("1\n123456 123456 10 100000\n") == "10\n"


def write(name, blocks):
    lines = [str(len(blocks))]
    for initial_state, initial_other, day_count, allowed_sum in blocks:
        lines.append(f"{initial_state} {initial_other} {day_count} {allowed_sum}")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (0, 0, 1, 0),
        (0, 0, 1, 100000),
        (699036, 2097150, 2, 1),
        (123456, 123456, 10, 8000),
        (123456, 123456, 10, 100000),
        (-5, -7, 3, 10000),
    ])
    write("3_wide", [
        (123456, 123456, 1500000, 900000),
        (777, 888, 1500000, 100),
        (31, 61, 1500000, 100000000),
    ])
    rng = random.Random(20261126)
    random_blocks = []
    for _ in range(24):
        day_count = rng.randint(1, 40000)
        allowed_sum = rng.choice([0, 1, 100, 10000, 100000, 100000000])
        random_blocks.append((rng.randint(0, 699036), rng.randint(0, 2097150), day_count, allowed_sum))
    write("4_random", random_blocks)
    io_blocks = []
    for index in range(20000):
        day_count = 1 + index % 7
        allowed_sum = 1000 + (index % 9) * 5000
        io_blocks.append((rng.randint(0, 699036), rng.randint(0, 2097150), day_count, allowed_sum))
    write("5_io", io_blocks)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(123456, 123456, 10, 10000)])
build()
