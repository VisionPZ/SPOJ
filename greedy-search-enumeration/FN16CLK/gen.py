#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

DIGITS = [
    [6, 9, 9, 0, 9, 9, 6],
    [0, 8, 8, 0, 8, 8, 0],
    [6, 8, 8, 6, 1, 1, 6],
    [6, 8, 8, 6, 8, 8, 6],
    [0, 9, 9, 6, 8, 8, 0],
    [6, 1, 1, 6, 8, 8, 6],
    [6, 1, 1, 6, 9, 9, 6],
    [6, 8, 8, 0, 8, 8, 0],
    [6, 9, 9, 6, 9, 9, 6],
    [6, 9, 9, 6, 8, 8, 6],
]
PIECES = {
    digit: ["".join("X" if mask & (1 << offset) else "." for offset in range(4))
            for mask in DIGITS[digit]]
    for digit in range(10)
}
STARTS = [0, 5, 12, 17]
NONSEGMENT = {(r, c) for c in (4, 9, 11, 16) for r in range(7)}
NONSEGMENT |= {(r, c) for r in (1, 2, 4, 5) for c in (1, 2, 6, 7, 13, 14, 18, 19)}
NONSEGMENT |= {(r, c) for r in (0, 3, 6) for c in (0, 3, 5, 8, 12, 15, 17, 20)}
NONSEGMENT |= {(r, 10) for r in (0, 1, 3, 5, 6)}
SEGMENTS = {(r, c) for r in range(7) for c in range(21)} - NONSEGMENT


def render(minute):
    rows = [["." for _ in range(21)] for _ in range(7)]
    hour = minute // 60
    mins = minute % 60
    digits = [hour // 10, hour % 10, mins // 10, mins % 10]
    for index, digit in enumerate(digits):
        if index == 0 and digit == 0:
            continue
        for row in range(7):
            for col in range(4):
                if PIECES[digit][row][col] == "X":
                    rows[row][STARTS[index] + col] = "X"
    rows[2][10] = "X"
    rows[4][10] = "X"
    return ["".join(row) for row in rows]


EXPECTED = [render(minute) for minute in range(1440)]
MIXED = {(row, col) for row in range(7) for col in range(21)}


def oracle_case(frames):
    frame_count = len(frames)
    observed = [[[frames[frame][row][col] == "X" for frame in range(frame_count)]
                 for col in range(21)] for row in range(7)]
    mixed = {(row, col) for row in range(7) for col in range(21)
             if len(set(observed[row][col])) == 2}
    valid_starts = []
    for start in range(1440):
        okay = True
        for row, col in mixed:
            seen_on = False
            seen_off = False
            for frame in range(frame_count):
                if EXPECTED[(start + frame) % 1440][row][col] == "X":
                    seen_on = True
                else:
                    seen_off = True
            if not (seen_on and seen_off):
                okay = False
                break
        if okay:
            valid_starts.append(start)
    if not valid_starts:
        return ["impossible"]
    answer = [["?" for _ in range(21)] for _ in range(7)]
    for row in range(7):
        for col in range(21):
            if (row, col) not in SEGMENTS:
                answer[row][col] = "."
                continue
            values = set(observed[row][col])
            statuses = set()
            for start in valid_starts:
                actual = {EXPECTED[(start + frame) % 1440][row][col] == "X"
                          for frame in range(frame_count)}
                if len(values) == 2:
                    statuses.add("W")
                elif values == {True}:
                    statuses.add("?" if actual == {True} else "1")
                else:
                    statuses.add("?" if actual == {False} else "0")
            if len(statuses) == 1:
                answer[row][col] = next(iter(statuses))
            else:
                answer[row][col] = "?"
    return ["".join(row) for row in answer]


def oracle(text):
    lines = text.splitlines()
    pos = 0
    outputs = []
    while pos < len(lines):
        if not lines[pos].strip():
            pos += 1
            continue
        frame_count = int(lines[pos])
        pos += 1
        frames = []
        for _ in range(frame_count):
            frames.append(lines[pos:pos + 7])
            pos += 7
            if _ < frame_count - 1:
                pos += 1
        outputs.extend(oracle_case(frames))
    return "\n".join(outputs) + "\n"


SAMPLE = """3
......XX.....XX...XX.
.....X..X...X..X....X
.....X..X.X.X..X....X
.............XX...XX.
.....X..X......X.X..X
.....X..X......X.X..X
......XX.....XX...XX.

......XX.....XX...XX.
.....X..X...X..X....X
.....X..X.X.X..X....X
.............XX...XX.
.....X..X......X.X..X
.....X..X......X.X..X
......XX.....XX...XX.

.............XX...XX.
........X...X..X....X
........X.X.X..X....X
.............XX......
........X...X..X.X..X
........X...X..X.X..X
......XX.....XX...XX.
2
......XX.....XX...XX.
...X....X...X..X.X..X
...X....X.X.X..X.X..X
......XX..........XX.
...X.X....X.X..X.X..X
...X.X......X..X.X..X
......XX.....XX...XX.

......XX.....XX......
...X....X...X..X.....
...X....X.X.X..X.....
......XX.............
...X.X....X.X..X.....
...X.X......X..X.....
......XX.....XX......
"""
SAMPLE_OUT = """.??...WW.....??...??.
?..?.W..?...?..1.0..?
?..?.W..?.?.?..1.0..?
.??...??.....11...WW.
?..?.W..?.0.W..?.1..?
?..?.W..?...W..?.1..?
.??...11.....??...??.
impossible
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert len(render(0)) == 7 and all(len(row) == 21 for row in render(0))
assert render(0)[2][10] == "X" and render(0)[4][10] == "X"
assert render(1439)[0][:4] == ".XX."


def make_case(start, frame_count, faults):
    images = []
    for frame in range(frame_count):
        rows = [list(row) for row in render((start + frame) % 1440)]
        for row in range(7):
            for col in range(21):
                status = faults.get((row, col), 2)
                if status == 0:
                    rows[row][col] = "."
                elif status == 1:
                    rows[row][col] = "X"
        images.append(["".join(row) for row in rows])
    return images


def case_text(cases):
    chunks = []
    for images in cases:
        chunk = [str(len(images))]
        for index, image in enumerate(images):
            chunk.extend(image)
            if index < len(images) - 1:
                chunk.append("")
        chunks.append("\n".join(chunk))
    return "\n".join(chunks) + "\n"


def random_faults(rng, density):
    faults = {}
    for position in SEGMENTS:
        choice = rng.random()
        if choice < density:
            faults[position] = 0
        elif choice < 2 * density:
            faults[position] = 1
        else:
            faults[position] = 2
    return faults


def write(name, cases):
    text = case_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    rng = random.Random(20261126)
    write("2_edges", [make_case(0, 1, random_faults(rng, 0.0))])
    rng = random.Random(20261127)
    write("3_wide", [make_case(rng.randrange(1440), 100, random_faults(rng, 0.08))])
    rng = random.Random(20261128)
    random_cases = []
    for _ in range(3):
        random_cases.append(make_case(rng.randrange(1440), rng.randint(5, 25),
                                      random_faults(rng, 0.12)))
    write("4_random", random_cases)
    rng = random.Random(20261129)
    io_cases = []
    for _ in range(3):
        io_cases.append(make_case(rng.randrange(1440), 100, random_faults(rng, 0.15)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
