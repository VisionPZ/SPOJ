#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(cases):
    results = []
    for budget, parties in cases:
        best_value = -1
        best_cost = 0
        for mask in range(1 << len(parties)):
            cost = 0
            fun = 0
            for index, (fee, value) in enumerate(parties):
                if mask >> index & 1:
                    cost += fee
                    fun += value
            if cost <= budget and (fun > best_value or
                                   (fun == best_value and cost < best_cost)):
                best_value = fun
                best_cost = cost
        results.append((best_cost, best_value))
    return results


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while cursor < len(tokens):
        budget = int(tokens[cursor]); cursor += 1
        count = int(tokens[cursor]); cursor += 1
        if budget == 0 and count == 0:
            break
        parties = []
        for _ in range(count):
            fee = int(tokens[cursor]); cursor += 1
            fun = int(tokens[cursor]); cursor += 1
            parties.append((fee, fun))
        cases.append((budget, parties))
    results = brute(cases)
    return "\n".join(f"{cost} {value}" for cost, value in results) + "\n"


def write(name, cases):
    text = "".join(f"{budget} {len(parties)}\n" +
                   "".join(f"{fee} {fun}\n" for fee, fun in parties)
                   for budget, parties in cases) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = (50, [(12, 3), (15, 8), (16, 9), (16, 6), (10, 2), (21, 9),
               (18, 4), (12, 4), (17, 8), (18, 9)])
assert oracle("50 10\n" + "".join(f"{a} {b}\n" for a, b in SAMPLE[1]) + "0 0\n") == "49 26\n"


def build():
    write("2_edges", [
        (5, []), (5, [(5, 1)]), (5, [(6, 10)]), (10, [(5, 2), (5, 2)]),
        (10, [(5, 3), (5, 2), (10, 5)]), (25, [(5, 0)]),
        (500, [(25, 10)] * 20),
    ])

    random.seed(2468)
    wide = []
    for _ in range(4):
        parties = [(random.randint(5, 25), random.randint(0, 10))
                   for _ in range(random.randint(12, 18))]
        wide.append((random.randint(50, 500), parties))
    write("3_wide", wide)

    random_cases = []
    for _ in range(100):
        parties = [(random.randint(5, 25), random.randint(0, 10))
                   for _ in range(random.randint(1, 16))]
        random_cases.append((random.randint(5, 500), parties))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(1000):
        parties = [(random.randint(5, 25), random.randint(0, 10))
                   for _ in range(random.randint(1, 12))]
        io_cases.append((random.randint(5, 500), parties))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
