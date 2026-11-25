#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text, trace=False):
    tokens = text.split()
    cursor = 0
    lines = []
    while cursor < len(tokens):
        people_count = int(tokens[cursor]); cursor += 1
        sequence_length = int(tokens[cursor]); cursor += 1
        if people_count == 0 and sequence_length == 0:
            break
        sequences = tokens[cursor:cursor + people_count]
        cursor += people_count
        ordered = sorted(sequences)
        histogram = [0] * (people_count + 1)
        run_start = 0
        while run_start < len(ordered):
            run_end = run_start + 1
            while run_end < len(ordered) and ordered[run_end] == ordered[run_start]:
                run_end += 1
            copies = run_end - run_start
            histogram[copies] += 1
            if trace:
                print(f"sequence {ordered[run_start]} appears {copies} time(s)")
            run_start = run_end
        if trace:
            print("histogram " + " ".join(str(value) for value in histogram[1:]))
        lines.extend(str(value) for value in histogram[1:])
    return "\n".join(lines) + "\n" if lines else ""


SAMPLE = """9 6
AAAAAA
ACACAC
GTTTTG
ACACAC
GTTTTG
ACACAC
ACACAC
TCCCCC
TCCCCC
0 0
"""
SAMPLE_OUT = """1
2
0
1
0
0
0
0
0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\nA\n0 0\n") == "1\n"
assert oracle("3 1\nA\nA\nA\n0 0\n") == "0\n0\n1\n"
assert oracle("4 2\nAA\nCC\nGG\nTT\n0 0\n") == "4\n0\n0\n0\n"
assert sorted(["ACACAC"] * 4).count("ACACAC") == 4


def encode_case(people, sequence_length, rng):
    bases = "ACGT"
    lines = [f"{people} {sequence_length}"]
    for _ in range(people):
        lines.append("".join(rng.choice(bases) for _ in range(sequence_length)))
    lines.append("0 0")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261125)
    edges = [
        "1 20\n" + "ACGTTTACGTACGTTTACGTA\n" + "0 0\n",
        "7 1\n" + "\n".join(["A"] * 7) + "\n0 0\n",
        "5 3\nAAA\nCCC\nGGG\nTTT\nAAA\n0 0\n",
    ]
    write("2_edges", edges)
    wide = encode_case(20000, 20, random.Random(7))
    write("3_wide", [wide])
    random_cases = []
    for people in (3, 50, 777, 3000):
        random_cases.append(encode_case(people, rng.randint(1, 20), rng))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(4):
        io_cases.append(encode_case(20000, 20, rng))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE])
build()
