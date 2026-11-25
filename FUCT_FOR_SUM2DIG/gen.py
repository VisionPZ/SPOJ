#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = "8\n"
SAMPLE_OUT = """17 = 1 + 7 = 8
26 = 2 + 6 = 8
35 = 3 + 5 = 8
44 = 4 + 4 = 8
53 = 5 + 3 = 8
62 = 6 + 2 = 8
71 = 7 + 1 = 8
80 = 8 + 0 = 8
"""


def oracle(input_text):
    lines = []
    for token in input_text.split():
        target = int(token)
        found = []
        for value in range(10, 100):
            tens = value // 10
            ones = value % 10
            if tens + ones == target:
                found.append("%d = %d + %d = %d" % (value, tens, ones, target))
        if found:
            lines.extend(found)
        else:
            lines.append("NO")
    return "\n".join(lines) + "\n"


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1\n") == "10 = 1 + 0 = 1\n"
assert oracle("18\n") == "99 = 9 + 9 = 18\n"
assert oracle("19\n") == "NO\n"
assert oracle("0\n") == "NO\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        target = 8
        hits = [v for v in range(10, 100) if v // 10 + v % 10 == target]
        print("target 8 scan 10..99 hits:", hits)
        raise SystemExit
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", SAMPLE_IN)
    write("2_edges", "1\n")
    write("3_wide", "18\n")
    write("4_random", "9\n")
    write("5_io", "9\n")
