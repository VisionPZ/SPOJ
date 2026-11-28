#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "3\nJuan Pedro Maria\n58 31 76\n88\n"
SAMPLE_OUTPUT = "Pedro 31\n"


def prime_flags(limit):
    flags = [True] * (limit + 1)
    flags[0] = False
    flags[1] = False
    for candidate in range(2, int(limit ** 0.5) + 1):
        if flags[candidate]:
            for multiple in range(candidate * candidate, limit + 1, candidate):
                flags[multiple] = False
    return flags


PRIME_FLAGS = prime_flags(100)


def oracle(text):
    tokens = text.split()
    pos = 0
    out = []
    while pos < len(tokens):
        count = int(tokens[pos])
        pos += 1
        names = tokens[pos:pos + count]
        pos += count
        values = [int(t) for t in tokens[pos:pos + count]]
        pos += count
        target = int(tokens[pos])
        pos += 1
        results = []
        for index, value in enumerate(values):
            if count == 1:
                neighbor = 0
            elif index == count - 1:
                neighbor = values[index - 1]
            else:
                neighbor = values[index + 1]
            raw = value + neighbor if PRIME_FLAGS[value] else value - neighbor
            results.append(abs(raw))
        winner = min(range(count), key=lambda index: abs(results[index] - target))
        out.append("%s %d\n" % (names[winner], values[winner]))
    return "".join(out)


def write(name, participants, target):
    names = " ".join(item[0] for item in participants)
    values = " ".join(str(item[1]) for item in participants)
    input_text = "%d\n%s\n%s\n%d\n" % (len(participants), names, values, target)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert PRIME_FLAGS[31] and not PRIME_FLAGS[58] and not PRIME_FLAGS[76]
assert sum(PRIME_FLAGS) == 25

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [("Juan", 58), ("Pedro", 31), ("Maria", 76)], 88)
write("2_edges", [("Solo", 7)], 7)
write("3_wide", [("A", 0), ("B", 2), ("C", 97), ("D", 100), ("E", 1),
                 ("F", 89), ("G", 53), ("H", 4), ("I", 83)], 100)
random.seed(2026)
write("4_random", [("Name%d" % index, random.randint(0, 100)) for index in range(9)], 55)
write("5_io", [("VeryLongParticipantName%d" % index, 89) for index in range(9)], 100)
