#!/usr/bin/env python3
import random
from collections import deque
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def flow_formula(job_counts):
    processor_count = len(job_counts)
    total = sum(job_counts)
    if total % processor_count:
        return -1
    target = total // processor_count
    running = 0
    largest = 0
    for jobs in job_counts[:-1]:
        running += jobs - target
        largest = max(largest, abs(running))
    return largest


def bfs_rounds(job_counts):
    processor_count = len(job_counts)
    total = sum(job_counts)
    if total % processor_count:
        return -1
    target = tuple([total // processor_count] * processor_count)
    start = tuple(job_counts)
    if start == target:
        return 0
    queue = deque([start])
    distance = {start: 0}
    while queue:
        state = queue.popleft()
        depth = distance[state]
        for moves in product((-1, 0, 1), repeat=processor_count - 1):
            following = list(state)
            sent = [0] * processor_count
            legal = True
            for edge, move in enumerate(moves):
                if move == 0:
                    continue
                source = edge if move == 1 else edge + 1
                if sent[source] >= state[source]:
                    legal = False
                    break
                sent[source] += 1
                following[source] -= 1
                following[2 * edge + 1 - source] += 1
            if not legal:
                continue
            next_state = tuple(following)
            if next_state == target:
                return depth + 1
            if next_state not in distance:
                distance[next_state] = depth + 1
                queue.append(next_state)
    return -1


def normalize(text):
    values = [int(token) for token in text.split()]
    blocks = []
    cursor = 0
    while cursor < len(values):
        processor_count = values[cursor]
        cursor += 1
        if processor_count == -1:
            break
        blocks.append(values[cursor:cursor + processor_count])
        cursor += processor_count
    return blocks


def oracle(text):
    answers = []
    for job_counts in normalize(text):
        if len(job_counts) <= 5 and max(job_counts) <= 12:
            answers.append(str(bfs_rounds(job_counts)))
        else:
            answers.append(str(flow_formula(job_counts)))
    if not answers:
        return ""
    return "\n".join(answers) + "\n"


SAMPLE_IN = """3
0 99 3

2
49 50

8
16 17 15 0 20 1 1 2

10
0 0 100 0 0 0 0 0 0 0

-1
"""
SAMPLE_OUT = """34
-1
23
70
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert flow_formula([0, 99, 3]) == 34
assert flow_formula([49, 50]) == -1
assert flow_formula([0, 0, 100, 0, 0, 0, 0, 0, 0, 0]) == 70
assert flow_formula([0, 3, 0]) == 1
assert bfs_rounds([0, 0, 6]) == 4
assert bfs_rounds([3, 0, 0]) == 2

check_rng = random.Random(7)
for _trial in range(200):
    sample_size = check_rng.randint(2, 4)
    sample_loads = [check_rng.randint(0, 7) for _ in range(sample_size)]
    assert bfs_rounds(sample_loads) == flow_formula(sample_loads), sample_loads


def write(name, blocks):
    pieces = []
    for job_counts in blocks:
        pieces.append(str(len(job_counts)) + "\n")
        pieces.append(" ".join(str(jobs) for jobs in job_counts) + "\n\n")
    pieces.append("-1\n")
    input_text = "".join(pieces)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def divisible_block(rng, processor_count, ceiling):
    while True:
        loads = [rng.randint(0, ceiling) for _ in range(processor_count)]
        if sum(loads) % processor_count == 0:
            return loads


def build():
    write("2_edges", [[0], [5, 5], [4, 2], [1, 1, 1], [7, 0, 0, 0, 1], [0, 0, 0]])
    write("3_wide", [[100000000, 0, 0, 0], [0, 0, 0, 120000000],
                     [9, 9, 9, 9, 9], [0, 0, 12]])
    rng = random.Random(20261126)
    write("4_random", [divisible_block(rng, rng.randint(2, 4), 24) for _ in range(120)])
    write("5_io", [divisible_block(rng, 3, 6) for _ in range(30000)])
    (Path("/tmp") / "BALIFE_big.txt").write_text(
        "9000\n" + " ".join(["0"] * 8999 + ["9000"]) + "\n-1\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[0, 99, 3], [49, 50], [16, 17, 15, 0, 20, 1, 1, 2],
                   [0, 0, 100, 0, 0, 0, 0, 0, 0, 0]])
build()
