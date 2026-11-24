#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    position = 0
    case_count = int(tokens[position]); position += 1
    cases = []
    for _ in range(case_count):
        k = int(tokens[position]); position += 1
        lengths = [int(tokens[position + i]) for i in range(k)]
        position += k
        position += 1
        left = list(tokens[position]); position += 1
        position += 1
        right = list(tokens[position]); position += 1
        cases.append((lengths, left, right))
    return cases


def expand(side, lengths, base, const_zero):
    bits = []
    for piece in side:
        for token in piece:
            if token == '0' or token == '1':
                bits.append(const_zero + int(token))
            else:
                index = ord(token) - 97
                for offset in range(lengths[index]):
                    bits.append(base[index] + offset)
    return bits


def layout(lengths):
    base = []
    running = 0
    for length in lengths:
        base.append(running)
        running += length
    return base, running


def oracle(case):
    lengths, left, right = case
    base, total_bits = layout(lengths)
    const_zero = total_bits
    const_one = total_bits + 1
    adjacency = [[] for _ in range(total_bits + 2)]
    left_bits = expand(left, lengths, base, const_zero)
    right_bits = expand(right, lengths, base, const_zero)
    if len(left_bits) != len(right_bits):
        return 0
    for i in range(len(left_bits)):
        a = left_bits[i]
        b = right_bits[i]
        adjacency[a].append(b)
        adjacency[b].append(a)
    seen = [False] * (total_bits + 2)
    free = 0
    for start in range(total_bits + 2):
        if seen[start]:
            continue
        stack = [start]
        seen[start] = True
        has_zero = False
        has_one = False
        while stack:
            node = stack.pop()
            if node == const_zero:
                has_zero = True
            elif node == const_one:
                has_one = True
            for neighbour in adjacency[node]:
                if not seen[neighbour]:
                    seen[neighbour] = True
                    stack.append(neighbour)
        if has_zero and has_one:
            return 0
        if not has_zero and not has_one:
            free += 1
    return 1 << free


def brute(case):
    lengths, left, right = case
    base, total_bits = layout(lengths)
    if total_bits > 18:
        return None
    const_zero = total_bits
    left_bits = expand(left, lengths, base, const_zero)
    right_bits = expand(right, lengths, base, const_zero)
    if len(left_bits) != len(right_bits):
        return 0
    count = 0
    for assignment in range(1 << total_bits):
        good = True
        for i in range(len(left_bits)):
            a = left_bits[i]
            b = right_bits[i]
            va = (assignment >> a) & 1 if a < total_bits else a - const_zero
            vb = (assignment >> b) & 1 if b < total_bits else b - const_zero
            if va != vb:
                good = False
                break
        if good:
            count += 1
    return count


def random_side(rng, lengths, total):
    side = []
    while total > 0:
        options = [('0', 1), ('1', 1)]
        options += [(chr(97 + i), lengths[i]) for i in range(len(lengths))
                    if lengths[i] <= total]
        token, size = rng.choice(options)
        side.append(token)
        total -= size
    return side


def format_case(case):
    lengths, left, right = case
    left_word = "".join(left)
    right_word = "".join(right)
    return "\n".join([str(len(lengths)), " ".join(map(str, lengths)),
                      str(len(left_word)), left_word,
                      str(len(right_word)), right_word])


def emit(name, cases):
    text = str(len(cases)) + "\n" + "\n\n".join(format_case(c) for c in cases) + "\n"
    answers = [str(oracle(c)) for c in cases]
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")
    return text


def describe_sample(case):
    lengths, left, right = case
    base, total_bits = layout(lengths)
    adjacency = [[] for _ in range(total_bits + 2)]
    left_bits = expand(left, lengths, base, total_bits)
    right_bits = expand(right, lengths, base, total_bits)
    for i in range(len(left_bits)):
        a = left_bits[i]
        b = right_bits[i]
        adjacency[a].append(b)
        adjacency[b].append(a)
    seen = [False] * (total_bits + 2)
    fixed = 0
    free = 0
    for start in range(total_bits + 2):
        if seen[start]:
            continue
        stack = [start]
        seen[start] = True
        touches_zero = False
        touches_one = False
        while stack:
            node = stack.pop()
            touches_zero |= node == total_bits
            touches_one |= node == total_bits + 1
            for neighbour in adjacency[node]:
                if not seen[neighbour]:
                    seen[neighbour] = True
                    stack.append(neighbour)
        if touches_zero or touches_one:
            fixed += 1
        else:
            free += 1
    return f"classes={fixed + free} fixed={fixed} free={free} answer=2^{free}={1 << free}"


