#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def valid_sequence(numbers, positions):
    current = list(numbers)
    for position in positions:
        index = position - 1
        current[index] = current[index] - current[index + 1]
        current.pop(index + 1)
    return current[0] if len(current) == 1 else None


def signs_for(numbers, target):
    if len(numbers) == 1:
        return [1]
    wanted = target - numbers[0] + numbers[1]
    tail = numbers[2:]
    size = len(tail)
    chosen = [0] * size

    def search(depth, total):
        if depth == size:
            return total == wanted
        index = size - 1 - depth
        for sign in (1, -1):
            chosen[index] = sign
            if search(depth + 1, total + sign * tail[index]):
                return True
        return False

    assert search(0, 0)
    return [1, -1] + chosen


def oracle_case(numbers, target):
    signs = signs_for(numbers, target)
    starts = list(range(len(numbers)))
    values = list(numbers)
    lines = []

    def effective(index, inverted):
        return -signs[index] if inverted else signs[index]

    def build(first, last, inverted):
        if first == last:
            return starts.index(first)
        split = -1
        for candidate in range(first + 1, last + 1):
            if effective(candidate, inverted) == -1 and (candidate == last or effective(candidate + 1, inverted) == 1):
                split = candidate
                break
        left_position = build(first, split - 1, inverted)
        right_position = build(split, last, not inverted)
        lines.append(str(left_position + 1))
        values[left_position] -= values[right_position]
        values.pop(right_position)
        starts.pop(right_position)
        return left_position

    build(0, len(numbers) - 1, False)
    assert valid_sequence(numbers, [int(line) for line in lines]) == target
    return lines


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor])
    cursor += 1
    output = []
    for _case in range(case_count):
        number_count = int(tokens[cursor])
        target = int(tokens[cursor + 1])
        cursor += 2
        numbers = [int(tokens[cursor + index]) for index in range(number_count)]
        cursor += number_count
        output.extend(oracle_case(numbers, target))
        output.append("")
    if not output:
        return ""
    return "\n".join(output) + "\n"


SAMPLE_IN = """1
5 4
12
10
4
3
5
"""
SAMPLE_OUT = """2
3
2
1

"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert valid_sequence([12, 10, 4, 3, 5], [2, 3, 2, 1]) == 4
assert valid_sequence([7], []) == 7
assert valid_sequence([12, 10, 4, 3, 5], [2, 2, 1, 1]) == 4


def case_text(numbers, target):
    return f"{len(numbers)} {target}\n" + "".join(f"{number}\n" for number in numbers)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(case_text(*case) for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def random_case(rng, limit):
    number_count = rng.randint(1, limit)
    numbers = [rng.randint(0, 20) for _ in range(number_count)]
    signs = [1] + ([-1] if number_count > 1 else []) + [rng.choice([-1, 1]) for _ in range(max(0, number_count - 2))]
    target = sum(sign * number for sign, number in zip(signs, numbers))
    return (numbers, target)


def build():
    write("2_edges", [([7], 7), ([12, 12], 0), ([12, 10, 4, 3, 5], 4),
                      ([0, 100], -100), ([100, 0, 100, 0, 100], 300)])
    write("3_wide", [([100] * 10, 0), ([100, 0] * 5, 100), ([0] * 10, 0)])
    rng = random.Random(20261126)
    write("4_random", [random_case(rng, 12) for _ in range(100)])
    write("5_io", [random_case(rng, 5) for _ in range(30000)])
    (Path("/tmp") / "MINUS_big.txt").write_text(
        "1\n100 0\n" + "".join(f"{index % 101}\n" for index in range(100)))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([12, 10, 4, 3, 5], 4)])
build()
