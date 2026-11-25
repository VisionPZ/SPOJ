#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = "5 1\n"
SAMPLE_OUT = "abcde\n"


def greedy_counts(total_length, per_letter_limit, letter_count=26):
    counts = []
    placed = 0
    for _ in range(letter_count):
        take = min(per_letter_limit, total_length - placed)
        counts.append(take)
        placed += take
    return counts


def expand(counts):
    letters = []
    for index, count in enumerate(counts):
        letters.append(chr(97 + index) * count)
    return "".join(letters)


def oracle(input_text):
    n_text, m_text = input_text.split()[:2]
    return expand(greedy_counts(int(n_text), int(m_text))) + "\n"


def brute_force(total_length, per_letter_limit, letter_count):
    best = [None]

    def walk(letter_index, remaining, prefix):
        if remaining == 0:
            candidate = "".join(prefix)
            if best[0] is None or candidate < best[0]:
                best[0] = candidate
            return
        if letter_index >= letter_count:
            return
        for take in range(min(per_letter_limit, remaining) + 1):
            walk(letter_index + 1, remaining - take, prefix + [chr(97 + letter_index) * take])

    walk(0, total_length, [])
    return best[0]


def write(name, total_length, per_letter_limit):
    input_text = "%d %d\n" % (total_length, per_letter_limit)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def trace_example():
    total_length, per_letter_limit = 5, 1
    counts = greedy_counts(total_length, per_letter_limit)
    print("n 5 m 1")
    print("letter quotas taken " + " ".join(str(count) for count in counts[:5]))
    print("answer abcde")


for letters in (2, 3):
    for total in range(1, 13):
        for limit in range(1, 5):
            if total > letters * limit:
                continue
            assert expand(greedy_counts(total, limit, letters)) == brute_force(total, limit, letters)

assert oracle(SAMPLE_INPUT) == SAMPLE_OUT
assert oracle("1 1\n") == "a\n"
assert oracle("26 1\n") == "abcdefghijklmnopqrstuvwxyz\n"
assert oracle("4 2\n") == "aabb\n"
assert oracle("27 2\n") == "aabbccddeeffgghhiijjkkllmmn\n"
assert oracle("3 100\n") == "aaa\n"


def build():
    write("2_edges", 1, 1)
    write("3_wide", 100000, 100000)
    rng = random.Random(2024)
    total_length = 100000
    per_letter_limit = rng.randint((total_length + 25) // 26, 100000)
    write("4_random", total_length, per_letter_limit)
    write("5_io", 100000, 3847)
    write("6_alphabet", 26, 1)
    write("7_minquota", 100000, 3847)
    write("8_bigquota", 99999, 100000)
    for index in range(12):
        small_total = rng.randint(1, 300)
        small_limit = rng.randint((small_total + 25) // 26, 200)
        write("9_small_%d" % index, small_total, small_limit)


if __name__ == "__main__":
    import sys
    if "--trace" in sys.argv:
        trace_example()
    else:
        (ROOT / "in").mkdir(exist_ok=True)
        (ROOT / "out").mkdir(exist_ok=True)
        (ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
        (ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
        build()
