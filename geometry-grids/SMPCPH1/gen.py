#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    pos = 0
    while pos < len(text) and not text[pos].isdigit():
        pos += 1
    start = pos
    while pos < len(text) and text[pos].isdigit():
        pos += 1
    key_length = int(text[start:pos])
    key = ""
    while len(key) < key_length:
        while pos < len(text) and text[pos].isspace():
            pos += 1
        key += text[pos]
        pos += 1
    while pos < len(text) and not text[pos].isdigit():
        pos += 1
    while pos < len(text) and text[pos].isdigit():
        pos += 1
    while pos < len(text) and text[pos] != "\n":
        pos += 1
    if pos < len(text):
        pos += 1
    rest = text[pos:]
    mapping = {letter: key[(index + 1) % key_length]
               for index, letter in enumerate(key)}
    result_lines = []
    for line in rest.split("\n"):
        encoded = "".join(mapping.get(char, char) for char in line)
        result_lines.append(encoded.rstrip(" \t\r"))
    if rest.endswith("\n") and result_lines and result_lines[-1] == "":
        result_lines.pop()
    return "\n".join(result_lines) + "\n"


SAMPLE_ONE = (
    "6\nspojit\n3\nafter this training \n"
    "we will solve even\ndifficult and tricky problems easily\n"
)
SAMPLE_ONE_OUT = (
    "afser shtp sratntng\nwe wtll pjlve even\n"
    "dtfftculs and srtcky orjblemp eaptly\n"
)
SAMPLE_TWO = (
    "10\ndontgiveup\n3\nafter this training\n"
    "we will solve even\ndifficult and tricky problems easily\n"
)
SAMPLE_TWO_OUT = (
    "afgur ghvs gravtvti\nwu wvll snleu ueut\n"
    "ovffvcplg ato grvcky drnblums uasvly\n"
)

assert oracle(SAMPLE_ONE) == SAMPLE_ONE_OUT
assert oracle(SAMPLE_TWO) == SAMPLE_TWO_OUT
assert oracle("2\nab\n1\nba\n") == "ab\n"
assert oracle("2\naz\n2\nza\nzz\n") == "az\naa\n"
assert oracle("3\nabc\n1\ncab\n") == "abc\n"


def write(name, key, lines):
    input_text = f"{len(key)}\n{key}\n{len(lines)}\n"
    input_text += "".join(line + "\n" for line in lines)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", "spojit", ["after this training ", "we will solve even",
                             "difficult and tricky problems easily"])
write("2_edges", "ab", ["ba", "ab", "aa", "bb", "ba ab"])

alphabet = "abcdefghijklmnopqrstuvwxyz"
write("3_wide", alphabet, [alphabet] * 9)

random.seed(2026)
for index in range(4):
    key_length = random.randint(2, 26)
    key_chars = random.sample(alphabet, key_length)
    key = "".join(key_chars)
    lines = []
    remaining = 1000
    for _ in range(10):
        length = min(remaining, random.randint(1, 20))
        if length <= 0:
            break
        letters = "".join(random.choice(alphabet + "  ") for _ in range(length))
        lines.append(letters)
        remaining -= length
    write(f"4_random_{index}", key, lines)

for index in range(5):
    key = "zyxwv"
    lines = ["abcdefghij", "klmnopqrst", "uvwxyzabcd", "efghijklmn",
             "opqrstuvwx", "yzabcdefgh", "ijklmnopqr", "stuvwxyzab",
             "cdefghijkl", "mnopqrstuv"]
    write(f"5_io_{index}", key, lines)
