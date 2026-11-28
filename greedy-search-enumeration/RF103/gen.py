#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF103.

Each line holds a braced list of misspelled words and a quoted wall message.
The oracle uses a regular expression and Python's substring operator.
The solution scans raw bytes and tests every word by hand.
A line containing only zero ends the input.
"""
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    '{"a", "e", "i"}, "murcielago"\n'
    '{"ci", "ur"}, "murcielago"\n'
    '{"muri"}, "murcielago"\n'
    '{"i","h", "e"}, "murcielago"\n'
    '0\n'
)
SAMPLE_OUTPUT = "true\ntrue\nfalse\nfalse\n"

LINE_PATTERN = re.compile(r"\{(.*?)\},\s*\"(.*)\"")
WORD_PATTERN = re.compile(r'"([^"]*)"')


def oracle(text):
    answers = []
    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if not stripped:
            continue
        if stripped == "0":
            break
        match = LINE_PATTERN.match(stripped)
        words = WORD_PATTERN.findall(match.group(1))
        message = match.group(2)
        answers.append("true" if all(word in message for word in words)
                       else "false")
    return "".join(answer + "\n" for answer in answers)


def write(name, lines):
    input_text = "".join('{%s}, "%s"\n' % (
        ", ".join('"%s"' % word for word in words), message)
        for words, message in lines) + "0\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == "true\ntrue\nfalse\nfalse\n"
assert "murcielago" in "murcielago" and "muri" not in "murcielago"
assert oracle('{}, "anything"\n') == "true\n"


def trace_example():
    for words, message in [
            (["a", "e", "i"], "murcielago"),
            (["ci", "ur"], "murcielago"),
            (["muri"], "murcielago"),
            (["i", "h", "e"], "murcielago")]:
        print("%s in %s -> %s" % (
            ",".join(words), message,
            "true" if all(word in message for word in words) else "false"))


if "--trace" in sys.argv:
    trace_example()
else:
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(["a", "e", "i"], "murcielago"),
                       (["ci", "ur"], "murcielago"),
                       (["muri"], "murcielago"),
                       (["i", "h", "e"], "murcielago")])
    write("2_edges", [([], "anything"), ([""], "anything"),
                      (["abcdefghij"], "abc"), (["murcielago"], "murcielago"),
                      (["a", "a"], "banana")])
    write("3_wide", [(["abc", "def", "ghi", "jkl"],
                      "xxabcdefghiyyjklzz" * 20),
                     (["z"], "a" * 1000),
                     (["a", "b", "c", "d", "e", "f"], "abcdef" * 50)])
    random.seed(2026)
    letters = "abcdefghijklmnopqrstuvwxyz"
    write("4_random", [(
        ["".join(random.choice(letters) for _ in range(random.randint(1, 4)))
         for _ in range(5)],
        "".join(random.choice(letters) for _ in range(60)))
        for _ in range(500)])
    write("5_io", [(
        ["".join(random.choice(letters) for _ in range(3)) for _ in range(20)],
        "".join(random.choice(letters) for _ in range(500)))
        for _ in range(5000)])
