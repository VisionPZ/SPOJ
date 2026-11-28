#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = "5\n"
SAMPLE_OUT = """1
2 1
3 2 1
4 3 2 1
5 4 3 2 1
"""


def oracle(input_text):
    tokens = input_text.split()
    lines = []
    for token in tokens:
        height = int(token)
        for row in range(1, height + 1):
            lines.append(" ".join(str(row - offset) for offset in range(row)))
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("2\n") == "1\n2 1\n"
assert oracle("1\n") == "1\n"
assert oracle("4\n") == "1\n2 1\n3 2 1\n4 3 2 1\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        print("height 5 row 3:", " ".join(str(3 - offset) for offset in range(3)))
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE_IN)
    write("2_edges", "1\n")
    write("3_wide", "100\n")
    write("4_random", "42\n")
    write("5_io", "100\n")
