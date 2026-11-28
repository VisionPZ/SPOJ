#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def brute(values):
    count = len(values)
    answer = 0
    for first in range(count):
        for last in range(first, count):
            left_min = min(values[first:last + 1])
            for right_first in range(last + 1, count):
                right_min = values[right_first]
                for right_last in range(right_first, count):
                    right_min = min(right_min, values[right_last])
                    if left_min <= right_min:
                        answer += 1
    return answer % MOD


def oracle(values):
    count = len(values)
    distinct = sorted(set(values))
    ranks = {value: index + 1 for index, value in enumerate(distinct)}
    ranked = [ranks[value] for value in values]
    rank_count = len(distinct) + 2

    right_values = []
    right_counts = []
    right_head = [0] * (count + 2)
    right_tail = [0] * (count + 2)
    stack = []
    written = 0
    for position in range(count - 1, -1, -1):
        current = ranked[position]
        group = 1
        while stack and stack[-1][0] > current:
            group += stack[-1][1]
            stack.pop()
        stack.append((current, group))
        right_head[position] = written
        for value, group_count in stack:
            right_values.append(value)
            right_counts.append(group_count)
            written += 1
        right_tail[position] = written

    frequency = [0] * (rank_count + 2)
    stack = []
    answer = 0
    for boundary in range(1, count):
        current = ranked[boundary - 1]
        group = 1
        while stack and stack[-1][0] > current:
            group += stack[-1][1]
            stack.pop()
        stack.append((current, group))
        for value_rank, group_count in stack:
            frequency[value_rank] += group_count
        prefix = [0] * (rank_count + 2)
        for value_rank in range(1, rank_count + 1):
            prefix[value_rank] = prefix[value_rank - 1] + frequency[value_rank]
        for index in range(right_head[boundary], right_tail[boundary]):
            answer += right_counts[index] * prefix[right_values[index]]
        answer %= MOD
    return answer


def input_text(values):
    return str(len(values)) + "\n" + " ".join(str(value) for value in values) + "\n"


SAMPLE = [5, 3, 0, 9, 8]
assert oracle(SAMPLE) == 21
assert brute(SAMPLE) == 21
assert oracle([7]) == 0
assert brute([7]) == 0
assert oracle([1, 1]) == 1
assert brute([1, 1]) == 1
assert oracle([2, 1]) == 0
assert brute([2, 1]) == 0
assert oracle([1, 2]) == 1
assert brute([1, 2]) == 1

check_rng = random.Random(91)
for trial in range(300):
    size = check_rng.randint(1, 9)
    values = [check_rng.randint(0, 4) for _ in range(size)]
    assert oracle(values) == brute(values), (trial, values)


def build():
    write("2_edges", [1, 1, 1, 1, 2, 1])
    rng = random.Random(20261126)
    write("3_wide", [rng.randint(0, 10**9) for _ in range(200)])
    write("4_random", [rng.randint(0, 1000) for _ in range(300)])
    write("5_io", [rng.randint(0, 10**9) for _ in range(300)])


def write(name, values):
    text = input_text(values)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(str(oracle(values)) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
