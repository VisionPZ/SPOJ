#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(token) for token in text.split()]
    sonya_start, sonya_end, filya_start, filya_end, preen = values
    boundaries = {sonya_start, sonya_end + 1, filya_start, filya_end + 1,
                  preen, preen + 1}
    points = sorted(boundaries)
    total = 0
    for index in range(len(points) - 1):
        segment_start = points[index]
        segment_end = points[index + 1] - 1
        if segment_start > segment_end:
            continue
        if not (sonya_start <= segment_start <= sonya_end):
            continue
        if not (filya_start <= segment_start <= filya_end):
            continue
        if segment_start <= preen <= segment_end:
            continue
        total += segment_end - segment_start + 1
    return str(total) + "\n"


SAMPLE_INPUT_ONE = "1 10 9 20 1\n"
SAMPLE_OUTPUT_ONE = "2\n"
SAMPLE_INPUT_TWO = "1 100 50 200 75\n"
SAMPLE_OUTPUT_TWO = "50\n"
assert oracle(SAMPLE_INPUT_ONE) == SAMPLE_OUTPUT_ONE
assert oracle(SAMPLE_INPUT_TWO) == SAMPLE_OUTPUT_TWO
assert oracle("1 10 20 30 5\n") == "0\n"
assert oracle("5 5 5 5 5\n") == "0\n"
assert oracle("5 5 5 5 6\n") == "1\n"
assert oracle("1 1000000000000000000 1 1000000000000000000 1\n") == "999999999999999999\n"


def write(name, values):
    input_text = " ".join(str(value) for value in values) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [1, 10, 9, 20, 1])
write("2_edges", [1, 100, 50, 200, 75])
write("3_wide", [1, 10 ** 18, 1, 10 ** 18, 10 ** 18])
write("4_random", [123456789, 987654321, 200000000, 800000000, 400000000])
write("5_io", [10 ** 18 - 500, 10 ** 18, 10 ** 18 - 1000, 10 ** 18, 10 ** 18 - 700])
