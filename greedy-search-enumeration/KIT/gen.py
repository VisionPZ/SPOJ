#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    pad_size = int(tokens[cursor]); cursor += 1
    pad = [int(tokens[cursor + index]) for index in range(pad_size)]
    cursor += pad_size
    pad_cursor = 0
    lines = []
    while cursor < len(tokens):
        word = tokens[cursor]
        cursor += 1
        if word == "-1":
            break
        encrypted = []
        for character in word:
            shift = pad[pad_cursor]
            pad_cursor += 1
            code = ord(character) - ord("a")
            encrypted.append(chr((code + shift) % 26 + ord("a")))
        lines.append("".join(encrypted))
    return "\n".join(lines) + "\n" if lines else ""


def direct_check(text):
    tokens = text.split()
    pad_size = int(tokens[0])
    pad = [int(value) for value in tokens[1:1 + pad_size]]
    words = []
    for token in tokens[1 + pad_size:]:
        if token == "-1":
            break
        words.append(token)
    answers = []
    used = 0
    for word in words:
        result = ""
        for character in word:
            result += chr((ord(character) - 97 + pad[used]) % 26 + 97)
            used += 1
        answers.append(result)
    return "\n".join(answers) + "\n" if answers else ""


SAMPLE = """10
1 2 3 4 5 4 3 2 1 0
aa aaa
zzzzz
-1
"""
SAMPLE_OUT = """bc
def
dcbaz
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert direct_check(SAMPLE) == SAMPLE_OUT
assert oracle("1\n0\na\n-1\n") == "a\n"
assert oracle("2\n25 25\naz\n-1\n") == "zy\n"
assert oracle("3\n1 2 3\nabc\n-1\n") == "bdf\n"
assert direct_check("3\n1 2 3\nabc\n-1\n") == "bdf\n"


def write(name, pad, words, pad_lines=1):
    lines = [str(len(pad))]
    for index in range(0, len(pad), pad_lines):
        lines.append(" ".join(str(value) for value in pad[index:index + pad_lines]))
    lines.append(" ".join(words))
    lines.append("-1")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [0], ["a"], 1)
    write("3_wide", [index % 26 for index in range(100)], ["abcdefghij"] * 10, 7)
    rng = random.Random(20261126)
    pad = [rng.randint(0, 25) for _ in range(100)]
    words = []
    remaining = 100
    while remaining > 0:
        length = min(remaining, rng.randint(1, 8))
        word = "".join(chr(rng.randint(97, 122)) for _ in range(length))
        words.append(word)
        remaining -= length
    write("4_random", pad, words, 9)
    write("5_io", [rng.randint(0, 25) for _ in range(100)], [chr(97 + letter % 26) for letter in range(100)], 5)


def trace_example():
    print("pad: 1 2 3 4 5 4 3 2 1 0")
    print("aa -> bc")
    print("aaa -> def")
    print("zzzzz -> dcbaz")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
trace_example()
