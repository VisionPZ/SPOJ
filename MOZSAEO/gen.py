#!/usr/bin/env python3
import random
import sys
from pathlib import Path

sys.set_int_max_str_digits(0)

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\n1 2\n2 2\n"
SAMPLE_OUT = "odd\neven\n"


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(case_count):
        first_number = tokens[cursor]
        cursor += 1
        second_number = tokens[cursor]
        cursor += 1
        if (int(first_number) + int(second_number)) % 2 == 0:
            answers.append("even")
        else:
            answers.append("odd")
    return "\n".join(answers) + "\n"


def write(name, pairs):
    input_text = str(len(pairs)) + "\n"
    input_text += "".join("%s %s\n" % (first, second) for first, second in pairs)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1\n0 0\n") == "even\n"
assert oracle("1\n999999 1\n") == "even\n"
assert oracle("3\n1 0\n7 7\n123456789 987654321\n") == "odd\neven\neven\n"


def trace_example():
    for first, second in [(1, 2), (2, 2)]:
        print("pair", first, second)
        print("sum", first + second)
        print("answer", "even" if (first + second) % 2 == 0 else "odd")


def build():
    write("2_edges", [("0", "0"), ("0", "1"), ("1", "0"), ("9", "9")])

    power = "1" + "0" * 50000
    wide = [(power, "0"), ("9" * 50000, "1"), (power, power)]
    write("3_wide", wide)

    rng = random.Random(50431)
    random_pairs = []
    for _ in range(50):
        first_length = rng.randint(1, 200)
        second_length = rng.randint(1, 200)
        first = "".join(str(rng.randint(0, 9)) for _ in range(first_length))
        second = "".join(str(rng.randint(0, 9)) for _ in range(second_length))
        random_pairs.append((first, second))
    write("4_random", random_pairs)

    io_pairs = []
    for index in range(50):
        first = str(index) * 20
        second = str(49 - index) * 20
        io_pairs.append((first, second))
    write("5_io", io_pairs)


if __name__ == "__main__":
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [("1", "2"), ("2", "2")])
        build()
