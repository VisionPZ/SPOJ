#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SAMPLE_IN = "4 1 4 2 3\n5 1 4 2 -1 6\n0\n"
SAMPLE_OUT = "Jolly\nNot jolly\n"


def oracle(text):
    tk = text.split()
    i = 0
    out = []
    while i < len(tk):
        n = int(tk[i])
        i += 1
        if n == 0:
            break
        if i + n > len(tk):
            break
        seq = [int(x) for x in tk[i:i + n]]
        i += n
        want = set(range(1, n))
        got = set()
        for a, b in zip(seq, seq[1:]):
            got.add(abs(a - b))
        out.append("Jolly\n" if got == want else "Not jolly\n")
    return "".join(out)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def perm_jolly(n, rng):
    vals = [0]
    used = {0}
    steps = list(range(1, n))
    rng.shuffle(steps)
    for s in steps:
        cand = [vals[-1] + s, vals[-1] - s]
        rng.shuffle(cand)
        pick = None
        for c in cand:
            if c not in used:
                pick = c
                break
        if pick is None:
            for c in cand:
                if -10**9 <= c <= 10**9:
                    pick = c
                    break
        used.add(pick)
        vals.append(pick)
    return vals


def trace_example():
    seq = [1, 4, 2, 3]
    print("seq", seq)
    print("abs diffs", [abs(b - a) for a, b in zip(seq, seq[1:])])
    print("want", sorted(set(range(1, len(seq)))))
    bad = [1, 4, 2, -1, 6]
    print("bad diffs", [abs(b - a) for a, b in zip(bad, bad[1:])], "missing", sorted(set(range(1, 5)) - {abs(b - a) for a, b in zip(bad, bad[1:])}))


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("1 7\n0\n") == "Jolly\n"
assert oracle("2 5 6\n2 5 5\n0\n") == "Jolly\nNot jolly\n"
assert oracle("3 1 3 2\n3 1 2 2\n0\n") == "Jolly\nNot jolly\n"
assert oracle("0\n") == ""


def build():
    write("2_edges", "1 0\n1 -999999999\n2 0 1\n2 0 0\n3 0 1 2\n0\n")
    rng = random.Random(11184)
    cases = []
    for _ in range(120):
        n = rng.randint(1, 40)
        v = perm_jolly(n, rng)
        cases.append("%d %s\n" % (n, " ".join(str(x) for x in v)))
        w = list(v)
        if n > 2:
            j = rng.randrange(1, n)
            w[j] = w[j - 1]
        cases.append("%d %s\n" % (n, " ".join(str(x) for x in w)))
    cases.append("0\n")
    write("4_random", "".join(cases))
    big = []
    for _ in range(200):
        big.append("2999 " + " ".join(str(x) for x in perm_jolly(2999, rng)) + "\n")
    big.append("0\n")
    write("5_io", "".join(big))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_IN)
        build()
