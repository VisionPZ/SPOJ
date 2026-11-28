#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def simulate_stops(n):
    seen = set()
    cur = n
    while cur > 1:
        if cur in seen:
            return False
        seen.add(cur)
        if cur % 2 == 0:
            cur //= 2
        else:
            cur = 3 * cur + 3
        if cur > 10**18:
            return False
    return True


def oracle(text):
    n = int(text.split()[0])
    return "TAK\n" if simulate_stops(n) else "NIE\n"


assert oracle("4\n") == "TAK\n"
assert oracle("3\n") == "NIE\n"
assert oracle("1\n") == "TAK\n"
assert oracle("6\n") == "NIE\n"


def write_case(name, n):
    text = f"{n}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", 4)
write_case("2_edges", 1)
write_case("3_wide", 1 << 45)
write_case("4_random", (1 << 45) - 2)
write_case("5_io", 10**14)
