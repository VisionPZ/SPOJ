#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(case_count):
        room_count = int(tokens[position])
        position += 1
        plan = tokens[position]
        position += 1
        balance = [0] * 26
        lowest = [0] * 26
        for door_index in range(room_count - 1):
            key_type = ord(plan[2 * door_index]) - 97
            door_type = ord(plan[2 * door_index + 1]) - 65
            balance[key_type] += 1
            lowest[key_type] = min(lowest[key_type], balance[key_type])
            balance[door_type] -= 1
            lowest[door_type] = min(lowest[door_type], balance[door_type])
        answers.append(str(sum(-value for value in lowest if value < 0)))
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answers = []
    for _ in range(case_count):
        room_count = int(tokens[position])
        position += 1
        plan = tokens[position]
        position += 1

        memo = {}

        def search(door_index, held):
            state = (door_index, held)
            if state in memo:
                return memo[state]
            if door_index == room_count - 1:
                return 0
            key_type = ord(plan[2 * door_index]) - 97
            door_type = ord(plan[2 * door_index + 1]) - 65
            after_key = list(held)
            after_key[key_type] += 1
            best = 1 + search(door_index + 1, tuple(after_key))
            if after_key[door_type] > 0:
                after_use = list(after_key)
                after_use[door_type] -= 1
                best = min(best, search(door_index + 1, tuple(after_use)))
            memo[state] = best
            return best

        answers.append(str(search(0, tuple([0] * 26))))
    return "\n".join(answers) + "\n"


SAMPLE = """1
3
aAbB
"""
SAMPLE_OUT = """0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\nbA\n") == "1\n"
assert oracle("1\n2\naA\n") == "0\n"
assert oracle("1\n5\nzZzZzZzZ\n") == "0\n"
assert brute("1\n5\nzZzZzZzZ\n") == "0\n"


def write(name, cases):
    lines = [str(len(cases))]
    for room_count, plan in cases:
        lines.append(str(room_count))
        lines.append(plan)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(rng, room_count):
    keys = [rng.randrange(26) for _ in range(room_count - 1)]
    doors = [rng.randrange(26) for _ in range(room_count - 1)]
    plan = ""
    for key_type, door_type in zip(keys, doors):
        plan += chr(97 + key_type) + chr(65 + door_type)
    return room_count, plan


def build():
    write("2_edges", [(2, "bA"), (2, "aA"), (4, "aAbBcC"), (4, "cBcAcA")])
    rng = random.Random(20261126)
    write("3_wide", [random_case(rng, 100000)])
    write("4_random", [random_case(rng, rng.randrange(2, 60)) for _ in range(20)])
    write("5_io", [random_case(rng, rng.randrange(2, 8)) for _ in range(600)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
small = "1\n6\naAbBcCaAbB\n"
assert oracle(small) == brute(small)
build()