SAMPLE_TEXT = "1\n5\n4 2 4 4 2\n5\n1bad1\n4\nacbe\n"
SAMPLE = parse(SAMPLE_TEXT)[0]

assert parse(SAMPLE_TEXT) == [([4, 2, 4, 4, 2], list("1bad1"), list("acbe"))]
assert oracle(SAMPLE) == 16
assert describe_sample(SAMPLE) == "classes=6 fixed=2 free=4 answer=2^4=16"
assert oracle(([], ['0'], ['0'])) == 1
assert oracle(([], ['0'], ['1'])) == 0
assert oracle(([1], ['a'], ['aa'])) == 0
assert oracle(([1], ['1a'], ['a0'])) == 0
assert oracle(([1], ['a'], ['a'])) == 2
assert oracle(([10000], ['a'], ['a'])) == 1 << 10000

hand = [
    ([], ['0'], ['0']),
    ([], ['1'], ['0']),
    ([1], ['a'], ['0']),
    ([1], ['a'], ['1']),
    ([1], ['a'], ['a']),
    ([1], ['a'], ['aa']),
    ([1], ['1a'], ['a0']),
    ([1], ['a0'], ['0a']),
    ([2], ['aa'], ['a', 'a']),
    ([2, 1], ['ab'], ['ba']),
    ([2, 1], ['ab'], ['a1']),
    ([3], ['aaa'], ['aaa']),
    ([3], ['a1a'], ['aa1']),
]
for case in hand:
    assert brute(case) == oracle(case), case

rng_cross = random.Random(11)
for _ in range(400):
    k = rng_cross.randint(0, 3)
    lengths = [rng_cross.randint(1, 3) for _ in range(k)]
    if sum(lengths) > 12:
        continue
    left = random_side(rng_cross, lengths, rng_cross.randint(1, 12))
    right = random_side(rng_cross, lengths, rng_cross.randint(1, 12))
    case = (lengths, left, right)
    assert brute(case) == oracle(case), case


def build_edges():
    return [
        ([], ['0'], ['0']),
        ([], ['0'], ['1']),
        ([1], ['a'], ['a']),
        ([1], ['a'], ['0']),
        ([1], ['0'], ['a']),
        ([1], ['1'], ['a']),
        ([1], ['a'], ['aa']),
        ([1], ['1a'], ['a0']),
        ([2, 1], ['ab'], ['ba']),
        ([3], ['aaa'], ['aaa']),
        ([2, 1], ['ab'], ['a1']),
    ]


def build_wide():
    alphabet = list("abcdefghijklmnopqrstuvwxyz")
    return [
        ([10000], ['a'], ['a']),
        ([384] * 25 + [400], alphabet, alphabet),
        ([10000, 10000], ['a'], ['b']),
        ([9999], ['a', '0'], ['0', 'a']),
        ([9999], ['a', '1'], ['0', 'a']),
    ]


def build_random():
    rng = random.Random(20261124)
    cases = []
    for _ in range(40):
        k = rng.randint(1, 26)
        lengths = [rng.randint(1, max(1, 10000 // k)) for _ in range(k)]
        total = rng.randint(1, 2000)
        left = random_side(rng, lengths, total)
        right = random_side(rng, lengths, total)
        cases.append((lengths, left, right))
    return cases


def build_io():
    return [([10000], ['a'], ['a']) for _ in range(200)]


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
emit("1_sample", [SAMPLE])
emit("2_edges", build_edges())
emit("3_wide", build_wide())
emit("4_random", build_random())
emit("5_io", build_io())
