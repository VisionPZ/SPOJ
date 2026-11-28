#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def case_answer(patterns, symbols, probability_map, length):
    total = 0.0
    for letters in itertools.product(symbols, repeat=length):
        generated = "".join(letters)
        if any(pattern in generated for pattern in patterns):
            continue
        likelihood = 1.0
        for letter in letters:
            likelihood *= probability_map[letter]
        total += likelihood
    return f"{total:.6f}"


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    lines = []
    for case_number in range(1, case_count + 1):
        pattern_count = int(tokens[cursor])
        cursor += 1
        patterns = tokens[cursor:cursor + pattern_count]
        cursor += pattern_count
        symbol_count = int(tokens[cursor])
        cursor += 1
        symbols = []
        probability_map = {}
        for _ in range(symbol_count):
            symbol = tokens[cursor]
            probability_map[symbol] = float(tokens[cursor + 1])
            symbols.append(symbol)
            cursor += 2
        length = int(tokens[cursor])
        cursor += 1
        lines.append("Case #" + str(case_number) + ": " +
                     case_answer(patterns, symbols, probability_map, length))
    return "\n".join(lines) + "\n"


SAMPLE = """2
1
a
2
a 0.5
b 0.5
2

2
ab
ab
2
a 0.2
b 0.8
2

"""
SAMPLE_OUT = """Case #1: 0.250000
Case #2: 0.840000
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert case_answer(["a"], ["a", "b"], {"a": 0.5, "b": 0.5}, 2) == "0.250000"
assert case_answer(["ab"], ["a", "b"], {"a": 0.25, "b": 0.75}, 2) == "0.812500"
assert case_answer(["x"], ["a", "b"], {"a": 0.5, "b": 0.5}, 3) == "1.000000"
assert case_answer(["aa"], ["a", "b"], {"a": 0.5, "b": 0.5}, 3) == "0.625000"


def write(name, cases):
    chunks = [str(len(cases))]
    for patterns, symbols, probability_map, length in cases:
        chunks.append(str(len(patterns)))
        chunks.extend(patterns)
        chunks.append(str(len(symbols)))
        for symbol in symbols:
            chunks.append(symbol + " " + str(probability_map[symbol]))
        chunks.append(str(length))
        chunks.append("")
    text = "\n".join(chunks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (["a"], ["a"], {"a": 1.0}, 1),
        (["z"], ["a"], {"a": 1.0}, 3),
        (["aa"], ["a", "b"], {"a": 0.5, "b": 0.5}, 3),
    ])
    write("3_wide", [
        (["ab", "ba", "aaa"], ["a", "b", "c"], {"a": 0.5, "b": 0.25, "c": 0.25}, 8),
    ])
    rng = random.Random(20261126)
    choices = [
        (["a", "b"], {"a": 0.5, "b": 0.5}),
        (["a", "b"], {"a": 0.25, "b": 0.75}),
        (["a", "b", "c"], {"a": 0.5, "b": 0.25, "c": 0.25}),
        (["a", "b", "c"], {"a": 0.125, "b": 0.375, "c": 0.5}),
    ]
    random_cases = []
    for _ in range(4):
        symbols, probability_map = rng.choice(choices)
        patterns = ["".join(rng.choice(symbols) for _ in range(rng.randint(1, 3)))
                    for _ in range(rng.randint(1, 3))]
        random_cases.append((patterns, symbols, probability_map, rng.randint(3, 7)))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20):
        probability_map = {"a": 0.5, "b": 0.25, "c": 0.25}
        patterns = ["ab", "cc", "bac"][:rng.randint(1, 3)]
        io_cases.append((patterns, ["a", "b", "c"], probability_map, 7))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
