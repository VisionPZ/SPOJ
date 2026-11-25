#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000000


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        length = int(tokens[cursor]); cursor += 1
        bits = int(tokens[cursor]); cursor += 1
        divisors = [int(tokens[cursor + index]) for index in range(length)]
        cursor += length
        size = 1 << bits
        ways = [1 if value % divisors[0] != 0 else 0 for value in range(size)]
        for position in range(1, length):
            divisor = divisors[position]
            following = [0] * size
            for value in range(size):
                if value % divisor == 0:
                    continue
                total = 0
                for previous in range(size):
                    if previous & value == 0:
                        total += ways[previous]
                following[value] = total % MODULUS
            ways = following
        answers.append(str(sum(ways) % MODULUS))
    return "\n".join(answers) + "\n"


SAMPLE = """1
2 2
3 2
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 2\n1\n") == "0\n"
assert oracle("1\n1 3\n2\n") == "4\n"
assert oracle("2\n1 2\n2\n1 2\n1\n") == "2\n0\n"
assert oracle("1\n3 2\n1 2 3\n") == "0\n"


def write(name, cases):
    chunks = [str(len(cases)) + "\n"]
    for length, bits, divisors in cases:
        chunks.append(f"{length} {bits}\n")
        chunks.append(" ".join(str(value) for value in divisors) + "\n")
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, 1, [1]),
        (1, 1, [2]),
        (2, 1, [2, 1]),
        (3, 2, [2, 1, 3]),
        (5, 3, [5, 6, 5, 6, 5]),
    ])
    rng = random.Random(20261126)
    write("3_wide", [(50, 8, [rng.randint(1, 16) for _ in range(50)])])
    random_cases = []
    for _ in range(4):
        bits = rng.randint(5, 7)
        length = rng.randint(20, 45)
        random_cases.append((length, bits,
                             [rng.randint(1, 2 * bits) for _ in range(length)]))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        length = rng.randint(35, 50)
        io_cases.append((length, 7,
                         [rng.randint(1, 14) for _ in range(length)]))
    write("5_io", io_cases)
    big_chunks = []
    for _ in range(10):
        big_chunks.append("50 15\n")
        big_chunks.append(" ".join(str(rng.randint(1, 30)) for _ in range(50)) + "\n")
    Path("/tmp/TLE_big.txt").write_text("10\n" + "".join(big_chunks))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
