#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_perfect(coins):
    reach = 0
    for coin in sorted(coins):
        if coin > reach + 1:
            return False
        reach += coin
    return True


def greedy_coins(value):
    coins = []
    remaining = value
    while remaining > 0:
        coin = 1 << ((remaining + 1).bit_length() - 2)
        coins.append(coin)
        remaining -= coin
    return coins


def oracle(text):
    tokens = text.split()
    count = int(tokens[0]); cursor = 1
    answers = []
    for _ in range(count):
        value = int(tokens[cursor]); cursor += 1
        coins = greedy_coins(value)
        assert sum(coins) == value
        assert is_perfect(coins)
        shifted = value + 1
        assert len(coins) == shifted.bit_length() + bin(shifted).count('1') - 2
        answers.append(str(len(coins)))
    return "\n".join(answers) + "\n"


def brute(value):
    best = [10 ** 9]

    def search(remaining, max_power, chosen):
        if remaining == 0:
            if is_perfect(chosen):
                best[0] = min(best[0], len(chosen))
            return
        for power in range(max_power, -1, -1):
            coin = 1 << power
            if coin <= remaining:
                search(remaining - coin, power, chosen + [coin])

    search(value, max(0, value.bit_length() - 1), [])
    return best[0]


def write(name, values):
    input_text = str(len(values)) + "\n" + "".join(f"{value}\n" for value in values)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [507, 29, 8574, 233, 149]
SAMPLE_TEXT = "5\n507\n29\n8574\n233\n149\n"
assert oracle(SAMPLE_TEXT) == "14\n7\n21\n11\n10\n"
for value in range(0, 41):
    assert brute(value) == len(greedy_coins(value)), value
assert len(greedy_coins(2 ** 3321)) == 3322
assert len(greedy_coins(10 ** 1000)) == 4484


def build():
    edges = [0, 1, 2, 3, 7, 8, 15, 16, 31, 32, 63, 64,
             2 ** 100 - 1, 2 ** 100, 10 ** 1000 - 1, 10 ** 1000]
    write("2_edges", edges)

    wide = [10 ** 1000, 10 ** 1000 - 1, 10 ** 999, 10 ** 1000 // 2,
            2 ** 3321, 2 ** 3321 - 1, 9 * (10 ** 999)]
    wide += [int('9' * 1000), int('1' + '0' * 999), int('5' * 1000)]
    write("3_wide", wide * 2)

    rng = random.Random(20261124)

    def random_value():
        length = rng.randint(1, 1000)
        digits = str(rng.randint(1, 9)) + "".join(str(rng.randint(0, 9)) for _ in range(length - 1))
        return int(digits)

    write("4_random", [random_value() for _ in range(50)])

    max_value = 10 ** 1000
    write("5_io", [max_value - rng.randint(0, max_value // 2) for _ in range(50)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
