#!/usr/bin/env python3
import random
import string
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def count_vector(raw_name):
    counts = [0] * 26
    for character in raw_name:
        if 'a' <= character <= 'z':
            counts[ord(character) - 97] += 1
        elif 'A' <= character <= 'Z':
            counts[ord(character) - 65] += 1
    return tuple(counts)


def rank_key(raw_name):
    return tuple(-value for value in count_vector(raw_name))


def selection_order(names):
    remaining = [(rank_key(name), name) for name in names]
    ordered = []
    while remaining:
        best = min(remaining, key=lambda item: item[0])
        ordered.append(best[1])
        remaining.remove(best)
    return ordered


def oracle(text):
    lines = text.split('\n')
    cursor = 0
    test_count = int(lines[cursor].strip())
    cursor += 1
    output = []
    for case_number in range(1, test_count + 1):
        problem_count = int(lines[cursor].strip())
        cursor += 1
        names = lines[cursor:cursor + problem_count]
        cursor += problem_count
        output.append(f"case: {case_number}")
        output.extend(sorted(names, key=rank_key))
    return "\n".join(output) + "\n"


SAMPLE_INPUT = "2\n2\nabc\nab\n4\nbcsaasd\ndbasaaaa\nazzz\nbayy\n"
SAMPLE_OUTPUT = "case: 1\nabc\nab\ncase: 2\ndbasaaaa\nbcsaasd\nbayy\nazzz\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert count_vector("cba") == (1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
assert sorted(["cba", "bc"], key=rank_key) == ["cba", "bc"]
assert oracle("1\n4\nabc\nABC\nCBA\ncba\n") == "case: 1\nabc\nABC\nCBA\ncba\n"
small_names = ["cba", "bc", "a a", "Azz", "bbb", "ab"]
assert selection_order(small_names) == sorted(small_names, key=rank_key)


def write(name, cases):
    text = str(len(cases)) + "\n"
    for names in cases:
        text += str(len(names)) + "\n" + "".join(raw + "\n" for raw in names)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_name(rng, length):
    alphabet = string.ascii_letters + "   "
    return "".join(rng.choice(alphabet) for _ in range(length))


def build():
    write("2_edges", [
        ["a"],
        ["cba", "bc"],
        ["a a", "Azz", " bB "],
        ["abc", "ABC", "CBA", "cba"],
        ["z" * 199, "a", "A" * 100],
    ])
    rng = random.Random(20261126)
    write("3_wide", [[random_name(rng, rng.randint(1, 199)) for _ in range(200)] for _ in range(2)])
    write("4_random", [[random_name(rng, rng.randint(1, 60)) for _ in range(rng.randint(1, 40))] for _ in range(30)])
    write("5_io", [[random_name(rng, rng.randint(6, 12)) for _ in range(999)] for _ in range(14)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
