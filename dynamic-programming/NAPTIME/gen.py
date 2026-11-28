#!/usr/bin/env python3
import random
from pathlib import Path
from itertools import combinations

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(count):
        period_count = int(tokens[cursor])
        bed_count = int(tokens[cursor + 1])
        cursor += 2
        utilities = [0] + [int(tokens[cursor + k]) for k in range(period_count)]
        cursor += period_count
        cases.append((period_count, bed_count, utilities))
    return cases


def oracle_brute(period_count, bed_count, utilities):
    best = 0
    for chosen in combinations(range(1, period_count + 1), bed_count):
        in_bed = set(chosen)
        total = 0
        for period in chosen:
            if period == 1:
                if period_count in in_bed:
                    total += utilities[1]
            elif period - 1 in in_bed:
                total += utilities[period]
        if total > best:
            best = total
    return best


def oracle_dp(period_count, bed_count, utilities):
    best = 0
    for boundary in (0, 1):
        outside = [-1] * (bed_count + 1)
        inside = [-1] * (bed_count + 1)
        outside[0] = 0
        inside[1] = utilities[1] if boundary == 1 else 0
        for i in range(2, period_count + 1):
            next_outside = [-1] * (bed_count + 1)
            next_inside = [-1] * (bed_count + 1)
            top = min(i - 1, bed_count)
            for j in range(top + 1):
                out_value = outside[j]
                in_value = inside[j]
                if out_value >= 0:
                    next_outside[j] = out_value
                    if j < bed_count:
                        next_inside[j + 1] = out_value
                if in_value >= 0:
                    if in_value > next_outside[j]:
                        next_outside[j] = in_value
                    if j < bed_count:
                        stay_value = in_value + utilities[i]
                        if stay_value > next_inside[j + 1]:
                            next_inside[j + 1] = stay_value
            outside, inside = next_outside, next_inside
        answer = outside[bed_count] if boundary == 0 else inside[bed_count]
        if answer > best:
            best = answer
    return best


def oracle(text):
    answers = []
    for period_count, bed_count, utilities in parse(text):
        if period_count <= 16:
            answer = oracle_brute(period_count, bed_count, utilities)
        else:
            answer = oracle_dp(period_count, bed_count, utilities)
        answers.append(str(answer))
    return "\n".join(answers) + "\n"


def build_text(cases):
    parts = [str(len(cases))]
    for period_count, bed_count, utilities in cases:
        parts.append(str(period_count))
        parts.append(str(bed_count))
        parts.extend(str(value) for value in utilities[1:])
    return "\n".join(parts) + "\n"


def write(name, cases):
    input_text = build_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_TEXT = "1\n5 3\n2\n0\n3\n1\n4\n"

assert oracle(SAMPLE_TEXT) == "6\n"
assert oracle_brute(3, 2, [0, 5, 7, 9]) == 9
assert oracle_dp(3, 2, [0, 5, 7, 9]) == 9
assert oracle_brute(4, 2, [0, 10, 1, 1, 10]) == 10
assert oracle_dp(4, 2, [0, 10, 1, 1, 10]) == 10
_check_seed = random.Random(7123)
for _ in range(200):
    _n = _check_seed.randint(3, 12)
    _b = _check_seed.randint(2, _n - 1)
    _u = [0] + [_check_seed.randint(0, 40) for _ in range(_n)]
    assert oracle_brute(_n, _b, _u) == oracle_dp(_n, _b, _u)


def worked_example():
    period_count = 5
    utilities = [0, 2, 0, 3, 1, 4]
    chosen = (1, 4, 5)
    lines = []
    for period in sorted(chosen, key=lambda value: (value - 4) % period_count):
        previous = period - 1 if period > 1 else period_count
        gain = utilities[period] if previous in chosen else 0
        lines.append(f"period {period}: utility {utilities[period]}, gain {gain}")
    lines.append("total 6")
    return "\n".join(lines)


def build():
    write("2_edges", [
        (3, 2, [0, 0, 0]),
        (3, 2, [0, 200000, 200000, 200000]),
        (4, 2, [0, 10, 1, 1, 10]),
        (5, 4, [0, 1, 2, 3, 4, 5]),
        (5, 2, [0, 0, 0, 0, 0, 0]),
        (6, 3, [0, 200000, 0, 200000, 0, 200000, 0]),
        (3830, 2, [0] + [200000 if k == 3830 else 0 for k in range(1, 3831)]),
    ])
    write("3_wide", [
        (3830, 3829, [0] + [200000] * 3830),
        (3830, 2, [0] + [(k * 7919) % 200001 for k in range(1, 3831)]),
        (3830, 1915, [0] + [200000 if k % 2 else 0 for k in range(1, 3831)]),
    ])
    rng = random.Random(20261124)
    random_cases = []
    for _ in range(8):
        period_count = rng.randint(40, 700)
        bed_count = rng.randint(2, period_count - 1)
        utilities = [0] + [rng.randint(0, 200000) for _ in range(period_count)]
        random_cases.append((period_count, bed_count, utilities))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50000):
        utilities = [0] + [rng.randint(100000, 200000) for _ in range(3)]
        io_cases.append((3, 2, utilities))
    write("5_io", io_cases)


if __name__ == "__main__":
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
    (ROOT / "out" / "1_sample.out").write_text("6\n")
    build()
    print(worked_example())
