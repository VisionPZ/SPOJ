#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10 ** 9


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = int(tokens[cursor])
        width = int(tokens[cursor + 1])
        cursor += 2
        colors = tokens[cursor]
        cursor += 1
        last_start = length - width
        dp = [INF] * (length + 1)
        dp[0] = 0
        for position in range(1, length + 1):
            wanted = colors[position - 1]
            best = INF
            for start in range(max(0, position - width), min(position - 1, last_start) + 1):
                if any(colors[index] != wanted for index in range(start, position)):
                    continue
                if dp[start] + 1 < best:
                    best = dp[start] + 1
            dp[position] = best
        answers.append(str(dp[length]) if dp[length] < INF else "-1")
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        length = int(tokens[cursor])
        width = int(tokens[cursor + 1])
        cursor += 2
        colors = tokens[cursor]
        cursor += 1
        memo = {0: 0}

        def solve(position):
            if position in memo:
                return memo[position]
            best = INF
            wanted = colors[position - 1]
            for start in range(max(0, position - width), min(position - 1, length - width) + 1):
                if all(colors[index] == wanted for index in range(start, position)):
                    best = min(best, solve(start) + 1)
            memo[position] = best
            return best

        value = solve(length)
        answers.append(str(value) if value < INF else "-1")
    return "\n".join(answers) + "\n"


SAMPLE = """2
3 2
rgg
3 3
rgg
"""
SAMPLE_OUT = """2
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n4 2\naaaa\n") == "2\n"
assert oracle("1\n4 2\nabba\n") == "-1\n"
assert oracle("1\n5 1\nabcde\n") == "5\n"
for tiny in ["1\n4 2\naaaa\n", "1\n5 3\naabba\n", "1\n6 2\nababab\n"]:
    assert oracle(tiny) == brute(tiny)


def write(name, cases):
    pieces = [str(len(cases))]
    for length, width, colors in cases:
        pieces.append(f"{length} {width}")
        pieces.append(colors)
    text = "\n".join(pieces) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, 1, "a"), (3, 3, "aaa"), (3, 3, "aab"), (2, 1, "ab"),
        (4, 2, "aabb"), (5, 3, "aabba"),
    ])
    rng = random.Random(20261126)
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    wide_one = "".join(rng.choice(alphabet) for _ in range(20000))
    wide_two = "".join(rng.choice("abc") for _ in range(20000))
    write("3_wide", [(20000, 1, wide_one), (20000, 2, wide_two)])
    random_cases = []
    for _ in range(30):
        length = rng.randint(1, 15)
        width = rng.randint(1, length)
        colors = "".join(rng.choice("abcd") for _ in range(length))
        random_cases.append((length, width, colors))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(50):
        length = rng.randint(10, 30)
        width = rng.randint(2, 8)
        colors = "".join(rng.choice("abc") for _ in range(length))
        io_cases.append((length, width, colors))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
