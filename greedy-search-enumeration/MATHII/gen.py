#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_count(limit):
    total = 0
    for first in range(1, limit + 1):
        for second in range(1, limit // first + 1):
            total += limit // (first * second)
    return total


SIEVE_LIMIT = 1000000
_sieve_answers = None


def build_sieve():
    global _sieve_answers
    if _sieve_answers is not None:
        return _sieve_answers
    divisor_counts = [0] * (SIEVE_LIMIT + 1)
    divisor_sums = [0] * (SIEVE_LIMIT + 1)
    for divisor in range(1, SIEVE_LIMIT + 1):
        for multiple in range(divisor, SIEVE_LIMIT + 1, divisor):
            divisor_counts[multiple] += 1
    for divisor in range(1, SIEVE_LIMIT + 1):
        weight = divisor_counts[divisor]
        for multiple in range(divisor, SIEVE_LIMIT + 1, divisor):
            divisor_sums[multiple] += weight
    answers = [0] * (SIEVE_LIMIT + 1)
    running = 0
    for value in range(1, SIEVE_LIMIT + 1):
        running += divisor_sums[value]
        answers[value] = running
    _sieve_answers = answers
    return answers


def pair_count(limit):
    root = math.isqrt(limit)
    return 2 * sum(limit // value for value in range(1, root + 1)) - root * root


def hyperbola_count(limit):
    split = round(limit ** (1.0 / 3.0))
    while (split + 1) ** 3 <= limit:
        split += 1
    while split ** 3 > limit:
        split -= 1
    answer = 0
    for level in range(1, split + 1):
        remaining = limit // level
        all_pairs = pair_count(remaining)
        before = sum(remaining // value for value in range(1, level))
        through = before + remaining // level
        answer += all_pairs - 2 * before + (level - 1) ** 2
        answer += all_pairs - through - before + level * (level - 1)
        answer += all_pairs - 2 * through + level * level
    return answer


def oracle(text):
    answers = []
    for line in text.split():
        limit = int(line)
        if limit <= SIEVE_LIMIT:
            answers.append(build_sieve()[limit])
        else:
            answers.append(hyperbola_count(limit))
    return "".join(f"Case {index}: {answer}\n" for index, answer in enumerate(answers, 1))


SAMPLE_IN = "1\n3\n6\n10\n15\n21\n28\n"
SAMPLE_OUT = (
    "Case 1: 1\nCase 2: 7\nCase 3: 25\nCase 4: 53\n"
    "Case 5: 95\nCase 6: 161\nCase 7: 246\n"
)
assert oracle(SAMPLE_IN) == SAMPLE_OUT
for small_limit in range(1, 121):
    assert brute_count(small_limit) == build_sieve()[small_limit]
assert brute_count(1000) == build_sieve()[1000]
assert hyperbola_count(1000) == build_sieve()[1000]
assert hyperbola_count(5000) == brute_count(5000)
assert hyperbola_count(100000000000) == 33978264556380


def write(name, limits):
    text = "".join(f"{limit}\n" for limit in limits)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5])
    write("3_wide", [1000] * 10)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, 100000) for _ in range(10)])
    write("5_io", [rng.randint(900000, 1000000) for _ in range(12)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
