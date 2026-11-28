#!/usr/bin/env python3
import random
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_force(total, capacity, checkpoints, max_returns):
    goal = checkpoints + 1
    start = (total,) + (0,) * (checkpoints + 1) + (0, 0, 0)
    visited = {start}
    queue = deque([start])
    best = 0
    while queue:
        state = queue.popleft()
        depots = list(state[:goal + 1])
        position, load, returns = state[goal + 1:]
        best = max(best, depots[goal])

        def push(new_depots, new_position, new_load, new_returns):
            next_state = tuple(new_depots) + (new_position, new_load, new_returns)
            if next_state not in visited:
                visited.add(next_state)
                queue.append(next_state)

        for amount in range(1, min(capacity - load, depots[position]) + 1):
            changed = depots[:]
            changed[position] -= amount
            push(changed, position, load + amount, returns)
        for amount in range(1, load + 1):
            changed = depots[:]
            changed[position] += amount
            push(changed, position, load - amount, returns)
        if position < goal:
            new_position = position + 1
            new_load = load
            if 1 <= new_position <= checkpoints and new_load >= 1:
                new_load -= 1
            push(depots, new_position, new_load, returns)
        if position > 0:
            new_position = position - 1
            if new_position == 0:
                if returns + 1 > max_returns:
                    continue
                new_returns = returns + 1
            else:
                new_returns = returns
            new_load = load
            if 1 <= new_position <= checkpoints and new_load >= 1:
                new_load -= 1
            push(depots, new_position, new_load, new_returns)
    return best


def can_deliver(needed, capacity, checkpoints, limit):
    if capacity == 1:
        return checkpoints == 0 and needed <= limit
    current = needed
    while checkpoints > 0 and current <= limit:
        trips = (current + capacity - 2) // (capacity - 1)
        band_top = trips * (capacity - 1)
        steps = (band_top - current) // trips + 1
        if steps > checkpoints:
            steps = checkpoints
        current += steps * trips
        checkpoints -= steps
    return checkpoints == 0 and current <= limit


def oracle(text):
    total, capacity, checkpoints, returns = (int(value) for value in text.split())
    departures = returns + 1
    leaving_depot = min(total, capacity * departures)
    first_bribes = (leaving_depot + capacity - 1) // capacity
    limit = leaving_depot - first_bribes
    lower, upper = 0, limit
    while lower < upper:
        middle = (lower + upper + 1) // 2
        if can_deliver(middle, capacity, max(checkpoints - 1, 0), limit):
            lower = middle
        else:
            upper = middle - 1
    return str(lower) + "\n"


SAMPLE = "4000 1000 1000 1\n"
assert oracle(SAMPLE) == "500\n"
assert brute_force(3, 2, 1, 0) == 1
assert brute_force(10, 3, 2, 1) == 2
assert brute_force(4, 2, 1, 0) == 1
assert oracle("3 2 1 0\n") == "1\n"
assert oracle("10 3 2 1\n") == "2\n"
assert oracle("1 1 100 0\n") == "0\n"


def write(name, total, capacity, checkpoints, returns):
    text = "%d %d %d %d\n" % (total, capacity, checkpoints, returns)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 1, 1, 0)
    write("3_wide", 10 ** 18, 10 ** 9, 10 ** 6, 0)
    rng = random.Random(20261126)
    for _ in range(30):
        total = rng.randint(1, 8)
        capacity = rng.randint(1, 3)
        checkpoints = rng.randint(1, 3)
        returns = rng.randint(0, 2)
        text = "%d %d %d %d\n" % (total, capacity, checkpoints, returns)
        assert oracle(text) == "%d\n" % brute_force(total, capacity, checkpoints, returns)
    write("4_random", 97, 7, 3, 3)
    write("5_io", 10 ** 18, 10 ** 18, 1000, 0)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 4000, 1000, 1000, 1)
build()
