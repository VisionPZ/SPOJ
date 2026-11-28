#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def ranks(window):
    order = sorted(range(len(window)), key=lambda index: window[index])
    result = [0] * len(window)
    for rank, index in enumerate(order):
        result[index] = rank
    return result


def oracle(test_cases):
    answers = []
    for sequences in test_cases:
        text = sequences[0]
        patterns = [ranks(pattern) for pattern in sequences[1:]]
        for end in range(1, len(text) + 1):
            for pattern in patterns:
                length = len(pattern)
                if length > end:
                    continue
                if ranks(text[end - length:end]) == pattern:
                    answers.append(str(end))
                    break
    return "\n".join(answers) + "\n" if answers else ""


def encode(test_cases):
    lines = [str(len(test_cases))]
    for sequences in test_cases:
        lines.append(str(len(sequences)))
        for sequence in sequences:
            lines.append(str(len(sequence)))
            lines.append(" ".join(map(str, sequence)))
    return "\n".join(lines) + "\n"


SAMPLE = [
    [[1], [2]],
    [[3, 1, 2], [4, 5], [10, 1]],
]
assert oracle(SAMPLE) == "1\n2\n3\n"
assert encode(SAMPLE) == (
    "2\n2\n1\n1\n1\n2\n3\n3\n3 1 2\n2\n4 5\n2\n10 1\n"
)
assert oracle([[[5, 6, 7, 8], [5, 6], [7, 8]]]) == "2\n3\n4\n"
assert oracle([[[10, 20, 30], [1, 2, 3, 4]]]) == ""
assert ranks([9, 3, 7]) == [2, 0, 1]


def write(name, test_cases):
    text = encode(test_cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(test_cases))


def random_case(rng, text_length, pattern_count, pattern_length):
    values = rng.sample(range(1, 2**31 - 1), text_length + pattern_count * pattern_length)
    cursor = 0
    text = values[cursor:cursor + text_length]
    cursor += text_length
    patterns = []
    for _ in range(pattern_count):
        patterns.append(values[cursor:cursor + pattern_length])
        cursor += pattern_length
    return [text] + patterns


def build():
    rng = random.Random(20261126)
    write("2_edges", [
        [[7, 3], [1]],
        [[5, 9, 2], [100, 200, 300]],
    ])
    write("3_wide", [random_case(rng, 60, 5, 8), random_case(rng, 50, 4, 5)])
    write("4_random", [random_case(rng, 80, 8, 7), random_case(rng, 70, 6, 6)])
    climbing = [10 * index for index in range(1, 3001)]
    write("5_io", [[climbing, climbing[0:12], climbing[100:112], climbing[500:512]]])
    big_text = rng.sample(range(1, 2**31 - 1), 400000)
    patterns = [rng.sample(range(1, 2**31 - 1), 100) for _ in range(1000)]
    big = [[big_text] + patterns]
    Path("/tmp/UNTITLED_big.txt").write_text(encode(big))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
