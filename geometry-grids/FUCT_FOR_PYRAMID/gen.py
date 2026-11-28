#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = "5\n"
SAMPLE_OUT = """        *
      * * *
    * * * * *
  * * * * * * *
* * * * * * * * *
"""


def oracle(input_text):
    tokens = input_text.split()
    lines = []
    for token in tokens:
        height = int(token)
        for row in range(1, height + 1):
            indent = "  " * (height - row)
            stars = " ".join(["*"] * (2 * row - 1))
            lines.append(indent + stars)
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n") == "*\n"
assert oracle("2\n") == "  *\n* * *\n"
assert oracle("3\n") == "    *\n  * * *\n* * * * *\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        height = 5
        row = 3
        print("height 5 row 3:", "  " * (height - row) + " ".join(["*"] * (2 * row - 1)))
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE_IN)
    write("2_edges", "1\n")
    write("3_wide", "100\n")
    write("4_random", "37\n")
    write("5_io", "100\n")
