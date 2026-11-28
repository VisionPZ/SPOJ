#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def max_wait(order):
    elapsed = 0
    worst = 0
    for crossing in order:
        worst = max(worst, elapsed)
        elapsed += crossing
    return worst


def all_interleavings(left, right):
    if not left and not right:
        yield []
        return
    if left:
        for tail in all_interleavings(left[1:], right):
            yield [left[0]] + tail
    if right:
        for tail in all_interleavings(left, right[1:]):
            yield [right[0]] + tail


def brute_best(left, right):
    return min(max_wait(order) for order in all_interleavings(left, right))


def simulate_best(left, right):
    return min(max_wait(list(left) + list(right)),
               max_wait(list(right) + list(left)))


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    answers = []
    for case_index in range(count):
        left_count = int(tokens[cursor]); cursor += 1
        right_count = int(tokens[cursor]); cursor += 1
        left = [int(tokens[cursor + index]) for index in range(left_count)]
        cursor += left_count
        right = [int(tokens[cursor + index]) for index in range(right_count)]
        cursor += right_count
        if left_count + right_count <= 12:
            best = brute_best(left, right)
        else:
            best = simulate_best(left, right)
        answers.append("Case %d: %d" % (case_index + 1, best))
    return "\n".join(answers) + "\n"


SAMPLE_INPUT = "2\n1 1\n5\n3\n3 2\n9 11 4\n10 12\n"
SAMPLE_OUTPUT = "Case 1: 3\nCase 2: 34\n"
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1 1\n100\n1\n") == "Case 1: 1\n"
assert oracle("1\n2 1\n1 1 1\n1\n") == "Case 1: 2\n"
assert oracle("1\n1 3\n7\n1 1 1\n") == "Case 1: 3\n"

random.seed(7)
for _ in range(120):
    left = [random.randint(1, 30) for _ in range(random.randint(1, 4))]
    right = [random.randint(1, 30) for _ in range(random.randint(1, 4))]
    assert brute_best(left, right) == simulate_best(left, right), (left, right)


def write(name, cases):
    input_text = str(len(cases)) + "\n"
    for left, right in cases:
        input_text += "%d %d\n" % (len(left), len(right))
        input_text += " ".join(str(value) for value in left) + "\n"
        input_text += " ".join(str(value) for value in right) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


write("1_sample", [([5], [3]), ([9, 11, 4], [10, 12])])
write("2_edges", [([1], [10 ** 9]), ([10 ** 9], [1]),
                  ([10 ** 9] * 3, [10 ** 9] * 3),
                  ([1] * 5, [10 ** 9] * 5)])
random.seed(2026)
write("3_wide", [([random.randint(1, 10 ** 9) for _ in range(random.randint(1, 40))],
                  [random.randint(1, 10 ** 9) for _ in range(random.randint(1, 40))])
                 for _ in range(40)])
write("4_random", [([random.randint(1, 10000) for _ in range(random.randint(1, 12))],
                    [random.randint(1, 10000) for _ in range(random.randint(1, 12))])
                   for _ in range(100)])
write("5_io", [([random.randint(1, 10 ** 9) for _ in range(random.randint(1, 10000))],
                [random.randint(1, 10 ** 9) for _ in range(random.randint(1, 10000))])
               for _ in range(30)])
