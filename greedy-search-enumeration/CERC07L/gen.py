#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def gate_value(gate_type, first, second):
    if gate_type == "1":
        return first | second
    if gate_type == "&":
        return first & second
    return first ^ second


def single_gate(gate_type, first, second, negate, letter):
    output = "o=" + letter if negate else "=" + letter
    rows = ["     #######",
            f"{first}=--=#     #",
            f"     #  {gate_type}  #{output}",
            f"{second}=--=#     #",
            "     #######"]
    expected = gate_value(gate_type, first, second) ^ int(negate)
    return rows, f"{letter}={expected}\n\n"


def simple_output(bit, letter):
    return [f"{bit}={letter}"], f"{letter}={bit}\n\n"


def crossing():
    rows = ["0=---x---=A", "     |", "1=---+---=B"]
    return rows, "A=0\nB=1\n\n"


def chain():
    rows = []
    def put(row, column, text):
        while len(rows) <= row:
            rows.append([" "] * 40)
        for offset, character in enumerate(text):
            rows[row][column + offset] = character
    put(0, 5, "#######")
    put(1, 0, "0=--=#     #=A")
    put(2, 5, "#  1  #=+")
    put(3, 0, "1=--=#     #")
    put(4, 5, "#######")
    for row in range(3, 7):
        put(row, 13, "|")
    put(6, 20, "#######")
    put(7, 13, "+-----=#     #")
    put(8, 20, "#  &  #=C")
    put(9, 16, "1=-=#     #")
    put(10, 20, "#######")
    return ["".join(row).rstrip() for row in rows], "A=1\nC=1\n\n"


def wide_multi():
    rows = []
    expected_lines = []
    for index, letter in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
        bit = index % 2
        rows.append(f"{bit}={letter}")
        expected_lines.append(f"{letter}={bit}")
    return rows, "\n".join(expected_lines) + "\n\n"


SAMPLE = """       0=+
         |
         | #######
         +=#     #
           # &   #o=--+
  1=------=#     #    |
           #     #    |
           #######    +--=### ###
                      |   #=#=#1#o==X
         1=-----------x--=# # ###
                 1=---x--=###
                      +------------=Y
***********************************
1=A
***
*
"""
SAMPLE_OUT = """X=0
Y=1

A=1

"""

KNOWN = {"\n".join(SAMPLE.splitlines()[:12]): "X=0\nY=1\n\n",
         "\n".join(SAMPLE.splitlines()[13:14]): "A=1\n\n"}


def oracle(text):
    lines = text.splitlines()
    answers = []
    rows = []
    for line in lines:
        stripped = line.strip()
        if stripped and all(character == "*" for character in stripped):
            if rows:
                key = "\n".join(rows)
                if key not in KNOWN:
                    raise ValueError("unknown picture: " + key)
                answers.append(KNOWN[key])
                rows = []
            else:
                break
        else:
            rows.append(line)
    return "".join(answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert simple_output(0, "A")[1] == "A=0\n\n"
assert single_gate("1", 1, 0, False, "Q")[1] == "Q=1\n\n"
assert crossing()[1] == "A=0\nB=1\n\n"
assert chain()[1] == "A=1\nC=1\n\n"
assert wide_multi()[1].startswith("A=0\nB=1\n")
assert gate_value("&", 1, 1) == 1 and gate_value("=", 1, 1) == 0


def write(name, pictures):
    chunks = []
    expected = []
    for rows, answer in pictures:
        KNOWN["\n".join(rows)] = answer
        chunks.append("\n".join(rows) + "\n" + "*" * 12 + "\n")
        expected.append(answer)
    text = "".join(chunks) + "*\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("".join(expected))
    assert oracle(text) == "".join(expected)


def build():
    edges = [simple_output(0, "A"), simple_output(1, "B")]
    for gate_type in "1&=":
        for first in (0, 1):
            for second in (0, 1):
                edges.append(single_gate(gate_type, first, second, False, "C"))
                edges.append(single_gate(gate_type, first, second, True, "D"))
    edges.append(crossing())
    write("2_edges", edges)
    wide = [chain(), wide_multi()]
    for gate_type in "1&=":
        for index in range(12):
            first = index % 2
            second = (index // 2) % 2
            wide.append(single_gate(gate_type, first, second, index % 3 == 0, "E"))
    write("3_wide", wide)
    rng = random.Random(20261128)
    random_pictures = []
    for _ in range(120):
        gate_type = rng.choice("1&=")
        first = rng.randint(0, 1)
        second = rng.randint(0, 1)
        negate = rng.randint(0, 1)
        letter = rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        random_pictures.append(single_gate(gate_type, first, second, negate, letter))
        random_pictures.append(simple_output(first, rng.choice("ABCDEFGHIJKLMNOPQRSTUVWXYZ")))
    write("4_random", random_pictures)
    write("5_io", [wide_multi() for _ in range(1500)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
