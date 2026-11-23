import os, random, sys

sys.setrecursionlimit(100000)

PUBLISHED = [
    ("110011000", 4),
    ("111000100", 3),
    ("010", 0),
    ("1", 1),
    ("11", 2),
    ("111100111000000", 7),
    ("101010110011000", 7),
    ("1100111011001010000", 9),
    ("1100111000100", 5),
    ("111010001010100", 4),
]


def oracle(bitword):
    word_length = len(bitword)
    span = [0] * (word_length + 1)
    for position in range(word_length - 1, -1, -1):
        if bitword[position] == "0":
            span[position] = 1
        else:
            left_span = span[position + 1]
            right_start = position + 1 + left_span
            span[position] = 1 + left_span + span[right_start]
    leaves = []
    cut_count = 0
    stack = [(0, 0)]
    while stack:
        position, depth = stack.pop()
        if position >= word_length or bitword[position] == "0":
            leaves.append((depth, cut_count))
        else:
            cut_count += 1
            right_start = position + 1 + span[position + 1]
            stack.append((right_start, depth + 1))
            stack.append((position + 1, depth + 1))
    deepest = max(depth for depth, _ in leaves)
    return min(cuts for depth, cuts in leaves if depth == deepest)


def recursive_check(bitword):
    word_length = len(bitword)
    leaf_records = []
    cut_counter = [0]

    def visit(position, depth):
        if position >= word_length or bitword[position] == "0":
            leaf_records.append((depth, cut_counter[0]))
            return position + 1
        cut_counter[0] += 1
        next_left = visit(position + 1, depth + 1)
        return visit(next_left, depth + 1)

    visit(0, 0)
    deepest = max(depth for depth, _ in leaf_records)
    return min(cuts for depth, cuts in leaf_records if depth == deepest)


assert all(oracle(word) == expected for word, expected in PUBLISHED)
assert all(oracle("0" * length) == 0 for length in range(1, 51))
assert all(oracle("1" * length) == length for length in range(1, 51))
assert all(oracle("0" + "1" * length) == 0 for length in range(1, 51))
check_rng = random.Random(101)
for _ in range(400):
    small_word = "".join(check_rng.choice("01") for _ in range(check_rng.randint(1, 14)))
    assert oracle(small_word) == recursive_check(small_word)


def write_pair(name, cases):
    input_lines = []
    output_lines = []
    for declared_length, bitword in cases:
        assert declared_length == len(bitword)
        input_lines.append(str(declared_length))
        input_lines.append(bitword)
        output_lines.append(str(oracle(bitword)))
    with open("in/" + name + ".txt", "w") as input_file:
        input_file.write("\n".join(input_lines) + "\n")
    with open("out/" + name + ".out", "w") as output_file:
        output_file.write("\n".join(output_lines) + "\n")


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write_pair("1_sample", [(9, "110011000")])

write_pair("2_edges", [
    (1, "0"),
    (1, "1"),
    (2, "10"),
    (2, "11"),
    (3, "010"),
    (3, "000"),
    (4, "1010"),
    (4, "1100"),
    (5, "11110"),
    (9, "111000100"),
    (15, "111100111000000"),
    (20, "1" * 20),
])

wide_cases = [
    (20000, "1" * 20000),
    (20000, "0" + "1" * 19999),
    (20000, "1" + "0" * 19999),
    (20000, "10" * 10000),
]
write_pair("3_wide", wide_cases)

randomizer = random.Random(20261123)
random_cases = []
for _ in range(10):
    word_length = randomizer.randint(19990, 20000)
    random_cases.append((word_length, "".join(randomizer.choice("01") for _ in range(word_length))))
write_pair("4_random", random_cases)

io_cases = []
for case_index in range(10):
    word_length = 20000
    if case_index % 3 == 0:
        bits = "1" * word_length
    elif case_index % 3 == 1:
        bits = "0" + "1" * (word_length - 1)
    else:
        bits = ("110011000" * ((word_length + 8) // 9))[:word_length]
    io_cases.append((word_length, bits))
write_pair("5_io", io_cases)

print("generated", len(random_cases), "random cases and", len(PUBLISHED), "verified published cases")
