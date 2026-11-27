#!/usr/bin/env python3
import random
from itertools import accumulate
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STMT_PATH = ROOT.parent / "stmts" / "SMPSEQ8.txt"
STATEMENT = STMT_PATH.read_text() if STMT_PATH.exists() else None

SAMPLES = [
    ("5\n-2 -1 0 1 4\n6\n-3 -2 -1 1 2 3\n", "-2 -1 0 1 4\n"),
    ("5\n-2 -1 0 1 2\n6\n-3 -2 -1 1 2 3\n", "-3 -2 -1 1 2 3\n"),
]


def oracle(text):
    values = [int(token) for token in text.split()]
    first_length = values[0]
    first = values[1:1 + first_length]
    second_length = values[1 + first_length]
    second = values[2 + first_length:2 + first_length + second_length]
    first_total = list(accumulate(first))[-1]
    second_total = list(accumulate(second))[-1]
    chosen = first if second_total < first_total else second
    return " ".join(map(str, chosen)) + "\n"


for sample_input, sample_output in SAMPLES:
    if STATEMENT is not None:
        assert sample_input in STATEMENT
        assert sample_output in STATEMENT
    assert oracle(sample_input) == sample_output

assert oracle("2\n-1 -2\n2\n5 5\n") == "5 5\n"
assert oracle("2\n5 5\n2\n1 1\n") == "5 5\n"
assert oracle("2\n1 2\n2\n-1 -2\n") == "1 2\n"
assert oracle("2\n1 2\n2\n3 0\n") == "3 0\n"
assert oracle("2\n-100 -100\n2\n100 100\n") == "100 100\n"


def write(name, first, second):
    input_text = (f"{len(first)}\n" + " ".join(map(str, first)) + "\n"
                  + f"{len(second)}\n" + " ".join(map(str, second)) + "\n")
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace(first, second):
    first_total = sum(first)
    second_total = sum(second)
    chosen = first if second_total < first_total else second
    lines = [f"first sum {first_total}", f"second sum {second_total}"]
    lines.append(f"second sum below first sum: {second_total < first_total}")
    lines.append("answer " + " ".join(map(str, chosen)))
    return "\n".join(lines)


write("1_sample", [-2, -1, 0, 1, 4], [-3, -2, -1, 1, 2, 3])
write("2_edges", [-100, -100], [100, 100])
write("3_wide", [100] * 100, [-100] * 100)
random.seed(2026)
write("4_random", [random.randint(-100, 100) for _ in range(100)],
      [random.randint(-100, 100) for _ in range(100)])
write("5_io", [100] * 100, [100] * 100)

if __name__ == "__main__":
    print(trace([-2, -1, 0, 1, 4], [-3, -2, -1, 1, 2, 3]))
