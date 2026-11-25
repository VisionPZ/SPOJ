#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    item_count = tokens[0]
    budget = tokens[1]
    items = []
    cursor = 2
    for _ in range(item_count):
        if cursor + 2 >= len(tokens):
            break
        items.append((tokens[cursor], tokens[cursor + 1], tokens[cursor + 2]))
        cursor += 3
    reachable = [-1] * (budget + 1)
    reachable[0] = 10 ** 9
    for equipment_type in range(1, 7):
        choices = [(price, quality) for (kind, price, quality) in items
                   if kind == equipment_type]
        updated = [-1] * (budget + 1)
        for cost in range(budget + 1):
            if reachable[cost] < 0:
                continue
            for price, quality in choices:
                new_cost = cost + price
                if new_cost > budget:
                    continue
                candidate = min(reachable[cost], quality)
                if candidate > updated[new_cost]:
                    updated[new_cost] = candidate
        reachable = updated
    return str(max(0, max(reachable))) + "\n"


def brute(text):
    tokens = [int(value) for value in text.split()]
    budget = tokens[1]
    groups = [[] for _ in range(7)]
    cursor = 2
    for index in range(tokens[0]):
        if cursor + 2 >= len(tokens):
            break
        groups[tokens[cursor]].append((tokens[cursor + 1], tokens[cursor + 2]))
        cursor += 3
    best = 0
    for combination in itertools.product(*[groups[kind] for kind in range(1, 7)]):
        price = sum(part[0] for part in combination)
        quality = min(part[1] for part in combination)
        if price <= budget and quality > best:
            best = quality
    return str(best) + "\n"


SAMPLE = """7 53
5 8 2
2 4 8
6 8 13
1 13 12
4 5 1
3 2 7
3 13 5
"""
SAMPLE_OUT = """1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("7 10\n1 2 3\n2 2 4\n3 2 5\n4 2 6\n5 2 7\n") == "0\n"
assert brute("7 10\n1 2 3\n2 2 4\n3 2 5\n4 2 6\n5 2 7\n") == "0\n"
assert oracle("6 6\n1 1 1\n2 1 2\n3 1 3\n4 1 4\n5 1 5\n6 1 6\n") == "1\n"
assert oracle("6 1000\n1 1 999\n2 1 999\n3 1 999\n4 1 999\n5 1 999\n6 1 999\n") == "999\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "7 10\n1 2 3\n2 2 4\n3 2 5\n4 2 6\n5 2 7\n6 9 8\n7 9 9\n")
    wide = ["100 1000"]
    for index in range(100):
        kind = index % 6 + 1
        price = 1 + index % 200
        quality = 1 + (index * 37) % 999
        wide.append(f"{kind} {price} {quality}")
    write("3_wide", "\n".join(wide) + "\n")
    rng = random.Random(20261126)
    random_budget = rng.randint(50, 1000)
    random_lines = [f"{rng.randint(7, 100)} {random_budget}"]
    for _ in range(int(random_lines[0].split()[0])):
        random_lines.append(f"{rng.randint(1, 6)} {rng.randint(1, random_budget - 1)} {rng.randint(1, random_budget - 1)}")
    write("4_random", "\n".join(random_lines) + "\n")
    io_lines = ["100 1000"]
    for index in range(100):
        kind = index % 6 + 1
        price = 1 + (index * 11) % 180
        quality = 500 + (index * 7) % 500
        io_lines.append(f"{kind} {price} {quality}")
    write("5_io", "\n".join(io_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
