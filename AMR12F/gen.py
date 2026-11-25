#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MOD = 1000000007


def dequeue_permutations(size):
    found = []

    def walk(low, high, prefix):
        if low > high:
            found.append(tuple(prefix))
            return
        walk(low + 1, high, prefix + [low])
        walk(low, high - 1, prefix + [high])

    walk(1, size, [])
    return sorted(set(found))


def oracle(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        cursor += 1
        half = size // 2
        seen = []
        broken = False
        for _ in range(half):
            position = int(tokens[cursor])
            value = int(tokens[cursor + 1])
            cursor += 2
            if broken:
                answers.append("-1")
                continue
            seen.append((position, value))
            furthest = max(position for position, _ in seen)
            best_min = None
            best_max = None
            for mask in range(1 << furthest):
                low = 1
                high = size
                base = 0
                valid = True
                for step in range(1, furthest + 1):
                    if (mask >> (step - 1)) & 1:
                        produced = high
                        base = (base + pow(2, size - step - 1, MOD)) % MOD
                        high -= 1
                    else:
                        produced = low
                        low += 1
                    if any(pos == step and val != produced for pos, val in seen):
                        valid = False
                        break
                if valid:
                    lowest = base
                    highest = (base + pow(2, size - furthest - 1, MOD) - 1) % MOD
                    if best_min is None or lowest < best_min:
                        best_min = lowest
                    if best_max is None or highest > best_max:
                        best_max = highest
            if best_min is None:
                broken = True
                answers.append("-1")
            else:
                answers.append(f"{best_min} {best_max}")
    return "\n".join(answers) + "\n"


def brute(text):
    tokens = text.split()
    case_count = int(tokens[0])
    cursor = 1
    answers = []
    for _ in range(case_count):
        size = int(tokens[cursor])
        cursor += 1
        half = size // 2
        permutations = dequeue_permutations(size)
        candidates = list(range(len(permutations)))
        broken = False
        for _ in range(half):
            position = int(tokens[cursor])
            value = int(tokens[cursor + 1])
            cursor += 2
            if broken:
                answers.append("-1")
                continue
            candidates = [rank for rank in candidates if permutations[rank][position - 1] == value]
            if not candidates:
                broken = True
                answers.append("-1")
            else:
                answers.append(f"{candidates[0]} {candidates[-1]}")
    return "\n".join(answers) + "\n"


SAMPLE = ("2\n3\n1 3\n32\n1 1\n3 2\n2 32\n4 4\n5 5\n6 6\n7 7\n8 8\n"
          "9 9\n10 10\n11 11\n12 12\n13 13\n14 14\n15 15\n16 3\n")
SAMPLE_OUT = ("2 3\n0 73741816\n536870912 805306367\n536870912 805306367\n"
              "-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n-1\n")
assert oracle(SAMPLE) == SAMPLE_OUT
assert brute("1\n3\n1 3\n") == "2 3\n"
assert oracle("1\n2\n1 1\n") == "0 0\n"
assert oracle("1\n2\n1 2\n") == "1 1\n"
for tiny in ["1\n4\n1 1\n2 4\n", "1\n5\n3 1\n1 5\n2 4\n",
             "1\n6\n2 6\n1 1\n3 2\n"]:
    assert oracle(tiny) == brute(tiny)


def write_cases(name, cases):
    pieces = [str(len(cases))]
    for size, pairs in cases:
        pieces.append(str(size))
        for position, value in pairs:
            pieces.append(f"{position} {value}")
    text = "\n".join(pieces) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write_cases("2_edges", [
        (2, [(1, 1)]), (2, [(1, 2)]), (3, [(1, 3)]),
        (4, [(1, 1), (2, 4)]), (5, [(2, 1), (1, 5)]),
        (6, [(2, 6), (1, 1), (3, 2)]),
    ])
    wide_pairs = [(position, position) for position in range(1, 9)]
    wide_pairs += [(position, position + 1) for position in range(9, 50000)]
    wide_pairs.append((50000, 50000))
    write_cases("3_wide", [(100000, wide_pairs)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(15):
        size = rng.randint(3, 14)
        half = size // 2
        options = dequeue_permutations(size)
        sample = rng.choice(options)
        positions = list(range(1, half + 1))
        rng.shuffle(positions)
        pairs = []
        for position in positions:
            if rng.random() < 0.85:
                value = sample[position - 1]
            else:
                value = rng.randint(1, size)
            pairs.append((position, value))
        random_cases.append((size, pairs))
    write_cases("4_random", random_cases)
    io_cases = []
    for _ in range(15):
        size = 200
        half = size // 2
        sample = dequeue_permutations(8)[0] + tuple(range(9, size + 1))
        order = list(range(1, half + 1))
        pairs = []
        for position in order:
            if position <= 5:
                value = sample[position - 1]
            elif position < half:
                value = position + 1
            else:
                value = sample[position - 1]
            pairs.append((position, value))
        io_cases.append((size, pairs))
    write_cases("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
