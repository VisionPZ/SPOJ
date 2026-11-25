#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

OPERATOR_TEXT = {0: "and", 1: "or", 2: "xor"}


def parse_expression(text):
    words = text.split()
    values = []
    operators = []
    for word in words:
        if word in ("T", "true"):
            values.append("True")
        elif word in ("F", "false"):
            values.append("False")
        elif word == "and":
            operators.append("and")
        elif word == "or":
            operators.append("or")
        else:
            operators.append("^")
    return values, operators


def expressions(values, operators, low, high):
    if low == high:
        yield values[low]
        return
    for split in range(low, high):
        for left in expressions(values, operators, low, split):
            for right in expressions(values, operators, split + 1, high):
                yield "(" + left + " " + operators[split] + " " + right + ")"


def oracle_expression(text):
    values, operators = parse_expression(text)
    return sum(1 for expression in expressions(values, operators, 0, len(values) - 1)
               if eval(expression))


def oracle(text):
    lines = text.splitlines()
    case_count = int(lines[0])
    answers = []
    for line in lines[1:case_count + 1]:
        answers.append(str(oracle_expression(line)))
    return "".join(answer + "\n" for answer in answers)


SAMPLE = """1
T and F
"""
SAMPLE_OUT = """0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\nT\n") == "1\n"
assert oracle("1\nF\n") == "0\n"
assert oracle_expression("T or T and F xor T and T or F") == 37
assert oracle_expression("T or F and T xor F") == 5
assert oracle_expression("T or T") == 1
assert oracle_expression("T xor T") == 0


def write(name, expressions_text):
    text = str(len(expressions_text)) + "\n" + "".join(
        expression + "\n" for expression in expressions_text)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", ["T", "F", "T and T", "T and F", "F or F", "T xor F"])
    write("3_wide", [
        "T or T and F xor T and T or F",
        "T or F and T xor F",
        "T and T or T and F xor T",
        "F xor T and T or F and T",
    ])
    rng = random.Random(20261126)
    random_lines = []
    for _ in range(20):
        operand_count = rng.randint(4, 7)
        parts = []
        for index in range(operand_count):
            parts.append(rng.choice(["T", "F"]))
            if index + 1 < operand_count:
                parts.append(rng.choice(["and", "or", "xor"]))
        random_lines.append(" ".join(parts))
    write("4_random", random_lines)
    io_lines = []
    for _ in range(200):
        operand_count = rng.randint(3, 5)
        parts = []
        for index in range(operand_count):
            parts.append(rng.choice(["T", "F"]))
            if index + 1 < operand_count:
                parts.append(rng.choice(["and", "or", "xor"]))
        io_lines.append(" ".join(parts))
    write("5_io", io_lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
