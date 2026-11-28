#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODULUS = 1000000007


@lru_cache(maxsize=None)
def factorize(value):
    factors = {}
    divisor = 2
    while divisor * divisor <= value:
        while value % divisor == 0:
            factors[divisor] = factors.get(divisor, 0) + 1
            value //= divisor
        divisor += 1
    if value > 1:
        factors[value] = factors.get(value, 0) + 1
    return tuple(factors.items())


def oracle(text):
    tokens = [int(value) for value in text.split()]
    field_count = tokens[0]
    event_count = tokens[1]
    fields = tokens[2:2 + field_count]
    position = 2 + field_count
    suppressed = 1
    answers = []
    for _ in range(event_count):
        event_type = tokens[position]
        position += 1
        if event_type == 1:
            suppressed = tokens[position]
            position += 1
        else:
            left_index = tokens[position]
            right_index = tokens[position + 1]
            position += 2
            maximums = {}
            for field in fields[left_index - 1:right_index]:
                for prime, exponent in factorize(field):
                    if prime not in maximums or exponent > maximums[prime]:
                        maximums[prime] = exponent
            if suppressed != 1:
                maximums.pop(suppressed, None)
            answer = 1
            for prime, exponent in maximums.items():
                answer = answer * pow(prime, exponent, MODULUS) % MODULUS
            answers.append(answer)
    return "\n".join(str(value) for value in answers) + ("\n" if answers else "")


SAMPLE = ("10 12\n"
          "4 2 3 5 6 47 10007 32768 59049 1\n"
          "0 1 5\n0 2 5\n1 2\n0 1 5\n0 2 5\n0 6 10\n"
          "1 3\n0 6 10\n1 1\n0 1 10\n0 10 10\n0 1 5\n")
SAMPLE_OUT = "60\n30\n15\n15\n772456932\n411740567\n342852967\n1\n60\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1\n0 1 1\n") == "1\n"
assert oracle("2 3\n4 2\n0 1 2\n1 2\n0 1 2\n") == "4\n1\n"
assert oracle("3 2\n100000 99991 1\n0 1 3\n0 2 2\n") == "999099937\n99991\n"
assert oracle("1 2\n100000\n1 7\n0 1 1\n") == "100000\n"


def write(name, fields, events):
    lines = [f"{len(fields)} {len(events)}", " ".join(str(value) for value in fields)]
    for event in events:
        lines.append(" ".join(str(value) for value in event))
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    edge_fields = [1, 2, 4, 8, 100000]
    edge_events = [(0, 1, 5), (1, 2), (0, 1, 5), (1, 3), (0, 2, 4),
                   (1, 1), (0, 1, 5), (0, 5, 5), (1, 5), (0, 3, 3)]
    write("2_edges", edge_fields, edge_events)
    rng = random.Random(20261126)
    wide_fields = [rng.randint(1, 100000) for _ in range(200)]
    wide_events = []
    for _ in range(300):
        if rng.randrange(4) == 0:
            wide_events.append((1, rng.choice([1, 2, 3, 5, 7, 97, 99991])))
        else:
            left = rng.randint(1, 200)
            right = rng.randint(left, 200)
            wide_events.append((0, left, right))
    write("3_wide", wide_fields, wide_events)
    random_fields = [rng.randint(1, 100000) for _ in range(1000)]
    random_events = []
    for _ in range(500):
        if rng.randrange(3) == 0:
            random_events.append((1, rng.choice([1, 2, 3, 5, 7, 11, 101, 10007])))
        else:
            left = rng.randint(1, 1000)
            right = rng.randint(left, 1000)
            random_events.append((0, left, right))
    write("4_random", random_fields, random_events)
    io_fields = [rng.randint(1, 100000) for _ in range(1000)]
    io_events = []
    for index in range(5000):
        if index % 100 == 0:
            io_events.append((1, rng.choice([1, 2, 3, 5, 7])))
        left = rng.randint(1, 1000)
        right = rng.randint(left, 1000)
        io_events.append((0, left, right))
    write("5_io", io_fields, io_events)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
