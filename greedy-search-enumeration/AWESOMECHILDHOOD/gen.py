import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "2\n10236\n172\n"
SAMPLE_OUTPUT = "Case 1: 5118\nCase 2: 86\n"


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for case_index in range(1, count + 1):
        given = int(tokens[cursor])
        cursor += 1
        possible = set()
        for borrowed in (2, 1000, given // 4 + 1):
            doubled = 2 * borrowed
            combined = doubled + given
            kept = combined // 2
            possible.add(kept - borrowed)
        assert len(possible) == 1
        answers.append("Case {}: {}".format(case_index, possible.pop()))
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n2\n") == "Case 1: 1\n"
assert oracle("3\n4\n6\n8\n") == "Case 1: 2\nCase 2: 3\nCase 3: 4\n"
assert oracle("1\n4294967296\n") == "Case 1: 2147483648\n"


def write(name, given_values):
    pieces = [str(len(given_values))] + [str(value) for value in given_values]
    input_text = "\n".join(pieces) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build():
    write("2_edges", [2, 4, 6, 8, 10, 12, 4294967296, 4294967294])
    write("3_wide", [4294967296] * 9999)
    random.seed(2026)
    write("4_random", [2 * random.randint(1, 2 ** 31 - 1) for _ in range(5000)])
    write("5_io", [2 * random.randint(1, 2 ** 31 - 1) for _ in range(9999)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [10236, 172])
build()
