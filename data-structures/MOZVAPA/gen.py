#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def valid_sequence(chars):
    depth = 0
    for char in chars:
        if char == '(':
            depth += 1
        else:
            depth -= 1
            if depth < 0:
                return False
    return depth == 0


CACHE = {}


def rearrangeable(substring):
    if substring in CACHE:
        return CACHE[substring]
    if len(substring) <= 6:
        answer = any(valid_sequence(order) for order in set(itertools.permutations(substring)))
    else:
        opens = substring.count('(')
        candidate = "()" * (len(substring) // 2) if opens * 2 == len(substring) else substring
        answer = valid_sequence(candidate)
    CACHE[substring] = answer
    return answer


def oracle(text):
    tokens = text.split()
    cursor = 0
    test_count = int(tokens[cursor])
    cursor += 1
    answer_lines = []
    for _ in range(test_count):
        length = int(tokens[cursor])
        cursor += 1
        sequence = tokens[cursor]
        cursor += 1
        query_count = int(tokens[cursor])
        cursor += 1
        for _ in range(query_count):
            left = int(tokens[cursor])
            right = int(tokens[cursor + 1])
            cursor += 2
            answer_lines.append("YES" if rearrangeable(sequence[left - 1:right]) else "NO")
    return "\n".join(answer_lines) + "\n"


def brute(text):
    tokens = text.split()
    cursor = 0
    test_count = int(tokens[cursor])
    cursor += 1
    answer_lines = []
    for _ in range(test_count):
        length = int(tokens[cursor])
        cursor += 1
        sequence = tokens[cursor]
        cursor += 1
        query_count = int(tokens[cursor])
        cursor += 1
        for _ in range(query_count):
            left = int(tokens[cursor])
            right = int(tokens[cursor + 1])
            cursor += 2
            answer_lines.append("YES" if any(
                valid_sequence(order) for order in set(itertools.permutations(sequence[left - 1:right]))
            ) else "NO")
    return "\n".join(answer_lines) + "\n"


SAMPLE = """1
6
())(()
4
1 2
1 3
2 5
1 6
"""
SAMPLE_OUT = """YES
NO
YES
YES
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n()\n2\n1 1\n1 2\n") == "NO\nYES\n"
assert oracle("1\n4\n(((\n2\n1 2\n1 4\n") == "NO\nNO\n"
assert oracle("1\n4\n)(()\n1\n1 4\n") == "YES\n"
for seed in range(100):
    rng_check = random.Random(seed)
    sequence_check = "".join(rng_check.choice("()") for _ in range(6))
    query_lines = []
    for _ in range(6):
        left_check = rng_check.randint(1, 6)
        right_check = rng_check.randint(left_check, 6)
        query_lines.append(f"{left_check} {right_check}")
    case_text = "1\n6\n" + sequence_check + "\n6\n" + "\n".join(query_lines) + "\n"
    assert oracle(case_text) == brute(case_text)


def write(name, cases):
    parts = [str(len(cases))]
    for sequence, queries in cases:
        parts.append(str(len(sequence)))
        parts.append(sequence)
        parts.append(str(len(queries)))
        for left, right in queries:
            parts.append(f"{left} {right}")
    text = "\n".join(parts) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ("()", [(1, 1), (1, 2)]),
        ("))((", [(1, 4), (2, 3)]),
        ("(()())", [(1, 6), (2, 5), (3, 4)]),
    ])
    wide_queries = [(1, 100000), (1, 99999), (2, 99999), (50000, 50001), (1, 2)]
    write("3_wide", [("()" * 50000, wide_queries)])
    rng = random.Random(20261126)
    random_sequence = "".join(rng.choice("()") for _ in range(2000))
    random_queries = []
    for _ in range(3000):
        left = rng.randint(1, 2000)
        right = rng.randint(left, 2000)
        random_queries.append((left, right))
    write("4_random", [(random_sequence, random_queries)])
    io_queries = [(index % 1000 + 1, index % 1000 + 2) for index in range(20000)]
    write("5_io", [("()" * 1000, io_queries)])
    big_queries = "\n".join(f"{index % 99999 + 1} {index % 99999 + 2}" for index in range(100000))
    (Path("/tmp") / "MOZVAPA_big.txt").write_text(
        "1\n100000\n" + "()" * 50000 + "\n100000\n" + big_queries + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("())(()", [(1, 2), (1, 3), (2, 5), (1, 6)])])
build()
