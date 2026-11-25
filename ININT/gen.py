#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007
INF = 10**9


def build_table(limit):
    steps = [INF] * (limit + 1)
    ways = [0] * (limit + 1)
    steps[1] = 0
    ways[1] = 1
    for number in range(2, limit + 1):
        best = INF
        total = 0
        for digit in range(1, 10):
            previous = number - digit
            if previous < 1:
                continue
            found = False
            remainder = previous
            while remainder > 0:
                if remainder % 10 == digit:
                    found = True
                    break
                remainder //= 10
            if not found or steps[previous] == INF:
                continue
            candidate = steps[previous] + 1
            if candidate < best:
                best = candidate
                total = ways[previous]
            elif candidate == best:
                total = (total + ways[previous]) % MOD
        steps[number] = best
        ways[number] = total if best < INF else 0
    return steps, ways


CACHE_LIMIT = 100000
STEPS, WAYS = build_table(CACHE_LIMIT)


def oracle(text):
    answers = []
    for token in text.split():
        value = int(token)
        if value > CACHE_LIMIT:
            raise ValueError("oracle query exceeds its table")
        if STEPS[value] == INF:
            answers.append("IMPOSSIBLE")
        else:
            answers.append(f"{STEPS[value]} {WAYS[value]}")
    return "\n".join(answers) + "\n"


SAMPLE = "16\n100\n87\n"
SAMPLE_OUT = "4 1\n17 2\nIMPOSSIBLE\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "0 1\n"
assert oracle("22\n") == "5 1\n"
assert oracle("24\n100\n") == "6 2\n17 2\n"
assert STEPS[1000] == 141 and WAYS[1000] == 87034171


def write(name, values):
    text = "\n".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 4, 8, 16, 22, 24, 33, 87, 95, 96, 100])
    write("3_wide", [99991, 99995, 99999, 100000, 99990, 99989])
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 100000) for _ in range(100)])
    write("5_io", [rng.randint(1, 100000) for _ in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [16, 100, 87])
build()
