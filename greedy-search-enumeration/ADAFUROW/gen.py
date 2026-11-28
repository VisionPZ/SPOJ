#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    lines = text.split('\n')
    query_count = int(lines[0])
    stored = {}
    answers = []
    for line in lines[1:1 + query_count]:
        parts = line.split()
        if not parts:
            continue
        operation = parts[0]
        left = int(parts[1])
        right = int(parts[2])
        first = stored.setdefault(left, set())
        second = stored.get(right, set())
        if operation == '+':
            first.add(right)
        elif operation == '-':
            first.discard(right)
        elif operation == 'v':
            answers.append(str(len(first | second)))
        elif operation == '^':
            answers.append(str(len(first & second)))
        elif operation == '!':
            answers.append(str(len(first ^ second)))
        elif operation == '\\':
            answers.append(str(len(first - second)))
    return '\n'.join(answers) + '\n' if answers else ''


SAMPLE = """10
+ 1 4
! 0 2
+ 0 2
\\ 0 2
^ 0 1
v 2 0
+ 2 4
! 2 0
+ 1 0
! 0 2
"""
SAMPLE_OUT = """0
1
0
1
2
2
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n+ 0 0\n! 0 0\n") == "0\n"
assert oracle("4\n+ 0 5\n+ 1 5\n^ 0 1\n\\ 0 1\n") == "1\n0\n"
assert oracle("3\n+ 3 3\nv 3 9\n! 3 3\n") == "1\n0\n"
assert oracle("3\n+ 0 1\n- 0 1\nv 0 0\n") == "0\n"


def generate(seed, query_count, furrow_count, kind_count, weights):
    rng = random.Random(seed)
    operations = []
    stored = {}
    for _ in range(query_count):
        operation = rng.choices(weights[0], weights=weights[1])[0]
        if operation in ('+', '-'):
            left = rng.randrange(furrow_count)
            present = stored.setdefault(left, set())
            if operation == '-' and not present:
                operation = '+'
            if operation == '+':
                available = [kind for kind in range(kind_count) if kind not in present]
                if not available:
                    operation = '-'
            if operation == '+':
                right = rng.choice(available)
                present.add(right)
            else:
                right = rng.choice(sorted(present))
                present.discard(right)
            operations.append(f"{operation} {left} {right}")
        else:
            left = rng.randrange(furrow_count)
            right = rng.randrange(furrow_count)
            operations.append(f"{operation} {left} {right}")
    return str(query_count) + '\n' + '\n'.join(operations) + '\n'


def write(name, text):
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(text))


def build():
    edges = """8
! 0 1
^ 0 1
\\ 0 1
v 0 1
+ 0 20000
! 0 1
- 0 20000
v 0 1
"""
    write("2_edges", edges)
    wide = generate(20260101, 4000, 20001, 20001, (['+', 'v', '^', '!', '\\'], [4, 1, 1, 1, 1]))
    write("3_wide", wide)
    random_case = generate(20261126, 6000, 40, 60, (['+', '-', 'v', '^', '!', '\\'], [4, 2, 2, 2, 2, 2]))
    write("4_random", random_case)
    io_case = generate(20261202, 50000, 20, 40, (['v', '^', '!', '\\'], [1, 1, 1, 1]))
    write("5_io", io_case)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
