#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = text.split()
    count = int(tokens[0])
    cases = []
    cursor = 1
    for _ in range(count):
        length = int(tokens[cursor]); cursor += 1
        target = int(tokens[cursor]); cursor += 1
        cases.append((length, target))
    assert cursor == len(tokens)
    return cases


def reference_case(length, target):
    total = length * (length - 1) // 2
    if abs(target) % 2 != total % 2 or abs(target) > total:
        return ["No"]
    remaining = (total - target) // 2
    negative = {}
    j = length - 1
    while j >= 1:
        if j <= remaining:
            negative[j] = True
            remaining -= j
        else:
            negative[j] = False
        j -= 1
    assert remaining == 0
    values = [0]
    current = 0
    for i in range(1, length):
        weight = length - i
        current += -1 if negative.get(weight, False) else 1
        values.append(current)
    assert sum(values) == target
    return [str(value) for value in values]


def oracle(text):
    blocks = []
    for length, target in parse_cases(text):
        blocks.append("\n".join(reference_case(length, target)) + "\n\n")
    return "".join(blocks)


def validate_output(text, output):
    cases = parse_cases(text)
    lines = output.split("\n")
    assert lines[-1] == ""
    position = 0
    for length, target in cases:
        total = length * (length - 1) // 2
        possible = abs(target) % 2 == total % 2 and abs(target) <= total
        expected = length if possible else 1
        block = lines[position:position + expected]
        assert len(block) == expected
        position += expected
        assert lines[position] == ""
        position += 1
        if not possible:
            assert block == ["No"]
            continue
        values = [int(value) for value in block]
        assert len(values) == length
        assert values[0] == 0
        assert sum(values) == target
        for k in range(1, length):
            assert abs(values[k] - values[k - 1]) == 1
    assert position == len(lines) - 1


def brute_sums(length):
    reachable = set()
    for mask in range(1 << max(0, length - 1)):
        walk = 0
        values = [0]
        for i in range(length - 1):
            walk += 1 if (mask >> i) & 1 else -1
            values.append(walk)
        reachable.add(sum(values))
    total = length * (length - 1) // 2
    expected = {value for value in range(-total, total + 1)
                if abs(value) % 2 == total % 2}
    assert reachable == expected, (length, sorted(reachable - expected),
                                  sorted(expected - reachable))
    return reachable


def pack(pairs):
    blocks = [f"{length}\n{target}" for length, target in pairs]
    return str(len(pairs)) + "\n\n" + "\n\n".join(blocks) + "\n"


def write(name, input_text):
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_IN = "1\n8\n4\n"
SAMPLE_OUT = ("0\n-1\n0\n-1\n0\n1\n2\n3\n\n")

assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert reference_case(1, 0) == ["0"]
assert reference_case(1, 1) == ["No"]
assert reference_case(2, 0) == ["No"]
assert reference_case(2, 1) == ["0", "1"]
assert reference_case(8, 29) == ["No"]
assert reference_case(10000, 49995000)[0] == "0"
assert 10000 * 9999 // 2 == 49995000
for length in range(1, 13):
    assert len(brute_sums(length)) == length * (length - 1) // 2 + 1


def build():
    edges = [(1, 0), (1, 1), (2, 0), (2, 1), (2, -1), (3, 2), (8, 4),
             (8, -4), (8, 3), (8, 29), (8, -29), (10000, 49995000),
             (10000, -49995000), (10000, 49995001)]
    write("2_edges", pack(edges))
    wide = [(10000, 49995000), (10000, -49995000), (10000, 0),
            (9999, 49985001), (9999, -49985001), (9998, 49965003)]
    write("3_wide", pack(wide))

    rng = random.Random(20261124)
    random_pairs = []
    for _ in range(200):
        length = rng.randint(1, 10000)
        total = length * (length - 1) // 2
        if rng.random() < 0.5:
            target = rng.randint(-total, total)
        else:
            target = rng.randint(-50000000, 50000000)
        random_pairs.append((length, target))
    write("4_random", pack(random_pairs))

    io_pairs = []
    for _ in range(200):
        length = 10000
        total = length * (length - 1) // 2
        target = rng.randint(-total, total)
        target -= (total + target) % 2
        io_pairs.append((length, target))
    write("5_io", pack(io_pairs))

    for name in ("2_edges", "3_wide", "4_random", "5_io"):
        text = (ROOT / "in" / f"{name}.txt").read_text()
        output = (ROOT / "out" / f"{name}.out").read_text()
        validate_output(text, output)


work_length = 8
work_target = 4
work_total = work_length * (work_length - 1) // 2
work_remaining = (work_total - work_target) // 2
work_negative = []
work_left = work_remaining
for j in range(work_length - 1, 0, -1):
    if j <= work_left:
        work_negative.append(j)
        work_left -= j
assert work_left == 0
print(f"WORKED n={work_length} S={work_target} totalWeight={work_total} "
      f"remainingSum={work_remaining} negative={work_negative}")
print("WORKED sequence " + " ".join(reference_case(work_length, work_target)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
validate_output(SAMPLE_IN, SAMPLE_OUT)
build()
