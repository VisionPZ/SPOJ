#!/usr/bin/env python3
import itertools
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    raw_lines = [line.strip() for line in text.splitlines()]
    lines = [line for line in raw_lines if line]
    pos = 0
    answers = []
    while pos < len(lines):
        ignored_count = int(lines[pos])
        pos += 1
        if ignored_count == 0:
            break
        ignored = set(lines[pos:pos + ignored_count])
        pos += ignored_count
        while pos < len(lines):
            case_line = lines[pos]
            pos += 1
            if case_line == "LAST CASE":
                break
            tokens = case_line.split()
            abbreviation = tokens[0]
            words = [word for word in tokens[1:] if word not in ignored]
            abbrev_len = len(abbreviation)

            def match_counts(word, start):
                result = []
                for count in range(1, abbrev_len - start + 1):
                    target = abbreviation[start:start + count].lower()
                    ways = 0
                    for positions in itertools.combinations(range(len(word)), count):
                        if "".join(word[index] for index in positions) == target:
                            ways += 1
                    if ways:
                        result.append((count, ways))
                return result

            @lru_cache(maxsize=None)
            def search(word_index, start):
                if word_index == len(words):
                    return 1 if start == abbrev_len else 0
                total = 0
                for count, ways in match_counts(words[word_index], start):
                    total += ways * search(word_index + 1, start + count)
                return total

            answer = search(0, 0)
            if answer == 0:
                answers.append(f"{abbreviation} is not a valid abbreviation")
            else:
                answers.append(f"{abbreviation} can be formed in {answer} ways")
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = """2
and
of
ACM academy of computer makers
RADAR radio detection and ranging
LAST CASE
2
a
an
APPLY an apple a day
LAST CASE
0
"""
SAMPLE_OUT = """ACM can be formed in 2 ways
RADAR is not a valid abbreviation
APPLY can be formed in 1 ways
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("0\n") == ""
assert oracle("1\nthe\nA a\nLAST CASE\n0\n") == "A can be formed in 1 ways\n"
assert oracle("1\na\nA a\nLAST CASE\n0\n") == "A is not a valid abbreviation\n"
assert oracle("1\nthe\nAA aa\nLAST CASE\n0\n") == "AA can be formed in 1 ways\n"
assert oracle("1\nthe\nAA a a\nLAST CASE\n0\n") == "AA can be formed in 1 ways\n"
assert oracle("1\nthe\nAB ba\nLAST CASE\n0\n") == "AB is not a valid abbreviation\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "1\nthe\nAA aa\nAB ba\nA a\nLAST CASE\n0\n")
    write("3_wide", "2\nand\nof\nACM academy of computer makers\nRADAR radio detection and ranging\nLAST CASE\n1\nthe\nAB alpha beta gamma\nLAST CASE\n0\n")
    rng = random.Random(20261123)
    cases = []
    for _ in range(3):
        ignored_count = rng.randint(0, 3)
        cases.append(f"{ignored_count}\n")
        for _ in range(ignored_count):
            cases.append("of\n")
        for _ in range(5):
            letter_count = rng.randint(1, 5)
            abbreviation = "".join(rng.choice("ABCD") for _ in range(letter_count))
            words = []
            for _ in range(rng.randint(1, 3)):
                words.append("".join(rng.choice("abcd") for _ in range(rng.randint(1, 5))))
            cases.append(abbreviation + " " + " ".join(words) + "\n")
        cases.append("LAST CASE\n")
    cases.append("0\n")
    write("4_random", "".join(cases))
    io_cases = []
    for case_index in range(60):
        io_cases.append("1\nthe\n")
        io_cases.append(f"A{'a' * (1 + case_index % 8)}\n")
        io_cases.append("LAST CASE\n")
    io_cases.append("0\n")
    write("5_io", "".join(io_cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
