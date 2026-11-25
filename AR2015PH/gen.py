#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def to_centi(text):
    major, minor = text.split('.')
    return int(major) * 100 + int(minor)


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while True:
        student_count = int(tokens[cursor]); cursor += 1
        total_units = int(tokens[cursor]); cursor += 1
        if student_count == 0 and total_units == 0:
            break
        scores = []
        for _ in range(student_count):
            scores.append(to_centi(tokens[cursor]))
            cursor += 1
        count = 0
        for width in range(0, 150):
            step = width + 1
            for lowest in range(250, 401 - step):
                slab_count = (400 - lowest) // step + 1
                if slab_count < 2:
                    continue
                qualified = [score for score in scores if score >= lowest]
                if not qualified:
                    continue
                base_total = 0
                for score in qualified:
                    base_total += (score - lowest) // step
                for step_size in range(1, 101):
                    if step_size * (slab_count - 1) >= 100:
                        break
                    remaining = total_units - step_size * base_total
                    if remaining <= 0:
                        break
                    if remaining % len(qualified):
                        continue
                    base_percent = remaining // len(qualified)
                    if base_percent >= 1 and base_percent + (slab_count - 1) * step_size <= 100:
                        count += 1
        answers.append(str(count))
    return "".join(answer + "\n" for answer in answers)


def oracle_direct(text):
    tokens = text.split()
    cursor = 0
    answers = []
    while True:
        student_count = int(tokens[cursor]); cursor += 1
        total_units = int(tokens[cursor]); cursor += 1
        if student_count == 0 and total_units == 0:
            break
        scores = [to_centi(tokens[cursor + index]) for index in range(student_count)]
        cursor += student_count
        count = 0
        for width in range(0, 150):
            step = width + 1
            for lowest in range(250, 401 - step):
                slab_count = (400 - lowest) // step + 1
                if slab_count < 2:
                    continue
                for base_percent in range(1, 101):
                    for step_size in range(1, 101):
                        if base_percent + (slab_count - 1) * step_size > 100:
                            break
                        units = 0
                        for score in scores:
                            if score < lowest:
                                continue
                            slab_index = (score - lowest) // step
                            units += base_percent + slab_index * step_size
                        if units == total_units:
                            count += 1
        answers.append(str(count))
    return "\n".join(answers) + "\n"


SAMPLE = """10 410
3.29
3.96
2.61
2.82
3.93
3.68
3.70
2.91
3.28
3.68
0 0
"""
SAMPLE_OUT = "79554\n"
assert oracle(SAMPLE) == SAMPLE_OUT
TINY = "2 10\n3.00\n4.00\n0 0\n"
assert oracle(TINY) == oracle_direct(TINY)
TINY2 = "3 30\n2.50\n3.50\n4.00\n0 0\n"
assert oracle(TINY2) == oracle_direct(TINY2)
assert to_centi('4.00') == 400
assert (400 - 288) // 15 + 1 == 8


def random_score(rng):
    whole = rng.randint(2, 4)
    fraction = rng.randint(0, 99) if whole < 4 else 0
    return (whole, fraction)


def case_text(scores, units):
    return (f"{len(scores)} {units}\n" +
            "".join(f"{whole}.{fraction:02d}\n" for whole, fraction in scores))


def write(name, cases):
    text = "".join(case_text(*case) for case in cases) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ([(3, 0)], 0),
        ([(3, 0), (4, 0)], 10),
        ([(2, 50), (3, 0), (4, 0)], 30),
    ])
    write("3_wide", [([(3, 29), (3, 96), (2, 61), (2, 82), (3, 93)], 410)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(12):
        scores = [random_score(rng) for _ in range(rng.randint(1, 12))]
        random_cases.append((scores, rng.randint(1, 300)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        scores = [random_score(rng) for _ in range(20)]
        io_cases.append((scores, rng.randint(1, 600)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
