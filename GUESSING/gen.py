#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent
SPOJ_TEXT = "LIFE IS LIKE A BOX OF CHOCOLATES. YOU NEVER KNOW WHAT YOU'RE GONNA GET."


def feedback(guess, secret):
    exact = sum(1 for idx in range(6) if guess[idx] == secret[idx])
    cross = sum(
        1
        for i in range(6)
        for j in range(6)
        if i != j and guess[i] == secret[j]
    )
    return exact, cross


def oracle_candidate_elimination(secret):
    pool = [f"{num:06d}" for num in range(1000000)]
    guess = "012345"
    while True:
        sig = feedback(guess, secret)
        if sig[0] == 6:
            return guess
        pool = [cand for cand in pool if feedback(guess, cand) == sig]
        assert pool
        if len(pool) == 1:
            return pool[0]
        guess = pool[len(pool) // 2]


def oracle(text):
    tokens = text.split()
    if not tokens:
        return SPOJ_TEXT + "\n"
    return "".join(f"{tok}\n" for tok in tokens)


assert feedback("121565", "121565") == (6, 4)
assert feedback("000000", "875520") == (1, 5)
assert feedback("555555", "875520") == (2, 10)
assert feedback("875520", "875520") == (6, 2)
for probe in ("000000", "875520", "121565", "555555", "999999"):
    assert oracle_candidate_elimination(probe) == probe


def write_case(name, content):
    (ROOT / "in" / f"{name}.txt").write_text(content)
    (ROOT / "out" / f"{name}.out").write_text(oracle(content))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write_case("1_sample", "")
write_case("2_edges", "000000\n999999\n111111\n121565\n555555\n875520\n")
write_case("3_wide", "012345\n543210\n909090\n000009\n900000\n123456\n")

rng = random.Random(20080526)
write_case("4_random", "".join(f"{rng.randrange(1000000):06d}\n" for _ in range(500)))
write_case("5_io", "".join(f"{rng.randrange(1000000):06d}\n" for _ in range(25000)))
