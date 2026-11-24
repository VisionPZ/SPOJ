#!/usr/bin/env python3
import random
import sys
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_longest_path(cases):
    results = []
    for count, intervals in cases:
        if count == 1:
            results.append(str(intervals[0][2]))
            continue
        max_coord = max(interval[1] for interval in intervals)
        size = max_coord + 2
        adj = [[] for _ in range(size)]
        for point in range(max_coord + 1):
            adj[point].append((point + 1, 0))
            adj[point + 1].append((point, -1))
        for left, right, demand in intervals:
            adj[left].append((right + 1, demand))
        dist = [-(10 ** 9)] * size
        dist[0] = 0
        queued = [False] * size
        queue = deque([0])
        queued[0] = True
        while queue:
            node = queue.popleft()
            queued[node] = False
            base = dist[node]
            for target, weight in adj[node]:
                candidate = base + weight
                if candidate > dist[target]:
                    dist[target] = candidate
                    if not queued[target]:
                        queued[target] = True
                        queue.append(target)
        results.append(str(dist[max_coord + 1]))
    return results


def oracle_brute(count, intervals):
    max_coord = max(interval[1] for interval in intervals)
    best = max_coord + 1
    for mask in range(1 << (max_coord + 1)):
        chosen = mask.bit_count()
        if chosen >= best:
            continue
        valid = True
        for left, right, demand in intervals:
            common = 0
            for point in range(left, right + 1):
                if mask >> point & 1:
                    common += 1
            if common < demand:
                valid = False
                break
        if valid:
            best = chosen
    return str(best)


def sample_cases():
    return [(5, [(3, 7, 3), (8, 10, 3), (6, 8, 1), (1, 3, 1), (10, 11, 1)])]


def write(name, cases):
    input_lines = [str(len(cases))]
    for count, intervals in cases:
        input_lines.append(str(count))
        for left, right, demand in intervals:
            input_lines.append(f"{left} {right} {demand}")
    input_text = "\n".join(input_lines) + "\n"
    output_text = "\n".join(oracle_longest_path(cases)) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


assert oracle_longest_path(sample_cases()) == ["6"]
assert oracle_longest_path([(1, [(0, 5, 1)]), (1, [(0, 5, 6)])]) == ["1", "6"]
assert oracle_longest_path([(2, [(0, 4, 5), (4, 8, 5)])]) == ["9"]
assert oracle_longest_path([(1, [(0, 50000, 50000)])]) == ["50000"]

random.seed(42002)
for _ in range(300):
    max_coord = random.randint(1, 8)
    count = random.randint(1, 7)
    intervals = []
    for _ in range(count):
        left = random.randint(0, max_coord)
        right = random.randint(left, max_coord)
        demand = random.randint(1, right - left + 1)
        intervals.append((left, right, demand))
    reference = oracle_brute(count, intervals)
    assert oracle_longest_path([(count, intervals)]) == [reference]


def build():
    write("2_edges", [
        (1, [(0, 0, 1)]),
        (1, [(7, 7, 1)]),
        (1, [(0, 5, 1)]),
        (1, [(0, 5, 6)]),
        (2, [(0, 4, 5), (4, 8, 5)]),
        (1, [(0, 50000, 50000)]),
        (3, [(0, 0, 1), (25000, 25000, 1), (50000, 50000, 1)]),
        (2, [(0, 9, 10), (9, 9, 1)]),
    ])

    random.seed(1604)
    wide_low = []
    wide_high = []
    for _ in range(50000):
        left = random.randint(0, 40000)
        right = random.randint(left, 50000)
        demand = random.randint(1, right - left + 1)
        wide_low.append((left, right, demand))
        left = random.randint(0, 100)
        right = random.randint(left, 50000)
        demand = random.randint(1, right - left + 1)
        wide_high.append((left, right, demand))
    write("3_wide", [(50000, wide_low), (50000, wide_high)])

    random.seed(99)
    random_cases = []
    for _ in range(3):
        count = random.randint(20000, 50000)
        intervals = []
        for _ in range(count):
            left = random.randint(0, 50000)
            right = random.randint(left, 50000)
            demand = random.randint(1, right - left + 1)
            intervals.append((left, right, demand))
        random_cases.append((count, intervals))
    write("4_random", random_cases)

    random.seed(77)
    io_cases = []
    for _ in range(200000):
        right = random.randint(1, 50000)
        left = random.randint(0, right)
        demand = random.randint(1, min(9, right - left + 1))
        io_cases.append((1, [(left, right, demand)]))
    write("5_io", io_cases)


def worked_trace():
    intervals = sorted(sample_cases()[0][1], key=lambda item: (item[1], -item[0]))
    chosen = []
    lines = []
    for left, right, demand in intervals:
        already = sum(1 for point in chosen if left <= point <= right)
        missing = max(0, demand - already)
        added = []
        while missing > 0:
            candidate = right
            while candidate in chosen:
                candidate -= 1
            chosen.append(candidate)
            added.append(str(candidate))
            missing -= 1
        lines.append(f"[{left},{right}] need {demand} have {already} add {','.join(added) or '-'}")
    lines.append(f"total {len(chosen)}")
    return "\n".join(lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", sample_cases())
build()
if "--trace" in sys.argv:
    print(worked_trace())
