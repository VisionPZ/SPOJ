#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def neg(vector):
    return tuple(-value for value in vector)


def cross(first, second):
    return (first[1] * second[2] - first[2] * second[1],
            first[2] * second[0] - first[0] * second[2],
            first[0] * second[1] - first[1] * second[0])


def folded_frames():
    positions = {1: (-1, 0), 2: (0, 0), 3: (1, 0), 4: (2, 0),
                 0: (0, 1), 5: (0, -1)}
    frames = {2: ((1, 0, 0), (0, 1, 0), (0, 0, 1))}
    pending = [2]
    while pending:
        face = pending.pop()
        right, up, normal = frames[face]
        column, row = positions[face]
        for dx, dy, kind in ((1, 0, 'R'), (-1, 0, 'L'), (0, 1, 'U'), (0, -1, 'D')):
            neighbours = [other for other, spot in positions.items()
                          if spot == (column + dx, row + dy)]
            if not neighbours:
                continue
            neighbour = neighbours[0]
            if kind == 'R':
                frame = (neg(normal), up, right)
            elif kind == 'L':
                frame = (normal, up, neg(right))
            elif kind == 'U':
                frame = (right, neg(normal), up)
            else:
                frame = (right, normal, neg(up))
            if neighbour not in frames:
                frames[neighbour] = frame
                pending.append(neighbour)
    return frames


FRAMES = folded_frames()
SIDES = [1, 2, 3, 4]
CORNERS = []
for top_sign in (1, -1):
    for side_index in range(4):
        side_left = SIDES[side_index]
        side_right = SIDES[(side_index + 1) % 4]
        if top_sign == 1:
            CORNERS.append([0, side_right, side_left])
        else:
            CORNERS.append([5, side_left, side_right])


def corner_digits(roles, orientations):
    normals = [FRAMES[face][2] for face in roles]
    rows = []
    for position, face in enumerate(roles):
        right, up, normal = FRAMES[face]
        if position == 0:
            display_up = normals[2]
        elif position == 1:
            display_up = (0, 1, 0) if roles[0] == 0 else (0, -1, 0)
        else:
            display_up = normals[1]
        display_right = cross(display_up, normal)
        display_dirs = [display_up, display_right, neg(display_up), neg(display_right)]
        flat_dirs = [up, right, neg(up), neg(right)]
        rows.append([display_dirs.index(flat_dirs[orientation])
                     for orientation in range(4)])
    return rows


def parse(specification):
    return [(ord(specification[index]) - 65, int(specification[index + 1]) - 1)
            for index in range(0, len(specification), 2)]


def corner_signatures(net):
    flat = parse(net)
    letters = [pair[0] for pair in flat]
    orientations = [pair[1] for pair in flat]
    signatures = []
    for roles in CORNERS:
        rows = corner_digits(roles, orientations)
        base = [(letters[face], rows[slot][orientations[face]])
                for slot, face in enumerate(roles)]
        for rotation in range(3):
            signatures.append([base[(rotation + slot) % 3] for slot in range(3)])
    return signatures


def oracle(net, answers):
    signatures = corner_signatures(net)
    verdicts = []
    for answer in answers:
        question = parse(answer)
        verdicts.append('Y' if question in signatures else 'N')
    count = verdicts.count('Y')
    return f"{count} " + " ".join(verdicts) + "\n"


def oracle_text(text):
    lines = text.splitlines()
    count = int(lines[0])
    results = []
    for index in range(count):
        net = lines[1 + index * 6]
        answers = lines[2 + index * 6:7 + index * 6]
        results.append(f"{index + 1} " + oracle(net, answers).rstrip('\n'))
    return "\n".join(results) + "\n"


SAMPLE = """2
F3E4E2D3C2F3
C2D2F2
E3F3C4
F2C2D2
D1E1F3
E1C1E1
A2F4F1A3A3C4
C3A4A2
F3F4A1
F3C4A1
A2C3A2
A4A4F1
"""
SAMPLE_OUT = """1 2 Y N Y N N
2 0 N N N N N
"""
assert oracle_text(SAMPLE) == SAMPLE_OUT
assert len(CORNERS) == 8
assert oracle("A4A2A3A4A2A3", ["A2A4A4", "A1A3A2", "A3A1A3", "A3A4A3", "A1A3A3"]) == "0 N N N N N\n"
assert oracle("F3E4E2D3C2F3", ["C2D2F2", "C2D2F2"]) == "2 Y Y\n"


def random_spec(rng, letters):
    return "".join(letter + str(rng.randint(1, 4)) for letter in letters)


def random_answer(rng, letters):
    return "".join(rng.choice(letters) + str(rng.randint(1, 4)) for _ in range(3))


def write(name, cases):
    text = str(len(cases)) + "\n"
    text += "".join(net + "\n" + "".join(answer + "\n" for answer in answers)
                    for net, answers in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(text))


def build():
    alphabet = "ABCDEF"
    edges = [
        ("A4A2A3A4A2A3", ["A2A4A4", "A1A3A2", "A3A1A3", "A3A4A3", "A1A3A3"]),
        ("F1F1F1F1F1F1", ["F1F1F1", "F2F2F2", "F3F3F3", "F4F4F4", "F1F2F3"]),
    ]
    write("2_edges", edges)
    rng = random.Random(20261126)
    wide = []
    for _ in range(20):
        net = random_spec(rng, list(alphabet))
        signatures = corner_signatures(net)
        answers = []
        for _ in range(3):
            answer = rng.choice(signatures)
            answers.append("".join(chr(65 + letter) + str(digit + 1) for letter, digit in answer))
        for _ in range(2):
            answers.append(random_answer(rng, alphabet))
        wide.append((net, answers))
    write("3_wide", wide)

    def random_case():
        letters = [rng.choice(alphabet) for _ in range(6)]
        net = random_spec(rng, letters)
        signatures = corner_signatures(net)
        answers = []
        for _ in range(5):
            if rng.random() < 0.5:
                answer = rng.choice(signatures)
                answers.append("".join(chr(65 + letter) + str(digit + 1) for letter, digit in answer))
            else:
                answers.append(random_answer(rng, alphabet))
        return net, answers

    write("4_random", [random_case() for _ in range(60)])
    write("5_io", [random_case() for _ in range(600)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ("F3E4E2D3C2F3", ["C2D2F2", "E3F3C4", "F2C2D2", "D1E1F3", "E1C1E1"]),
    ("A2F4F1A3A3C4", ["C3A4A2", "F3F4A1", "F3C4A1", "A2C3A2", "A4A4F1"])])
build()
