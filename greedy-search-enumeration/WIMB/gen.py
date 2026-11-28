#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RESULT_CACHE = {}


def solved_values(first_percent, second_percent):
    first_serve = first_percent / 100.0
    second_serve = second_percent / 100.0

    def winner(first_games, second_games, first_won):
        if first_won:
            first_games += 1
        else:
            second_games += 1
        if first_games >= 6 and first_games - second_games >= 2:
            return 1
        if second_games >= 6 and second_games - first_games >= 2:
            return 2
        if first_games == 7 and second_games == 6:
            return 1
        if second_games == 7 and first_games == 6:
            return 2
        return 0

    def progress(state):
        first_games, second_games, first_sets, second_sets, _ = state
        return 20 * (first_sets + second_sets) + first_games + second_games

    all_states = [
        (first_games, second_games, first_sets, second_sets, server)
        for first_games in range(8)
        for second_games in range(8)
        for first_sets in range(4)
        for second_sets in range(4)
        for server in range(2)
    ]
    all_states.sort(key=lambda state: (progress(state), state[4]), reverse=True)
    values = {}
    for state in all_states:
        first_games, second_games, first_sets, second_sets, server = state
        already_won = (
            first_games >= 6 and first_games - second_games >= 2
            or second_games >= 6 and second_games - first_games >= 2
            or first_games == 7 and second_games == 6
            or second_games == 7 and first_games == 6
            or first_games == 7 and second_games == 7
        )
        if first_sets == 3 or second_sets == 3 or already_won:
            values[state] = 0.0
            continue
        win_probability = first_serve if server == 0 else 1.0 - second_serve
        total = 1.0
        for first_won in (True, False):
            chance = win_probability if first_won else 1.0 - win_probability
            next_first_sets, next_second_sets = first_sets, second_sets
            next_first_games, next_second_games = first_games, second_games
            set_winner = winner(first_games, second_games, first_won)
            if set_winner:
                if set_winner == 1:
                    next_first_sets += 1
                else:
                    next_second_sets += 1
                next_first_games, next_second_games = 0, 0
            elif first_won:
                next_first_games += 1
            else:
                next_second_games += 1
            next_state = (next_first_games, next_second_games,
                          next_first_sets, next_second_sets, 1 - server)
            total += chance * values[next_state]
        values[state] = total
    return values[(0, 0, 0, 0, 0)] * 5.0


def oracle(first_percent, second_percent):
    key = (first_percent, second_percent)
    if key not in RESULT_CACHE:
        minutes = solved_values(first_percent, second_percent)
        RESULT_CACHE[key] = f"{minutes:.6f}\n"
    return RESULT_CACHE[key]


def solve_text(text):
    lines = [line for line in text.splitlines() if line.strip()]
    count = int(lines[0])
    result = []
    position = 1
    for _ in range(count):
        first_percent = int(lines[position].split()[-1])
        second_percent = int(lines[position + 1].split()[-1])
        position += 2
        result.append(oracle(first_percent, second_percent))
    return "".join(result)


SAMPLE = """2
Pete Sampras 50
Rafael Nadal 50
Roger Federer 100
Arjit Srivastava 0
"""
SAMPLE_OUT = """199.281006
90.000000
"""
assert oracle(50, 50) == "199.281006\n"
assert oracle(100, 0) == "90.000000\n"
assert oracle(0, 100) == "90.000000\n"
assert oracle(100, 100) == "325.000000\n"
assert solve_text(SAMPLE) == SAMPLE_OUT


def write(name, pairs):
    names = ["Alpha Barker", "Bravo Cedar", "Charlie Delta", "Echo Foxtrot"]
    lines = [str(len(pairs))]
    for index, (first_percent, second_percent) in enumerate(pairs):
        lines.append(names[index % len(names)] + " " + str(first_percent))
        lines.append(names[(index + 1) % len(names)] + " " + str(second_percent))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(solve_text(text))


def build():
    write("2_edges", [(0, 0), (100, 100), (0, 100), (100, 0), (50, 50)])
    rng = random.Random(20261126)
    write("3_wide", [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(40)])
    write("4_random", [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(60)])
    write("5_io", [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(400)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
