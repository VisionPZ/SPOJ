#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def step_simulation(disk_count, step_count):
    peg_of_disk = {disk: 0 for disk in range(1, disk_count + 1)}
    stacks = [[], [], []]
    for disk in range(disk_count, 0, -1):
        stacks[0].append(disk)
    remaining = step_count

    def move(size, source, target, spare):
        nonlocal remaining
        if size == 0 or remaining == 0:
            return
        move(size - 1, source, spare, target)
        if remaining == 0:
            return
        remaining -= 1
        moved_disk = stacks[source].pop()
        stacks[target].append(moved_disk)
        peg_of_disk[moved_disk] = target
        move(size - 1, spare, target, source)

    move(disk_count, 0, 1, 2)
    return [peg_of_disk[disk] for disk in range(1, disk_count + 1)]


def oracle(disk_count, step_count):
    peg_of_disk = [0] * (disk_count + 1)

    def place(size, source, target, spare, steps):
        if size == 0:
            return
        half = 1 << (size - 1)
        if steps < half:
            peg_of_disk[size] = source
            place(size - 1, source, spare, target, steps)
        elif steps == half:
            peg_of_disk[size] = target
            for disk in range(1, size):
                peg_of_disk[disk] = spare
        else:
            peg_of_disk[size] = target
            place(size - 1, spare, target, source, steps - half)

    place(disk_count, 0, 1, 2, step_count)
    return peg_of_disk[1:]


def format_case(disk_count, step_count):
    pegs = oracle(disk_count, step_count)
    lines = []
    for peg in range(3):
        disks = [str(disk) for disk in range(disk_count, 0, -1) if pegs[disk - 1] == peg]
        lines.append(str(peg + 1) + ":" + (" " + "|".join(disks) if disks else ""))
    return "\n".join(lines) + "\n"


def format_cases(cases):
    return "".join(format_case(disk_count, step_count) for disk_count, step_count in cases)


SAMPLE_INPUT = "3\n3 6\n32 889397450\n31 16543\n"
SAMPLE_CASES = [(3, 6), (32, 889397450), (31, 16543)]
SAMPLE_OUTPUT = """1: 1
2: 3|2
3:
1: 32|31|28|25|18|17|14|3
2: 30|29|26|13|12|11|10|9|6|5|2
3: 27|24|23|22|21|20|19|16|15|8|7|4|1
1: 31|30|29|28|27|26|25|24|23|22|21|20|19|18|17|16|7|6
2: 15|8|5|4|3|2|1
3: 14|13|12|11|10|9
"""

assert format_cases(SAMPLE_CASES) == SAMPLE_OUTPUT
assert all(oracle(size, steps) == step_simulation(size, steps)
           for size in range(3, 10) for steps in range(1 << size))
assert oracle(60, (1 << 60) - 1) == [1] * 60
assert oracle(3, 1) == [1, 0, 0]


def write_literal(name, input_text, output_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{disk_count} {step_count}\n" for disk_count, step_count in cases)
    write_literal(name, input_text, format_cases(cases))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write_literal("1_sample", SAMPLE_INPUT, SAMPLE_OUTPUT)

edges = []
for steps in range(1, 8):
    edges.append((3, steps))
edges += [(4, 1), (4, 8), (4, 15), (5, 16), (5, 31),
          (60, 1), (60, 1 << 59), (60, (1 << 60) - 1)]
write("2_edges", edges)

wide = [(60, 1), (60, 2), (60, 1 << 30), (60, 1 << 59),
        (60, (1 << 60) - 1), (60, 889397450), (60, 123456789012345678),
        (59, (1 << 59) - 1), (58, 1 << 57), (31, 16543), (3, 7)]
write("3_wide", wide)

rng = random.Random(20261125)
random_cases = []
for _ in range(600):
    disk_count = rng.randint(3, 60)
    step_count = rng.randint(1, (1 << disk_count) - 1)
    random_cases.append((disk_count, step_count))
write("4_random", random_cases)

io_cases = [(60, rng.randint(1, (1 << 60) - 1)) for _ in range(55000)]
write("5_io", io_cases)

print("generated", len(random_cases), "random cases and", len(io_cases), "io cases")
