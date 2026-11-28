#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def brute_force(part_count, limit):
    found = 0

    def extend(start, remaining, picked):
        nonlocal found
        if picked == part_count:
            found += 1
            return
        for value in range(start, remaining + 1):
            extend(value + 1, remaining - value, picked + 1)

    extend(1, limit, 0)
    return found % MOD


def oracle(text):
    tokens = [int(value) for value in text.split()]
    test_count = tokens[0]
    queries = [(tokens[1 + 2 * index], tokens[2 + 2 * index])
               for index in range(test_count)]
    largest_size = max((size for size, _ in queries), default=0)
    largest_limit = max((limit for _, limit in queries), default=0)
    table = [[0] * (largest_limit + 1) for _ in range(largest_size + 1)]
    table[0][0] = 1
    for parts in range(1, largest_size + 1):
        previous = table[parts - 1]
        current = table[parts]
        for total in range(largest_limit + 1):
            current[total] = previous[total]
            if total >= parts:
                current[total] = (current[total] + current[total - parts]) % MOD
    answers = []
    for size, limit in queries:
        spare = limit - size * (size + 1) // 2
        if spare < 0:
            answers.append("0")
        else:
            answers.append(str(sum(table[size][:spare + 1]) % MOD))
    return "\n".join(answers) + "\n"


SAMPLE = "4\n6 16\n4 16\n1 14\n3 7\n"
SAMPLE_OUT = "0\n27\n14\n2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force(6, 16) == 0
assert brute_force(4, 16) == 27
assert brute_force(1, 14) == 14
assert brute_force(3, 7) == 2
for size, limit in [(1, 3), (2, 7), (3, 12), (4, 16), (5, 20)]:
    assert oracle(f"1\n{size} {limit}\n") == str(brute_force(size, limit)) + "\n"


def write(name, queries):
    text = str(len(queries)) + "\n" + "".join(
        f"{size} {limit}\n" for size, limit in queries)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 2), (20, 210), (20, 209), (2, 3), (5, 15)])
    write("3_wide", [(20, 100000), (15, 100000), (10, 100000)])
    rng = random.Random(20261126)
    random_queries = []
    for _ in range(40):
        size = rng.randint(1, 20)
        smallest = size * (size + 1) // 2
        random_queries.append((size, smallest + rng.randint(0, 5000)))
    write("4_random", random_queries)
    io_queries = []
    for _ in range(1000):
        size = rng.randint(1, 20)
        smallest = size * (size + 1) // 2
        io_queries.append((size, smallest + rng.randint(0, 2000)))
    write("5_io", io_queries)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(6, 16), (4, 16), (1, 14), (3, 7)])
build()
