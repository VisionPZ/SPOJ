#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_order(bags):
    best = None
    best_sum = -1
    size = len(bags)
    for chocolate in range(size):
        for strawberry in range(size):
            if strawberry == chocolate:
                continue
            for banana in range(size):
                if banana == chocolate or banana == strawberry:
                    continue
                kept = bags[chocolate][0] + bags[strawberry][1] + bags[banana][2]
                if kept > best_sum:
                    best_sum = kept
                    best = (chocolate, strawberry, banana)
    return best


def fast_order(bags):
    tops = []
    for flavor in range(3):
        ranked = sorted(range(len(bags)), key=lambda index: (-bags[index][flavor], index))
        tops.append(sorted(ranked[:5]))
    best = None
    best_sum = -1
    for chocolate in tops[0]:
        for strawberry in tops[1]:
            if strawberry == chocolate:
                continue
            for banana in tops[2]:
                if banana == chocolate or banana == strawberry:
                    continue
                kept = bags[chocolate][0] + bags[strawberry][1] + bags[banana][2]
                if kept > best_sum:
                    best_sum = kept
                    best = (chocolate, strawberry, banana)
    return best


def oracle(text):
    tokens = [int(token) for token in text.split()]
    size = tokens[0]
    bags = [tuple(tokens[1 + 3 * index:4 + 3 * index]) for index in range(size)]
    chosen = brute_order(bags) if size <= 8 else fast_order(bags)
    return "".join(f"{index}\n" for index in chosen)


SAMPLE = """5
10 10 10
40 39 40
10 20 30
30 20 10
1 2 27
"""
SAMPLE_OUT = """3
1
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n1 0 0\n0 1 0\n0 0 1\n") == "0\n1\n2\n"
assert oracle("3\n5 0 0\n0 5 0\n0 0 5\n") == "0\n1\n2\n"
assert oracle("4\n7 1 1\n1 7 1\n1 1 7\n9 9 9\n") == "0\n1\n3\n"
assert brute_order([(10, 10, 10), (40, 39, 40), (10, 20, 30), (30, 20, 10), (1, 2, 27)]) == (3, 1, 2)
rng_check = random.Random(61)
for _ in range(200):
    bags = [(rng_check.randint(0, 9), rng_check.randint(0, 9), rng_check.randint(0, 9))
            for _ in range(rng_check.randint(3, 8))]
    assert brute_order(bags) == fast_order(bags)


def write_case(name, bags):
    lines = [str(len(bags))]
    lines.extend(f"{chocolate} {strawberry} {banana}" for chocolate, strawberry, banana in bags)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [(0, 0, 0), (5, 0, 0), (0, 5, 0), (0, 0, 5), (1, 1, 1)])
    rng = random.Random(20261126)
    write_case("3_wide", [(rng.randint(0, 10**9), rng.randint(0, 10**9), rng.randint(0, 10**9))
                          for _ in range(5000)])
    write_case("4_random", [(rng.randint(0, 10**6), rng.randint(0, 10**6), rng.randint(0, 10**6))
                            for _ in range(2000)])
    write_case("5_io", [(rng.randint(0, 977), rng.randint(0, 977), rng.randint(0, 977))
                        for _ in range(5000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
