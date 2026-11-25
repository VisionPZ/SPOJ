#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

KNOWN = {
    999999937: 1,
    1000000000: 161,
    999999999: 40,
    999983: 1,
    8675309: 1,
    123456789: 22,
}


def oracle(text):
    tokens = list(map(int, text.split()))
    count = tokens[0]
    results = []
    for leg in tokens[1:1 + count]:
        if leg in KNOWN:
            results.append(str(KNOWN[leg]))
            continue
        core = leg if leg % 2 else leg // 2
        square = core * core
        found = 0
        for divisor in range(1, core):
            if square % divisor == 0:
                found += 1
        results.append(str(found))
    return "".join(result + "\n" for result in results)


SAMPLE = "3\n5\n10\n15\n"
SAMPLE_OUT = "1\n1\n4\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n2\n") == "0\n"
assert oracle("2\n12\n24\n") == "4\n7\n"
assert oracle("1\n1000000000\n") == "161\n"
assert oracle("1\n100\n") == "7\n"


def write(name, legs):
    text = str(len(legs)) + "\n" + "".join(str(leg) + "\n" for leg in legs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 8, 9, 12, 15, 24, 25, 45, 60])
    write("3_wide", list(KNOWN.keys()))
    rng = random.Random(20261129)
    write("4_random", [rng.randint(1, 4000) for _ in range(200)])
    write("5_io", [rng.randint(1, 2000) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
