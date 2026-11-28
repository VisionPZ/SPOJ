#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_NUMBER = 1000000


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    numbers = tokens[1:1 + case_count]
    win = [False] * (max(numbers) + 1)
    for divisor in range(1, MAX_NUMBER // 2 + 1):
        if divisor >= len(win):
            break
        for multiple in range(divisor * 2, len(win), divisor):
            if not win[multiple - divisor]:
                win[multiple] = True
    lines = []
    for number in numbers:
        lines.append("Thankyou Shaktiman" if win[number] else "Sorry Shaktiman")
    return "\n".join(lines) + "\n"


SAMPLE = """2
212
424
"""
SAMPLE_OUT = """Thankyou Shaktiman
Thankyou Shaktiman
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1\n") == "Sorry Shaktiman\n"
assert oracle("1\n2\n") == "Thankyou Shaktiman\n"
assert oracle("3\n3\n4\n5\n") == "Sorry Shaktiman\nThankyou Shaktiman\nSorry Shaktiman\n"
assert oracle("1\n1000000\n") == "Thankyou Shaktiman\n"


def write(name, numbers):
    input_text = str(len(numbers)) + "\n" + "".join(str(number) + "\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [1, 2, 3, 4, 5, 6, 7, 999999])
    write("3_wide", [MAX_NUMBER] * 50)
    rng = random.Random(20261126)
    write("4_random", [rng.randint(1, MAX_NUMBER) for _ in range(500)])
    write("5_io", [rng.randint(1, MAX_NUMBER) for _ in range(99999)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [212, 424])
build()
