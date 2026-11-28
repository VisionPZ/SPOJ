#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(goal, rounds, initial, round_times):
    experience = list(initial)
    winner = None
    for index, value in enumerate(experience):
        if value >= goal:
            winner = (index + 1, 0)
            break
    if winner is not None:
        return winner, experience
    for round_number, times in enumerate(round_times[:rounds], start=1):
        chosen = []
        other = []
        for team in range(3):
            lower = team * 2
            higher = team * 2 + 1
            if times[lower] <= times[higher]:
                chosen.append(lower)
                other.append(higher)
            else:
                chosen.append(higher)
                other.append(lower)
        groups = [chosen, other]
        starts = [max(times[player] for player in group) for group in groups]
        properties = []
        for start in starts:
            stun_count = (240 - start) // 7
            leftover = 240 - start - 7 * stun_count
            properties.append((start, stun_count, leftover))
        for second in range(1, 241):
            crossed = []
            for group_index, group in enumerate(groups):
                start, stun_count, leftover = properties[group_index]
                reward = 0
                if start < second <= start + 7 * stun_count and (second - start) % 7 == 0:
                    reward = 300
                elif second == 240 and leftover >= 2:
                    reward = 1800
                if reward == 0:
                    continue
                for player in group:
                    experience[player] += reward
            for index, value in enumerate(experience):
                if value >= goal:
                    crossed.append(index)
            if crossed:
                winner = (min(crossed) + 1, round_number)
                break
        if winner is not None:
            break
    return winner, experience


def oracle(text):
    tokens = [int(value) for value in text.split()]
    pos = 0
    lines = []
    while True:
        goal = tokens[pos]
        rounds = tokens[pos + 1]
        pos += 2
        if goal == 0 and rounds == 0:
            break
        initial = tokens[pos:pos + 6]
        pos += 6
        round_times = []
        for _ in range(rounds):
            round_times.append(tokens[pos:pos + 6])
            pos += 6
        winner, experience = oracle_case(goal, rounds, initial, round_times)
        if winner is None:
            lines.append("-1 " + " ".join(str(value) for value in experience))
        else:
            lines.append(f"{winner[0]} {winner[1]}")
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """10000 1
1000 12345 50000 9000 100 1
30 10 20 20 10 30
650000 1
100 200 300 400 500 600
20 10 30 20 20 30
0 0
"""
SAMPLE_OUT = """2 0
-1 9100 11300 9300 11500 11600 9600
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1 0 0 0 0 0\n1 2 3 4 5 6\n0 0\n") == "1 0\n"
assert oracle("301 1\n0 0 0 0 0 0\n1 2 3 4 5 6\n0 0\n") == "1 1\n"
assert oracle("1800 1\n0 0 0 0 0 0\n239 239 239 239 239 239\n0 0\n") == "-1 0 0 0 0 0 0\n"
assert oracle("1800 1\n0 0 0 0 0 0\n238 238 238 238 238 238\n0 0\n") == "1 1\n"
assert 31 * 300 + 1800 == 11100


def write_case(name, cases):
    text = ""
    for goal, rounds, initial, round_times in cases:
        text += f"{goal} {rounds}\n"
        text += " ".join(str(value) for value in initial) + "\n"
        for times in round_times:
            text += " ".join(str(value) for value in times) + "\n"
    text += "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [
        (1, 1, [1, 0, 0, 0, 0, 0], [[1, 2, 3, 4, 5, 6]]),
        (301, 1, [0, 0, 0, 0, 0, 0], [[1, 2, 3, 4, 5, 6]]),
        (1800, 1, [0, 0, 0, 0, 0, 0], [[239, 239, 239, 239, 239, 239]]),
        (1800, 1, [0, 0, 0, 0, 0, 0], [[238, 238, 238, 238, 238, 238]]),
        (650000, 2, [0, 0, 0, 0, 0, 0], [[30, 10, 20, 20, 10, 30], [20, 10, 30, 20, 20, 30]]),
    ])
    rng = random.Random(20261126)
    wide_times = [[rng.randint(1, 239) for _ in range(6)] for _ in range(1000)]
    write_case("3_wide", [(650000, 1000, [0, 0, 0, 0, 0, 0], wide_times)])
    random_cases = []
    for _ in range(20):
        goal = rng.choice([300, 3000, 10000, 650000])
        rounds = rng.randint(1, 30)
        initial = [rng.randint(0, 20000) for _ in range(6)]
        times = [[rng.randint(1, 239) for _ in range(6)] for _ in range(rounds)]
        random_cases.append((goal, rounds, initial, times))
    write_case("4_random", random_cases)
    io_cases = []
    for _ in range(12000):
        goal = rng.choice([300, 600, 1800, 650000])
        initial = [rng.randint(0, 500) for _ in range(6)]
        times = [[rng.randint(1, 239) for _ in range(6)]]
        io_cases.append((goal, 1, initial, times))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", [
    (10000, 1, [1000, 12345, 50000, 9000, 100, 1], [[30, 10, 20, 20, 10, 30]]),
    (650000, 1, [100, 200, 300, 400, 500, 600], [[20, 10, 30, 20, 20, 30]]),
])
build()
