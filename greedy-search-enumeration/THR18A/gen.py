#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    values = [int(value) for value in text.split()]
    persepolis_home, esteghlal_away, esteghlal_home, persepolis_away = values
    persepolis_total = persepolis_home + persepolis_away
    esteghlal_total = esteghlal_home + esteghlal_away
    if persepolis_total > esteghlal_total:
        return "Persepolis\n"
    if esteghlal_total > persepolis_total:
        return "Esteghlal\n"
    if persepolis_away > esteghlal_away:
        return "Persepolis\n"
    if esteghlal_away > persepolis_away:
        return "Esteghlal\n"
    return "Penalty\n"


SAMPLES = [
    ("3 0\n2 1\n", "Persepolis\n"),
    ("3 1\n2 0\n", "Esteghlal\n"),
    ("2 0\n2 0\n", "Penalty\n"),
]
for sample, expected in SAMPLES:
    assert oracle(sample) == expected


def write(name, values):
    text = f"{values[0]} {values[1]}\n{values[2]} {values[3]}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", (0, 0, 0, 0))
    write("3_wide", (20, 20, 20, 20))
    write("4_random", (7, 3, 4, 6))
    write("5_io", (10, 10, 10, 10))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", (3, 0, 2, 1))
build()
