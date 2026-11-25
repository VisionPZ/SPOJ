#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def exact_units(hour, minute):
    hour_units = (hour * 80 + minute) * 9
    minute_units = minute * 144
    separation = abs(hour_units - minute_units) % 11520
    return min(separation, 11520 - separation)


def is_tie(hour, minute):
    return exact_units(hour, minute) % 720 == 360


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for position in range(1, count + 1):
        hour_text, minute_text = tokens[position].split(":")
        hour = int(hour_text)
        minute = int(minute_text)
        minute_angle = minute * 360.0 / 80.0
        hour_angle = ((hour % 16) + minute / 80.0) * 360.0 / 16.0
        separation = abs(hour_angle - minute_angle) % 360.0
        if separation > 180.0:
            separation = 360.0 - separation
        answers.append("{:.1f}".format(separation))
    return "\n".join(answers) + "\n"


SAMPLE = """3
12:00
06:00
13:15
"""
SAMPLE_OUT = """90.0
135.0
130.8
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n00:00\n") == "0.0\n"
assert oracle("1\n08:00\n") == "180.0\n"
assert oracle("1\n01:00\n") == "22.5\n"
assert not is_tie(12, 0) and not is_tie(13, 15)
assert is_tie(2, 8)


def times_text(times):
    return str(len(times)) + "\n" + "".join(f"{hour:02d}:{minute:02d}\n" for hour, minute in times)


def write(name, times):
    text = times_text(times)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(0, 0), (0, 79), (15, 79), (8, 0), (1, 0)])
    write("3_wide", [(hour, 0) for hour in range(16)] + [(hour, 40) for hour in range(16)])
    rng = random.Random(20261126)
    random_times = []
    while len(random_times) < 300:
        pair = (rng.randrange(16), rng.randrange(80))
        if not is_tie(*pair):
            random_times.append(pair)
    write("4_random", random_times)
    io_times = []
    while len(io_times) < 5000:
        pair = (rng.randrange(16), rng.randrange(80))
        if not is_tie(*pair):
            io_times.append(pair)
    write("5_io", io_times)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(12, 0), (6, 0), (13, 15)])
build()
