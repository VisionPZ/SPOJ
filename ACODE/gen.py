#!/usr/bin/env python3
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parent


def oracle(text):
    out = []
    for tok in text.split():
        if tok == "0":
            break
        ways = [0] * (len(tok) + 1)
        ways[len(tok)] = 1
        for i in range(len(tok) - 1, -1, -1):
            if tok[i] != "0":
                ways[i] += ways[i + 1]
                if i + 1 < len(tok) and 10 <= int(tok[i : i + 2]) <= 26:
                    ways[i] += ways[i + 2]
        out.append(str(ways[0]))
    return "\n".join(out) + ("\n" if out else "")


assert oracle("25114\n1111111111\n3333333333\n0\n") == "6\n89\n1\n"
assert oracle("10\n202\n2626\n0\n") == "1\n1\n4\n"


def make_valid_string(rng, length):
    parts = []
    cur_len = 0
    while cur_len < length:
        if cur_len + 2 <= length and rng.random() < 0.35:
            parts.append(str(rng.randint(10, 26)))
            cur_len += 2
        else:
            parts.append(str(rng.randint(1, 9)))
            cur_len += 1
    return "".join(parts)[:length]


def write_case(name, strings):
    text = "\n".join(strings) + "\n0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_case("1_sample", ["25114", "1111111111", "3333333333"])
write_case("2_edges", ["1", "9", "10", "20", "101", "2020", "27", "102010"])
write_case("3_wide", ["1" * 80, "2" * 85, "3" * 5000, "12" * 40])
rng = random.Random(1020)
write_case("4_random", [make_valid_string(rng, rng.randint(10, 80)) for _ in range(100)])
write_case("5_io", [make_valid_string(rng, 70) for _ in range(3000)])
