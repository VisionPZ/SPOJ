#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def cuteness(text):
    best = 0
    run = 0
    previous = None
    for char in text:
        if char == previous:
            run += 1
        else:
            run = 1
            previous = char
        best = max(best, run)
    return best


def brute_shuffles(first, second):
    best = 0

    def visit(first_index, second_index, current):
        nonlocal best
        if first_index == len(first) and second_index == len(second):
            best = max(best, cuteness(current))
            return
        if first_index < len(first):
            visit(first_index + 1, second_index, current + first[first_index])
        if second_index < len(second):
            visit(first_index, second_index + 1, current + second[second_index])

    visit(0, 0, "")
    return best


def is_subsequence(needle, haystack):
    iterator = iter(haystack)
    return all(char in iterator for char in needle)


def oracle_case(first, second):
    best = 0
    for char in set(first + second):
        matches_first = list(re.finditer(char + "+", first))
        matches_second = list(re.finditer(char + "+", second))
        match_first = max(matches_first, key=lambda item: len(item.group())) if matches_first else None
        match_second = max(matches_second, key=lambda item: len(item.group())) if matches_second else None
        run_first = match_first.group() if match_first else ""
        run_second = match_second.group() if match_second else ""
        before_first = first[:match_first.start()] if match_first else first
        after_first = first[match_first.end():] if match_first else ""
        before_second = second[:match_second.start()] if match_second else second
        after_second = second[match_second.end():] if match_second else ""
        candidate = before_first + before_second + run_first + run_second + after_first + after_second
        if is_subsequence(first, candidate) and is_subsequence(second, candidate):
            best = max(best, cuteness(candidate))
    return best


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    cursor = 1
    for _ in range(count):
        answers.append(str(oracle_case(tokens[cursor], tokens[cursor + 1])))
        cursor += 2
    return "\n".join(answers) + "\n"


SAMPLE = """1
ab ab
"""
SAMPLE_OUT = """2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case("cxc", "cxc") == 2
assert oracle_case("aaaa", "aa") == 6
assert oracle_case("abc", "xyz") == 1
assert oracle_case("ab", "ab") == 2
rng = random.Random(20261126)
for _ in range(300):
    first = "".join(rng.choice("abc") for _ in range(rng.randint(1, 5)))
    second = "".join(rng.choice("abc") for _ in range(rng.randint(1, 5)))
    assert oracle_case(first, second) == brute_shuffles(first, second), (first, second)


def write(name, pairs):
    text = str(len(pairs)) + "\n" + "".join(first + " " + second + "\n" for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("a", "a"), ("a", "b"), ("aaaa", "aa"), ("abc", "abc"), ("cxc", "cxc")])
    write("3_wide", [("a" * 100000, "a" * 100000), ("b" * 100000, "a" * 100000)])
    write("4_random", [
        ("".join(rng.choice("abc") for _ in range(rng.randint(1, 10))),
         "".join(rng.choice("abc") for _ in range(rng.randint(1, 10))))
        for _ in range(200)])
    write("5_io", [
        ("".join(rng.choice("ab") for _ in range(100000)),
         "".join(rng.choice("ab") for _ in range(100000)))
        for _ in range(20)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("ab", "ab")])
build()
