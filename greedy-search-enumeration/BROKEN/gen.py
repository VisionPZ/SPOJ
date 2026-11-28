#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    cursor = 0
    answers = []
    while cursor < len(lines):
        fields = lines[cursor].split()
        cursor += 1
        if not fields:
            continue
        max_keys = int(fields[0])
        if max_keys == 0:
            break
        typed = lines[cursor]
        cursor += 1
        longest = 0
        for start in range(len(typed)):
            used = set()
            for end in range(start, len(typed)):
                used.add(typed[end])
                if len(used) > max_keys:
                    break
                longest = max(longest, end - start + 1)
        answers.append(str(longest))
    return "\n".join(answers) + "\n"


SAMPLE = """5
This can't be solved by brute force.
1
Mississippi
0
"""
SAMPLE_OUT = """7
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\naaaa\n0\n") == "4\n"
assert oracle("5\nabcdef\n0\n") == "5\n"
assert oracle("1\n\n0\n") == "0\n"
assert oracle("2\nab ca \n0\n") == "2\n"


def write(name, cases):
    chunks = []
    for max_keys, typed in cases:
        chunks.append(f"{max_keys}\n{typed}\n")
    chunks.append("0\n")
    input_text = "".join(chunks)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, "aaaa"), (5, "abcdef"), (1, ""), (2, "ab ca ")])
    rng = random.Random(20261126)
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    wide_text = "".join(rng.choice(alphabet[:30]) for _ in range(300))
    write("3_wide", [(10, wide_text)])
    random_cases = []
    for _ in range(5):
        length = rng.randint(50, 250)
        text = "".join(rng.choice(alphabet) for _ in range(length))
        random_cases.append((rng.randint(1, 20), text))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        text = "".join(rng.choice(alphabet) for _ in range(500))
        io_cases.append((rng.randint(1, 60), text))
    write("5_io", io_cases)
    big_text = "".join(rng.choice(alphabet) for _ in range(1000000))
    Path("/tmp/BROKEN_big.txt").write_text("128\n" + big_text + "\n0\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
