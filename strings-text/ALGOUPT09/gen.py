#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    case_count = int(lines[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        word_count, line_count = (int(value) for value in lines[cursor].split())
        cursor += 1
        word_map = {}
        for _ in range(word_count):
            japanese = lines[cursor]
            cursor += 1
            portuguese = lines[cursor]
            cursor += 1
            word_map[japanese] = portuguese
        for _ in range(line_count):
            lyric = lines[cursor]
            cursor += 1
            answers.append(" ".join(word_map.get(word, word) for word in lyric.split(" ")))
        answers.append("")
    return "\n".join(answers) + "\n"


def make_case(entries, lyrics):
    lines = [f"{len(entries)} {len(lyrics)}"]
    for japanese, portuguese in entries:
        lines.extend([japanese, portuguese])
    lines.extend(lyrics)
    return "\n".join(lines) + "\n"


def word_name(index):
    letters = []
    while True:
        letters.append(chr(ord("a") + index % 26))
        index //= 26
        if index == 0:
            break
    return "".join(reversed(letters))


SAMPLE = """1
4 3
galaxy
cara tossiu
kagayaku
canalha do
atsuki
alto que
yuushi
util
o galaxy
o galaxy
o kagayaku atsuki yuushi
"""
SAMPLE_OUT = """o cara tossiu
o cara tossiu
o canalha do alto que util

"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n" + make_case([("a", "b c")], ["a", "x", ""])) == "b c\nx\n\n\n"
assert oracle("1\n" + make_case([("a", "1"), ("b", "2")], ["a b", "b a"])) == "1 2\n2 1\n\n"
assert oracle("1\n" + make_case([("k", "long phrase here")], ["k k"])) == "long phrase here long phrase here\n\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edges = make_case([
        ("alpha", "one two"),
        ("beta", "three"),
        ("gamma", "four five six"),
    ], ["", "alpha beta", "unknown gamma", "beta beta beta"])
    write("2_edges", "1\n" + edges)
    rng = random.Random(20261126)
    wide_entries = [(word_name(index),
                     " ".join(word_name(rng.randrange(26)) for _ in range(3)))
                    for index in range(200)]
    wide_lyrics = [" ".join(word_name(rng.randrange(200)) for _ in range(3))
                   for _ in range(50)]
    write("3_wide", "1\n" + make_case(wide_entries, wide_lyrics))
    random_entries = [(word_name(index),
                       " ".join(word_name(rng.randrange(26)) for _ in range(rng.randint(1, 3))))
                      for index in range(100)]
    random_lyrics = [" ".join(word_name(rng.randrange(110)) for _ in range(rng.randint(1, 5)))
                     for _ in range(20)]
    write("4_random", "1\n" + make_case(random_entries, random_lyrics))
    io_entries = [(word_name(index), "t" * 20) for index in range(200)]
    io_lyrics = [" ".join(word_name(index % 200) for index in range(offset, offset + 3))
                 for offset in range(1000)]
    write("5_io", "1\n" + make_case(io_entries, io_lyrics))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
