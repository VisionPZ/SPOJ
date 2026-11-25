#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


@lru_cache(maxsize=None)
def oracle(options_tuple, group_count):
    options = [list(group_set) for group_set in options_tuple]
    friend_count = len(options)
    best = friend_count + 1
    loads = [0] * group_count

    def search(friend_index):
        nonlocal best
        if friend_index == friend_count:
            if max(loads) < best:
                best = max(loads)
            return
        for group_index in options[friend_index]:
            loads[group_index] += 1
            if loads[group_index] < best:
                search(friend_index + 1)
            loads[group_index] -= 1

    search(0)
    return best


SAMPLE = """3 2 
John 0 1 
Rose 1 
Mary 1 
5 4 
ACM 1 2 3 
ICPC 0 1  
Asian 0 2 3 
Regional 1 2 
ShangHai 0 2 
0 0 
"""
SAMPLE_OUT = "2\n2\n"
assert oracle(((0, 1), (1,), (1,)), 2) == 2
assert oracle(((1, 2, 3), (0, 1), (0, 2, 3), (1, 2), (0, 2)), 4) == 2
assert oracle(((0,), (0,), (0,)), 2) == 3
assert oracle(((0,), (1,)), 2) == 1
assert oracle(((0, 1), (0, 1), (0, 1), (0, 1)), 2) == 2


def write(name, cases):
    chunks = []
    expected = []
    for options, group_count in cases:
        chunks.append(f"{len(options)} {group_count}\n")
        for friend_index, allowed_groups in enumerate(options):
            friend_name = "Name" + chr(ord("A") + friend_index)
            chunks.append(friend_name + " " + " ".join(str(group) for group in allowed_groups) + "\n")
        expected.append(str(oracle(tuple(tuple(groups) for groups in options), group_count)) + "\n")
    text = "".join(chunks) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(expected))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)

write("2_edges", [
    ([[0]], 1),
    ([[0], [0], [0]], 2),
    ([[0, 1], [0, 1], [0, 1], [0, 1]], 2),
    ([[0], [1], [2], [3]], 4),
])

rng = random.Random(20261202)


def random_case(friend_count, group_count, widest):
    options = []
    for _ in range(friend_count):
        allowed = rng.sample(range(group_count), rng.randint(1, min(group_count, widest)))
        options.append(sorted(allowed))
    return options, group_count


write("3_wide", [random_case(10, 4, 3) for _ in range(5)])

random_cases = []
for _ in range(30):
    friend_size = rng.randint(3, 9)
    group_size = rng.randint(2, 5)
    random_cases.append(random_case(friend_size, group_size, group_size))
write("4_random", random_cases)

write("5_io", [random_case(8, 4, 3) for _ in range(300)])
