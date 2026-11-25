#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    target = int(text)
    distance = {0: 0}
    queue = deque([0])
    while queue:
        value = queue.popleft()
        for following in (value + 1, value * 3):
            if following <= target and following not in distance:
                distance[following] = distance[value] + 1
                queue.append(following)
    return str(distance[target]) + "\n"


SAMPLE = "17\n"
SAMPLE_OUT = "7\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n") == "1\n"
assert oracle("3\n") == "2\n"
assert oracle("2\n") == "2\n"
assert oracle("100\n") == "8\n"
assert oracle("1000000\n") == "26\n"


def write(name, target):
    text = f"{target}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1)
    write("3_wide", 1000000)
    rng = random.Random(20261126)
    write("4_random", rng.randint(1, 1000000))
    write("5_io", 999999)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
