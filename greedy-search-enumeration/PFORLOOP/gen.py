#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    numbers = {int(value) for value in text.split()}
    starts = [value for value in numbers if value - 1 not in numbers]
    starts.sort()
    loops = []
    for start in starts:
        end = start
        while end + 1 in numbers:
            end += 1
        loops.append(f'for (int i = {start}; i <= {end}; i++) cout << i << " ";')
    return "\n".join(loops) + "\n"


SAMPLE = """9 6 100 1 3 105
2 4 101 102 103 104 5 7 8
"""
SAMPLE_OUT = """for (int i = 1; i <= 9; i++) cout << i << " ";
for (int i = 100; i <= 105; i++) cout << i << " ";
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("5\n") == 'for (int i = 5; i <= 5; i++) cout << i << " ";\n'
assert oracle("0 1 2 4 6 7 9\n") == (
    'for (int i = 0; i <= 2; i++) cout << i << " ";\n'
    'for (int i = 4; i <= 4; i++) cout << i << " ";\n'
    'for (int i = 6; i <= 7; i++) cout << i << " ";\n'
    'for (int i = 9; i <= 9; i++) cout << i << " ";\n'
)
assert oracle("1000000000\n") == 'for (int i = 1000000000; i <= 1000000000; i++) cout << i << " ";\n'


def write(name, lines):
    text = "".join(" ".join(str(value) for value in line) + "\n" for line in lines)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [[5]])
    write("3_wide", [[1000000000 - offset for offset in range(4)],
                      [1000000000 - 10 - offset for offset in range(4)]])
    rng = random.Random(20261126)
    picked = rng.sample(range(1000000001), 200)
    write("4_random", [picked[index:index + 20] for index in range(0, len(picked), 20)])
    picked = rng.sample(range(1000000001), 40000)
    write("5_io", [picked[index:index + 1000] for index in range(0, len(picked), 1000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [[9, 6, 100, 1, 3, 105], [2, 4, 101, 102, 103, 104, 5, 7, 8]])
build()
