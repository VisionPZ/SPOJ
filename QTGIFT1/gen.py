#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STRESS_PATH = Path("/tmp/QTGIFT1_big.txt")


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pack_count = tokens[0]
    skip_length = tokens[1]
    values = tokens[2:2 + pack_count]
    prefix = [0]
    for value in values:
        prefix.append(prefix[-1] + value)
    take = [0] * (pack_count + 1)
    gap = [0] * (pack_count + 1)
    for last in range(1, pack_count + 1):
        gap[last] = max(take[last - 1], gap[last - 1])
        choice = 0
        longest_block = min(skip_length - 1, last)
        for block_length in range(1, longest_block + 1):
            block_start = last - block_length
            candidate = gap[block_start] + prefix[last] - prefix[block_start]
            if candidate > choice:
                choice = candidate
        take[last] = choice
    return str(max(take[pack_count], gap[pack_count])) + "\n"


def brute(values, skip_length):
    pack_count = len(values)
    answer = 0
    for mask in range(1 << pack_count):
        run = 0
        valid = True
        for index in range(pack_count):
            if mask >> index & 1:
                run += 1
                if run >= skip_length:
                    valid = False
                    break
            else:
                run = 0
        if valid:
            answer = max(answer, sum(values[index] for index in range(pack_count)
                                     if mask >> index & 1))
    return answer


SAMPLE = "5 3\n6 19 8 7 13\n"
SAMPLE_OUT = "45\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n2000\n") == "0\n"
assert oracle("5 5\n1 2 3 4 5\n") == "14\n"
assert oracle("4 2\n0 2000 0 2000\n") == "4000\n"
assert oracle("5 3\n0 0 0 0 0\n") == "0\n"
for small_values in ([3, 1, 4], [0, 2, 0, 5], [7, 7, 7]):
    for small_skip in (1, 2, 3):
        small_text = f"{len(small_values)} {small_skip}\n" + \
            " ".join(str(value) for value in small_values) + "\n"
        assert oracle(small_text).strip() == str(brute(small_values, small_skip))


def write(name, pack_count, skip_length, values):
    text = f"{pack_count} {skip_length}\n" + " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 5, 5, [1, 2, 3, 4, 5])
    write("3_wide", 100000, 3, [2000 if index % 2 else 0 for index in range(100000)])
    rng = random.Random(20261126)
    values = [rng.randint(0, 2000) for _ in range(20000)]
    write("4_random", 20000, rng.randint(2, 6), values)
    write("5_io", 200000, 3, [2000] * 200000)
    stress_values = [2000 if index % 3 else 0 for index in range(1000000)]
    STRESS_PATH.write_text("1000000 3\n" + " ".join(str(value) for value in stress_values) + "\n")


def trace():
    values = [6, 19, 8, 7, 13]
    skip_length = 3
    pack_count = len(values)
    best_run = 0
    best_mask = 0
    for mask in range(1 << pack_count):
        run = 0
        valid = True
        for index in range(pack_count):
            if mask >> index & 1:
                run += 1
                if run >= skip_length:
                    valid = False
                    break
            else:
                run = 0
        if valid:
            taken = sum(values[index] for index in range(pack_count) if mask >> index & 1)
            if taken > best_run:
                best_run = taken
                best_mask = mask
    skips = [index for index in range(pack_count) if not (best_mask >> index & 1)]
    print(f"values: {values}  k: {skip_length}")
    print(f"total: {sum(values)}  chosen skips: {skips}")
    print(f"answer: {best_run}")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace()
