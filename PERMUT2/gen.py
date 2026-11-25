#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "4\n1 4 3 2\n5\n2 3 4 5 1\n1\n1\n0\n"
SAMPLE_OUTPUT = "ambiguous\nnot ambiguous\nambiguous\n"


def build_inverse(perm):
    n = len(perm) - 1
    inverse = [0] * (n + 1)
    for position in range(1, n + 1):
        inverse[perm[position]] = position
    return inverse


def oracle(cases):
    answers = []
    for perm in cases:
        n = len(perm) - 1
        inverse = build_inverse(perm)
        matches = True
        for value in range(1, n + 1):
            if perm[value] != inverse[value]:
                matches = False
                break
        answers.append("ambiguous" if matches else "not ambiguous")
    return "\n".join(answers) + "\n"


def brute(perm):
    n = len(perm) - 1
    inverse = [perm.index(value) for value in range(1, n + 1)]
    return inverse == perm[1:]


def identity(n):
    return [0] + list(range(1, n + 1))


def reversal(n):
    return [0] + list(range(n, 0, -1))


def random_permutation(n, rng):
    values = list(range(1, n + 1))
    rng.shuffle(values)
    return [0] + values


def random_involution(n, rng):
    values = list(range(1, n + 1))
    rng.shuffle(values)
    perm = [0] * (n + 1)
    idx = 0
    while idx < n:
        if idx + 1 < n and rng.random() < 0.5:
            perm[values[idx]] = values[idx + 1]
            perm[values[idx + 1]] = values[idx]
            idx += 2
        else:
            perm[values[idx]] = values[idx]
            idx += 1
    return perm


def render_input(cases):
    return "".join(
        f"{len(perm) - 1}\n" + " ".join(str(value) for value in perm[1:]) + "\n"
        for perm in cases
    ) + "0\n"


def write(name, cases):
    input_text = render_input(cases)
    if name == "1_sample":
        assert input_text == SAMPLE_INPUT
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))


SAMPLE_CASES = [[0, 1, 4, 3, 2], [0, 2, 3, 4, 5, 1], [0, 1]]

assert oracle(SAMPLE_CASES) == SAMPLE_OUTPUT
assert brute([0, 1, 4, 3, 2]) is True
assert brute([0, 2, 3, 4, 5, 1]) is False
assert brute([0, 2, 1, 3, 4]) is True
for check_size in range(1, 9):
    for check_seed in range(12):
        check_rng = random.Random(check_size * 100 + check_seed)
        check_perm = random_permutation(check_size, check_rng)
        expected = "ambiguous\n" if brute(check_perm) else "not ambiguous\n"
        assert oracle([check_perm]) == expected


def build():
    write("1_sample", SAMPLE_CASES)

    write("2_edges", [
        [0, 1],
        [0, 2, 1],
        [0, 1, 2],
        [0, 2, 3, 1],
        [0, 3, 2, 1],
        [0, 1, 2, 3],
        identity(100000),
        reversal(100000),
    ])

    wide_rng = random.Random(424242)
    write("3_wide", [
        [0, 1],
        identity(100000),
        reversal(100000),
        random_involution(100000, wide_rng),
    ])

    rng = random.Random(20261125)
    random_cases = []
    for size in (1, 2, 3, 4, 5, 7, 10, 50, 100, 1000, 10000):
        random_cases.append(random_permutation(size, rng))
        random_cases.append(random_involution(size, rng))
    random_cases.append(random_permutation(100000, rng))
    random_cases.append(random_involution(100000, rng))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(150000):
        io_cases.append([0, 1])
        io_cases.append([0, 2, 3, 1])
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
build()

print("worked example: n = 4, permutation 1 4 3 2")
trace_perm = [0, 1, 4, 3, 2]
trace_inverse = build_inverse(trace_perm)
for position in range(1, 5):
    twice = trace_perm[trace_perm[position]]
    print(f"  k={position}: P(k)={trace_perm[position]} inverse(k)={trace_inverse[position]} P(P(k))={twice}")
print("answer: ambiguous")

print("worked example: n = 5, permutation 2 3 4 5 1")
trace_perm = [0, 2, 3, 4, 5, 1]
for position in range(1, 6):
    twice = trace_perm[trace_perm[position]]
    print(f"  k={position}: P(k)={trace_perm[position]} P(P(k))={twice}")
    if twice != position:
        break
print("answer: not ambiguous")
