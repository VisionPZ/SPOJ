#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """2
smsmmsms 1
mmsm 1
"""

SAMPLE_OUT = """1 5
-1
"""


def prefix_s(text):
    counts = [0]
    for character in text:
        counts.append(counts[-1] + (1 if character == "s" else 0))
    return counts


def solve_case(text, target):
    counts = prefix_s(text)
    best_length = 0
    best_start = 0
    best_end = 0
    for left in range(len(text)):
        weighted_m = 0
        weighted_end = 0
        for right in range(left, len(text)):
            if text[right] == "m":
                before = counts[right] - counts[left]
                weighted_m += before
                weighted_end += before * counts[right + 1]
            current = counts[right + 1] * weighted_m - weighted_end
            if current == target and right - left + 1 > best_length:
                best_length = right - left + 1
                best_start = left
                best_end = right
    if best_length == 0:
        return "-1"
    return f"{best_start + 1} {best_end + 1}"


def whole_count(text):
    counts = prefix_s(text)
    weighted_m = 0
    weighted_end = 0
    for position, character in enumerate(text):
        if character == "m":
            before = counts[position]
            weighted_m += before
            weighted_end += before * counts[position + 1]
    return counts[len(text)] * weighted_m - weighted_end


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(case_count):
        pattern = tokens[cursor]
        target = int(tokens[cursor + 1])
        cursor += 2
        answers.append(solve_case(pattern, target))
    return "\n".join(answers) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n" + "".join(
        f"{text} {target}\n" for text, target in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\nsms 0\n") == "1 2\n"
assert oracle("1\nsms 1\n") == "1 3\n"
assert oracle("1\nabc 5\n") == "-1\n"


def build():
    write("2_edges", [("s", 0), ("abc", 0), ("sms", 1), ("sms", 2),
                      ("mmsm", 1), ("smss", 2), ("ssmmss", 4),
                      ("sm", 1), ("smsms", 2), ("mmsm", 0)])
    wide_patterns = [
        "s" * 333 + "m" * 334 + "s" * 333,
        "s" * 334 + "m" * 332 + "s" * 334,
        "abc" * 333 + "a",
        "sm" * 500,
        "ms" * 500,
        "sms" * 333 + "s",
        "s" * 500 + "m" * 500,
        "m" * 500 + "s" * 500,
        "s" * 300 + "m" * 400 + "s" * 300,
        "s" * 250 + "m" * 500 + "s" * 250,
    ]
    write("3_wide", [(pattern, whole_count(pattern)) for pattern in wide_patterns])
    rng = random.Random(10153)
    random_pairs = []
    for _ in range(10):
        text = "".join(rng.choice("ssmmabcde") for _ in range(1000))
        target = rng.randint(0, 10**8)
        random_pairs.append((text, target))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(10):
        text = "".join(rng.choice("ssmm") for _ in range(1000))
        total = whole_count(text)
        target = total if total <= 10**8 else rng.randint(0, 10**8)
        io_pairs.append((text, target))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
