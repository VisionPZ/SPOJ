#!/usr/bin/env python3
import heapq
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    tn_values = tokens[1:1 + count]
    db_values = tokens[1 + count:1 + 2 * count]
    ascending = sorted(range(count), key=lambda coin: tn_values[coin])
    pending = []
    keeps_db = [False] * count
    chosen_count = 0
    processed_count = 0
    db_total = 0
    for coin in ascending:
        heapq.heappush(pending, (-db_values[coin], coin))
        processed_count += 1
        tn_count = processed_count - chosen_count
        if tn_count > chosen_count:
            _, dropped = heapq.heappop(pending)
            keeps_db[dropped] = True
            chosen_count += 1
            db_total += db_values[dropped]
    db_coins = [coin for coin in ascending if keeps_db[coin]]
    tn_coins = [coin for coin in ascending if not keeps_db[coin]]
    lines = [str(db_total)]
    for db_coin, tn_coin in zip(db_coins, tn_coins):
        lines.append(f"{db_coin + 1} {tn_coin + 1}")
    return "\n".join(lines) + "\n"


def brute_force(text):
    tokens = [int(value) for value in text.split()]
    count = tokens[0]
    tn_values = tokens[1:1 + count]
    db_values = tokens[1 + count:1 + 2 * count]
    ascending = sorted(range(count), key=lambda coin: tn_values[coin])
    best = -1
    for candidate in itertools.combinations(ascending, count // 2):
        chosen = set(candidate)
        db_seen = 0
        tn_seen = 0
        valid = True
        for coin in ascending:
            if coin in chosen:
                db_seen += 1
            else:
                tn_seen += 1
            if tn_seen > db_seen:
                valid = False
                break
        if valid:
            best = max(best, sum(db_values[coin] for coin in candidate))
    return best


SAMPLE = """6
6 10 11 18 5 14
1 7 6 12 15 1
"""
SAMPLE_OUT = """28
5 1
2 6
3 4
"""

assert oracle(SAMPLE) == SAMPLE_OUT
assert brute_force(SAMPLE) == 28
assert oracle("2\n1 2\n3 4\n") == "3\n1 2\n"
assert brute_force("2\n1 2\n3 4\n") == 3
assert oracle("4\n1 2 3 4\n1 2 3 4\n").splitlines()[0] == "4"

rng_check = random.Random(7)
for _ in range(60):
    size = rng_check.choice([2, 4, 6, 8])
    values = rng_check.sample(range(1, 1000), size)
    rewards = [rng_check.randint(1, 1000) for _ in range(size)]
    text = f"{size}\n" + " ".join(map(str, values)) + "\n" + " ".join(map(str, rewards)) + "\n"
    assert int(oracle(text).splitlines()[0]) == brute_force(text)


def write_case(name, tn_values, db_values):
    text = (str(len(tn_values)) + "\n" + " ".join(map(str, tn_values)) + "\n" +
            " ".join(map(str, db_values)) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_case("2_edges", [1, 2], [3, 4])
    rng = random.Random(20261126)
    write_case("3_wide", rng.sample(range(1, 10**9), 100),
               rng.sample(range(10**8, 10**9), 100))
    write_case("4_random", rng.sample(range(1, 10**9), 200),
               [rng.randint(1, 10**9) for _ in range(200)])
    write_case("5_io", rng.sample(range(1, 10**9), 10000),
               [rng.randint(1, 10**9) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
