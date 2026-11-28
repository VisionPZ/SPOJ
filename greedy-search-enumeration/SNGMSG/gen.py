#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def key_positions(key_length, count):
    positions = []
    position = 0
    step = 1
    for _ in range(count):
        positions.append(position)
        if step == 1:
            if position == key_length - 1:
                step = -1
            else:
                position += 1
        else:
            if position == 0:
                step = 1
            else:
                position -= 1
    return positions


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        key = tokens[cursor]
        cursor += 1
        encoded = tokens[cursor]
        cursor += 1
        positions = key_positions(len(key), len(encoded))
        decoded = []
        for index, character in enumerate(encoded):
            shift = int(key[positions[index]])
            plain = (ord(character) - ord("a") - shift) % 26
            decoded.append(chr(ord("a") + plain))
        answers.append("".join(decoded))
    return "\n".join(answers) + "\n"


def encode(key, plain):
    positions = key_positions(len(key), len(plain))
    result = []
    for index, character in enumerate(plain):
        shift = int(key[positions[index]])
        result.append(chr((ord(character) - ord("a") + shift) % 26 + ord("a")))
    return "".join(result)


SAMPLE = """6
132
nxovdba
212
uitktjvjmc
011
lfbejngafspsasfjnposubot
123
jnrygzpw
11
lfbejngafspsasfjnposubot
130
behipbobu
"""
SAMPLE_OUT = """mumtaaz
shrishtika
leadingzerosareimportant
iloveyou
keadimfzerorzreimonrtans
abhimanyu
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert key_positions(3, 7) == [0, 1, 2, 2, 1, 0, 0]
assert oracle("1\n1\nz\n") == "y\n"
assert oracle("1\n011\na\n") == "a\n"
assert encode("132", "mumtaaz") == "nxovdba"
assert oracle("1\n9821\n" + encode("9821", "bpcikcpjw") + "\n") == "bpcikcpjw\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        key + "\n" + message + "\n" for key, message in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [("0", "a"), ("1", "z"), ("011", "abc"), ("9", "abcd"),
                      ("000", "zzzzz")])
    write("3_wide", [("1234567", encode("1234567", "q" * 500)),
                     ("900001", encode("900001", "z" * 500))])
    rng = random.Random(20261126)
    cases = []
    for _ in range(60):
        length = rng.randint(1, 7)
        key = "".join(str(rng.randint(0, 9)) for _ in range(length))
        plain = "".join(chr(rng.randint(0, 25) + ord("a"))
                        for _ in range(rng.randint(1, 120)))
        cases.append((key, encode(key, plain)))
    write("4_random", cases)
    io_cases = []
    for _ in range(10000):
        key = "".join(str(rng.randint(0, 9)) for _ in range(7))
        plain = "".join(chr(rng.randint(0, 25) + ord("a")) for _ in range(500))
        io_cases.append((key, encode(key, plain)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
