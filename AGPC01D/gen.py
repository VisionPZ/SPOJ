#!/usr/bin/env python3
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        cursor += 2
        source = tokens[cursor]; cursor += 1
        target = tokens[cursor]; cursor += 1
        have = Counter(source)
        want = Counter(target)
        if want:
            answers.append(str(min(have[letter] // want[letter] for letter in want)))
        else:
            answers.append("0")
    return "\n".join(answers) + "\n"


SAMPLE = """2
4 2
abcd
ca
4 1
abcd
e
"""
SAMPLE_OUT = """1
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n10 8\naaaaaaaaaa\naaaaaaaa\n") == "1\n"
assert oracle("1\n3 2\nabc\nzz\n") == "0\n"
assert oracle("1\n6 3\naabbcc\nabc\n") == "2\n"


def write(name, cases):
    rows = [str(len(cases))]
    for source, target in cases:
        rows.append(f"{len(source)} {len(target)}")
        rows.append(source)
        rows.append(target)
    text = "\n".join(rows) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        ("a", "a"), ("a", "b"), ("abc", "abc"), ("aaaa", "aa"),
        ("abcdef", "fed"), ("xyzxyz", "zyx"), ("aabbcc", "abcabc"),
    ])
    alphabet = "abcdefghijklmnopqrstuvwxyz"
    write("3_wide", [
        (alphabet * 3846, alphabet * 3846),
        ("a" * 100000, "a" * 100000),
        ("z" * 100000, "z" * 7),
        (alphabet * 3846, "q" * 100000),
    ])
    import random
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(60):
        size_a = rng.randint(1, 1500)
        size_b = rng.randint(1, 1500)
        source = "".join(rng.choice(alphabet) for _ in range(size_a))
        target = "".join(rng.choice(alphabet) for _ in range(size_b))
        random_cases.append((source, target))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        source = "".join(rng.choice(alphabet) for _ in range(100000))
        target = "".join(rng.choice(alphabet[:8]) for _ in range(100000))
        io_cases.append((source, target))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("abcd", "ca"), ("abcd", "e")])
build()
