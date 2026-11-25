#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    answers = []
    for line in lines:
        tokens = line.split()
        if not tokens:
            answers.append("ERROR")
            continue
        pieces = []
        bad = False
        for token in tokens:
            if token in ("+", "-", "*", "/"):
                if len(pieces) < 2:
                    bad = True
                    break
                right = pieces.pop()
                left = pieces.pop()
                pieces.append("(" + left + token + right + ")")
            else:
                try:
                    number = float(token)
                except ValueError:
                    bad = True
                    break
                pieces.append(repr(number))
        if bad or len(pieces) != 1:
            answers.append("ERROR")
            continue
        try:
            value = eval(pieces[0], {"__builtins__": {}}, {})
        except (ZeroDivisionError, OverflowError, ValueError):
            answers.append("ERROR")
            continue
        answers.append(format(value, ".4f"))
    return "\n".join(answers) + "\n"


def write(name, lines):
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [
    "1 2 3 /",
    "2 3 /",
    "3 4 * /",
    "1 2 4 + - 5 * 7 /",
]
assert oracle("\n".join(SAMPLE) + "\n") == "ERROR\n0.6667\nERROR\n-3.5714\n"
assert oracle("5\n") == "5.0000\n"
assert oracle("1 3 /\n") == "0.3333\n"
assert oracle("1 8 /\n") == "0.1250\n"
assert oracle("1 0 /\n") == "ERROR\n"
assert oracle("1 2\n") == "ERROR\n"
assert oracle("\n") == "ERROR\n"


def number_token(rng):
    choice = rng.random()
    if choice < 0.45:
        return str(rng.randint(1, 9))
    if choice < 0.75:
        return f"{rng.randint(1, 9)}.{rng.randint(0, 99):02d}"
    if choice < 0.9:
        return f"{rng.randint(1, 9)}e{rng.randint(0, 2)}"
    return "-" + str(rng.randint(1, 9))


def build_valid(rng, steps):
    tokens = []
    stack_size = 0
    for _ in range(steps):
        if stack_size < 2 or (stack_size < 4 and rng.random() < 0.5):
            tokens.append(number_token(rng))
            stack_size += 1
        else:
            tokens.append(rng.choice(["+", "-", "*", "/"]))
            stack_size -= 1
    while stack_size > 1:
        tokens.append(rng.choice(["+", "-", "*"]))
        stack_size -= 1
    if stack_size == 0:
        tokens.append(number_token(rng))
    return tokens


def random_case(rng):
    tokens = build_valid(rng, rng.randint(1, 10))
    mode = rng.randint(0, 4)
    if mode == 0:
        return " ".join(tokens)
    if mode == 1:
        return " ".join(tokens + [number_token(rng)])
    if mode == 2:
        tokens[rng.randrange(len(tokens))] = "?"
        return " ".join(tokens)
    if mode == 3:
        return " ".join(["+"] + tokens)
    return " ".join(tokens + ["/"])


write("1_sample", SAMPLE)
write("2_edges", [
    "1 2",
    "",
    "5",
    "1 0 /",
    "foo 1 +",
    "1 2 + +",
    "1 2 3 +",
    "1.2.3",
    "+ 1 2 +",
    "1 2 /",
    "1 3 /",
    "1 8 /",
    "22 7 /",
    "1e2 3 /",
    "-5 2 /",
    "1.5 2.25 *",
    "0 -1 *",
    "-0",
])
rounding = [
    "1 3 /", "2 3 /", "1 6 /", "1 7 /", "1 8 /", "1 16 /", "1 9 /",
    "5 7 /", "10 3 /", "100 7 /", "1 11 /", "1 12 /", "1 13 /", "1 15 /",
]
long_expression = build_valid(random.Random(7), 80)
write("3_wide", rounding + [" ".join(long_expression)])
random.seed(2026)
write("4_random", [random_case(random) for _ in range(200)])
io_rng = random.Random(90210)
write("5_io", [random_case(io_rng) for _ in range(10000)])
