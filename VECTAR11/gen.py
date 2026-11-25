#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    numbers = tokens[1:1 + case_count]
    largest = max(numbers) if numbers else 0
    squares = []
    root = 1
    while root * root <= largest:
        squares.append(root * root)
        root += 1
    winning = [False] * (largest + 1)
    for value in range(largest + 1):
        if winning[value]:
            continue
        for square in squares:
            target = value + square
            if target > largest:
                break
            winning[target] = True
    return "".join("Win\n" if winning[value] else "Lose\n" for value in numbers)


SAMPLE = "3\n1\n2\n3\n"
SAMPLE_OUT = "Win\nLose\nWin\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\n") == "Lose\n"
assert oracle("1\n4\n") == "Win\n"
assert oracle("4\n7\n8\n9\n10\n") == "Lose\nWin\nWin\nLose\n"
assert 31 // 3 == 10


def write(name, numbers):
    text = str(len(numbers)) + "\n" + "".join(str(value) + "\n" for value in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 15, 20, 22, 24, 50])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(0, 100000) for _ in range(200)])
    write("4_random", [rng.randint(0, 1000) for _ in range(500)])
    write("5_io", [rng.randint(0, 1000) for _ in range(40000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [1, 2, 3])
build()
