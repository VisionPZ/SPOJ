#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "10 2 4 1\n16 5 7 10\n5 1 1 4\n"
SAMPLE_OUT = "19\n57\n7\n"
BASE_DOOR_HEIGHT = 7


def fits(initial_height, target_day, daily_growth, column_height):
    dragon_height = initial_height + target_day * daily_growth
    low = 0
    high = dragon_height + 1
    while low < high:
        middle = (low + high) // 2
        if BASE_DOOR_HEIGHT + middle * column_height > dragon_height:
            high = middle
        else:
            low = middle + 1
    return BASE_DOOR_HEIGHT + low * column_height


def oracle(text):
    answers = []
    for line in text.split("\n"):
        if not line.strip():
            continue
        values = [int(token) for token in line.split()]
        answers.append(str(fits(*values)))
    return "".join(answer + "\n" for answer in answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 2 4 1\n") == "19\n"
assert oracle("16 5 7 10\n") == "57\n"
assert oracle("5 1 1 4\n") == "7\n"
assert oracle("1 1 1 1\n") == "7\n"
assert oracle("749 999 949 1\n") == "948801\n"


def write(name, cases):
    input_text = "".join(" ".join(str(value) for value in case) + "\n"
                         for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(1, 1, 1, 1), (5, 1, 1, 4), (749, 1, 1, 2000),
                      (1, 1, 949, 1999), (749, 999, 949, 1999),
                      (749, 999, 949, 1)])
    write("3_wide", [(749, 999, 949, 1), (749, 999, 949, 1999),
                     (1, 999, 1, 1), (749, 999, 949, 2000)] * 10)
    rng = random.Random(20261125)
    write("4_random", [(rng.randint(1, 749), rng.randint(1, 999),
                        rng.randint(1, 949), rng.randint(1, 1999))
                       for _ in range(300)])
    write("5_io", [(rng.randint(1, 749), rng.randint(1, 999),
                    rng.randint(1, 949), rng.randint(1, 1999))
                   for _ in range(20000)])


def worked_example():
    initial_height, target_day, daily_growth, column_height = 10, 2, 4, 1
    dragon_height = initial_height + target_day * daily_growth
    attempts = [BASE_DOOR_HEIGHT + columns * column_height
                for columns in range(14)]
    first_fit = next(height for height in attempts if height > dragon_height)
    print(f"dragon height: {dragon_height}")
    print(f"door heights: {attempts}")
    print(f"first height above dragon: {first_fit}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(10, 2, 4, 1), (16, 5, 7, 10), (5, 1, 1, 4)])
    build()
    if "--trace" in sys.argv:
        worked_example()


if __name__ == "__main__":
    main()
