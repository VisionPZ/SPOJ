#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    height = tokens[0]
    steps = tokens[1:4]
    top = height - 1
    if top <= 1000000:
        reachable = [False] * (top + 1)
        reachable[0] = True
        for offset in range(top + 1):
            if reachable[offset]:
                for step in steps:
                    if offset + step <= top:
                        reachable[offset + step] = True
        return str(sum(reachable)) + "\n"
    modulus = min(steps)
    distance = [None] * modulus
    distance[0] = 0
    queue = deque([0])
    queued = [False] * modulus
    queued[0] = True
    while queue:
        residue = queue.popleft()
        queued[residue] = False
        for step in steps:
            if step == modulus:
                continue
            next_residue = (residue + step) % modulus
            next_distance = distance[residue] + step
            if distance[next_residue] is None or next_distance < distance[next_residue]:
                distance[next_residue] = next_distance
                if not queued[next_residue]:
                    queue.append(next_residue)
                    queued[next_residue] = True
    total = 0
    for value in distance:
        if value is not None and value <= top:
            total += (top - value) // modulus + 1
    return str(total) + "\n"


SAMPLE = """15
4 7 9
"""
SAMPLE_OUT = """9
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("500000\n160 96 111\n") == "498167\n"
assert oracle("987654321987654321\n99995 99997 99999\n") == "987654319487854318\n"
assert oracle("1\n1 1 1\n") == "1\n"
assert oracle("20\n6 10 15\n") == "7\n"


def write(name, height, steps):
    text = f"{height}\n{' '.join(map(str, steps))}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, [1, 1, 1])
    write("3_wide", 100000, [99991, 99993, 99997])
    rng = random.Random(20261126)
    write("4_random", rng.randint(1000, 100000), rng.sample(range(1, 2000), 3))
    write("5_io", 999999999999999999, [99991, 99993, 99997])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 15, [4, 7, 9])
build()
