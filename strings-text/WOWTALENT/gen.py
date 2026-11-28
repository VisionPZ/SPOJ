#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "Siam Hasan Antik\n"
SAMPLE_OUT = "Welcome Siam Hasan Antik to SIU\n"


def oracle(text):
    answers = []
    for name_line in text.splitlines():
        if not name_line:
            continue
        answers.append("Welcome " + name_line + " to SIU")
    return "".join(answer + "\n" for answer in answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("Alice\n") == "Welcome Alice to SIU\n"
assert oracle("Bob Smith\n") == "Welcome Bob Smith to SIU\n"
assert oracle("A\n\nB C\n") == "Welcome A to SIU\nWelcome B C to SIU\n"


def write(name, names):
    input_text = "".join(student_name + "\n" for student_name in names)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", ["A", "B" * 100, "Two  Spaces", "", "Z"])
    write("3_wide", ["A" * 100, "z" * 100, "A a A a" * 14] * 50)
    rng = random.Random(20261125)
    letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ "
    write("4_random", ["".join(rng.choice(letters) for _ in range(rng.randint(3, 100)))
                       for _ in range(300)])
    write("5_io", ["".join(rng.choice(letters) for _ in range(100))
                   for _ in range(2000)])


def worked_example():
    name_line = "Siam Hasan Antik"
    pieces = ["Welcome", name_line, "to", "SIU"]
    print(f"input line: {name_line}")
    print(f"pieces: {pieces}")
    print(f"joined: {' '.join(pieces)}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", ["Siam Hasan Antik"])
    build()
    if "--trace" in sys.argv:
        worked_example()


if __name__ == "__main__":
    main()
