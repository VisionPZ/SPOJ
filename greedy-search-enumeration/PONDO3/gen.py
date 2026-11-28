#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pondo_count = tokens[0]
    bomboo_count = tokens[1]
    days = tokens[2:2 + pondo_count]
    if pondo_count == 0 or bomboo_count < pondo_count:
        return "0\n"
    queue = [(life, index, 1) for index, life in enumerate(days)]
    heapq.heapify(queue)
    spare = bomboo_count - pondo_count
    while spare > 0:
        life, index, eaten = heapq.heappop(queue)
        heapq.heappush(queue, (life + days[index], index, eaten + 1))
        spare -= 1
    return str(min(entry[0] for entry in queue)) + "\n"


SAMPLE = "3 17\n1 2 5\n"
SAMPLE_OUT = "10\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 210\n1 2 3 4 5 6 7 8 9 10\n") == "70\n"
assert oracle("3 2\n1 2 5\n") == "0\n"
assert oracle("2 2\n5 7\n") == "5\n"
assert oracle("2 3\n5 7\n") == "7\n"
assert oracle("1 10\n3\n") == "30\n"


def write(name, days, bomboo_count):
    text = f"{len(days)} {bomboo_count}\n" + " ".join(str(value) for value in days) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 5], 2)
    write("3_wide", [1000000000] * 5, 1000)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(8)],
          rng.randint(8, 3000))
    write("5_io", [1000000000 if index % 2 else 1 for index in range(10)], 3000)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
