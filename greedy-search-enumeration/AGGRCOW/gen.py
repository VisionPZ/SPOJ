#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute(stalls, cows):
    places = sorted(stalls)
    size = len(places)
    if cows == 1:
        return 0
    infinite = 10**18
    table = [[-1] * size for _ in range(cows + 1)]
    for last in range(size):
        table[1][last] = infinite
    for used in range(2, cows + 1):
        for last in range(used - 1, size):
            best = -1
            for prev in range(used - 2, last):
                if table[used - 1][prev] < 0:
                    continue
                candidate = min(table[used - 1][prev], places[last] - places[prev])
                if candidate > best:
                    best = candidate
            table[used][last] = best
    return max(table[cows][size - cows:])


def max_cows(places, gap):
    tally = [1] * len(places)
    prefix = 0
    walk = 0
    for here, position in enumerate(places):
        bound = position - gap
        while walk < here and places[walk] <= bound:
            if tally[walk] > prefix:
                prefix = tally[walk]
            walk += 1
        tally[here] = prefix + 1
    return max(tally)


def oracle_solve(stalls, cows):
    places = sorted(stalls)
    if cows <= 1:
        return 0
    low = 0
    high = places[-1] - places[0] + 1
    while low < high:
        middle = (low + high + 1) // 2
        if max_cows(places, middle) >= cows:
            low = middle
        else:
            high = middle - 1
    return low


def oracle(text):
    tokens = text.split()
    cursor = 0
    cases = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(cases):
        stalls = int(tokens[cursor]); cursor += 1
        cows = int(tokens[cursor]); cursor += 1
        positions = [int(tokens[cursor + i]) for i in range(stalls)]
        cursor += stalls
        answers.append(str(oracle_solve(positions, cows)))
    return "\n".join(answers) + "\n"


def write(name, cases):
    parts = [str(len(cases)) + "\n"]
    for stalls, cows, positions in cases:
        parts.append(f"{stalls} {cows}\n")
        parts.extend(f"{position}\n" for position in positions)
    input_text = "".join(parts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(5, 3, [1, 2, 8, 4, 9])]
assert oracle_solve([1, 2, 8, 4, 9], 3) == 3
assert oracle_solve([4, 5, 6, 7, 8], 3) == 2
assert brute([1, 2, 8, 4, 9], 3) == 3
assert brute([4, 5, 6, 7, 8], 3) == 2
assert oracle_solve([0, 0, 0, 10], 2) == 10
assert oracle_solve([0, 1, 10**9], 3) == 1
assert oracle("1\n5 3\n1\n2\n8\n4\n9\n") == "3\n"


def build():
    edges = [
        (2, 2, [0, 1]),
        (2, 2, [5, 5]),
        (2, 2, [0, 10**9]),
        (5, 5, [0, 1, 2, 3, 4]),
        (5, 2, [0, 0, 0, 0, 10]),
        (3, 2, [0, 1, 10**9]),
        (3, 3, [0, 1, 10**9]),
        (10, 2, [10**9] * 10),
        (4, 3, [0, 3, 6, 9]),
        (4, 3, [0, 3, 6, 7]),
        (5, 4, [0, 2, 4, 6, 8]),
        (7, 4, [0, 0, 1, 1, 2, 2, 10**9]),
    ]
    write("2_edges", edges)

    full = list(range(100000))
    even = [2 * i for i in range(100000)]
    wide = [
        (100000, 2, full),
        (100000, 100000, full),
        (100000, 50000, even),
        (100000, 2, full[:-1] + [10**9]),
    ]
    write("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(80):
        size = rng.randint(2, 5000)
        cows = rng.randint(2, size)
        span = rng.choice([20, 1000, 10**6, 10**9])
        positions = [rng.randint(0, span) for _ in range(size)]
        random_cases.append((size, cows, positions))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(20000):
        first = rng.randint(0, 10**9)
        second = rng.randint(0, 10**9)
        third = rng.randint(0, 10**9)
        io_cases.append((3, 2, [first, second, third]))
    write("5_io", io_cases)

    for _ in range(300):
        size = rng.randint(2, 12)
        cows = rng.randint(2, size)
        positions = [rng.randint(0, 40) for _ in range(size)]
        assert oracle_solve(positions, cows) == brute(positions, cows)


def worked_example():
    places = sorted(SAMPLE[0][2])
    print("| Gap | Placed stalls | Cow count |")
    print("| --- | --- | --- |")
    for gap in (2, 3, 4):
        chosen = [places[0]]
        for position in places[1:]:
            if position - chosen[-1] >= gap:
                chosen.append(position)
        print(f"| {gap} | {', '.join(str(value) for value in chosen)} | {len(chosen)} |")


worked_example()

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
