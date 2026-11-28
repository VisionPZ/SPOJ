#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(cases):
    answer_lines = []
    for operator, first_text, second_text in cases:
        opcode = int(operator, 2)
        first = int(first_text, 2)
        second = int(second_text, 2)
        if opcode == 0:
            answer_lines.append("1" if first > second else "0")
        elif opcode == 1:
            answer_lines.append(bin(first + second)[2:])
        elif opcode == 2:
            if first < second:
                shift = max(first, second).bit_length()
                first += 1 << shift
            answer_lines.append(bin(first - second)[2:])
        elif opcode == 3:
            answer_lines.append(bin(first * second)[2:])
        elif opcode == 4:
            if second == 0:
                answer_lines.append("0 0")
            else:
                answer_lines.append(bin(first // second)[2:] + " "
                                    + bin(first % second)[2:])
    return "\n".join(answer_lines) + "\n"


SAMPLE = [("0", "10", "10"), ("1", "10", "11"), ("0", "11", "10\u00a0"),
          ("11", "101", "11"), ("10", "11", "10"), ("100", "1011", "11"),
          ("10", "10", "11")]
SAMPLE_OUT = "0\n101\n1\n1111\n1\n11 10\n11\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle([("100", "0", "1")]) == "0 0\n"
assert oracle([("10", "100", "101")]) == "111\n"
assert oracle([("1", bin(2**200 - 1)[2:], "1")]) == bin(2**200)[2:] + "\n"
assert oracle([("100", bin(2**199)[2:], bin(2**100)[2:])]) == \
    (bin(2**99)[2:] + " 0\n")


def write(name, cases):
    input_text = bin(len(cases))[2:] + "\n"
    input_text += "".join(f"{op} {first} {second}\n" for op, first, second in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


write("1_sample", SAMPLE)
write("2_edges", [
    ("100", "0", "0"), ("100", "0", "1"), ("100", "1", "0"),
    ("10", "0", "0"), ("10", "0", "1"), ("10", "1", "1"),
    ("10", "101", "1000"), ("0", "0", "0"), ("0", "1", "0"),
    ("1", "0", "0"), ("11", "0", "111"), ("11", "111", "0"),
])

wide = []
for exponent in (60, 100, 199, 200):
    wide.append(("1", bin(2**exponent - 1)[2:], "1"))
    wide.append(("11", bin(2**(exponent - 1))[2:], bin(2**(exponent - 1))[2:]))
    wide.append(("100", bin(2**exponent - 1)[2:], bin(2**(exponent // 2))[2:]))
    wide.append(("10", bin(2**exponent - 1)[2:], bin(2**exponent - 3)[2:]))
    wide.append(("0", bin(2**exponent - 1)[2:], bin(2**exponent - 2)[2:]))
write("3_wide", wide)

random.seed(2026)
operators = ["0", "1", "10", "11", "100"]
random_cases = []
for _ in range(200):
    op = random.choice(operators)
    bits_first = random.randint(1, 200)
    bits_second = random.randint(1, 200)
    first = random.getrandbits(bits_first)
    second = random.getrandbits(bits_second)
    if op == "100" and random.random() < 0.1:
        second = 0
    random_cases.append((op, bin(first)[2:], bin(second)[2:]))
write("4_random", random_cases)

io_cases = []
for _ in range(300):
    op = operators[_ % 5]
    first = random.getrandbits(random.randint(1, 200))
    second = random.getrandbits(random.randint(1, 200))
    io_cases.append((op, bin(first)[2:], bin(second)[2:]))
write("5_io", io_cases)
