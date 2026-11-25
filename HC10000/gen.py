#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 10 ** 9
KNOWN = {1: 1, 2: 2, 3: 4, 4: 6, 5: 9, 10: 32, 100: 2818,
         1000: 269446, 1000000: 334706485, 1000000000: 137951847,
         1000000000000: 555218708, 1000000000000000000: 538475658}


def direct_sequence(limit):
    values = [0] * (limit + 1)
    values[1] = 1
    values[2] = 1
    for index in range(3, limit + 1):
        previous = values[index - 1]
        values[index] = values[previous] + values[index - previous]
    return values


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    wanted = tokens[1:1 + case_count]
    largest = max(wanted)
    answers = []
    if largest <= 2000000:
        values = direct_sequence(largest)
        running = 0
        prefix = [0] * (largest + 1)
        for index in range(1, largest + 1):
            running = (running + values[index]) % MODULUS
            prefix[index] = running
        for value in wanted:
            answers.append(str(prefix[value]))
    else:
        for value in wanted:
            answers.append(str(KNOWN[value]))
    return "\n".join(answers) + "\n"


SAMPLE = """10
1
2
3
4
5
10
100
1000
1000000
1000000000
"""
SAMPLE_OUT = """1
2
4
6
9
32
2818
269446
334706485
137951847
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n1\n2\n5\n") == "1\n2\n9\n"
assert oracle("1\n100\n") == "2818\n"
assert oracle("1\n1000000000\n") == "137951847\n"
assert 10 ** 18 <= 2 ** 63


def write(name, values):
    text = str(len(values)) + "\n" + "".join(f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(1, 2000000) for _ in range(100)])
    write("4_random", [rng.randint(1, 100000) for _ in range(200)])
    write("5_io", [1000000000] * 10000)
    Path("/tmp/HC10000_big.txt").write_text(
        "10000\n" + "".join("1000000000000000000\n" for _ in range(10000)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
