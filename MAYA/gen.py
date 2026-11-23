#!/usr/bin/env python3
import random


def render_symbol(digit):
    if digit == 0:
        return "S"
    dash_count, dot_count = divmod(digit, 5)
    return "." * dot_count + " -" * dash_count


def serialize(numbers):
    blocks = []
    for digits in numbers:
        blocks.append(str(len(digits)) + "\n")
        for digit in digits:
            blocks.append(render_symbol(digit) + "\n")
        blocks.append("\n")
    blocks.append("0\n")
    return "".join(blocks)


def oracle(digits):
    value = 0
    multiplier = 1
    for digit in reversed(digits):
        value += digit * multiplier
        if multiplier == 1:
            multiplier = 20
        elif multiplier == 20:
            multiplier = 360
        else:
            multiplier *= 20
    return value


def expected_output(numbers):
    return "".join(str(oracle(digits)) + "\n" for digits in numbers)


SAMPLE_INPUT = "1\n..\n\n5\n... -\n. - -\nS\nS\nS\n\n0\n"
SAMPLE_OUTPUT = "2\n1231200\n"
SAMPLE_NUMBERS = [[2], [8, 11, 0, 0, 0]]

assert serialize(SAMPLE_NUMBERS) == SAMPLE_INPUT
assert expected_output(SAMPLE_NUMBERS) == SAMPLE_OUTPUT
assert oracle([2]) == 2
assert oracle([8, 11, 0, 0, 0]) == 1231200
assert oracle([3, 19]) == 79
assert oracle([1, 17, 8, 15]) == 13495
assert oracle([0] * 7) == 0
assert oracle([19] * 7) == 1152000039
assert oracle([1, 0, 0]) == 360
assert oracle([0, 0, 1, 0, 0]) == 360
assert oracle([1, 0, 0, 0, 0, 0]) == 2880000

PLACE_VALUES = [1, 20, 360, 7200, 144000, 2880000, 57600000]


def table_value(digits):
    total = 0
    for index, digit in enumerate(digits):
        total += digit * PLACE_VALUES[len(digits) - 1 - index]
    return total


check_rng = random.Random(1977)
for digit_count in range(1, 8):
    for _ in range(500):
        digits = [check_rng.randint(0, 19) for _ in range(digit_count)]
        assert oracle(digits) == table_value(digits)


def write_case(name, numbers):
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write(serialize(numbers))
    with open("out/" + name + ".out", "w") as output_file:
        output_file.write(expected_output(numbers))


with open("in/1_sample.txt", "w") as input_file:
    input_file.write(SAMPLE_INPUT)
with open("out/1_sample.out", "w") as output_file:
    output_file.write(SAMPLE_OUTPUT)

write_case("2_edges", [
    [1], [19], [0], [0, 0], [0, 0, 0], [0] * 7, [19] * 7,
    [1, 0], [0, 1], [0, 0, 1], [0, 0, 1, 0, 0],
    [1, 0, 0, 0, 0, 0], [5, 0, 6, 0, 7, 0, 8],
])

rng = random.Random(20261124)
wide_numbers = [[0] * 7, [19] * 7, [19, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 19], [1, 0, 0, 0, 0, 0, 0],
                [0, 0, 0, 0, 0, 0, 1]]
wide_numbers += [[rng.randint(0, 19) for _ in range(7)] for _ in range(200)]
write_case("3_wide", wide_numbers)

random_numbers = []
for _ in range(1000):
    digit_count = rng.randint(1, 7)
    random_numbers.append([rng.randint(0, 19) for _ in range(digit_count)])
write_case("4_random", random_numbers)

io_numbers = [[19] * 7 for _ in range(20000)]
write_case("5_io", io_numbers)

stress_numbers = [[rng.randint(0, 19) for _ in range(7)] for _ in range(200000)]
with open("/tmp/MAYA_big.txt", "w") as stress_file:
    stress_file.write(serialize(stress_numbers))

print("generated five cases and stress file")
