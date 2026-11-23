import os
import random

def naive_is_correct(word):
    balance = 0
    for bracket in word:
        if bracket == '(':
            balance += 1
        else:
            balance -= 1
            if balance < 0:
                return False
    return balance == 0

assert naive_is_correct("") is True
assert naive_is_correct("()") is True
assert naive_is_correct(")(") is False
assert naive_is_correct("(()())") is True and naive_is_correct("())(") is False

def render_case(word, operations):
    lines = [str(len(word)), word, str(len(operations))]
    lines.extend(str(operation) for operation in operations)
    return "\n".join(lines) + "\n"

def render_expected(cases):
    result = []
    for case_number, (word, operations) in enumerate(cases, 1):
        current = list(word)
        result.append("Test %d:" % case_number)
        for operation in operations:
            if operation == 0:
                result.append("YES" if naive_is_correct(current) else "NO")
            else:
                position = operation - 1
                current[position] = ')' if current[position] == '(' else '('
    return "\n".join(result) + "\n"

def emit(name, cases):
    with open(os.path.join("in", name + ".txt"), "w", newline="\n") as handle:
        for word, operations in cases:
            handle.write(render_case(word, operations))
    with open(os.path.join("out", name + ".out"), "w", newline="\n") as handle:
        handle.write(render_expected(cases))

sample_cases = [("()((", [4, 0, 2, 0])]
emit("1_sample", sample_cases)

edge_cases = [
    ("(", [0, 1, 0, 1, 0]),
    (")", [0, 1, 0]),
    ("()", [0, 1, 0, 2, 0, 1, 0]),
    (")((", [0, 1, 0, 3, 0, 2, 0]),
    ("(())", [0, 2, 0, 3, 0, 1, 0, 4, 0]),
]
emit("2_edges", edge_cases)

wide_cases = [
    ("(" * 30000, [0, 1, 0, 30000, 0]),
    ("()" * 15000, [0, 1, 0, 2, 0, 1, 0]),
    (")" * 15000 + "(" * 15000, [0, 15000, 0, 15001, 0]),
]
emit("3_wide", wide_cases)

rng = random.Random(20240615)
random_cases = []
for case_index in range(10):
    length = rng.randint(1, 30000) if case_index % 3 == 0 else rng.randint(1, 120)
    word = "".join(rng.choice("()") for _ in range(length))
    operations = []
    for _ in range(60):
        if rng.random() < 0.45:
            operations.append(0)
        else:
            operations.append(rng.randint(1, length))
    random_cases.append((word, operations))
emit("4_random", random_cases)

io_cases = [("()", [0] * 300000) for _ in range(10)]
emit("5_io", io_cases)
