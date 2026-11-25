#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 10**9 + 7


def oracle(text):
    lines = text.splitlines()
    key = lines[0]
    haystack = lines[1]
    positions = []
    start = haystack.find(key)
    while start != -1:
        positions.append(start)
        start = haystack.find(key, start + 1)
    total = 0
    for mask in range(1, 1 << len(positions)):
        chosen = []
        for index in range(len(positions)):
            if mask >> index & 1:
                chosen.append(positions[index])
        valid = True
        for index in range(len(chosen) - 1):
            if chosen[index + 1] - chosen[index] < len(key):
                valid = False
                break
        if valid:
            total += 1
    return str(total % MOD) + "\n"


assert oracle("c\na\n") == "0\n"
assert oracle("aba\nabababa\n") == "4\n"
assert oracle("a\naaaaa\n") == "31\n"
assert oracle("ab\nabab\n") == "3\n"
assert oracle("abc\nabcabc\n") == "3\n"


def write(name, key, haystack):
    text = key + "\n" + haystack + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "a", "aaaaa")
    write("3_wide", "aba", "abababa")
    long_text = "".join("abcde" + "z" * 40000 for _ in range(12))
    write("5_io", "abcde", long_text)
    rng = random.Random(20261126)
    for attempt in range(100):
        key = "".join(rng.choice("abc") for _ in range(rng.randint(2, 5)))
        haystack = "".join(rng.choice("abcd") for _ in range(120))
        found = 0
        start = haystack.find(key)
        while start != -1:
            found += 1
            start = haystack.find(key, start + 1)
        if found <= 18:
            write("4_random", key, haystack)
            break

    Path("/tmp/DURIN_big.txt").write_text("a" * 10 + "\n" + "a" * 500000 + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "c", "a")
build()
