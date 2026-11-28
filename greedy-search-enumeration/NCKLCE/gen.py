#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    size = int(tokens[cursor]); cursor += 1
    color_count = int(tokens[cursor]); cursor += 1
    beads = [int(value) for value in tokens[cursor:cursor + size]]
    cursor += size
    command_count = int(tokens[cursor]); cursor += 1
    reversed_order = False
    offset = 0
    answers = []

    def physical(position):
        index = (position - 1 - offset) % size
        if reversed_order:
            index = (size - index) % size
        return index

    for _ in range(command_count):
        command = tokens[cursor]; cursor += 1
        if command == 'R':
            offset = (offset + int(tokens[cursor])) % size
            cursor += 1
        elif command == 'F':
            reversed_order = not reversed_order
            offset = (size - offset) % size
        elif command == 'S':
            first = physical(int(tokens[cursor]))
            second = physical(int(tokens[cursor + 1]))
            cursor += 2
            beads[first], beads[second] = beads[second], beads[first]
        elif command == 'P':
            first = physical(int(tokens[cursor]))
            second = physical(int(tokens[cursor + 1]))
            color = int(tokens[cursor + 2])
            cursor += 3
            if reversed_order:
                first, second = second, first
            second = (second + 1) % size
            if first < second:
                for index in range(first, second):
                    beads[index] = color
            else:
                for index in list(range(first, size)) + list(range(0, second)):
                    beads[index] = color
        elif command == 'C':
            changes = sum(1 for index in range(size)
                          if beads[index] != beads[(index - 1) % size])
            answers.append(str(changes) if changes else "1")
        else:
            start = int(tokens[cursor])
            finish = int(tokens[cursor + 1])
            cursor += 2
            colors = []
            position = start
            while True:
                colors.append(beads[physical(position)])
                if position == finish:
                    break
                position = position % size + 1
            parts = 1
            for index in range(1, len(colors)):
                if colors[index] != colors[index - 1]:
                    parts += 1
            answers.append(str(parts))
    return "\n".join(answers) + "\n"


SAMPLE = """5 3
1 2 3 2 1
4
C
R 2
P 5 5 2
CS 4 1
"""
SAMPLE_OUT = """4
1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3 2\n1 1 1\n2\nC\nCS 1 3\n") == "1\n1\n"
assert oracle("4 2\n1 2 1 2\n3\nC\nF\nCS 2 4\n") == "4\n3\n"
assert oracle("5 3\n1 2 3 2 1\n3\nR 2\nC\nCS 4 1\n") == "4\n3\n"
assert oracle("6 3\n1 2 3 1 2 3\n3\nP 2 5 3\nC\nCS 5 2\n") == "2\n3\n"


def write(name, bead_count, color_count, initial, commands):
    lines = [f"{bead_count} {color_count}", " ".join(str(value) for value in initial),
             str(len(commands))]
    lines += [" ".join(str(part) for part in command) for command in commands]
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_commands(rng, bead_count, color_count, amount):
    commands = []
    for _ in range(amount):
        choice = rng.random()
        if choice < 0.15:
            commands.append(('R', rng.randint(1, bead_count - 1)))
        elif choice < 0.25:
            commands.append(('F',))
        elif choice < 0.4:
            commands.append(('S', rng.randint(1, bead_count), rng.randint(1, bead_count)))
        elif choice < 0.6:
            commands.append(('P', rng.randint(1, bead_count), rng.randint(1, bead_count),
                             rng.randint(1, color_count)))
        elif choice < 0.8:
            commands.append(('C',))
        else:
            commands.append(('CS', rng.randint(1, bead_count), rng.randint(1, bead_count)))
    return commands


def build():
    write("2_edges", 1, 1, [1], [('C',), ('F',), ('P', 1, 1, 1), ('CS', 1, 1)])
    write("3_wide", 6, 3, [1, 2, 3, 1, 2, 3],
          [('C',), ('R', 2), ('F',), ('S', 2, 5), ('P', 4, 2, 2), ('CS', 5, 1), ('C',)])
    rng = random.Random(20261126)
    initial = [rng.randint(1, 4) for _ in range(40)]
    write("4_random", 40, 4, initial, random_commands(rng, 40, 4, 400))
    initial = [rng.randint(1, 5) for _ in range(100)]
    write("5_io", 100, 5, initial, random_commands(rng, 100, 5, 2000))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", 5, 3, [1, 2, 3, 2, 1],
      [('C',), ('R', 2), ('P', 5, 5, 2), ('CS', 4, 1)])
build()
