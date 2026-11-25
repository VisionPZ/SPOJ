#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 18


def brute(values, attacks):
    count = len(values)
    groups = attacks + 1

    def cost(left, right):
        block = values[left:right]
        total = sum(block)
        return (total * total - sum(value * value for value in block)) // 2

    table = [[INF] * (count + 1) for _ in range(groups + 1)]
    table[0][0] = 0
    for used in range(1, groups + 1):
        for filled in range(used, count + 1):
            best = INF
            for split in range(used - 1, filled):
                candidate = table[used - 1][split] + cost(split, filled)
                if candidate < best:
                    best = candidate
            table[used][filled] = best
    return table[groups][count]


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    attacks = int(tokens[1])
    values = [int(value) for value in tokens[2:2 + count]]
    prefix = [0]
    squares = [0]
    for value in values:
        prefix.append(prefix[-1] + value)
        squares.append(squares[-1] + value * value)

    def cost(split, filled):
        total = prefix[filled] - prefix[split]
        square_sum = squares[filled] - squares[split]
        return (total * total - square_sum) // 2

    groups = attacks + 1
    previous = [cost(0, filled) for filled in range(count + 1)]
    for used in range(2, groups + 1):
        current = [INF] * (count + 1)

        def solve(low, high, option_low, option_high):
            if low > high:
                return
            middle = (low + high) // 2
            best_value = INF
            best_split = option_low
            upper = min(option_high, middle - 1)
            for split in range(option_low, upper + 1):
                candidate = previous[split] + cost(split, middle)
                if candidate < best_value:
                    best_value = candidate
                    best_split = split
            current[middle] = best_value
            solve(low, middle - 1, option_low, best_split)
            solve(middle + 1, high, best_split, option_high)

        solve(used, count, used - 1, count - 1)
        previous = current
    return str(previous[count]) + "\n"


SAMPLE = """4
1
4 5 1 2
"""
SAMPLE_OUT = "17\n"
SECOND = """4
2
4 5 1 2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == "2\n"
assert oracle("1\n0\n20\n") == "0\n"
assert oracle("2\n0\n20 20\n") == "400\n"
assert oracle("2\n1\n20 20\n") == "0\n"
assert oracle("4\n3\n4 5 1 2\n") == "0\n"
for length in range(1, 9):
    for attacks in range(length):
        for _ in range(6):
            values = [random.Random(length * 100 + attacks * 10 + item).randint(0, 20)
                      for item in range(length)]
            text = str(length) + "\n" + str(attacks) + "\n" + " ".join(map(str, values)) + "\n"
            assert oracle(text) == str(brute(values, attacks)) + "\n"


def write(name, count, attacks, values):
    text = str(count) + "\n" + str(attacks) + "\n" + " ".join(map(str, values)) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 1, 0, [20])
    write("3_wide", 500, 250,
          [20 if index % 3 == 0 else index % 21 for index in range(500)])
    rng = random.Random(20261126)
    write("4_random", 40, 17, [rng.randint(0, 20) for _ in range(40)])
    write("5_io", 500, 100, [rng.randint(0, 20) for _ in range(500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
