#!/usr/bin/env python3
import random
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def show(value):
    text = format(value, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text


def oracle(text):
    tokens = text.replace("\u00a0", " ").split()
    count = int(tokens[0])
    values = [Decimal(token) for token in tokens[1:]]
    answers = []
    for index in range(count):
        answers.append(show(values[2 * index] + values[2 * index + 1]))
    return "\n".join(answers) + "\n"


SAMPLE = "1\n23.33 34\n"
SAMPLE_OUT = "57.33\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1 2\n3.5 -0.5\n") == "3\n3\n"
assert oracle("1\n0.0000001 0.0000001\n") == "0.0000002\n"
assert oracle("1\n-1000000000 1000000000\n") == "0\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n"
    input_text += "".join(f"{show(first)} {show(second)}\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [(Decimal("23.33"), Decimal("34"))])
write("2_edges", [(Decimal("0"), Decimal("0")), (Decimal("-1.5"), Decimal("1.5")),
                  (Decimal("1000000000"), Decimal("-999999999.5"))])

wide = [(Decimal("123456789.123456"), Decimal("-123456789.123456")) for _ in range(200)]
write("3_wide", wide)

random.seed(2026)
random_pairs = []
for _ in range(500):
    first = Decimal(random.randint(-1000000, 1000000)) / Decimal(1000)
    second = Decimal(random.randint(-1000000, 1000000)) / Decimal(1000)
    random_pairs.append((first, second))
write("4_random", random_pairs)

io_pairs = [(Decimal(random.randint(-99999, 99999)) / Decimal(100),
             Decimal(random.randint(-99999, 99999)) / Decimal(100))
            for _ in range(5000)]
write("5_io", io_pairs)
