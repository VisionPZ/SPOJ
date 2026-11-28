#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent

MONO_PATTERN = re.compile(r"([+-]?\d*)a([+-]?\d*)b([+-]?\d*)\Z")


def parse_monomial(token):
    match = MONO_PATTERN.match(token)
    assert match is not None, token
    return tuple(int(part or "0") for part in match.groups())


def format_expression(terms):
    parts = []
    for power_a, power_b in sorted(key for key, value in terms.items() if value != 0):
        coefficient = terms[(power_a, power_b)]
        sign = "-" if coefficient < 0 else ("+" if parts else "")
        magnitude = abs(coefficient)
        body = ""
        if magnitude != 1 or (power_a == 0 and power_b == 0):
            body += str(magnitude)
        if power_a > 0:
            body += "a" + (str(power_a) if power_a != 1 else "")
        elif power_a < 0:
            body += "a" + str(power_a)
        if power_b > 0:
            body += "b" + (str(power_b) if power_b != 1 else "")
        elif power_b < 0:
            body += "b" + str(power_b)
        parts.append(sign + body)
    return "".join(parts) if parts else "0"


def evaluate(commands):
    terms = {}
    lines = []
    for command in commands:
        kind = command[0]
        if kind == 3:
            lines.append(format_expression(terms))
            continue
        coefficient, power_a, power_b = command[1]
        key = (power_a, power_b)
        delta = coefficient if kind == 1 else -coefficient
        terms[key] = terms.get(key, 0) + delta
    return lines


def oracle(text):
    tokens = text.split()
    pos = 0
    cases = int(tokens[pos]); pos += 1
    lines = []
    for _ in range(cases):
        count = int(tokens[pos]); pos += 1
        commands = []
        for _ in range(count):
            kind = int(tokens[pos]); pos += 1
            if kind == 3:
                commands.append((3,))
            else:
                commands.append((kind, parse_monomial(tokens[pos])))
                pos += 1
        lines.extend(evaluate(commands))
    return "\n".join(lines) + ("\n" if lines else "")


SAMPLE = (
    "1\n11\n"
    "3\n"
    "1 2a1b1\n"
    "3\n"
    "1 1a2b0\n"
    "3\n"
    "2 1a0b2\n"
    "3\n"
    "2 1a5b1\n"
    "3\n"
    "1 1a2b0\n"
    "3\n"
)
SAMPLE_OUT = (
    "0\n2ab\n2ab+a2\n-b2+2ab+a2\n-b2+2ab+a2-a5b\n-b2+2ab+2a2-a5b\n"
)
assert oracle(SAMPLE) == SAMPLE_OUT
assert evaluate([(3,)]) == ["0"]
assert evaluate([(1, (3, 0, 0)), (3,)]) == ["3"]
assert evaluate([(1, (1, 1, 1)), (2, (1, 1, 1)), (3,)]) == ["0"]
assert evaluate([(1, (-1, 0, 1)), (3,)]) == ["-b"]


def write(name, cases):
    body = [str(len(cases)) + "\n"]
    for commands in cases:
        body.append(f"{len(commands)}\n")
        for command in commands:
            if command[0] == 3:
                body.append("3\n")
            else:
                _, (coefficient, power_a, power_b) = command
                body.append(f"{command[0]} {coefficient}a{power_a}b{power_b}\n")
    text = "".join(body)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [(3,), (1, (0, 0, 0)), (3,), (2, (1, 0, 0)), (3,)],
        [(1, (1, 10, 10)), (1, (2, 0, 10)), (2, (1, 10, 10)), (3,)],
        [(1, (-1, 1, 0)), (1, (1, 1, 0)), (3,), (2, (1, 5, 2)), (3,)],
        [(1, (10, 0, 0)), (2, (9, 0, 0)), (3,), (1, (1, 1, 2)), (3,)],
    ])

    random.seed(2026)
    wide = []
    for _ in range(101):
        commands = []
        for _ in range(101):
            if random.random() < 0.3:
                commands.append((3,))
            else:
                kind = random.choice([1, 2])
                commands.append((kind, (
                    random.randint(-10, 10),
                    random.randint(0, 10),
                    random.randint(0, 10),
                )))
        wide.append(commands)
    write("3_wide", wide)

    rnd = []
    for _ in range(50):
        commands = []
        for _ in range(50):
            if random.random() < 0.4:
                commands.append((3,))
            else:
                commands.append((random.choice([1, 2]), (
                    random.randint(-10, 10),
                    random.randint(0, 10),
                    random.randint(0, 10),
                )))
        rnd.append(commands)
    write("4_random", rnd)

    io_cases = []
    for _ in range(101):
        commands = []
        for _ in range(101):
            if random.random() < 0.6:
                commands.append((3,))
            else:
                commands.append((random.choice([1, 2]), (
                    random.randint(-10, 10),
                    random.randint(0, 10),
                    random.randint(0, 10),
                )))
        io_cases.append(commands)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [(3,), (1, (2, 1, 1)), (3,), (1, (1, 2, 0)), (3,),
     (2, (1, 0, 2)), (3,), (2, (1, 5, 1)), (3,), (1, (1, 2, 0)), (3,)],
])
build()
print("trace: 2ab + a2 - b2 - a5b + a2 -> -b2+2ab+2a2-a5b")
