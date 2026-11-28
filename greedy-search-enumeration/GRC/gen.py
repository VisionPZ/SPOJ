#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LETTERS = "YR BGWM".replace(" ", "")
AXES = {
    1: (-1, 0, 0),
    2: (0, 0, 1),
    3: (1, 0, 0),
    4: (0, 0, -1),
    5: (0, 1, 0),
    6: (0, -1, 0),
}
FACE_ORDER = "1234"


def cross(first, second):
    return (
        first[1] * second[2] - first[2] * second[1],
        first[2] * second[0] - first[0] * second[2],
        first[0] * second[1] - first[1] * second[0],
    )


def dot(first, second):
    return sum(a * b for a, b in zip(first, second))


def rotate(vector, axis, sine):
    projection = dot(axis, vector)
    turned = cross(axis, vector)
    return tuple(axis[index] * projection + sine * turned[index] for index in range(3))


def sticker_geometry(face_number, row, column):
    if face_number == 1:
        return (-1, 1 - row, column - 1), (-1, 0, 0)
    if face_number == 2:
        return (column - 1, 1 - row, 1), (0, 0, 1)
    if face_number == 3:
        return (1, 1 - row, 1 - column), (1, 0, 0)
    if face_number == 4:
        return (1 - column, 1 - row, -1), (0, 0, -1)
    if face_number == 5:
        return (column - 1, 1, row - 1), (0, 1, 0)
    return (column - 1, -1, 1 - row), (0, -1, 0)


def oracle(text):
    lines = text.splitlines()
    position = 1
    answers = []
    for _ in range(int(lines[0])):
        stickers = {}
        for line_index in range(9):
            letters = [letter for letter in lines[position].split() if letter]
            position += 1
            for letter_index, letter in enumerate(letters):
                if line_index < 3:
                    face_number, row, column = 5, line_index, letter_index
                elif line_index < 6:
                    face_number = int(FACE_ORDER[letter_index // 3])
                    row, column = line_index - 3, letter_index % 3
                else:
                    face_number, row, column = 6, line_index - 6, letter_index
                place, normal = sticker_geometry(face_number, row, column)
                stickers[(place, normal)] = letter
        rotations = [int(value) for value in lines[position].split()]
        position += 1
        for rotation in rotations:
            if rotation == 0:
                break
            axis = AXES[abs(rotation)]
            sine = -1 if rotation > 0 else 1
            updated = {}
            for (place, normal), color in stickers.items():
                if dot(place, axis) == 1:
                    place = rotate(place, axis, sine)
                    normal = rotate(normal, axis, sine)
                updated[(place, normal)] = color
            stickers = updated
        winning = True
        for axis in AXES.values():
            colors = [color for (place, normal), color in stickers.items() if normal == axis]
            if len(set(colors)) != 1:
                winning = False
        answers.append("Yes, grandpa!" if winning else "No, you are wrong!")
    return "\n".join(answers) + "\n"


def grid_text(rows):
    return "\n".join(" ".join(row) for row in rows) + "\n"


def solved_rows():
    middle = ["Y"] * 3 + ["R"] * 3 + ["B"] * 3 + ["G"] * 3
    return [
        ["M"] * 3,
        ["M"] * 3,
        ["M"] * 3,
        middle[:],
        middle[:],
        middle[:],
        ["W"] * 3,
        ["W"] * 3,
        ["W"] * 3,
    ]


def case_text(rows, rotations):
    return grid_text(rows) + " ".join(str(value) for value in rotations) + " 0\n"


SAMPLE = """3
      G Y Y
      G Y Y
      G Y Y
W W W Y R R M M M G G B
W W W Y R R M M M G G B
W W W Y R R M M M G G B
      R B B
      R B B
      R B B
-1 0
      G Y Y
      G Y Y
      G Y Y
W W W Y R R M M M G G B
W M W Y R R M W M G G B
W W W Y R R M M M G G B
      R B B
      R B B
      R B B
-1 0
      M W M
      W W G
      W W Y
G Y Y M M B M B G W R B
B Y Y M M B M G G W R R
Y M G W B B R R G R R W
      R Y Y
      G B Y
      R G B
+4 +6 -2 +3 -4 +2 -3 -6 0
"""
SAMPLE_OUT = """Yes, grandpa!
No, you are wrong!
Yes, grandpa!
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n" + case_text(solved_rows(), [])) == "Yes, grandpa!\n"
assert oracle("1\n" + case_text(solved_rows(), [1])) == "No, you are wrong!\n"
assert len(LETTERS) == 6
assert dot(AXES[3], (1, 0, 0)) == 1
assert rotate((1, 0, 0), (0, 0, 1), -1) == (0, -1, 0)

rng = random.Random(20261126)
for _ in range(20):
    rows = [[rng.choice(LETTERS) for _ in range(3)] for _ in range(9)]
    rotations = [rng.choice((-6, -4, -2, -1, 1, 2, 4, 6)) for _ in range(rng.randint(1, 8))]
    text = "1\n" + case_text(rows, rotations)
    result = oracle(text)
    assert result in ("Yes, grandpa!\n", "No, you are wrong!\n")


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [case_text(solved_rows(), []), case_text(solved_rows(), [1])])
    wide = []
    for _ in range(30):
        rows = [[rng.choice(LETTERS) for _ in range(3)] for _ in range(9)]
        rotations = [rng.choice((-6, -5, -4, -3, -2, -1, 1, 2, 3, 4, 5, 6))
                     for _ in range(20)]
        wide.append(case_text(rows, rotations))
    write("3_wide", wide)
    mixed = []
    for _ in range(40):
        rows = [[rng.choice(LETTERS) for _ in range(3)] for _ in range(9)]
        rotations = [rng.choice((-6, -4, -2, -1, 1, 2, 4, 6))
                     for _ in range(rng.randint(1, 30))]
        mixed.append(case_text(rows, rotations))
    write("4_random", mixed)
    write("5_io", [case_text(solved_rows(), []) for _ in range(120)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
