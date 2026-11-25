#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """sasmasamsas
3
1 6
3 9
8 11
"""
SAMPLE_OUT = """2
4
0
"""


def brute_count(text, left, right):
    window = text[left - 1:right]
    count = 0
    for first in range(len(window)):
        if window[first] != "s":
            continue
        for middle in range(first + 1, len(window)):
            if window[middle] != "m":
                continue
            for last in range(middle + 1, len(window)):
                if window[last] == "s":
                    count += 1
    return count


def scan_count(text, left, right):
    seen_s = 0
    pairs = 0
    total = 0
    for character in text[left - 1:right]:
        if character == "s":
            total += pairs
            seen_s += 1
        elif character == "m":
            pairs += seen_s
    return total


def oracle(input_text):
    lines = input_text.split("\n")
    text = lines[0]
    query_count = int(lines[1])
    answers = []
    for index in range(query_count):
        left, right = map(int, lines[2 + index].split())
        answers.append(str(scan_count(text, left, right)))
    return "\n".join(answers) + "\n"


def write(name, text, queries):
    input_text = text + "\n" + str(len(queries)) + "\n"
    input_text += "".join("%d %d\n" % (left, right) for left, right in queries)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    text = "skmjssm"
    print("window", text)
    print("brute", brute_count(text, 1, 7))
    print("scan", scan_count(text, 1, 7))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("sms\n1\n1 3\n") == "1\n"
assert oracle("skmjssm\n1\n1 7\n") == "2\n"
assert oracle("aaa\n1\n1 3\n") == "0\n"


def build():
    write("2_edges", "skmjssm",
          [(1, 1), (1, 7), (2, 6), (5, 5), (1, 3), (4, 7)])
    write("3_wide", "sms" * 6666 + "s",
          [(1, 19999), (1, 1), (5000, 15000), (6667, 13333),
           (19999, 19999), (2, 2)])
    rng = random.Random(91731)
    text = "".join(rng.choice("ssmmabcde") for _ in range(5000))
    queries = []
    for _ in range(200):
        left = rng.randint(1, 5000)
        right = rng.randint(left, 5000)
        queries.append((left, right))
    write("4_random", text, queries)
    write("5_io", "sms" * 6666 + "s",
          [(rng.randint(1, 10000), rng.randint(10001, 19999))
           for _ in range(500)])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", "sasmasamsas", [(1, 6), (3, 9), (8, 11)])
        build()
