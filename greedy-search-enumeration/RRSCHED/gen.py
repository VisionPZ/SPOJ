#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(durations):
    remaining = list(durations)
    finished = [0] * len(remaining)
    elapsed = 0
    while any(remaining):
        for index, left in enumerate(remaining):
            if left > 0:
                elapsed += 1
                remaining[index] -= 1
                if remaining[index] == 0:
                    finished[index] = elapsed
    return finished


def oracle(text):
    tokens = [int(value) for value in text.split()]
    task_count = tokens[0]
    durations = tokens[1:1 + task_count]
    sorted_durations = sorted(durations)
    prefix = [0]
    for duration in sorted_durations:
        prefix.append(prefix[-1] + duration)
    seen = []
    answers = []
    for duration in durations:
        shorter = bisect.bisect_left(sorted_durations, duration)
        elapsed_before = prefix[shorter] + (task_count - shorter) * (duration - 1)
        rank = len(seen) - bisect.bisect_left(seen, duration)
        answers.append(str(elapsed_before + rank + 1))
        bisect.insort(seen, duration)
    return "\n".join(answers) + "\n"


SAMPLE = """5
8
1
3
3
8
"""
SAMPLE_OUT = """22
2
11
12
23
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute([8, 1, 3, 3, 8]) == [22, 2, 11, 12, 23]
assert oracle("1\n1\n") == "1\n"
assert oracle("3\n1 1 1\n") == "1\n2\n3\n"
assert oracle("2\n1000000000 1\n") == "1000000001\n2\n"
for trial in range(120):
    rng = random.Random(trial)
    durations = [rng.randint(1, 6) for _ in range(rng.randint(1, 8))]
    text = str(len(durations)) + "\n" + "\n".join(
        str(duration) for duration in durations) + "\n"
    expected = "\n".join(str(value) for value in brute(durations)) + "\n"
    assert oracle(text) == expected


def write(name, durations):
    text = str(len(durations)) + "\n" + "".join(
        f"{duration}\n" for duration in durations)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1])
    write("3_wide", [1000000000] * 50)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 1000000000) for _ in range(500)])
    write("5_io", [rng.randint(1, 1000000000) for _ in range(20000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8, 1, 3, 3, 8])
build()
