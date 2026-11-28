#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def chain_search(prefix, start, end, turns_left, memo):
    key = (start, end, turns_left)
    if key in memo:
        return memo[key]
    if turns_left == 0 or start > end:
        memo[key] = 0
        return 0
    best = 0
    for split in range(start, end + 1):
        left_gain = prefix[split + 1] - prefix[start]
        right_gain = prefix[end + 1] - prefix[split]
        best = max(best, left_gain + chain_search(prefix, split + 1, end, turns_left - 1, memo))
        best = max(best, right_gain + chain_search(prefix, start, split - 1, turns_left - 1, memo))
    memo[key] = best
    return best


def oracle(text):
    tokens = iter(int(value) for value in text.split())
    lines = []
    case_number = 1
    while True:
        width = next(tokens)
        allowance = next(tokens)
        ball_count = next(tokens)
        if width == 0 and allowance == 0 and ball_count == 0:
            break
        money = [next(tokens) for _ in range(ball_count)]
        chains = [[] for _ in range(width)]
        for index, value in enumerate(money):
            chains[index % width].append(value)
        turn_limit = min(allowance, ball_count)
        progress = [0] * (turn_limit + 1)
        for chain in chains:
            if not chain:
                continue
            prefix = [0]
            for value in chain:
                prefix.append(prefix[-1] + value)
            last = len(chain) - 1
            per_turn = [chain_search(prefix, 0, last, turns, {}) for turns in range(turn_limit + 1)]
            updated = list(progress)
            for turns in range(turn_limit + 1):
                updated[turns] = max(updated[turns], progress[turns])
                if turns >= 1:
                    updated[turns] = max(updated[turns], progress[turns - 1] + per_turn[1])
                if turns >= 2:
                    updated[turns] = max(updated[turns], progress[turns - 2] + per_turn[2])
            progress = updated
        top = progress[turn_limit]
        used = next(turns for turns in range(turn_limit + 1) if progress[turns] == top)
        lines.append(f"Case#{case_number}: Jack wins ${top} out of {used} throws.")
        case_number += 1
    return "\n".join(lines) + "\n"


SAMPLE = """2 3 10
-1 3 2 5 1 -2 0 5 1 -3
2 3 14
-1 3 2 5 -5 -5 1 -2 0 5 -5 -5 1 -3
3 3 5
-1 -2 -3 -4 -5
1 2 6
-1 -1 10 10 -1 -1
0 0 0
"""
SAMPLE_OUT = """Case#1: Jack wins $15 out of 2 throws.
Case#2: Jack wins $10 out of 3 throws.
Case#3: Jack wins $0 out of 0 throws.
Case#4: Jack wins $18 out of 1 throws.
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1 1\n5\n0 0 0\n") == "Case#1: Jack wins $5 out of 1 throws.\n"
assert oracle("1 1 1\n-5\n0 0 0\n") == "Case#1: Jack wins $0 out of 0 throws.\n"
assert oracle("2 1 2\n5 -5\n0 0 0\n") == "Case#1: Jack wins $5 out of 1 throws.\n"
assert sum([1, 2, 3]) == 6


def build_case(width, allowance, money):
    lines = [f"{width} {allowance} {len(money)}",
             " ".join(str(value) for value in money), "0 0 0"]
    return "\n".join(lines) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "".join([
        build_case(1, 1, [5]),
        build_case(1, 1, [-5]),
        build_case(2, 3, [4, -4, 4, -4]),
        build_case(3, 2, [-1, -2, -3, -4, -5]),
        build_case(1, 9, list(range(-5, 6))),
    ]))
    rng = random.Random(20261126)
    wide = "".join(
        build_case(rng.randint(1, 12), rng.randint(1, 9),
                   [rng.randint(-1000000, 1000000) for _ in range(100)])
        for _ in range(8))
    write("3_wide", wide)
    random_cases = "".join(
        build_case(rng.randint(1, 7), rng.randint(1, 6),
                   [rng.randint(-1000000, 1000000) for _ in range(rng.randint(1, 40))])
        for _ in range(30))
    write("4_random", random_cases)
    io_cases = "".join(
        build_case(rng.randint(1, 3), rng.randint(1, 3),
                   [rng.randint(-100, 100) for _ in range(rng.randint(1, 8))])
        for _ in range(2000))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
