#!/usr/bin/env python3
import heapq
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(floor_total, elevators, gifts):
    gift_total = len(gifts)
    full_mask = (1 << gift_total) - 1
    start_state = (0, 0, 0)
    best = {start_state: 0}
    heap = [(0, start_state)]
    while heap:
        cost, state = heapq.heappop(heap)
        if cost != best[state]:
            continue
        floor, position, collected = state
        if collected == full_mask and position == 0:
            return cost
        if position != 0:
            row, col = gifts[position - 1][1], gifts[position - 1][2]
            next_state = (floor, 0, collected)
            next_cost = cost + row + col
            if next_cost < best.get(next_state, 10**18):
                best[next_state] = next_cost
                heapq.heappush(heap, (next_cost, next_state))
        for gift_index, (gift_floor, gift_row, gift_col) in enumerate(gifts):
            if collected & (1 << gift_index) or gift_floor != floor:
                continue
            if position == 0:
                current_row, current_col = 0, 0
            else:
                current_row = gifts[position - 1][1]
                current_col = gifts[position - 1][2]
            step = abs(current_row - gift_row) + abs(current_col - gift_col)
            next_state = (floor, gift_index + 1, collected | (1 << gift_index))
            next_cost = cost + step
            if next_cost < best.get(next_state, 10**18):
                best[next_state] = next_cost
                heapq.heappush(heap, (next_cost, next_state))
        if position == 0:
            for offset in elevators:
                next_floor = floor + offset
                if 0 <= next_floor < floor_total:
                    next_state = (next_floor, 0, collected)
                    next_cost = cost + 1
                    if next_cost < best.get(next_state, 10**18):
                        best[next_state] = next_cost
                        heapq.heappush(heap, (next_cost, next_state))
    return -1


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    lines = []
    for case_number in range(1, case_count + 1):
        floor_total = tokens[position]
        elevator_total = tokens[position + 1]
        gift_total = tokens[position + 2]
        grid_size = tokens[position + 3]
        position += 4
        elevators = tokens[position:position + elevator_total]
        position += elevator_total
        gifts = []
        for _ in range(gift_total):
            gifts.append(tuple(tokens[position:position + 3]))
            position += 3
        answer = oracle_case(floor_total, elevators, gifts)
        lines.append(f"Scenario #{case_number}: {answer}")
    return "\n".join(lines) + "\n"


SAMPLE = """5
5 1 1 1
1
3 0 0
5 3 1 1
1
4
-1
3 0 0
5 1 2 1
1
2 0 0
4 0 0
10 3 2 1
1
8
-2
4 0 0
6 0 0
5 3 3 5
1
2
-1
2 1 3
2 4 1
2 3 4
"""
SAMPLE_OUT = """Scenario #1: 3
Scenario #2: 2
Scenario #3: 4
Scenario #4: 3
Scenario #5: 17
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(5, [1], [(3, 0, 0)]) == 3
assert oracle_case(5, [1, 4, -1], [(3, 0, 0)]) == 2
assert oracle_case(3, [1], [(2, 0, 0), (1, 0, 0)]) == 2
assert oracle_case(5, [2], [(2, 1, 1)]) == 5


def write(name, cases):
    pieces = [str(len(cases)) + "\n"]
    for floor_total, elevators, gifts, grid_size in cases:
        pieces.append(f"{floor_total} {len(elevators)} {len(gifts)} {grid_size}\n")
        pieces.extend(str(offset) + "\n" for offset in elevators)
        pieces.extend(f"{floor} {row} {col}\n" for floor, row, col in gifts)
    text = "".join(pieces)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (5, [1], [(3, 0, 0)], 1),
        (3, [1], [(1, 0, 0)], 5),
        (10, [2, -2], [(4, 0, 0), (6, 0, 0)], 1),
        (5, [2], [(2, 2, 3)], 5),
    ])
    write("3_wide", [(1000, [1, 250, -3], [(500, 0, 0), (900, 10, 20)], 1000)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(20):
        floor_total = rng.randint(2, 100)
        elevators = [1]
        for _ in range(rng.randint(0, 4)):
            offset = rng.randint(-floor_total + 1, floor_total - 1)
            if offset != 0:
                elevators.append(offset)
        grid_size = rng.randint(1, 20)
        gift_total = rng.randint(1, 5)
        gifts = []
        for _ in range(gift_total):
            gifts.append((rng.randint(1, floor_total - 1),
                          rng.randint(0, grid_size - 1),
                          rng.randint(0, grid_size - 1)))
        random_cases.append((floor_total, elevators, gifts, grid_size))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(10):
        floor_total = rng.randint(50, 200)
        elevators = [1, -1, rng.randint(1, floor_total - 1)]
        grid_size = rng.randint(1, 1000)
        gifts = [(rng.randint(1, floor_total - 1),
                  rng.randint(0, grid_size - 1),
                  rng.randint(0, grid_size - 1)) for _ in range(5)]
        io_cases.append((floor_total, elevators, gifts, grid_size))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
sample_cases = [
    (5, [1], [(3, 0, 0)], 1),
    (5, [1, 4, -1], [(3, 0, 0)], 1),
    (5, [1], [(2, 0, 0), (4, 0, 0)], 1),
    (10, [1, 8, -2], [(4, 0, 0), (6, 0, 0)], 1),
    (5, [1, 2, -1], [(2, 1, 3), (2, 4, 1), (2, 3, 4)], 5),
]
write("1_sample", sample_cases)
assert oracle((ROOT / "in" / "1_sample.txt").read_text()) == SAMPLE_OUT
build()
