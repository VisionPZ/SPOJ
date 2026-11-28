#!/usr/bin/env python3
"""Test-data generator and statement-derived oracle for RF105.

The cake and ice cream rows each list children with a leading count.
The oracle uses set symmetric difference and Python's sorted().
The solution sorts every name once and prints runs of length one.
"""
import random
import string
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "4 Sofia Pedro Pablo Yolanda\n1 Pedro\n"
SAMPLE_OUTPUT = "Pablo Sofia Yolanda\n"
SECOND_INPUT = (
    "4 Pedro Pablo Miguel Santiago\n"
    "5 Pablo Marta Pilar Carlos Alfonso\n"
)
SECOND_OUTPUT = "Alfonso Carlos Marta Miguel Pedro Pilar Santiago\n"


def oracle(text):
    rows = [line.split() for line in text.splitlines() if line.strip()]
    cake = rows[0][1:]
    cream = rows[1][1:]
    return " ".join(sorted(set(cake) ^ set(cream))) + "\n"


def write(name, cake, cream):
    input_text = "%d %s\n%d %s\n" % (
        len(cake), " ".join(cake), len(cream), " ".join(cream))
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert SAMPLE_OUTPUT == "Pablo Sofia Yolanda\n"
assert oracle(SECOND_INPUT) == SECOND_OUTPUT
assert oracle("1 A\n1 A\n") == "\n"
assert oracle("0\n0\n") == "\n"


def trace_example():
    cake = ["Sofia", "Pedro", "Pablo", "Yolanda"]
    cream = ["Pedro"]
    print("cake: %s" % ", ".join(sorted(cake)))
    print("cream: %s" % ", ".join(sorted(cream)))
    print("both: %s" % ", ".join(sorted(set(cake) & set(cream))))
    print("only one: %s" % " ".join(sorted(set(cake) ^ set(cream))))


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", ["Sofia", "Pedro", "Pablo", "Yolanda"], ["Pedro"])
    write("2_edges", ["Z", "a", "A", "aa", "0"], ["a", "A", "bb", "1"])
    write("3_wide", ["Name%04d" % i for i in range(500)],
          ["Name%04d" % i for i in range(250, 750)])
    random.seed(2026)
    alphabet = string.ascii_letters + string.digits
    pool = ["".join(random.choice(alphabet) for _ in range(random.randint(2, 12)))
            for _ in range(800)]
    cake = pool[:400]
    cream = pool[200:600]
    write("4_random", cake, cream)
    big_pool = ["".join(random.choice(alphabet) for _ in range(random.randint(3, 15)))
                for _ in range(10000)]
    write("5_io", big_pool[:5000], big_pool[2500:7500])


if "--trace" in sys.argv:
    trace_example()
else:
    main()
