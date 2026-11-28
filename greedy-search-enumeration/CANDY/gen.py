#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    answers = []
    while cursor < len(tokens):
        packet_count = tokens[cursor]
        cursor += 1
        if packet_count == -1:
            break
        counts = tokens[cursor:cursor + packet_count]
        cursor += packet_count
        candy_total = sum(counts)
        if candy_total % packet_count:
            answers.append("-1")
        else:
            target = candy_total // packet_count
            total_gap = sum(abs(value - target) for value in counts)
            answers.append(str(total_gap // 2))
    return "\n".join(answers) + "\n"


def simulate(counts):
    total = sum(counts)
    if total % len(counts):
        return -1
    target = total // len(counts)
    packets = list(counts)
    moves = 0
    while any(value > target for value in packets):
        rich = max(range(len(packets)), key=lambda index: packets[index])
        poor = min(range(len(packets)), key=lambda index: packets[index])
        packets[rich] -= 1
        packets[poor] += 1
        moves += 1
    return moves


SAMPLE = """5
1
1
1
1
6
2
3
4
-1
"""
SAMPLE_OUT = """4
-1
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7\n-1\n") == "0\n"
assert oracle("2\n1\n2\n-1\n") == "-1\n"
assert oracle("4\n2\n2\n2\n2\n-1\n") == "0\n"
assert simulate([1, 1, 1, 1, 6]) == 4
assert simulate([3, 4]) == -1
assert simulate([0, 2, 4]) == 2


def write(name, blocks):
    lines = []
    for counts in blocks:
        lines.append(str(len(counts)))
        lines.extend(str(value) for value in counts)
    lines.append("-1")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[7], [0], [1, 2], [2, 2], [0, 0, 0], [999, 0, 0]])
    write("3_wide", [[998] * 5000 + [0] * 5000, [999] * 10000])
    rng = random.Random(20261126)
    random_blocks = []
    for _ in range(200):
        size = rng.randint(1, 200)
        random_blocks.append([rng.randint(0, 999) for _ in range(size)])
    write("4_random", random_blocks)
    io_blocks = [[rng.randint(0, 999)] for _ in range(20000)]
    write("5_io", io_blocks)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
