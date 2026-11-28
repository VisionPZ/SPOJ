#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TOP = 1000
SAMPLE_INPUT = "4\n"
SAMPLE_OUT = "997\n991 983\n977 971 967\n953 947 941 937\n"


def is_prime_trial(x):
    if x < 2:
        return False
    d = 2
    while d * d <= x:
        if x % d == 0:
            return False
        d += 1
    return True


def descending_primes():
    return [x for x in range(TOP, 1, -1) if is_prime_trial(x)]


PRIMES = descending_primes()


def oracle(text):
    tokens = [t for t in text.split() if t.isdigit()]
    if not tokens:
        return ""
    rows = int(tokens[0])
    out = []
    idx = 0
    width = 0
    while rows > 0 and idx < len(PRIMES):
        width += 1
        take = PRIMES[idx:idx + width]
        idx += len(take)
        out.append(" ".join(str(x) for x in take))
        rows -= 1
    return "".join(line + "\n" for line in out)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def trace_example():
    print("primes below 1000:", PRIMES[:10])
    print("count:", len(PRIMES))
    print("rows that fit:", max(r for r in range(1, 40) if r * (r + 1) // 2 <= len(PRIMES)))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n") == "997\n"
assert oracle("0\n") == ""
assert oracle("2\n") == "997\n991 983\n"
assert len(PRIMES) == 168


def build():
    write("2_edges", "17\n")
    write("3_overflow", "25\n")
    rng = random.Random(10185)
    write("4_random", "".join("%d\n" % rng.randint(1, 17) for _ in range(1)))
    write("5_io", "17\n")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_INPUT)
        build()
