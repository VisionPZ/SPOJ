#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        day_count = int(tokens[cursor])
        cursor += 1
        capital = float(tokens[cursor])
        cursor += 1
        mone_rates = []
        luck_rates = []
        share_rates = []
        for _ in range(day_count):
            mone_rates.append(float(tokens[cursor]))
            luck_rates.append(float(tokens[cursor + 1]))
            share_rates.append(float(tokens[cursor + 2]))
            cursor += 3
        capitals = [capital]
        for day_index in range(day_count):
            best = capitals[-1]
            for earlier in range(day_index):
                denominator = mone_rates[earlier] * share_rates[earlier] + luck_rates[earlier]
                if denominator <= 0:
                    continue
                factor = (share_rates[earlier] * mone_rates[day_index]
                          + luck_rates[day_index]) / denominator
                candidate = capitals[earlier + 1] * factor
                if candidate > best:
                    best = candidate
            capitals.append(best)
        answers.append(f"{capitals[-1]:.3f}")
    return "\n".join(answers) + "\n"


SAMPLE = "1\n3 100\n1 1 1\n1 2 2\n2 2 3\n"
SAMPLE_OUT = "225.000\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 100\n1 1 1\n") == "100.000\n"
assert oracle("1\n2 10\n1 1 1\n10 10 1\n") == "100.000\n"
assert oracle("1\n3 50\n1 1 1\n3 4 2\n0.5 0.5 3\n") == "175.000\n"


def format_capital(value):
    if abs(value - round(value)) < 1e-12 and abs(value) < 1e15:
        return str(int(round(value)))
    return repr(value)


def render(cases):
    pieces = [str(len(cases))]
    for day_count, capital, rows in cases:
        pieces.append(f"{day_count} {format_capital(capital)}")
        for mone_rate, luck_rate, share_rate in rows:
            pieces.append(f"{mone_rate} {luck_rate} {share_rate}")
    return "\n".join(pieces) + "\n"


def write(name, cases):
    text = render(cases)
    answer = max(float(value) for value in oracle(text).split())
    if answer > 100000000.0:
        scale = 100000000.0 / answer
        cases = [(day_count, capital * scale, rows) for day_count, capital, rows in cases]
        text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 100, [(1, 1, 1)]),
        (2, 10, [(1, 1, 1), (10, 10, 1)]),
        (3, 50, [(1, 1, 1), (3, 4, 2), (0.5, 0.5, 3)]),
    ])
    rng = random.Random(20261126)
    wide_rows = [(round(rng.uniform(0.5, 10), 2), round(rng.uniform(0.5, 10), 2),
                  round(rng.uniform(0.5, 100), 2)) for _ in range(60)]
    write("3_wide", [(60, 1000, wide_rows)])
    random_rows = [(round(rng.uniform(0.25, 8), 2), round(rng.uniform(0.25, 8), 2),
                    round(rng.uniform(0.25, 80), 2)) for _ in range(45)]
    write("4_random", [(45, 250, random_rows)])
    io_cases = []
    for _ in range(5):
        rows = [(round(rng.uniform(0.5, 9), 2), round(rng.uniform(0.5, 9), 2),
                 round(rng.uniform(0.5, 90), 2)) for _ in range(1000)]
        io_cases.append((1000, 500, rows))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(3, 100, [(1, 1, 1), (1, 2, 2), (2, 2, 3)])])
build()
