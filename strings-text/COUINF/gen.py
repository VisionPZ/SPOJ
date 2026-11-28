#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = ""
SAMPLE_OUT = "Thank You, Avengers\n"


def oracle(text):
    return "".join(chr(code) for code in
                   (84, 104, 97, 110, 107, 32, 89, 111, 117, 44,
                    32, 65, 118, 101, 110, 103, 101, 114, 115, 10))


assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert SAMPLE_OUT == "Thank You, Avengers\n"
assert len(SAMPLE_OUT) == 20
assert oracle("unexpected bytes\n") == SAMPLE_OUT


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", SAMPLE_INPUT)
write("2_edges", "")
write("3_wide", "\n" * 4096)
write("4_random", "".join(chr(33 + (index * 17) % 94) for index in range(1024)))
write("5_io", "ignored\n" * 20000)

print("trace: input ignored; fixed reply bytes -> " + SAMPLE_OUT.strip())
