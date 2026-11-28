#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_IN = """10
move 9 onto 1
move 8 over 1
move 7 over 1
move 6 over 1
pile 8 over 6
pile 8 over 5
move 2 over 1
move 4 over 9
quit
"""
SAMPLE_OUT = (
    "0: 0\n1: 1 9 2 4\n2:\n3: 3\n4:\n5: 5 8 7 6\n6:\n7:\n8:\n9:\n"
)


def simulate(n, cmds):
    piles = [[i] for i in range(n)]

    def find(x):
        for pi, pile in enumerate(piles):
            if x in pile:
                return pi, pile.index(x)
        return -1, -1

    def give_home(x):
        piles[x].append(x)

    for kind, a, rel, b in cmds:
        pa, ha = find(a)
        pb, hb = find(b)
        if kind == "pile":
            if pa == pb:
                continue
            if rel == "onto":
                while len(piles[pb]) > hb + 1:
                    give_home(piles[pb].pop())
            sub = piles[pa][ha:]
            del piles[pa][ha:]
            piles[pb].extend(sub)
        else:
            while len(piles[pa]) > ha + 1:
                give_home(piles[pa].pop())
            if rel == "onto":
                pb2, hb2 = find(b)
                while len(piles[pb2]) > hb2 + 1:
                    give_home(piles[pb2].pop())
            pa = find(a)[0]
            pb = find(b)[0]
            piles[pb].append(piles[pa].pop())
    return "".join("%d:%s\n" % (i, (" " + " ".join(str(x) for x in piles[i])) if piles[i] else "") for i in range(n))


def oracle(text):
    lines = [l.strip() for l in text.split("\n") if l.strip()]
    if not lines:
        return ""
    n = int(lines[0])
    cmds = []
    for line in lines[1:]:
        tk = line.split()
        if tk[0] == "quit":
            break
        cmds.append((tk[0], int(tk[1]), tk[2], int(tk[3])))
    return simulate(n, cmds)


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def trace_example():
    piles = [[i] for i in range(10)]
    print("start:", piles[1])
    print("move 9 onto 1 ->", piles[1] + [9])
    print("after 4 moves pile 1 holds [1,9,8,7,6]")
    print("pile 8 over 6: same pile, no-op")
    print("pile 8 over 5: sub [8,7,6] joins pile 5 ->", [5, 8, 7, 6])
    print("move 2 over 1 ->", [1, 9, 2])
    print("move 4 over 9 ->", [1, 9, 2, 4])


assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert oracle("4\nquit\n") == "0: 0\n1: 1\n2: 2\n3: 3\n"
assert oracle("3\nmove 0 onto 2\nquit\n") == "0:\n1: 1\n2: 2 0\n"
assert oracle("3\nmove 1 over 1\nquit\n") == "0: 0\n1: 1\n2: 2\n"


def build():
    write("2_edges", "1\nquit\n")
    write("3_same_pile", "4\nmove 1 over 0\nmove 2 over 0\nmove 3 over 1\npile 2 over 1\nmove 3 onto 0\npile 0 over 3\nquit\n")
    rng = random.Random(11183)

    def case(n, steps):
        cmds = []
        for _ in range(steps):
            a = rng.randrange(n)
            b = rng.randrange(n)
            if a == b:
                continue
            cmds.append("%s %d %s %d" % (rng.choice(["move", "pile"]), a, rng.choice(["onto", "over"]), b))
        cmds.append("quit")
        return "%d\n%s\n" % (n, "\n".join(cmds))

    for t in range(8):
        write("4_random_%d" % t, case(rng.randint(2, 24), 80))
    write("5_io", case(24, 100000))


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", SAMPLE_IN)
        build()
