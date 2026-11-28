#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = """15
< 1000 1999
< 9898 9898
< 1234 123
< 0 0
+ 1791593436984766559642626609333245051871 307634751338542477034677711517175
- 1000000000000000000000000000000000000000000000 1
- 9851454318615645743724544440468029862 40153566442954896526103872421591156
* 333333333 0
* 1 3333333335555
* 9999999999999999999999999999999999999999 999999999999999999999999999999999999999
/ 1 999999999999999999999999999999999999999999999
/ 999999999999999999999999999999999999999999999 2
/ 861564574372454444046802986230763475133854247703 6442954896526103872421591156
# 1010 2020 1
# 619665458372652911688999608 5642672187122910629212227277 6
"""

SAMPLE_OUT = """1
0
-1
0
1791593744619517898185103644010956569046
999999999999999999999999999999999999999999999
9811300752172690847198440568046438706
0
3333333335555
9999999999999999999999999999999999999989000000000000000000000000000000000000001
0 1
499999999999999999999999999999999999999999999 1
133721962703322764598 5829723863328422309867552415
20400
3496569047280138337581751280571264068913704
"""


def base_hundred_digits(text):
    result = []
    while text:
        result.append(int(text[-2:]))
        text = text[:-2]
    return result


def truncated_product(left, right, skip):
    left_digits = base_hundred_digits(left)
    right_digits = base_hundred_digits(right)
    convolution = [0] * (len(left_digits) + len(right_digits) - 1)
    for left_index, left_digit in enumerate(left_digits):
        for right_index, right_digit in enumerate(right_digits):
            convolution[left_index + right_index] += left_digit * right_digit
    carry = 0
    rendered = ""
    for coefficient in convolution[skip:]:
        coefficient += carry
        rendered = f"{coefficient % 100:02d}" + rendered
        carry = coefficient // 100
    while carry:
        rendered = f"{carry % 100:02d}" + rendered
        carry //= 100
    return str(int(rendered)) if rendered else "0"


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(count):
        operation = tokens[cursor]; cursor += 1
        first = int(tokens[cursor]); cursor += 1
        second = int(tokens[cursor]); cursor += 1
        if operation == "#":
            skip = int(tokens[cursor]); cursor += 1
            answers.append(truncated_product(str(first), str(second), skip))
        elif operation == "<":
            answers.append("1" if first < second else ("0" if first == second else "-1"))
        elif operation == "+":
            answers.append(str(first + second))
        elif operation == "-":
            answers.append(str(first - second if first >= second else 0))
        elif operation == "*":
            answers.append(str(first * second))
        elif operation == "/":
            if second == 0:
                answers.append("0 0")
            else:
                answers.append(f"{first // second} {first % second}")
        else:
            raise ValueError(operation)
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert truncated_product("910", "820", 1) == "7460"
assert truncated_product("910", "820", 2) == "72"
assert truncated_product("0", "12345", 3) == "0"


def write(name, cases):
    lines = [str(len(cases))]
    for case in cases:
        lines.append(" ".join(str(field) for field in case))
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def big_number(rng, length):
    value = str(rng.randint(1, 9))
    while len(value) < length:
        value += str(rng.randint(0, 9))
    return value


def build():
    write("2_edges", [
        ("<", 0, 0), ("<", 0, 1), ("<", 1, 0),
        ("+", 0, 0), ("-", 0, 1), ("*", 0, 0),
        ("/", 1, 0), ("/", 0, 0), ("/", 10**40, 1),
        ("#", 910, 820, 1), ("#", 910, 820, 2), ("#", 0, 999, 0),
        ("#", 1, 1, 50), ("#", 10**80, 10**60, 70),
    ])

    large_left = "9" * 160
    large_right = "1234567890" * 18
    write("3_wide", [
        ("<", large_left, large_right),
        ("+", large_left, large_right),
        ("-", large_left, large_right),
        ("-", large_right, large_left),
        ("*", large_left, large_right),
        ("/", large_left, large_right),
        ("/", large_right, large_left),
        ("#", large_left, large_right, 1),
        ("#", large_left, large_right, 90),
        ("#", large_left, large_right, 200),
        ("*", "1" + "0" * 200, "1" + "0" * 200),
        ("/", "1" + "0" * 200, "3"),
    ])

    rng = random.Random(20261125)
    operations = ["<", "+", "-", "*", "/", "#"]
    random_cases = []
    for _ in range(120):
        operation = rng.choice(operations)
        left = big_number(rng, rng.randint(1, 110))
        right = big_number(rng, rng.randint(1, 110))
        if rng.random() < 0.08:
            right = "0"
        if operation == "#":
            random_cases.append((operation, left, right, rng.randint(0, 120)))
        else:
            random_cases.append((operation, left, right))
    write("4_random", random_cases)

    io_cases = []
    for index in range(220):
        operation = operations[index % len(operations)]
        left = big_number(rng, 60 + index % 80)
        right = big_number(rng, 40 + index % 70)
        if operation == "#":
            io_cases.append((operation, left, right, index % 130))
        else:
            io_cases.append((operation, left, right))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [tuple(line.split()) for line in SAMPLE_IN.strip().splitlines()[1:]])
build()
