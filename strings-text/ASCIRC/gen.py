#!/usr/bin/env python3
import random
import sys
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OPS = "ABCD"


def oracle_case(instructions):
    reg = list(range(26))
    produced = {}
    for k, text in enumerate(instructions):
        op = ord(text[0]) - 65
        source_one = ord(text[1]) - 97
        source_two = ord(text[2]) - 97
        destination = ord(text[3]) - 97
        value_id = 26 + k
        produced[value_id] = (op, reg[source_one], reg[source_two])
        reg[destination] = value_id
    needed = set(reg)
    keys = set()
    for k in range(len(instructions) - 1, -1, -1):
        value_id = 26 + k
        if value_id in needed:
            op, left, right = produced[value_id]
            keys.add((op, left, right))
            needed.add(left)
            needed.add(right)
    return len(keys)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        size = int(tokens[cursor]); cursor += 1
        instructions = tokens[cursor:cursor + size]; cursor += size
        answers.append(str(oracle_case(instructions)))
    return "".join(answer + "\n" for answer in answers)


def brute_case(instructions):
    size = len(instructions)
    reg = list(range(26))
    info = []
    for k, text in enumerate(instructions):
        op = ord(text[0]) - 65
        source_one = ord(text[1]) - 97
        source_two = ord(text[2]) - 97
        destination = ord(text[3]) - 97
        left, right = reg[source_one], reg[source_two]
        value_id = 26 + k
        info.append((op, left, right, destination, value_id))
        reg[destination] = value_id
    final_values = reg[:]
    key_of = {26 + k: (info[k][0], info[k][1], info[k][2]) for k in range(size)}
    for gates in range(size + 1):
        for subset in combinations(range(size), gates):
            available = set()
            possible = True
            for k in subset:
                op, left, right, dest, value_id = info[k]
                if left >= 26 and key_of[left] not in available:
                    possible = False
                    break
                if right >= 26 and key_of[right] not in available:
                    possible = False
                    break
                available.add(key_of[value_id])
            if not possible:
                continue
            if all(value < 26 or key_of[value] in available for value in final_values):
                return gates
    return size


def write_cases(name, cases):
    input_text = str(len(cases)) + "\n" + "\n".join(
        str(len(case)) + "\n" + "\n".join(case) for case in cases) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


SAMPLE_TEXT = ("1\n8\nAfbc\nBfbd\nCddd\nBcbc\nAfcc\nAfbf\nCfbb\nDfdb\n")

assert oracle(SAMPLE_TEXT) == "6\n"
assert oracle_case(["Aabc"]) == 1
assert oracle_case(["Aabc", "Aabd"]) == 1
assert oracle_case(["Aabc", "Babc"]) == 1
assert oracle_case(["Aabc", "Aabc"]) == 1
assert oracle_case(["Aabc", "Acde", "Aabc"]) == 2

CHECK = random.Random(99)
for _ in range(300):
    small = ["".join(CHECK.choice(OPS) + chr(97 + CHECK.randrange(4))
                     + chr(97 + CHECK.randrange(4)) + chr(97 + CHECK.randrange(4)))
             for _ in range(CHECK.randrange(1, 7))]
    assert oracle_case(small) == brute_case(small), small


def make_instruction(rng):
    return (rng.choice(OPS) + chr(97 + rng.randrange(26))
            + chr(97 + rng.randrange(26)) + chr(97 + rng.randrange(26)))


def build():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_TEXT)
    (ROOT / "out" / "1_sample.out").write_text("6\n")

    edges = [
        ["Aabc"], ["Babc"], ["Cabc"], ["Dabc"],
        ["Aaaa"], ["Azza"],
        ["Aabc", "Aabc"],
        ["Aabc", "Babc"],
        ["Aabc", "Aabd"],
        ["Aabc", "Abca", "Acab"],
        ["Aabc", "Aabc", "Aabc"],
        ["Aabc", "Babc", "Cabc", "Dabc"],
        ["Aabc", "Abcd", "Acde", "Adef", "Aefa", "Afab", "Abca"],
    ]
    write_cases("2_edges", edges)

    rng = random.Random(1234)
    wide = []
    for _ in range(2):
        wide.append([make_instruction(rng) for _ in range(1000)])
    chain = []
    for k in range(1000):
        source_one = 97 + (k % 26)
        source_two = 97 + ((k + 7) % 26)
        destination = 97 + ((k + 13) % 26)
        chain.append(rng.choice(OPS) + chr(source_one) + chr(source_two) + chr(destination))
    wide.append(chain)
    write_cases("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(40):
        size = rng.randrange(1, 1001)
        random_cases.append([make_instruction(rng) for _ in range(size)])
    write_cases("4_random", random_cases)

    rng = random.Random(777)
    io_cases = [[make_instruction(rng)] for _ in range(20000)]
    write_cases("5_io", io_cases)


def worked_example():
    instructions = SAMPLE_TEXT.strip().split("\n")[2:]
    reg = list(range(26))
    first_seen = {}
    rows = []
    for k, text in enumerate(instructions):
        op = text[0]
        source_one = ord(text[1]) - 97
        source_two = ord(text[2]) - 97
        destination = ord(text[3]) - 97
        left, right = reg[source_one], reg[source_two]
        key = (op, left, right)
        value_id = 26 + k
        if key in first_seen:
            value_id = first_seen[key]
            note = "reuse"
        else:
            first_seen[key] = value_id
            note = "new"
        reg[destination] = value_id
        rows.append(f"{text}  {op}(v{left},v{right}) -> v{value_id}  {note}")
    finals = " ".join(chr(97 + i) + "=v" + str(reg[i]) for i in range(26) if reg[i] >= 26)
    print("\n".join(rows))
    print("final: " + finals)
    print("gates: " + str(oracle_case(instructions)))


if __name__ == "__main__":
    build()
    if "--example" in sys.argv:
        worked_example()
