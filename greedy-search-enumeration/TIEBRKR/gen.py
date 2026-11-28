#!/usr/bin/env python3
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = re.findall(r"[A-Z]+|[0-9]+", text)
    ticket_count = int(tokens[0])
    winners = []
    for ticket_index in range(ticket_count):
        number = int(tokens[1 + 2 * ticket_index])
        status = tokens[2 + 2 * ticket_index]
        if status == "WIN":
            winners.append(number)
    winners = sorted(winners)
    return str(len(winners)) + "\n" + " ".join(str(number) for number in winners) + "\n"


SAMPLE = """5
5011
WIN
4000
NOWIN
101
WIN
500
NOWIN
501
WIN
"""
SAMPLE_OUT = """3
101 501 5011
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("2\n1\nNOWIN\n2\nNOWIN\n") == "0\n\n"
assert oracle("3\n7\nWIN\n5\nWIN\n9\nWIN\n") == "3\n5 7 9\n"
assert oracle("1\n42\nWIN\n") == "1\n42\n"


def write(name, tickets):
    lines = [str(len(tickets))]
    for number, status in tickets:
        lines.append(str(number))
        lines.append(status)
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, "NOWIN"), (2, "NOWIN")])
    write("3_wide", [(1000000000 - index * 7, "WIN" if index % 3 else "NOWIN") for index in range(100)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 1000000000), rng.choice(["WIN", "NOWIN"])) for _ in range(100)])
    write("5_io", [(1000000000 - index, "WIN") for index in range(100)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5011, "WIN"), (4000, "NOWIN"), (101, "WIN"), (500, "NOWIN"), (501, "WIN")])
build()
