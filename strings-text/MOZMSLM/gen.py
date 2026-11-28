#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """2
asdfmnsmdsms
ssmssmjm
"""

SAMPLE_OUT = """10
4
"""


def count_sms(text):
    total_s = text.count("s")
    seen_s = 0
    answer = 0
    for character in text:
        if character == "s":
            seen_s += 1
        elif character == "m":
            answer += seen_s * (total_s - seen_s)
    return answer


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    answers = []
    for index in range(1, case_count + 1):
        answers.append(str(count_sms(tokens[index])))
    return "\n".join(answers) + "\n"


def write(name, strings):
    input_text = str(len(strings)) + "\n" + "\n".join(strings) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\nskmjssm\n") == "2\n"
assert oracle("2\nsms\nmmm\n") == "1\n0\n"
assert oracle("1\n" + "s" * 7000 + "\n") == "0\n"


def build():
    write("2_edges", ["s", "m" * 7000])
    write("3_wide", ["s" * 2333 + "m" * 2334 + "s" * 2333,
                     "s" * 2334 + "m" * 2332 + "s" * 2334])
    rng = random.Random(90044)
    alphabet = "ssmmabcde"
    write("4_random", ["".join(rng.choice(alphabet) for _ in range(7000))
                       for _ in range(2)])
    write("5_io", ["".join(rng.choice("ssmm") for _ in range(7000))
                   for _ in range(2)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
