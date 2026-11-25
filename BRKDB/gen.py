#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "Antonio\n"
SAMPLE_OUTPUT = (
    "Antonio Silva 200120039010\n"
    "Antonio Pineda 199810024010\n"
    "Antonio Monsalve 200410061010\n"
)

PROSE_CODES = {
    "Monsalve": "200410061010",
    "Silva": "200120039010",
    "Pineda": "199810024010",
}
RECOVERY_ORDER = ("Silva", "Pineda", "Monsalve")


def oracle(text):
    recovered_name = text.split()[0]
    return "".join(
        f"{recovered_name} {surname} {PROSE_CODES[surname]}\n"
        for surname in RECOVERY_ORDER)


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("Maria\n") == (
    "Maria Silva 200120039010\n"
    "Maria Pineda 199810024010\n"
    "Maria Monsalve 200410061010\n")
assert oracle("X\n").startswith("X Silva 200120039010\n")
assert oracle("A long name\n").count("\n") == 3


def write(name, recovered_name):
    input_text = recovered_name + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", "Antonio")
write("2_edges", "X")
write("3_wide", "Alexandra")
write("4_random", "Jose")
write("5_io", "Christopher")
