#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "1234567890\n50\n"
SAMPLE_OUT = "51234567890\n"


def restore_brute(written, digit_total):
    digit_sum = sum(int(ch) for ch in written)
    missing = digit_total - digit_sum
    best = None
    for position in range(len(written) + 1):
        candidate = written[:position] + str(missing) + written[position:]
        if candidate[0] == "0":
            continue
        if best is None or int(candidate) > int(best):
            best = candidate
    return best


def oracle(input_text):
    tokens = input_text.split()
    answers = []
    index = 0
    while index + 1 < len(tokens):
        written = tokens[index]
        digit_total = int(tokens[index + 1])
        index += 2
        answers.append(restore_brute(written, digit_total))
    return "".join(answer + "\n" for answer in answers)


def write(name, cases):
    input_text = "".join("%s\n%d\n" % (written, digit_total) for written, digit_total in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    written = "1234567890"
    digit_total = 50
    digit_sum = sum(int(ch) for ch in written)
    print("written 1234567890")
    print("digit sum %d, target %d, missing %d" % (digit_sum, digit_total, digit_total - digit_sum))
    print("insert 5 before the first digit smaller than 5 -> 51234567890")


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1111111111\n10\n") == "11111111110\n"
assert oracle("9999999999\n90\n") == "99999999990\n"
assert oracle("1234567890\n45\n") == "12345678900\n"
assert oracle("0123456789\n46\n") == "10123456789\n"
assert oracle("9999911111\n55\n") == "99999511111\n"
assert oracle("1111111119\n19\n") == "11111111191\n"
assert oracle("1234567890\n50\n1111111111\n11\n") == "51234567890\n11111111111\n"


def build():
    rng = random.Random(1971)
    write("2_edges", [("1111111111", 11), ("9999999999", 99), ("1000000000", 10),
                      ("1234567890", 45), ("9999911111", 55), ("0123456789", 46)])
    write("3_wide", [("1111111111", 19), ("9999999999", 90), ("1000000000", 10),
                     ("0000000001", 10), ("1234567890", 54)])
    random_cases = []
    for _ in range(200):
        digits = [rng.randint(0, 9) for _ in range(10)]
        written = "".join(str(d) for d in digits)
        missing = rng.randint(1, 9) if written[0] == "0" else rng.randint(0, 9)
        random_cases.append((written, sum(digits) + missing))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(100000):
        digits = [rng.randint(0, 9) for _ in range(10)]
        written = "".join(str(d) for d in digits)
        missing = rng.randint(1, 9) if written[0] == "0" else rng.randint(0, 9)
        io_cases.append((written, sum(digits) + missing))
    write("5_io", io_cases)
    write("6_front", [("1111111111", 19), ("2222222222", 20), ("1234567890", 54)])
    write("7_end", [("1234567899", 54), ("1111111119", 19), ("2222222222", 20)])


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
        build()
