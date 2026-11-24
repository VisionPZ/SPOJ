#!/usr/bin/env python3
import math
import random
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def gcd(a, b):
    return math.gcd(a, b)


def min_pair_gcd(periods, kept):
    if len(kept) == 1:
        return periods[kept[0]]
    return min(gcd(periods[a], periods[b]) for a, b in combinations(kept, 2))


def brute(periods, keep_count):
    total = len(periods)
    best_value = -1
    best_removal = None
    for kept in combinations(range(total), keep_count):
        value = min_pair_gcd(periods, kept)
        removal = tuple(i for i in range(total) if i not in kept)
        if value > best_value or (value == best_value and removal < best_removal):
            best_value = value
            best_removal = removal
    return best_value, best_removal


def oracle(periods, keep_count):
    total = len(periods)
    if keep_count == 1:
        keep = max(range(total), key=lambda i: (periods[i], i))
        return periods[keep], tuple(i for i in range(total) if i != keep)
    matrix = [[gcd(periods[i], periods[j]) for j in range(total)] for i in range(total)]
    pair_count = keep_count * (keep_count - 1) // 2
    all_gcds = sorted(matrix[i][j] for i in range(total) for j in range(i + 1, total))
    upper_bound = all_gcds[pair_count - 1]
    order = sorted(range(total), key=lambda i: (periods[i], i), reverse=True)
    seed = sorted(order[:keep_count])
    best_value = min_pair_gcd(periods, seed)
    infinity = 10 ** 30

    def search(idx, kept, running_min):
        nonlocal best_value
        if len(kept) == keep_count:
            if running_min > best_value:
                best_value = running_min
            return
        left = total - idx
        if len(kept) + left < keep_count:
            return
        if running_min != infinity and running_min <= best_value:
            return
        new_min = running_min
        for v in kept:
            if matrix[v][idx] < new_min:
                new_min = matrix[v][idx]
        if new_min > best_value or new_min == infinity:
            search(idx + 1, kept + [idx], new_min)
        search(idx + 1, kept, running_min)

    search(0, [], infinity)
    adjacency = [0] * total
    for i in range(total):
        for j in range(total):
            if i != j and matrix[i][j] >= best_value:
                adjacency[i] |= 1 << j
    removal = []

    def decide(idx, kept_mask, have, taken):
        if have == keep_count and taken == total - keep_count:
            return True
        left = total - idx
        if have + left < keep_count or taken + left < total - keep_count:
            return False
        if taken < total - keep_count and decide(idx + 1, kept_mask, have, taken + 1):
            removal.append(idx)
            return True
        if have < keep_count and (adjacency[idx] & kept_mask) == kept_mask:
            if decide(idx + 1, kept_mask | (1 << idx), have + 1, taken):
                return True
        return False

    assert decide(0, 0, 0, 0)
    return best_value, tuple(sorted(removal))


def worked_example():
    periods = [6, 13, 10, 15, 7]
    keep_count = 3
    lines = ["periods       : 6 13 10 15 7", "holidays kept : 3 of 5"]
    levels = sorted(set(gcd(periods[i], periods[j]) for i in range(5) for j in range(i + 1, 5)))
    lines.append("gcd levels    : " + " ".join(str(level) for level in levels))
    best_level = 0
    for level in levels:
        feasible = any(all(gcd(periods[a], periods[b]) >= level for a, b in combinations(kept, 2))
                       for kept in combinations(range(5), keep_count))
        lines.append(f"level {level} : " + ("clique of 3" if feasible else "none"))
        if feasible:
            best_level = level
    value, removal = oracle(periods, keep_count)
    kept = [i + 1 for i in range(5) if i not in removal]
    lines.append(f"best level    : {best_level}")
    lines.append("kept holidays : " + " ".join(str(i) for i in kept))
    lines.append("removed       : " + " ".join(str(i + 1) for i in removal))
    lines.append(f"shortest gap  : {value} days")
    return "\n".join(lines)


def solve_test(test):
    total, remove_count, periods = test
    keep_count = total - remove_count
    _, removal = oracle(periods, keep_count)
    return " ".join(str(i + 1) for i in removal) + "\n"


def render(pairs):
    text = str(len(pairs)) + "\n"
    for total, remove_count, periods in pairs:
        text += f"{total} {remove_count}\n"
        text += " ".join(str(value) for value in periods) + "\n"
    return text


def write(name, pairs):
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    input_text = render(pairs)
    output_text = "".join(solve_test(test) for test in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


SAMPLE = (5, 2, [6, 13, 10, 15, 7])
assert oracle([6, 13, 10, 15, 7], 3)[1] == (1, 4)
assert oracle([7, 7, 7, 7], 2)[0] == 7
assert oracle([2, 3, 5, 7], 2)[0] == 1
assert oracle([999999999999999999, 999999999999999997], 1)[0] == 999999999999999999

for trial in range(4000):
    total = random.randint(2, 9)
    keep_count = random.randint(1, total - 1)
    periods = [random.randint(1, 60) for _ in range(total)]
    assert oracle(periods, keep_count) == brute(periods, keep_count)


def build():
    edges = [
        (2, 1, [999999999999999999, 999999999999999997]),
        (3, 2, [10**18, 10**18 - 1, 7]),
        (4, 3, [2, 3, 5, 7]),
        (5, 4, [6, 6, 6, 6, 6]),
        (5, 1, [6, 10, 15, 21, 35]),
        (30, 29, list(range(1, 31))),
        (30, 1, [random.Random(11).randint(10**17, 10**18) for _ in range(30)]),
    ]
    write("2_edges", edges)

    wide_random = random.Random(13)
    wide = [
        (30, 1, [wide_random.randint(10**17, 10**18) for _ in range(30)]),
        (30, 15, [wide_random.randint(1, 10**18) for _ in range(30)]),
        (30, 29, [wide_random.randint(1, 10**18) for _ in range(30)]),
        (30, 15, [wide_random.randint(1, 1000) for _ in range(30)]),
    ]
    write("3_wide", wide)

    rand = random.Random(2026)
    random_pairs = []
    for _ in range(120):
        total = rand.randint(2, 30)
        remove_count = rand.randint(1, total - 1)
        ceiling = rand.choice([20, 1000, 10**9, 10**18])
        periods = [rand.randint(1, ceiling) for _ in range(total)]
        random_pairs.append((total, remove_count, periods))
    write("4_random", random_pairs)

    io_random = random.Random(77)
    io_pairs = []
    for _ in range(200):
        periods = [io_random.randint(10**17, 10**18) for _ in range(30)]
        io_pairs.append((30, 29, periods))
    write("5_io", io_pairs)


write("1_sample", [SAMPLE])
build()
