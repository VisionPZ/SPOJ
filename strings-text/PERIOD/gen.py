#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_N = 1_000_000


def divisors(value):
    small = []
    large = []
    step = 1
    while step * step <= value:
        if value % step == 0:
            small.append(step)
            partner = value // step
            if partner != step:
                large.append(partner)
        step += 1
    return small + large[::-1]


def oracle(text):
    length = len(text)
    lines = []
    for size in range(2, length + 1):
        best_unit = None
        for unit in divisors(size):
            if unit >= size:
                break
            if text[:size - unit] == text[unit:size]:
                best_unit = unit
                break
        if best_unit is not None:
            lines.append(f"{size} {size // best_unit}\n")
    return lines


def brute(text):
    length = len(text)
    lines = []
    for size in range(2, length + 1):
        for unit in range(1, size // 2 + 1):
            if size % unit:
                continue
            if all(text[k] == text[k + unit] for k in range(size - unit)):
                lines.append(f"{size} {size // unit}\n")
                break
    return lines


def input_text(cases):
    parts = [str(len(cases))]
    for text in cases:
        parts.append(str(len(text)))
        parts.append(text)
    return "\n".join(parts) + "\n"


def output_text(cases, outputs=None):
    parts = []
    for index in range(len(cases)):
        parts.append(f"Test case #{index + 1}\n")
        parts.extend(outputs[index] if outputs is not None
                     else oracle(cases[index]))
        parts.append("\n")
    return "".join(parts)


def write_pair(name, cases, outputs=None):
    (ROOT / "in" / f"{name}.txt").write_text(input_text(cases))
    (ROOT / "out" / f"{name}.out").write_text(
        output_text(cases, outputs))


SAMPLE = ["aaa", "aabaabaabaab"]
SAMPLE_OUTPUT = (
    "Test case #1\n2 2\n3 3\n\n"
    "Test case #2\n2 2\n6 2\n9 3\n12 4\n\n"
)
assert output_text(SAMPLE) == SAMPLE_OUTPUT
assert oracle("ababa") == ["4 2\n"]
assert oracle("ab") == []
assert oracle("aaaa") == ["2 2\n", "3 3\n", "4 4\n"]
assert oracle("ababab") == ["4 2\n", "6 3\n"]

check_rng = random.Random(7)
for trial in range(200):
    size = check_rng.randint(1, 40)
    text = "".join(check_rng.choice("abcde")
                   for _ in range(size))
    assert oracle(text) == brute(text), (trial, text)


def build():
    edges = ["ab", "aa", "abc", "abab", "ababa", "abcabc",
             "aaaaaaaa", "zz", "abababa", "abcabcabcabc",
             "bca", "abcabcab", "xyzxyzx", "d" * 13]
    write_pair("2_edges", edges)

    wide = ["a" * 5000, "b" * 4999,
            "ab" * 2500, "abc" * 1666 + "ab",
            "".join(chr(97 + (k * 7) % 26) for k in range(5000))]
    write_pair("3_wide", wide)

    random_rng = random.Random(2026)
    random_cases = []
    for _ in range(10):
        size = random_rng.randint(100, 2000)
        alphabet = "abcdefghijklmnopqrstuvwxyz"
        random_cases.append("".join(random_rng.choice(alphabet)
                                    for _ in range(size)))
    write_pair("4_random", random_cases)

    with (ROOT / "in" / "5_io.txt").open("w") as source:
        source.write("10\n")
        for _ in range(10):
            source.write(f"{MAX_N}\n")
            source.write("a" * MAX_N + "\n")

    with (ROOT / "out" / "5_io.out").open("w") as target:
        for case_index in range(10):
            target.write(f"Test case #{case_index + 1}\n")
            chunk = []
            for size in range(2, MAX_N + 1):
                chunk.append(f"{size} {size}\n")
                if len(chunk) >= 65536:
                    target.write("".join(chunk))
                    chunk = []
            if chunk:
                target.write("".join(chunk))
            target.write("\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_pair("1_sample", SAMPLE)
build()
