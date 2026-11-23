
import os
import random

OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def min_code(size):
    if size == 1:
        return 0
    return (1 << (size - 1)) + min_code(size - 2)


def max_code(size):
    if size == 1:
        return 0
    return (1 << (size - 1)) + 2 * max_code(size - 2)


def parse_tree(code, size):
    left_size = 0
    left_bits = 0
    slots = 1
    pos = size - 2
    while True:
        bit = (code >> pos) & 1
        left_bits = (left_bits << 1) | bit
        left_size += 1
        if bit == 1:
            slots += 1
        else:
            slots -= 1
        pos -= 1
        if slots == 0:
            break
    right_size = size - 1 - left_size
    right_code = code & ((1 << right_size) - 1) if right_size > 0 else 0
    return left_size, left_bits, right_code


def compose(left_size, left_code, right_size, right_code):
    return (1 << (left_size + right_size)) + (1 << right_size) * left_code + right_code


def bounded_next(code, max_size):
    if max_size < 1:
        return None
    if code == 0:
        return 4 if 3 <= max_size else None
    size = code.bit_length()
    left_size, left_code, right_code = parse_tree(code, size)
    next_right = bounded_next(right_code, max_size - left_size - 1)
    if next_right is not None:
        return compose(left_size, left_code, next_right.bit_length(), next_right)
    next_left = bounded_next(left_code, max_size - 2)
    if next_left is None:
        return None
    return compose(next_left.bit_length(), next_left, 1, 0)


def successor(code, size):
    if size <= 1:
        return 0
    left_size, left_code, right_code = parse_tree(code, size)
    right_size = size - 1 - left_size
    if right_code != max_code(right_size):
        return compose(left_size, left_code, right_size, successor(right_code, right_size))
    next_left = bounded_next(left_code, size - 2)
    if next_left is None:
        return min_code(size)
    next_left_size = next_left.bit_length()
    next_right_size = size - 1 - next_left_size
    return compose(next_left_size, next_left, next_right_size, min_code(next_right_size))


def brute_codes(size):
    if size == 1:
        return [0]
    result = []

    def walk(bits, slots):
        if len(bits) == size:
            if slots == 0:
                value = 0
                for bit in bits:
                    value = value * 2 + bit
                result.append(value)
            return
        if slots >= 1:
            walk(bits + [1], slots + 1)
        walk(bits + [0], slots - 1)

    walk([1], 2)
    return sorted(result)


assert min_code(5) == 20 and max_code(5) == 24
assert min_code(9) == 340 and max_code(9) == 480
assert successor(20, 5) == 24 and successor(24, 5) == 20
assert successor(112, 7) == 84
for check_size in (1, 3, 5, 7, 9, 11, 13, 15):
    codes = brute_codes(check_size)
    expected_counts = {1: 1, 3: 1, 5: 2, 7: 5, 9: 14, 11: 42, 13: 132, 15: 429}
    assert len(codes) == expected_counts[check_size]
    for index, code in enumerate(codes):
        assert successor(code, check_size) == codes[(index + 1) % len(codes)]


def random_tree(size, rng):
    if size == 1:
        return 0
    choices = list(range(1, size - 1, 2))
    left_size = rng.choice(choices)
    left_code = random_tree(left_size, rng)
    right_size = size - 1 - left_size
    right_code = random_tree(right_size, rng)
    return compose(left_size, left_code, right_size, right_code)


def write_pair(name, identifiers):
    input_path = os.path.join(OUT_DIR, "in", name + ".txt")
    output_path = os.path.join(OUT_DIR, "out", name + ".out")
    with open(input_path, "w") as input_file:
        input_file.write(str(len(identifiers)) + "\n")
        for identifier in identifiers:
            input_file.write(str(identifier) + "\n")
    with open(output_path, "w") as output_file:
        for identifier in identifiers:
            size = identifier.bit_length() or 1
            output_file.write(str(successor(identifier, size)) + "\n")


write_pair("1_sample", [20])

edges = [0, 4, 20, 24, 84, 88, 100, 104, 112, 340, 480]
for size in range(11, 30, 2):
    edges.append(min_code(size))
    edges.append(max_code(size))
write_pair("2_edges", edges)

wide = []
for size in range(1, 30, 2):
    wide.append(min_code(size))
    wide.append(max_code(size))
    wide.append(random_tree(size, random.Random(size)))
    wide.append(random_tree(size, random.Random(size + 1000)))
write_pair("3_wide", wide)

rng = random.Random(20231124)
random_cases = []
for _ in range(50000):
    size = rng.choice(list(range(3, 30, 2)))
    random_cases.append(random_tree(size, rng))
write_pair("4_random", random_cases)

io_rng = random.Random(987654321)
io_cases = [random_tree(29, io_rng) for _ in range(200000)]
write_pair("5_io", io_cases)
