#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCALE = 8192
STEP = 1220703125


def oracle(text):
    tokens = text.split()
    position = 0
    dataset_count = int(tokens[position])
    position += 1
    lines = []
    for _ in range(dataset_count):
        initial = int(tokens[position])
        years = int(tokens[position + 1])
        operation_count = int(tokens[position + 2])
        position += 3
        best = 0
        for _ in range(operation_count):
            kind = int(tokens[position])
            rate = Fraction(tokens[position + 1])
            charge = int(tokens[position + 2])
            position += 3
            balance = initial
            saved = 0
            for _ in range(years):
                interest = math.floor(balance * rate)
                if kind == 1:
                    balance += interest
                else:
                    saved += interest
                balance -= charge
            amount = balance if kind == 1 else balance + saved
            if amount > best:
                best = amount
        lines.append(str(best))
    return "\n".join(lines) + "\n"


SAMPLE = """4
1000000
5
2
0 0.03125 3000
1 0.03125 3000
6620000
7
2
0 0.0732421875 42307
1 0.0740966796875 40942
39677000
4
4
0 0.0709228515625 30754
1 0.00634765625 26165
0 0.03662109375 79468
0 0.0679931640625 10932
10585000
6
4
1 0.0054931640625 59759
1 0.12353515625 56464
0 0.0496826171875 98193
0 0.0887451171875 78966
"""
SAMPLE_OUT = """1150357
10559683
50796918
20829397
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1000000\n5\n1\n1 0.03125 3000\n") == "1150357\n"
assert oracle("1\n1000000\n5\n1\n0 0.03125 3000\n") == "1140311\n"
assert Fraction("0.03125") * SCALE == 256
assert Fraction("0.125") * SCALE == 1024


def rate_text(numerator):
    digits = f"{numerator * STEP:013d}".rstrip("0")
    return "0." + digits


def operation(kind, numerator, charge):
    return f"{kind} {rate_text(numerator)} {charge}\n"


def dataset(initial, years, operations):
    return f"{initial}\n{years}\n{len(operations)}\n" + "".join(operations)


def write(name, datasets):
    text = str(len(datasets)) + "\n" + "".join(datasets)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        dataset(1, 1, [operation(0, 1, 0), operation(1, SCALE, 0)]),
        dataset(100000000, 10, [operation(0, 1, 100000),
                                operation(1, 128, 50000)]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(100):
        ops = [operation(rng.randint(0, 1), rng.randint(1, SCALE), rng.randint(0, 5000))
               for _ in range(100)]
        wide.append(dataset(100000000, 10, ops))
    write("3_wide", wide)
    mixed = []
    for _ in range(50):
        initial = rng.randint(1000, 100000000)
        ops = [operation(rng.randint(0, 1), rng.randint(1, SCALE), rng.randint(0, 100000))
               for _ in range(rng.randint(1, 100))]
        mixed.append(dataset(initial, rng.randint(1, 10), ops))
    write("4_random", mixed)
    io = []
    for _ in range(100):
        ops = [operation(1, rng.randint(1, 64), rng.randint(50000, 100000))
               for _ in range(100)]
        io.append(dataset(100000000, 10, ops))
    write("5_io", io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
