#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
STMT_PATH = ROOT.parent / "stmts" / "SMPSEQ7.txt"
STATEMENT = STMT_PATH.read_text() if STMT_PATH.exists() else None

SAMPLES = [
    ("5\n-1 2 -1 1 -1\n", "No\n"),
    ("6\n3 1 -2 -2 -1 3\n", "Yes\n"),
    ("6\n2 2 1 0 1 2\n", "No\n"),
]


def oracle(text):
    values = [int(token) for token in text.split()]
    length = values[0]
    sequence = values[1:1 + length]
    for split in range(1, length):
        first_part = sequence[:split]
        second_part = sequence[split:]
        decreasing = all(first_part[k] < first_part[k - 1]
                         for k in range(1, len(first_part)))
        increasing = all(second_part[k] > second_part[k - 1]
                         for k in range(1, len(second_part)))
        if decreasing and increasing:
            return "Yes\n"
    return "No\n"


for sample_input, sample_output in SAMPLES:
    if STATEMENT is not None:
        assert sample_input in STATEMENT
        assert sample_output in STATEMENT
    assert oracle(sample_input) == sample_output

assert oracle("2\n1 2\n") == "Yes\n"
assert oracle("2\n2 1\n") == "Yes\n"
assert oracle("3\n2 2 1\n") == "No\n"
assert oracle("4\n4 3 2 1\n") == "Yes\n"


def write(name, values):
    input_text = str(len(values)) + "\n" + " ".join(map(str, values)) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace(values):
    length = len(values)
    prefix = 1
    while prefix < length and values[prefix] < values[prefix - 1]:
        prefix += 1
    suffix = 1
    while suffix < length and values[length - suffix - 1] < values[length - suffix]:
        suffix += 1
    split = max(1, length - suffix)
    lines = [f"values: {values}", f"decreasing prefix length {prefix}",
             f"increasing suffix length {suffix}", f"candidate split {split}"]
    lines.append("answer Yes" if split <= prefix else "answer No")
    return "\n".join(lines)


write("1_sample", [-1, 2, -1, 1, -1])
write("2_edges", list(range(100)))
write("3_wide", list(range(100, 0, -1)))
random.seed(2026)
write("4_random", [random.randint(-100, 100) for _ in range(100)])
first_half = list(range(100, 50, -1))
second_half = list(range(-50, 0))
write("5_io", first_half + second_half)

if __name__ == "__main__":
    print(trace([3, 1, -2, -2, -1, 3]))
