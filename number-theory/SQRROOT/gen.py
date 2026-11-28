#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        value = int(tokens[cursor])
        cursor += 1
        root = math.isqrt(value)
        assert root * root == value
        answers.append(str(root))
    return "\n".join(answers) + "\n"


def write(name, roots):
    numbers = [root * root for root in roots]
    input_text = str(len(numbers)) + "\n" + "".join(
        str(number) + "\n" for number in numbers)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [6, 9, 476]
assert oracle("3\n36\n81\n226576\n") == "6\n9\n476\n"
assert math.isqrt(226576) == 476
assert math.isqrt(10 ** 800 - 1) == 10 ** 400 - 1
assert math.isqrt(10 ** 798) == 10 ** 399
for value in range(1, 5000):
    trial = math.isqrt(value)
    assert trial * trial <= value < (trial + 1) * (trial + 1)


def build():
    edges = [1, 2, 3, 9, 10, 11, 99, 100, 101, 10 ** 399,
             10 ** 400 - 2, 10 ** 400 - 1]
    write("2_edges", edges)
    write("3_wide", [10 ** 399 + k for k in range(25)] +
          [10 ** 400 - 1 - k for k in range(25)])
    random.seed(2026)
    ragged = []
    for _ in range(50):
        length = random.randint(1, 400)
        ragged.append(random.randrange(10 ** (length - 1), 10 ** length))
    write("4_random", ragged)
    full = [random.randrange(10 ** 399, 10 ** 400) for _ in range(50)]
    write("5_io", full)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()


def demo():
    text = str(226576)
    if len(text) % 2 == 1:
        text = "0" + text
    root = 0
    remainder = 0
    print("| pair | before | base | digit | product | after | root |")
    print("| --- | --- | --- | --- | --- | --- | --- |")
    for k in range(0, len(text), 2):
        pair = int(text[k:k + 2])
        before = remainder * 100 + pair
        base = 20 * root
        chosen = 0
        for digit in range(9, -1, -1):
            if (base + digit) * digit <= before:
                chosen = digit
                break
        product = (base + chosen) * chosen
        remainder = before - product
        root = root * 10 + chosen
        print(f"| {pair} | {before} | {base} | {chosen} | {product} | {remainder} | {root} |")


if __name__ == "__main__":
    demo()
