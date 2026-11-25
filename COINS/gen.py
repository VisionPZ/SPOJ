#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_force(limit):
    table = [0] * (limit + 1)
    table[1] = 1
    for value in range(2, limit + 1):
        table[value] = max(value, table[value // 2] + table[value // 3] + table[value // 4])
    return table


def oracle(coin_numbers):
    reachable = set()
    pending = list(coin_numbers)
    while pending:
        value = pending.pop()
        if value <= 1 or value in reachable:
            continue
        reachable.add(value)
        pending.append(value // 2)
        pending.append(value // 3)
        pending.append(value // 4)
    table = {0: 0, 1: 1}
    for value in sorted(reachable):
        table[value] = max(value, table[value // 2] + table[value // 3] + table[value // 4])
    return [table[value] for value in coin_numbers]


assert oracle([0, 1, 2, 12, 24]) == [0, 1, 2, 13, 27]
assert oracle([10**9]) == [4243218150]
small = brute_force(5000)
probes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 24, 100, 999, 4999]
assert oracle(probes) == [small[value] for value in probes]
assert oracle([12, 2]) == [13, 2]


def write(name, values):
    input_text = "".join(f"{value}\n" for value in values)
    answer_text = "".join(f"{answer}\n" for answer in oracle(values))
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(answer_text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

(ROOT / "in" / "1_sample.txt").write_text("12\n2\n")
(ROOT / "out" / "1_sample.out").write_text("13\n2\n")

write("2_edges", [0, 1, 2, 3, 4, 5, 6, 8, 12, 24])
write("3_wide", [10**9, 999999999, 999999937, 500000000, 1000000, 999999, 7, 1, 0, 2])

rng = random.Random(20261125)
write("4_random", [rng.randint(0, 10**9) for _ in range(10)])
write("5_io", [10**9] * 10)

print("generated five test pairs")
