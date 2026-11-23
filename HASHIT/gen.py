#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TABLE_SIZE = 101


def hash_key(key):
    weighted = sum(ord(char) * (index + 1) for index, char in enumerate(key))
    return 19 * weighted % TABLE_SIZE


def probe(start, step):
    return (start + step * step + 23 * step) % TABLE_SIZE


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    tests = int(lines[cursor]); cursor += 1
    result = []
    for _ in range(tests):
        operations = int(lines[cursor]); cursor += 1
        table = {}
        for _ in range(operations):
            line = lines[cursor]; cursor += 1
            action, key = line.split(":", 1)
            if action == "ADD":
                if key in table.values():
                    continue
                start = hash_key(key)
                placed = False
                for step in range(20):
                    slot = probe(start, step)
                    if slot not in table:
                        table[slot] = key
                        placed = True
                        break
            elif action == "DEL":
                start = hash_key(key)
                for step in range(20):
                    slot = probe(start, step)
                    if table.get(slot) == key:
                        del table[slot]
                        break
        result.append(str(len(table)))
        for slot in sorted(table):
            result.append(f"{slot}:{table[slot]}")
    return "\n".join(result) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_IN = """1
11
ADD:marsz
ADD:marsz
ADD:Dabrowski
ADD:z
ADD:ziemii
ADD:wloskiej
ADD:do
ADD:Polski
DEL:od
DEL:do
DEL:wloskiej
"""
SAMPLE_OUT = """5
34:Dabrowski
46:Polski
63:marsz
76:ziemii
96:z
"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT


def build():
    random.seed(1618)
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

    def random_key():
        return "".join(random.choice(alphabet)
                       for _ in range(random.randint(1, 15)))

    edge_ops = []
    edge_ops.append("ADD:a")
    edge_ops.append("ADD:a")
    edge_ops.append("DEL:a")
    edge_ops.append("DEL:a")
    edge_ops.append("ADD:" + "a" * 15)
    edge_ops.append("DEL:" + "z" * 15)
    for index in range(100):
        edge_ops.append("ADD:" + random_key())
    for index in range(40):
        edge_ops.append("DEL:" + random_key())
    write("2_edges", "1\n" + str(len(edge_ops)) + "\n" +
          "\n".join(edge_ops) + "\n")

    wide_ops = []
    for index in range(1000):
        wide_ops.append("ADD:" + random_key())
    for index in range(400):
        wide_ops.append("DEL:" + random_key())
    write("3_wide", "1\n" + str(len(wide_ops)) + "\n" +
          "\n".join(wide_ops) + "\n")

    random_suites = []
    for _ in range(40):
        ops = [random.choice(["ADD", "DEL"]) + ":" + random_key()
               for _ in range(random.randint(1, 60))]
        random_suites.append(ops)
    random_text = str(len(random_suites)) + "\n" + "".join(
        str(len(ops)) + "\n" + "\n".join(ops) + "\n"
        for ops in random_suites)
    write("4_random", random_text)

    io_suites = []
    for _ in range(100):
        ops = ["ADD:" + random_key() for _ in range(80)]
        io_suites.append(ops)
    io_text = str(len(io_suites)) + "\n" + "".join(
        str(len(ops)) + "\n" + "\n".join(ops) + "\n"
        for ops in io_suites)
    write("5_io", io_text)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
