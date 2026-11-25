#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle_case(pattern, fingerprints):
    matcher = re.compile(re.escape(pattern) + "$")
    matches = [line for line in fingerprints if matcher.search(line)]
    if not matches:
        return "Wrong fingerprints!\n"
    return str(len(matches)) + "\n" + "".join(line + "\n" for line in sorted(matches))


def oracle(text):
    lines = text.split("\n")
    pattern = lines[0]
    count = int(lines[1])
    fingerprints = lines[2:2 + count]
    return oracle_case(pattern, fingerprints)


SAMPLE = "On\n5\nPattern recognatiOn\nCommOn patterN\ngame\norganizatiOn\nlion\n"
SAMPLE_OUT = "2\nPattern recognatiOn\norganizatiOn\n"
SECOND = "Ze\n2\nFingerprint\npattern design\n"
SECOND_OUT = "Wrong fingerprints!\n"
SPACES = ("a\n8\nabc aa\nza za\naz aza a\nab ba\nba\n  a\nabfk\naa\n")
SPACES_OUT = ("7\n  a\naa\nab ba\nabc aa\naz aza a\nba\nza za\n")
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(SECOND) == SECOND_OUT
assert oracle(SPACES) == SPACES_OUT
assert oracle_case("A", ["  A ", "A ", "xAx"]) == "Wrong fingerprints!\n"
assert oracle_case("ZZ", ["ZZ", "aZZ", "ZZZ"]) == "3\nZZ\nZZZ\naZZ\n"


def write(name, pattern, fingerprints):
    text = pattern + "\n" + str(len(fingerprints)) + "\n"
    text += "".join(line + "\n" for line in fingerprints)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", "Ze", ["Fingerprint", "pattern design", "Ze", "  Ze"])
    write("3_wide", "Q" * 50, ["Q" * 50, "a" + "Q" * 49, "Q" * 49 + " ",
                              " " + "Q" * 49, "q" * 50])
    rng = random.Random(20261126)
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "
    pattern = "def"
    fingerprints = []
    for _ in range(10):
        prefix = "".join(rng.choice(alphabet) for _ in range(rng.randint(0, 20)))
        tail = pattern if rng.random() < 0.5 else "".join(rng.choice(alphabet[:52]) for _ in range(3))
        fingerprints.append(prefix + tail)
    write("4_random", pattern, fingerprints)
    write("5_io", "Tail", ["A" * 46 + "Tail"] * 10)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", "On", ["Pattern recognatiOn", "CommOn patterN", "game",
                         "organizatiOn", "lion"])
build()
