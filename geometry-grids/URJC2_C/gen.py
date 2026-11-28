import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "2\n"
    "3 5\n"
    "1\n"
    "200\n"
    "4\n"
    "2 5000\n"
    "4999\n"
    "5000\n"
)
SAMPLE_OUTPUT = (
    "Yes, it blends!\n"
    "Well, it mostly blended\n"
    "Yes, it blends!\n"
    "Yes, it blends!\n"
    "Well, it mostly blended\n"
)


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        item_count = int(tokens[cursor])
        blender_power = int(tokens[cursor + 1])
        cursor += 2
        needed = [int(tokens[cursor + k]) for k in range(item_count)]
        cursor += item_count
        ordered = sorted(needed)
        first_blocked = bisect.bisect_left(ordered, blender_power)
        blocked = set(ordered[first_blocked:])
        for power in needed:
            if power in blocked:
                answers.append("Well, it mostly blended")
            else:
                answers.append("Yes, it blends!")
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1 1\n1\n") == "Well, it mostly blended\n"
assert oracle("1\n1 1000000000\n1000000000\n") == "Well, it mostly blended\n"
assert oracle("1\n2 7\n7\n6\n") == "Well, it mostly blended\nYes, it blends!\n"


def write(name, cases):
    lines = [str(len(cases))]
    for blender_power, needed in cases:
        lines.append("{} {}".format(len(needed), blender_power))
        lines.extend(str(value) for value in needed)
    input_text = "\n".join(lines) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build():
    write("2_edges", [
        (1, [1]),
        (1000000000, [1000000000]),
        (1, [1000000000]),
        (1000000000, [1, 999999999, 1000000000]),
    ])
    write("3_wide", [(500000000, [1, 499999999, 500000000, 500000001,
                                  1000000000] * 200)])
    random.seed(2026)
    write("4_random", [
        (random.randint(1, 10 ** 9),
         [random.randint(1, 10 ** 9) for _ in range(random.randint(1, 20))])
        for _ in range(300)
    ])
    write("5_io", [
        (random.randint(1, 10 ** 9),
         [random.randint(1, 10 ** 9) for _ in range(1000)])
        for _ in range(30)
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(5, [1, 200, 4]), (5000, [4999, 5000])])
build()
