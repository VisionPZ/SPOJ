#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    process_count = tokens[0]
    quantum = tokens[1]
    waiting = deque((index + 1, tokens[2 + index]) for index in range(process_count))
    finished = []
    while waiting:
        process_id, remaining = waiting.popleft()
        if remaining <= quantum:
            finished.append(process_id)
        else:
            waiting.append((process_id, remaining - quantum))
    return " ".join(str(value) for value in finished) + "\n"


SAMPLE = """4 3
5 10 3 8
"""
SAMPLE_OUT = """3 1 4 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 2\n2 2 2\n") == "1 2 3\n"
assert oracle("1 5\n7\n") == "1\n"
assert oracle("5 1\n1 1 1 1 1\n") == "1 2 3 4 5\n"
assert oracle("4 2\n3 1 4 2\n") == "2 4 1 3\n"


def write(name, quantum, bursts):
    text = f"{len(bursts)} {quantum}\n" + " ".join(str(value) for value in bursts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [1, 3, 2, 5, 4])
    write("3_wide", 3, [(index % 17) * 7 + 1 for index in range(200)])
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 20), [rng.randint(1, 500) for _ in range(80)])
    write("5_io", 2, [(index % 3) + 1 for index in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
