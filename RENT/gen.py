#!/usr/bin/env python3
import bisect
import random
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def make_text(cases):
    lines = [str(len(cases))]
    for orders in cases:
        lines.append(str(len(orders)))
        for start, duration, price in orders:
            lines.append(f"{start} {duration} {price}")
    return "\n".join(lines) + "\n"


def to_intervals(orders):
    return [(start, start + duration, price) for start, duration, price in orders]


def solve_intervals(intervals):
    if not intervals:
        return 0
    jobs_at_start = defaultdict(list)
    for start, finish, price in intervals:
        jobs_at_start[start].append((finish, price))
    starts = sorted(jobs_at_start)
    size = len(starts)
    best = [0] * size
    for position in range(size - 1, -1, -1):
        local_best = 0
        for finish, price in jobs_at_start[starts[position]]:
            next_position = bisect.bisect_left(starts, finish)
            tail = best[next_position] if next_position < size else 0
            if price + tail > local_best:
                local_best = price + tail
        later = best[position + 1] if position + 1 < size else 0
        best[position] = local_best if local_best > later else later
    return best[0]


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        order_count = int(tokens[cursor])
        cursor += 1
        intervals = []
        for _ in range(order_count):
            start = int(tokens[cursor])
            cursor += 1
            duration = int(tokens[cursor])
            cursor += 1
            price = int(tokens[cursor])
            cursor += 1
            intervals.append((start, start + duration, price))
        answers.append(str(solve_intervals(intervals)))
    return "\n".join(answers) + "\n"


def brute_force(intervals):
    count = len(intervals)
    best = 0
    for mask in range(1 << count):
        chosen = [intervals[index] for index in range(count) if mask >> index & 1]
        valid = True
        for left in range(len(chosen)):
            for right in range(left + 1, len(chosen)):
                if chosen[left][1] > chosen[right][0] and chosen[right][1] > chosen[left][0]:
                    valid = False
                    break
            if not valid:
                break
        if valid:
            total = sum(item[2] for item in chosen)
            if total > best:
                best = total
    return best


def write(name, cases):
    input_text = make_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_CASES = [[(0, 5, 10), (3, 7, 14), (5, 9, 7), (6, 9, 8)]]

assert oracle(make_text(SAMPLE_CASES)) == "18\n"
assert oracle(make_text([[(0, 5, 10)]])) == "10\n"
assert oracle(make_text([[(0, 5, 10), (5, 9, 7)]])) == "17\n"
assert oracle(make_text([[(0, 5, 10), (4, 9, 20)]])) == "20\n"

random.seed(31415)
for _ in range(300):
    count = random.randint(1, 12)
    orders = []
    for _ in range(count):
        start = random.randint(0, 30)
        duration = random.randint(1, 12)
        price = random.randint(1, 100)
        orders.append((start, duration, price))
    intervals = to_intervals(orders)
    assert solve_intervals(intervals) == brute_force(intervals)


def build():
    write("2_edges", [
        [(0, 5, 10)],
        [(999999, 1, 99999)],
        [(0, 999999, 99999)],
        [(0, 5, 10), (5, 9, 7)],
        [(0, 5, 10), (4, 9, 20)],
        [(0, 5, 10), (5, 9, 7), (6, 9, 8)],
        [(0, 1, 5)] * 14,
        [(index, 1, index + 1) for index in range(100)],
        [(index, 1, 100 - index) for index in range(100)],
        [(0, 999999, 99999), (999999, 1, 99999)],
    ])

    random.seed(9001)
    low = []
    high = []
    chain = []
    spread = []
    for index in range(10000):
        low.append((0, random.randint(1, 999999), random.randint(1, 99999)))
        high.append((999999, 1, random.randint(1, 99999)))
        chain.append((index, 1, random.randint(1, 99999)))
        start = random.randint(0, 999999)
        duration = random.randint(1, 100)
        if start + duration > 1000000:
            duration = 1000000 - start
        spread.append((start, duration, random.randint(1, 99999)))
    write("3_wide", [low, high, chain, spread])

    random.seed(2718)
    random_cases = []
    for _ in range(5):
        orders = []
        for _ in range(10000):
            start = random.randint(0, 999999)
            duration = random.randint(1, 999999)
            price = random.randint(1, 99999)
            orders.append((start, duration, price))
        random_cases.append(orders)
    write("4_random", random_cases)

    random.seed(1618)
    io_cases = []
    for _ in range(30):
        orders = []
        for _ in range(10000):
            start = random.randint(0, 999999)
            duration = random.randint(1, 999999)
            price = random.randint(1, 99999)
            orders.append((start, duration, price))
        io_cases.append(orders)
    write("5_io", io_cases)


def worked_trace():
    intervals = sorted(to_intervals(SAMPLE_CASES[0]), key=lambda item: (item[1], item[0]))
    finishes = [item[1] for item in intervals]
    best = [0]
    lines = []
    for index, (start, finish, price) in enumerate(intervals):
        compatible = bisect.bisect_right(finishes, start)
        take = price + best[compatible]
        skip = best[index]
        chosen = take if take > skip else skip
        best.append(chosen)
        lines.append(f"order {index + 1} finish {finish} price {price} compatible {compatible} take {take} skip {skip} best {chosen}")
    lines.append(f"answer {best[-1]}")
    return "\n".join(lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_CASES)
build()
if "--trace" in sys.argv:
    print(worked_trace())
