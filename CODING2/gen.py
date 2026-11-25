#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    answers = []
    while True:
        alphabet_bits = tokens[pos]
        message_length = tokens[pos + 1]
        pos += 2
        if alphabet_bits == 0 and message_length == 0:
            break
        alphabet_size = 1 << alphabet_bits
        counts = [0] * alphabet_size
        for symbol in tokens[pos:pos + message_length]:
            counts[symbol] += 1
        pos += message_length
        leaves = deque(sorted((weight, index) for index, weight in enumerate(counts) if weight > 0))
        if len(leaves) == 1:
            answers.append(str(leaves[0][0]))
            continue
        internal = deque()
        total = 0
        while len(leaves) + len(internal) > 1:
            if not leaves:
                first = internal.popleft()
            elif not internal:
                first = leaves.popleft()
            elif leaves[0][0] <= internal[0][0]:
                first = leaves.popleft()
            else:
                first = internal.popleft()
            if not leaves:
                second = internal.popleft()
            elif not internal:
                second = leaves.popleft()
            elif leaves[0][0] <= internal[0][0]:
                second = leaves.popleft()
            else:
                second = internal.popleft()
            weight = first[0] + second[0]
            total += weight
            internal.append((weight, 0))
        answers.append(str(total))
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = "2 16\n0 0 0 0 1 1 1 1 0 0 0 0 2 2 3 3\n0 0\n"
SAMPLE_OUT = "28\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 4\n0 0 0 0\n0 0\n") == "4\n"
assert oracle("1 4\n0 1 0 1\n0 0\n") == "4\n"
assert oracle("2 8\n0 0 0 0 1 1 2 3\n0 0\n") == "14\n"
assert (1 << 15) == 32768


def write_case(name, cases):
    text = ""
    for alphabet_bits, message in cases:
        text += f"{alphabet_bits} {len(message)}\n"
        text += " ".join(str(value) for value in message) + "\n"
    text += "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, [0, 0, 0, 0]),
        (1, [1, 0, 1, 0]),
        (2, [0, 1, 2, 3]),
        (3, [7]),
        (4, [15, 15, 0, 3, 3, 3]),
    ])
    rng = random.Random(20261126)
    wide = [rng.randrange(32768) for _ in range(30000)]
    for value in range(32768):
        wide.append(value)
    write_case("3_wide", [(15, wide)])
    random_cases = []
    for _ in range(12):
        bits = rng.randint(1, 8)
        size = 1 << bits
        length = rng.randint(1, 500)
        message = [rng.randrange(size) for _ in range(length)]
        random_cases.append((bits, message))
    write_case("4_random", random_cases)
    io_cases = []
    for case_index in range(60000):
        bits = rng.randint(1, 4)
        size = 1 << bits
        length = rng.randint(1, 8)
        io_cases.append((bits, [rng.randrange(size) for _ in range(length)]))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [(2, [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 2, 2, 3, 3])])
build()
