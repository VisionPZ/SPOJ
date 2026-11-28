#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def bit_sum(limit):
    total = 0
    for bit_index in range(52):
        period = 1 << (bit_index + 1)
        half = 1 << bit_index
        full = (limit + 1) // period
        rest = (limit + 1) % period
        total += full * half + max(0, rest - half)
    return total


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    results = []
    for target in tokens[1:1 + case_count]:
        low = 0
        high = 1 << 51
        while low < high:
            middle = (low + high + 1) // 2
            if bit_sum(middle) <= target:
                low = middle
            else:
                high = middle - 1
        results.append(str(low) if bit_sum(low) == target else "Does Not Exist.")
    return "\n".join(results) + "\n"


SAMPLE = "6\n282657\n377636\n472615\n567594\n662573\n1992279\n"
SAMPLE_OUT = "38050\n49299\nDoes Not Exist.\nDoes Not Exist.\n82953\n227394\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "1\n"
assert oracle("1\n3\n") == "Does Not Exist.\n"
assert oracle("1\n4\n") == "3\n"
assert bit_sum(3) == 4


def write(name, targets):
    text = str(len(targets)) + "\n" + "\n".join(str(value) for value in targets) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 1000000000000000])
    rng = random.Random(20261125)
    wide = [bit_sum(rng.randint(1, 1 << 45)) for _ in range(20)]
    wide.append(999999999999999)
    write("3_wide", wide)
    write("4_random", [rng.randint(1, 1000000000000000) for _ in range(200)])
    write("5_io", [rng.randint(1, 1000000000000000) for _ in range(100000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [282657, 377636, 472615, 567594, 662573, 1992279])
build()
