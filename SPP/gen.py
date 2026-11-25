#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    answers = []
    for order, values, coeffs, lower, upper, modulus in cases:
        sequence = list(values)
        while len(sequence) < upper:
            total = sum(coeffs[j] * sequence[-1 - j] for j in range(order))
            sequence.append(total % modulus)
        prefix = [0]
        for value in sequence:
            prefix.append((prefix[-1] + value) % modulus)
        answers.append(str((prefix[upper] - prefix[lower - 1]) % modulus))
    return "\n".join(answers) + "\n"


def encode(cases):
    lines = [str(len(cases))]
    for order, values, coeffs, lower, upper, modulus in cases:
        lines.append(str(order))
        lines.append(" ".join(map(str, values)))
        lines.append(" ".join(map(str, coeffs)))
        lines.append(f"{lower} {upper} {modulus}")
    return "\n".join(lines) + "\n"


SAMPLE = [(2, [1, 1], [1, 1], 2, 10, 1000003)]
assert oracle(SAMPLE) == "142\n"
assert oracle([(1, [5], [2], 1, 1, 7)]) == "5\n"
assert oracle([(1, [5], [2], 1, 4, 7)]) == "5\n"
assert oracle([(3, [1, 2, 4], [0, 0, 1], 1, 8, 100)]) == "17\n"
assert encode(SAMPLE) == "1\n2\n1 1\n1 1\n2 10 1000003\n"


def write(name, cases):
    text = encode(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


def build():
    write("2_edges", [
        (1, [1], [1], 1, 1, 1000003),
        (1, [1], [1], 1, 100, 1000003),
        (15, [0] * 15, [1] + [0] * 14, 1, 40, 1),
        (3, [1, 2, 4], [0, 0, 1], 1, 8, 100),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(12):
        order = rng.randint(1, 15)
        values = [rng.randint(0, 10**9) for _ in range(order)]
        coeffs = [rng.randint(0, 3) for _ in range(order)]
        lower = rng.randint(1, 30)
        upper = lower + rng.randint(0, 60)
        modulus = rng.randint(1, 10**8)
        wide.append((order, values, coeffs, lower, upper, modulus))
    write("3_wide", wide)
    random_cases = []
    for _ in range(20):
        order = rng.randint(1, 15)
        values = [rng.randint(0, 10**9) for _ in range(order)]
        coeffs = [rng.randint(0, 10**9) for _ in range(order)]
        lower = rng.randint(1, 50)
        upper = lower + rng.randint(0, 50)
        modulus = rng.randint(1, 10**8)
        random_cases.append((order, values, coeffs, lower, upper, modulus))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50):
        order = 15
        values = [rng.randint(0, 10**9) for _ in range(order)]
        coeffs = [rng.randint(0, 10**9) for _ in range(order)]
        lower = rng.randint(1, 40)
        upper = lower + 60
        modulus = 100000000
        io_cases.append((order, values, coeffs, lower, upper, modulus))
    write("5_io", io_cases)
    huge = [(15, [rng.randint(0, 10**9) for _ in range(15)],
             [rng.randint(0, 10**9) for _ in range(15)],
             1, 10**18, 10**8) for _ in range(50)]
    Path("/tmp/SPP_big.txt").write_text(encode(huge))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
