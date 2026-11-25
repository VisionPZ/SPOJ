#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    case_count = tokens[cursor]; cursor += 1
    answers = []
    for case_index in range(1, case_count + 1):
        pad_count = tokens[cursor]; cursor += 1
        jump_distance = tokens[cursor]; cursor += 1
        positions = tokens[cursor:cursor + pad_count + 2]
        cursor += pad_count + 2
        gaps = [positions[i + 1] - positions[i] for i in range(pad_count + 1)]
        slacks = []
        for rope_index in range(pad_count + 1):
            slacks.append(tokens[cursor] - gaps[rope_index])
            cursor += 1

        @lru_cache(None)
        def solve(step_index, state):
            if step_index == pad_count + 1:
                return 0
            current_gaps = list(state[:pad_count + 1])
            current_slacks = list(state[pad_count + 1:])
            if current_gaps[step_index] <= jump_distance:
                best = solve(step_index + 1, state)
            else:
                best = 1 + solve(step_index + 1, state)
            bank = sum(current_slacks[step_index + 1:])
            for pull in range(1, bank + 1):
                new_gaps = list(current_gaps)
                new_slacks = list(current_slacks)
                new_gaps[step_index] -= pull
                remaining = pull
                for rope_index in range(step_index + 1, pad_count + 1):
                    used = min(remaining, new_slacks[rope_index])
                    new_slacks[rope_index] -= used
                    new_gaps[rope_index] += used
                    remaining -= used
                    if remaining == 0:
                        break
                if new_gaps[step_index] < 0:
                    continue
                next_state = tuple(new_gaps + new_slacks)
                cost = (0 if new_gaps[step_index] <= jump_distance else 1)
                best = min(best, cost + solve(step_index + 1, next_state))
            return best

        start_state = tuple(gaps + slacks)
        answers.append(f"Case {case_index}: {solve(0, start_state)}")
    return "\n".join(answers) + "\n"


SAMPLE = ("5\n1 10\n0 10 20\n10 10\n\n1 10\n0 11 20\n11 10\n\n"
          "1 10\n0 11 20\n11 9\n\n1 5\n0 10 20\n20 20\n\n1 5\n0 10 20\n20 12\n")
SAMPLE_OUT = "Case 1: 0\nCase 2: 0\nCase 3: 1\nCase 4: 1\nCase 5: 2\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 100\n0 50 100\n100 100\n") == "Case 1: 0\n"
assert oracle("1\n1 100\n0 50 100\n100 50\n") == "Case 1: 0\n"
assert oracle("1\n1 50\n0 50 100\n50 50\n") == "Case 1: 0\n"
assert 3 * 3 == 9


def case_text(pad_count, jump_distance, positions, ropes):
    return (f"{pad_count} {jump_distance}\n" +
            " ".join(str(value) for value in positions) + "\n" +
            " ".join(str(value) for value in ropes) + "\n")


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 10, [0, 10, 20], [10, 10]),
        (1, 10, [0, 11, 20], [11, 10]),
        (1, 10, [0, 11, 20], [11, 9]),
        (1, 5, [0, 10, 20], [20, 20]),
        (1, 5, [0, 10, 20], [20, 12]),
        (2, 4, [0, 9, 14, 20], [15, 5, 8]),
        (2, 3, [0, 8, 10, 12], [8, 5, 4]),
        (4, 5, [0, 6, 17, 24, 25, 27], [10, 15, 8, 1, 6]),
        (5, 6, [0, 11, 23, 32, 34, 44, 52], [12, 15, 14, 6, 14, 9]),
    ])
    rng = random.Random(20261126)
    wide_cases = []
    for _ in range(20):
        pad_count = rng.randint(1, 3)
        positions = [0]
        for _ in range(pad_count + 1):
            positions.append(positions[-1] + rng.randint(1, 12))
        ropes = [positions[i + 1] - positions[i] + rng.randint(0, 5)
                 for i in range(pad_count + 1)]
        wide_cases.append((pad_count, rng.randint(1, 10), positions, ropes))
    write("3_wide", wide_cases)
    random_cases = []
    for _ in range(60):
        pad_count = rng.randint(1, 3)
        positions = [0]
        for _ in range(pad_count + 1):
            positions.append(positions[-1] + rng.randint(1, 10))
        ropes = [positions[i + 1] - positions[i] + rng.randint(0, 4)
                 for i in range(pad_count + 1)]
        random_cases.append((pad_count, rng.randint(1, 8), positions, ropes))
    write("4_random", random_cases)
    io_cases = []
    for case_index in range(9000):
        positions = [0, rng.randint(4, 10), rng.randint(14, 20)]
        ropes = [positions[1], rng.randint(10, 20)]
        io_cases.append((1, rng.randint(2, 6), positions, ropes))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
