#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


def oracle_value(rupees):
    target = 4 * rupees
    pairs = target // 4
    remainder = target % 4
    constant = 2 * pairs + remainder // 2 + 1
    even_top = pairs // 2
    odd_top = (pairs - 1) // 2 if pairs >= 1 else -1
    even_sum = constant * (even_top + 1) * (even_top + 2) // 2
    even_sum -= 4 * even_top * (even_top + 1) * (even_top + 2) // 3
    odd_sum = 0
    if odd_top >= 0:
        odd_sum = (constant - 2) * (odd_top + 1) * (odd_top + 2) // 2
        odd_sum -= 4 * odd_top * (odd_top + 1) * (odd_top + 2) // 3
    return (even_sum + odd_sum) % MODULUS


def brute_value(rupees):
    target = 4 * rupees
    ways = [0] * (target + 1)
    ways[0] = 1
    for coin in (1, 2, 4, 8):
        for amount in range(coin, target + 1):
            ways[amount] += ways[amount - coin]
    return ways[target]


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    amounts = tokens[1:1 + case_count]
    return "".join(f"{oracle_value(amount)}\n" for amount in amounts)


SAMPLE_INPUT = "2\n1\n2\n"
SAMPLE_OUTPUT = "4\n10\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle_value(1) == 4
assert oracle_value(2) == 10
assert oracle_value(5) == 56
assert oracle_value(0) == 1
for check_amount in range(0, 31):
    assert oracle_value(check_amount) == brute_value(check_amount)


def write(name, amounts):
    text = str(len(amounts)) + "\n" + "".join(f"{amount}\n" for amount in amounts)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0, 1, 2, 3, 4, 5, 7, 8, 1000000000])
    write("3_wide", [1000000000, 999999999, 999999998, 500000000] * 8)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(0, 1000000000) for _ in range(200)])
    write("5_io", [rng.randint(0, 1000000000) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
