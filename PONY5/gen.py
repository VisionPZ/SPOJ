#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LIMIT = 10 ** 18


def oracle_case(numbers):
    if len(numbers) == 1 or all(value == numbers[0] for value in numbers):
        return "I can't count that high"
    for candidate in range(max(numbers), 0, -1):
        target = numbers[0] % candidate
        if all(value % candidate == target for value in numbers[1:]):
            return str(candidate) if candidate <= LIMIT else "I can't count that high"
    raise AssertionError("candidate 1 always works")


def oracle(text):
    raw_lines = [line for line in text.splitlines() if line.strip()]
    case_count = int(raw_lines[0])
    lines = []
    for case_index in range(1, case_count + 1):
        fields = [int(field) for field in re.findall(r"\d+", raw_lines[case_index])]
        pony_count = fields[1]
        numbers = fields[2:2 + pony_count]
        assert len(numbers) == pony_count
        lines.append(f"Case #{case_index}: {oracle_case(numbers)}")
    return "\n".join(lines) + "\n"


SAMPLE = """2
Case #1: 3 178 928 440
Case #2: 1 1000000000000000000
"""
SAMPLE_OUT = """Case #1: 2
Case #2: I can't count that high
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nCase #1: 3 6 10 14\n") == "Case #1: 4\n"
assert oracle("1\nCase #1: 2 5 5 5\n") == "Case #1: I can't count that high\n"
assert oracle("1\nCase #1: 2 10 15\n") == "Case #1: 5\n"
assert oracle("1\nCase #1: 4 7 11 13 17\n") == "Case #1: 2\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"Case #{index}: {len(numbers)} " + " ".join(str(value) for value in numbers) + "\n"
        for index, numbers in enumerate(cases, 1))
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[3], [7, 7, 7], [2, 2], [2, 4], [1, 2, 3],
                      [10 ** 18, 10 ** 18]])
    write("3_wide", [[10 ** 18], [10 ** 18] * 5,
                     [1000 + 3 * index for index in range(12)]])
    rng = random.Random(20261126)
    write("4_random", [
        [rng.randint(1, 3000) for _ in range(rng.randint(2, 12))]
        for _ in range(40)])
    write("5_io", [
        [rng.randint(1, 2000) for _ in range(rng.randint(2, 8))]
        for _ in range(200)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[178, 928, 440], [10 ** 18]])
build()
