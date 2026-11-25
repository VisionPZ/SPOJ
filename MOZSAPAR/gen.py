#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    sequences = tokens[1:1 + case_count]
    answers = []
    for sequence in sequences:
        reachable = {0}
        for char in sequence:
            following = set()
            for balance in reachable:
                if char == "(":
                    following.add(balance + 1)
                elif char == ")":
                    if balance > 0:
                        following.add(balance - 1)
                else:
                    following.add(balance + 1)
                    if balance > 0:
                        following.add(balance - 1)
            reachable = following
        answers.append("yes" if 0 in reachable else "no")
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = text.split()
    case_count = int(tokens[0])
    sequences = tokens[1:1 + case_count]
    answers = []
    for sequence in sequences:
        questions = [index for index, char in enumerate(sequence) if char == "?"]
        valid = False
        for choices in itertools.product("()", repeat=len(questions)):
            candidate = list(sequence)
            for index, choice in zip(questions, choices):
                candidate[index] = choice
            balance = 0
            good = True
            for char in candidate:
                balance += 1 if char == "(" else -1
                if balance < 0:
                    good = False
                    break
            if good and balance == 0:
                valid = True
                break
        answers.append("yes" if valid else "no")
    return "\n".join(answers) + "\n"


SAMPLE = """2
(()??((??)
((??
"""
SAMPLE_OUT = """yes
yes
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute(SAMPLE) == SAMPLE_OUT
assert oracle("1\n?\n") == "no\n"
assert oracle("1\n??\n") == "yes\n"
assert oracle("1\n)(?\n") == "no\n"
assert oracle("1\n((??\n") == "yes\n"
for length in range(1, 8):
    for letters in itertools.product("()?", repeat=length):
        candidate = "1\n" + "".join(letters) + "\n"
        assert oracle(candidate) == brute(candidate)


def write(name, sequences):
    text = "\n".join([str(len(sequences))] + sequences) + "\n"
    if sum(sequence.count("?") for sequence in sequences) <= 16:
        assert oracle(text) == brute(text)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["?", "??", ")(", "(()", "())", "(?"])
    rng = random.Random(20261126)
    write("3_wide", ["".join(rng.choice("()?") for _ in range(200)) for _ in range(6)])
    write("4_random", ["".join(rng.choice("()?") for _ in range(rng.randint(1, 100)))
                       for _ in range(10)])
    write("5_io", ["".join(rng.choice("()?") for _ in range(100)) for _ in range(2000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
