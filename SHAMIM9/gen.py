#!/usr/bin/env python3
import random
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "3\n99\n"
SAMPLE_OUT = "7\n1\n"


def oracle(text):
    answers = []
    for token in text.split():
        digit = (9 * int(token)) % 10
        answers.append(str(digit))
    return "".join(answer + "\n" for answer in answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n") == "7\n"
assert oracle("99\n") == "1\n"
assert oracle("10\n") == "0\n"
assert oracle("123456789012345678901234567890\n") == "0\n"


def write(name, numbers):
    input_text = "".join(number + "\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", ["3", "99", "10", "0", "1",
                      "1" + "0" * 39, "9" * 40, "123456789" * 4])
    write("3_wide", ["9" * 40, "0" * 40, "12345678901234567890" * 2] * 20)
    rng = random.Random(20261125)
    write("4_random", ["".join(str(rng.randint(0, 9)) for _ in range(rng.randint(1, 40)))
                       for _ in range(300)])
    write("5_io", ["".join(str(rng.randint(0, 9)) for _ in range(40))
                   for _ in range(100000)])


def worked_example():
    value = 99
    product = 9 * value
    last_digit = product % 10
    print(f"N: {value}")
    print(f"9 times N: {product}")
    print(f"last digit: {last_digit}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", ["3", "99"])
    build()
    if "--trace" in sys.argv:
        worked_example()


if __name__ == "__main__":
    main()
