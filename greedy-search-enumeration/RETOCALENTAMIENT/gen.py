#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

CYCLE = list(range(16)) + list(range(14, 0, -1))
CYCLE_STR = "".join(chr(x) for x in CYCLE)
LONG_STR = CYCLE_STR * 12

SAMPLE_INPUT = "5\n3 4 5 6 7\n"
SAMPLE_OUT = "CRECIENTE\n"


def answer_for_record(record):
    needle = "".join(chr(x) for x in record)
    length = len(needle)
    directions = set()
    start = LONG_STR.find(needle)
    while start != -1 and start + length < len(LONG_STR):
        nxt = ord(LONG_STR[start + length])
        last = ord(needle[-1])
        directions.add(1 if nxt > last else (-1 if nxt < last else 0))
        start = LONG_STR.find(needle, start + 1)
    if len(directions) == 1 and 1 in directions:
        return "CRECIENTE\n"
    if len(directions) == 1 and -1 in directions:
        return "MENGUANTE\n"
    return "-1\n"


def oracle(input_text):
    tokens = input_text.split()
    cursor = 0
    answers = []
    while cursor < len(tokens):
        n = int(tokens[cursor])
        cursor += 1
        record = [int(x) for x in tokens[cursor:cursor + n]]
        cursor += n
        answers.append(answer_for_record(record))
    return "".join(answers)


def format_case(record):
    return "%d\n%s\n" % (len(record), " ".join(str(x) for x in record))


def write(name, records):
    input_text = "".join(format_case(record) for record in records)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    record = [3, 4, 5, 6, 7]
    needle = "".join(chr(x) for x in record)
    start = LONG_STR.find(needle)
    print("record 3 4 5 6 7")
    print("phase %d in 30-day cycle" % (start % 30))
    print("next size %d" % ord(LONG_STR[start + len(record)]))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("7\n12 13 14 15 14 13 12\n") == "MENGUANTE\n"
assert oracle("1\n8\n") == "-1\n"
assert oracle("1\n0\n") == "CRECIENTE\n"
assert oracle("1\n15\n") == "MENGUANTE\n"
assert oracle("1\n1\n") == "-1\n"
assert oracle("30\n" + " ".join(str(x) for x in CYCLE) + "\n") == "MENGUANTE\n"


def consistent_record(rng, length):
    phase = rng.randrange(30)
    return [CYCLE[(phase + offset) % 30] for offset in range(length)]


def build():
    write("2_edges", [
        [0], [15], [1], [8],
        CYCLE,
        CYCLE[7:] + CYCLE[:7],
        [14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
    ])
    rng = random.Random(20161007)
    wide_records = [consistent_record(rng, 92) for _ in range(20)]
    write("3_wide", wide_records)
    random_records = []
    for _ in range(400):
        length = rng.randint(1, 92)
        random_records.append(consistent_record(rng, length))
    write("4_random", random_records)
    io_records = [consistent_record(rng, 92) for _ in range(50000)]
    write("5_io", io_records)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        write("1_sample", [[3, 4, 5, 6, 7]])
        build()
