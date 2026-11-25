#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE_IN = "5 1\n"
SAMPLE_OUT = "-1 0 1 2 3\n0 1 2 3 4\n1 2 3 4 5\n2 3 4 5 6\n3 4 5 6 7\n75\n7\n-1\n"


def oracle(text):
    tk = text.split()
    if len(tk) < 2:
        return ""
    n, k = int(tk[0]), int(tk[1])
    rows = []
    flat = []
    for i in range(n):
        row = [i + j - k for j in range(n)]
        rows.append(" ".join(str(x) for x in row))
        flat.extend(row)
    if not flat:
        return "".join(r + "\n" for r in rows)
    return "".join(r + "\n" for r in rows) + "%d\n%d\n%d\n" % (sum(flat), max(flat), min(flat))


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def trace_example():
    n, k = 5, 1
    print("n=%d k=%d closed form sum=%d" % (n, k, n * n * (n - 1 - k)))
    print("loop sum=%d" % sum(i + j - k for i in range(n) for j in range(n)))
    print("corners: min=%d max=%d" % (0 + 0 - k, n - 1 + n - 1 - k))


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1 20\n") == "-20\n-20\n-20\n-20\n"
assert oracle("4 2\n") == "-2 -1 0 1\n-1 0 1 2\n0 1 2 3\n1 2 3 4\n16\n4\n-2\n"
assert oracle("2 0\n") == "0 1\n1 2\n4\n2\n0\n"


def build():
    write("2_edges", "1 0\n")
    write("3_negative", "3 100\n")
    rng = random.Random(115)
    for t in range(8):
        write("4_random_%d" % t, "%d %d\n" % (rng.randint(1, 30), rng.randint(-1000, 1000)))
    write("5_io", "300 7\n")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_IN)
        build()
