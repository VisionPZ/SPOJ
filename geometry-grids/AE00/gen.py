#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    n = int(text.split()[0])
    total = 0
    for area in range(1, n + 1):
        for w in range(1, int(area**0.5) + 1):
            if area % w == 0:
                total += 1
    return f"{total}\n"


assert oracle("6\n") == "8\n"
assert oracle("1\n") == "1\n"
assert oracle("4\n") == "5\n"


def write_case(name, n):
    text = f"{n}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", 6)
write_case("2_edges", 1)
write_case("3_wide", 10000)
write_case("4_random", 7777)
write_case("5_io", 9999)
