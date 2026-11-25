#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULO = 10007
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def build_transitions(words, max_length):
    prefixes = set()
    for word in words:
        for length in range(1, len(word) + 1):
            prefixes.add(word[:length])
    states = [""]
    state_index = {"": 0}
    rows = []
    cursor = 0
    while cursor < len(states):
        state = states[cursor]
        row = []
        for letter in ALPHABET:
            candidate = state + letter
            if len(candidate) > max_length:
                candidate = candidate[-max_length:]
            while candidate and candidate not in prefixes:
                candidate = candidate[1:]
            if any(word in candidate for word in words):
                row.append(-1)
                continue
            if candidate not in state_index:
                state_index[candidate] = len(states)
                states.append(candidate)
            row.append(state_index[candidate])
        rows.append(row)
        cursor += 1
    absorbing = len(states)
    rows.append([absorbing] * 26)
    return rows, absorbing


def oracle_case(word_count, article_length, words):
    rows, absorbing = build_transitions(words, max(len(word) for word in words))
    size = len(rows)
    counts = [0] * size
    counts[0] = 1
    for _ in range(article_length):
        updated = [0] * size
        for state in range(size):
            count = counts[state]
            if count == 0:
                continue
            for destination in rows[state]:
                updated[destination] = (updated[destination] + count) % MODULO
        counts = updated
    return counts[absorbing]


def oracle(text):
    tokens = text.split()
    position = 0
    answers = []
    while position + 1 < len(tokens):
        word_count = int(tokens[position])
        article_length = int(tokens[position + 1])
        position += 2
        words = tokens[position:position + word_count]
        position += word_count
        answers.append(str(oracle_case(word_count, article_length, words)))
    return "\n".join(answers) + "\n"


def brute_force(words, length):
    total = 0
    for letters in itertools.product(ALPHABET, repeat=length):
        article = "".join(letters)
        if any(word in article for word in words):
            total += 1
    return total % MODULO


SAMPLE = """2 2
A
B
2 10000
ABC
B
"""
SAMPLE_OUT = """100
5960
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle_case(1, 1, ["A"]) == 1
assert oracle_case(1, 2, ["A"]) == 51
assert oracle_case(2, 3, ["A", "B"]) == brute_force(["A", "B"], 3)
assert oracle_case(2, 3, ["AB", "BC"]) == brute_force(["AB", "BC"], 3)


def write(name, cases):
    text = ""
    for word_count, article_length, words in cases:
        text += f"{word_count} {article_length}\n"
        text += "".join(word + "\n" for word in words)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [(1, 1, ["A"]), (1, 6, ["ABCDEF"]), (2, 5, ["A", "AB"]),
                      (3, 4, ["A", "AA", "AAA"])])
    write("3_wide", [(10, 200, ["".join(rng.choice(ALPHABET) for _ in range(6))
                                for _ in range(10)]) for _ in range(5)])
    random_cases = []
    for _ in range(12):
        words = ["".join(rng.choice(ALPHABET) for _ in range(rng.randint(1, 6)))
                 for _ in range(rng.randint(1, 10))]
        random_cases.append((len(words), rng.randint(1, 300), words))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(500):
        words = ["".join(rng.choice(ALPHABET) for _ in range(rng.randint(1, 6)))
                 for _ in range(rng.randint(1, 10))]
        io_cases.append((len(words), rng.randint(1, 60), words))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2, ["A", "B"]), (2, 10000, ["ABC", "B"])])
build()
