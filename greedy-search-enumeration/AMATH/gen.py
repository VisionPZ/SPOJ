#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    answers = []
    for index in range(0, len(tokens), 2):
        number = int(tokens[index])
        power = int(tokens[index + 1])
        modulus = 10 ** power
        first_power = number % modulus
        limit = 4 * 10 ** (power - 1)
        found = -1
        for period in range(1, limit + 1):
            if pow(number, period + 1, modulus) == first_power:
                found = period
                break
        answers.append(str(found))
    return "\n".join(answers) + "\n"


SAMPLE = "32 2\n"
SAMPLE_OUT = "4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 1\n") == "4\n"
assert oracle("2 1\n") == "4\n"
assert oracle("10 2\n") == "-1\n"
assert oracle("100 2\n") == "1\n"
assert oracle("5 1\n") == "1\n"


def write(name, pairs):
    text = "".join(f"{number} {power}\n" for number, power in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [("1", 1), ("10", 1), ("10", 2), ("2", 1),
                      ("5", 1), ("5", 2), ("15", 1), ("32", 4)])
    wide = []
    for power in (1, 2, 3, 4):
        digits = [rng.choice("13579")] + [rng.choice("0123456789") for _ in range(98)]
        digits.append(rng.choice("13579"))
        wide.append(("".join(digits), power))
    write("3_wide", wide)
    random_pairs = []
    for _ in range(12):
        length = rng.randint(1, 100)
        digits = [rng.choice("0123456789") for _ in range(length)]
        digits[0] = rng.choice("123456789")
        random_pairs.append(("".join(digits), rng.randint(1, 4)))
    write("4_random", random_pairs)
    io_pairs = []
    for _ in range(20):
        digits = [rng.choice("0123456789") for _ in range(rng.randint(1, 60))]
        digits[0] = rng.choice("123456789")
        io_pairs.append(("".join(digits), rng.randint(1, 3)))
    write("5_io", io_pairs)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("32", 2)])
build()
