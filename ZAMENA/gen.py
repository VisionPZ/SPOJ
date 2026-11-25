#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def digits(value, length):
    return [(value // (10 ** place)) % 10 for place in range(length - 1, -1, -1)]


def oracle(text):
    tokens = text.split()
    member_count = int(tokens[0])
    member_ids = [int(value) for value in tokens[1:1 + member_count]]
    digit_length = len(str(member_ids[0]))
    chain_scores = []
    best_score = 0
    for position, current_id in enumerate(member_ids):
        current_digits = digits(current_id, digit_length)
        chain_score = 0
        for earlier in range(position):
            earlier_digits = digits(member_ids[earlier], digit_length)
            changes = [index for index in range(digit_length)
                       if earlier_digits[index] != current_digits[index]]
            if len(changes) > 1:
                continue
            change_amount = 0
            if changes:
                index = changes[0]
                change_amount = abs(earlier_digits[index] - current_digits[index])
            chain_score = max(chain_score, chain_scores[earlier] + change_amount)
        chain_scores.append(chain_score)
        best_score = max(best_score, chain_score)
    return str(best_score) + "\n"


SAMPLE = """6
8823
2145
2185
3385
4145
4445
"""
SAMPLE_OUT = """5
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1234\n1274\n") == "4\n"
assert oracle("3\n1234\n1274\n1674\n") == "8\n"
assert oracle("2\n1234\n1234\n") == "0\n"
assert oracle("4\n1000\n9000\n9900\n9990\n") == "26\n"


def write(name, member_ids):
    input_text = str(len(member_ids)) + "\n" + "".join(
        str(value) + "\n" for value in member_ids)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1000, 1000, 1000])
    write("3_wide", [1000 + step * 100 for step in range(8)])
    rng = random.Random(20261126)
    write("4_random", [1000 + rng.randint(0, 999) for _ in range(30)])
    write("5_io", [1000 + rng.randint(0, 999) for _ in range(60)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [8823, 2145, 2185, 3385, 4145, 4445])
build()
