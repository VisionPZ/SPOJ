#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = b"4\nx\nmxx\nMxx\nMmxxMxx\xc2\xa0\n"
SAMPLE_OUT = "0.500000\n0.333333\n0.666667\n0.700000\n"


def convolution(first, second):
    result = [Fraction(0)] * (len(first) + len(second) - 1)
    for first_index, first_value in enumerate(first):
        for second_index, second_value in enumerate(second):
            result[first_index + second_index] += first_value * second_value
    return result


def parse_tree(expression, pos):
    symbol = expression[pos]
    pos += 1
    if symbol == "x":
        return [Fraction(0), Fraction(1)], pos
    left, pos = parse_tree(expression, pos)
    right, pos = parse_tree(expression, pos)
    product = convolution(left, right)
    if symbol == "M":
        return product, pos
    size = max(len(left), len(right), len(product))
    result = [Fraction(0)] * size
    for index in range(size):
        left_value = left[index] if index < len(left) else Fraction(0)
        right_value = right[index] if index < len(right) else Fraction(0)
        product_value = product[index] if index < len(product) else Fraction(0)
        result[index] = left_value + right_value - product_value
    return result, pos


def oracle(data):
    if isinstance(data, bytes):
        expression_bytes = bytes(char for char in data if char in b"Mmx")
        expressions = expression_bytes.decode("ascii")
    else:
        expressions = "".join(char for char in data if char in "Mmx")
    pos = 0
    answers = []
    while pos < len(expressions):
        symbol = expressions[pos]
        if symbol not in "Mmx":
            pos += 1
            continue
        coefficients, pos = parse_tree(expressions, pos)
        expected = Fraction(1)
        for index, coefficient in enumerate(coefficients):
            expected -= coefficient / Fraction(index + 1)
        answers.append("%.6f" % float(expected))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle(b"1\nx\n") == "0.500000\n"
assert oracle(b"1\nmxx\n") == "0.333333\n"
assert oracle(b"1\nMxx\n") == "0.666667\n"
assert oracle(b"1\nMmxxMxx\n") == "0.700000\n"
assert oracle(b"2\nx\nMxx\n") == "0.500000\n0.666667\n"


def make_expression(rng, leaf_count, shape):
    if shape == "left":
        expression = "x"
        for _ in range(leaf_count - 1):
            expression = rng.choice("Mm") + "x" + expression
        return expression
    if shape == "right":
        expression = "x"
        for _ in range(leaf_count - 1):
            expression = rng.choice("Mm") + expression + "x"
        return expression

    def build(leaves):
        if leaves == 1:
            return "x"
        left_leaves = rng.randint(1, leaves - 1)
        return rng.choice("Mm") + build(left_leaves) + build(leaves - left_leaves)

    return build(leaf_count)


def write(name, expressions):
    text = str(len(expressions)) + "\n" + "\n".join(expressions) + "\n"
    data = text.encode("ascii")
    (ROOT / "in" / (name + ".txt")).write_bytes(data)
    (ROOT / "out" / (name + ".out")).write_text(oracle(data))


def build():
    rng = random.Random(20261126)
    write("2_edges", ["x", "mxx", "Mxx", "MmxxMxx", "mmxxx", "MMxxx"])
    write("3_wide", [
        make_expression(rng, 50, "left"),
        make_expression(rng, 50, "right"),
    ])
    write("4_random", [make_expression(rng, 25, "random") for _ in range(20)])
    write("5_io", [make_expression(rng, 50, rng.choice(["left", "right"])) for _ in range(1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_bytes(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
