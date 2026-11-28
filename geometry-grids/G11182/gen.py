#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = (
    "MATCHES CHEESECAKE PICNIC EXCUSES\n"
    "PEANUT BANANA VACUUM GREEDY\n"
    "#\n"
)
SAMPLE_OUT = (
    "MATCHES CHEESECAKE PICNIC EXCUSES\n"
    " C\n"
    " H\n"
    " E\n"
    " E\n"
    " S\n"
    " E          E\n"
    " C          X\n"
    "MATCHES   PICNIC\n"
    " K          U\n"
    " E          S\n"
    "            E\n"
    "            S\n"
    "\n"
    "PEANUT BANANA VACUUM GREEDY\n"
    "Unable to make two crosses\n"
)


def leading_cross(hz, vt):
    for i, ch in enumerate(hz):
        j = vt.find(ch)
        if j >= 0:
            return i, j
    return None


def render(cells):
    if not cells:
        return ""
    return "".join(cells.get(c, " ") for c in range(max(cells) + 1))


def draw(w):
    lines = [" ".join(w)]
    a = leading_cross(w[0], w[1])
    b = leading_cross(w[2], w[3])
    if a is None or b is None:
        lines.append("Unable to make two crosses")
        return lines
    (c1, v1), (c3, v3) = a, b
    col2 = len(w[0]) + 3 + c3
    height = max(v1, v3)
    for off in range(height):
        cells = {}
        i1 = off - (height - v1)
        i3 = off - (height - v3)
        if i1 >= 0:
            cells[c1] = w[1][i1]
        if i3 >= 0:
            cells[col2] = w[3][i3]
        lines.append(render(cells))
    lines.append(w[0] + "   " + w[2])
    for off in range(max(len(w[1]) - v1 - 1, len(w[3]) - v3 - 1)):
        cells = {}
        i1 = v1 + 1 + off
        i3 = v3 + 1 + off
        if i1 < len(w[1]):
            cells[c1] = w[1][i1]
        if i3 < len(w[3]):
            cells[col2] = w[3][i3]
        lines.append(render(cells))
    return lines


def oracle(text):
    blocks = []
    for line in text.split("\n"):
        line = line.rstrip("\r")
        if line.strip() == "#":
            break
        w = line.split()
        if len(w) != 4:
            continue
        blocks.append(draw(w))
    return "".join(("\n" if bi else "") + "".join(x + "\n" for x in block) for bi, block in enumerate(blocks))


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def trace_example():
    w = ["MATCHES", "CHEESECAKE", "PICNIC", "EXCUSES"]
    a = leading_cross(w[0], w[1])
    b = leading_cross(w[2], w[3])
    print("cross 1:", a, "letter", w[0][a[0]])
    print("cross 2:", b, "letter", w[2][b[0]])
    print("line row:", repr(w[0] + "   " + w[2]))
    print("hang 1 above (top to line):", w[1][:a[1]])
    print("hang 1 below the line:", w[1][a[1] + 1:])
    print("hang 2 above:", w[3][:b[1]], " below:", w[3][b[1] + 1:])


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("#\n") == ""
assert oracle("AB CD EF GH\n#\n") == "AB CD EF GH\nUnable to make two crosses\n"
assert oracle("AAA BBB CCC DDD\n#\n") == "AAA BBB CCC DDD\nUnable to make two crosses\n"
assert oracle("CAT ACT DOG GOD\n#\n") == (
    "CAT ACT DOG GOD\n"
    "      G\n"
    "A     O\n"
    "CAT   DOG\n"
    "T\n"
)


def build():
    write("2_edges", "A B C D\nAAAAA BBBBB CCCCC DDDDD\n#\n")
    rng = random.Random(11182)

    def word():
        return "".join(rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ") for _ in range(rng.randint(1, 10)))

    cases = [" ".join(word() for _ in range(4)) for _ in range(400)]
    cases.append("#")
    write("4_random", "\n".join(cases) + "\n")
    write("5_io", "\n".join(" ".join(word() for _ in range(4)) for _ in range(20000)) + "\n#\n")


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_IN)
        build()
