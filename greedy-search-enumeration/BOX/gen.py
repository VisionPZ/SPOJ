#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    test_count = tokens[cursor]
    cursor += 1
    answers = []
    for _ in range(test_count):
        box_count = tokens[cursor]
        cursor += 1
        counts = tokens[cursor:cursor + box_count]
        cursor += box_count
        balls = []
        for source, count in enumerate(counts):
            balls.extend([source] * count)
        if not balls:
            answers.append("0")
            continue
        infinity = 10 ** 9
        states = [infinity] * (1 << box_count)
        states[0] = 0
        for source in balls:
            next_states = [infinity] * (1 << box_count)
            for mask in range(1 << box_count):
                known = states[mask]
                if known >= infinity:
                    continue
                for box in range(box_count):
                    if mask & (1 << box):
                        continue
                    direct = abs(source - box)
                    distance = min(direct, box_count - direct)
                    new_mask = mask | (1 << box)
                    candidate = known + distance
                    if candidate < next_states[new_mask]:
                        next_states[new_mask] = candidate
            states = next_states
        answers.append(str(min(states)))
    return "\n".join(answers) + "\n"


SAMPLE = """1
12
0 0 2 4 3 1 0 0 0 0 0 1
"""
SAMPLE_OUT = """19
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n2 0\n") == "1\n"
assert oracle("1\n3\n3 0 0\n") == "2\n"
assert oracle("1\n4\n1 0 1 0\n") == "0\n"
assert oracle("2\n3\n0 0 0\n4\n1 1 1 1\n") == "0\n0\n"


def write(name, cases):
    chunks = [str(len(cases))]
    for counts in cases:
        chunks.append(str(len(counts)))
        chunks.append(" ".join(str(value) for value in counts))
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[0, 0], [2, 0], [3, 0, 0], [1, 0, 1, 0]])
    write("3_wide", [[0, 0, 2, 4, 3, 1, 0, 0, 0, 0, 0, 1],
                     [1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]])
    rng = random.Random(20261126)
    cases = []
    for _ in range(6):
        box_count = rng.randint(2, 9)
        ball_count = rng.randint(1, box_count)
        counts = [0] * box_count
        for _ in range(ball_count):
            counts[rng.randrange(box_count)] += 1
        cases.append(counts)
    write("4_random", cases)
    cases = []
    for _ in range(19):
        box_count = rng.randint(2, 9)
        ball_count = rng.randint(1, box_count)
        counts = [0] * box_count
        for _ in range(ball_count):
            counts[rng.randrange(box_count)] += 1
        cases.append(counts)
    write("5_io", cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
