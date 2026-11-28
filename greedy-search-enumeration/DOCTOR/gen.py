#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    cases = []
    while True:
        disease_count = tokens[cursor]
        material_count = tokens[cursor + 1]
        cursor += 2
        if disease_count == 0 and material_count == 0:
            break
        sets = []
        for _ in range(material_count):
            detected_count = tokens[cursor]
            cursor += 1
            detected = tokens[cursor:cursor + detected_count]
            cursor += detected_count
            mask = 0
            for disease in detected:
                mask |= 1 << (disease - 1)
            sets.append(mask)
        cases.append(sets)
    return cases


def oracle(text):
    answers = []
    for sets in parse_cases(text):
        distinct = list(dict.fromkeys(sets))
        unions = [0] * (1 << len(distinct))
        for mask in range(1, 1 << len(distinct)):
            lowest = mask & -mask
            index = lowest.bit_length() - 1
            unions[mask] = unions[mask ^ lowest] | distinct[index]
        irreducible = 0
        for index, target in enumerate(distinct):
            generated = False
            for mask in range(1, 1 << len(distinct)):
                if (mask >> index) & 1:
                    continue
                if unions[mask] == target:
                    generated = True
                    break
            if not generated:
                irreducible += 1
        answers.append(str(len(sets) - irreducible))
    return "\n".join(answers) + "\n"


SAMPLE = """10 5
2 1 2
2 2 3
3 1 2 3
4 1 2 3 4
1 4
3 7
1 1
1 2 
1 3
2 1 2
2 1 3
2 3 2
3 1 2 3
0 0
"""
SAMPLE_OUT = """2
4
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1\n1 1\n0 0\n") == "0\n"
assert oracle("2 2\n1 1\n1 1\n0 0\n") == "1\n"
assert oracle("3 3\n1 1\n1 2\n2 1 2\n0 0\n") == "1\n"
assert oracle("5 4\n2 1 2\n2 3 4\n4 1 2 3 4\n4 1 2 3 4\n0 0\n") == "2\n"


def format_case(sets):
    text = f"{max(max(disease for disease in diseases) for diseases in sets) if sets else 1} {len(sets)}\n"
    for diseases in sets:
        text += f"{len(diseases)}" + "".join(f" {disease}" for disease in diseases) + "\n"
    return text


def write(name, cases):
    text = "".join(format_case(case) for case in cases) + "0 0\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        [[1]],
        [[1], [1]],
        [[1], [2], [1, 2]],
        [[1, 2], [2, 3], [1, 2, 3], [4]],
    ])
    rng = random.Random(20261201)
    write("3_wide", [[rng.sample(range(1, 13), rng.randint(1, 6)) for _ in range(12)]])
    write("4_random", [[rng.sample(range(1, 11), rng.randint(1, 5)) for _ in range(9)]
                       for _ in range(5)])
    write("5_io", [[rng.sample(range(1, 9), rng.randint(1, 4)) for _ in range(rng.randint(2, 8))]
                   for _ in range(130)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
