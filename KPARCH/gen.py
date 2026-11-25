#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def suffix_array(source):
    length = len(source)
    if length == 0:
        return []
    order = list(range(length))
    rank = [ord(char) for char in source]
    span = 1
    while True:
        order.sort(key=lambda index: (rank[index],
                                      rank[index + span] if index + span < length else -1))
        next_rank = [0] * length
        next_rank[order[0]] = 0
        for position in range(1, length):
            previous = order[position - 1]
            current = order[position]
            previous_key = (rank[previous], rank[previous + span] if previous + span < length else -1)
            current_key = (rank[current], rank[current + span] if current + span < length else -1)
            next_rank[current] = next_rank[previous] + (previous_key != current_key)
        rank = next_rank
        if rank[order[-1]] == length - 1:
            break
        span *= 2
    return order, rank


def sparse_lcp(source, order, rank):
    length = len(source)
    lcp = [0] * (length - 1)
    shared = 0
    for index in range(length):
        if rank[index] == 0:
            continue
        other = order[rank[index] - 1]
        while index + shared < length and other + shared < length and source[index + shared] == source[other + shared]:
            shared += 1
        lcp[rank[index] - 1] = shared
        if shared > 0:
            shared -= 1
    levels = [lcp]
    for level in range(1, max(1, math.floor(math.log2(length)) + 1)):
        previous = levels[-1]
        half = 1 << (level - 1)
        levels.append([min(previous[index], previous[index + half])
                       if index + half < len(previous) else previous[index]
                       for index in range(len(previous))])
    return levels


def oracle(text):
    source = ''.join(char for char in text if char.isalpha())
    length = len(source)
    if length < 2:
        return '0\n'
    order, rank = suffix_array(source)
    levels = sparse_lcp(source, order, rank)

    def longest_common_prefix(first, second):
        low, high = rank[first], rank[second]
        if low > high:
            low, high = high, low
        start = low
        span = high - low
        level = span.bit_length() - 1
        return min(levels[level][start], levels[level][start + span - (1 << level)])

    total = 0
    for start in range(length):
        half = 1
        while start + 2 * half <= length:
            if longest_common_prefix(start, start + half) >= half:
                total += 1
            half += 1
    return str(total) + '\n'


SAMPLE = """abcdefg
"""
SAMPLE_OUT = """0
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("blabla\n") == "1\n"
assert oracle("aCacaacaa\n") == "4\n"
assert oracle("acababaee\n") == "3\n"
assert oracle("aaaa\n") == "4\n"
assert oracle("aaa\n") == "2\n"
assert oracle("\n") == "0\n"


def write(name, text):
    (ROOT / 'in' / (name + '.txt')).write_text(text)
    (ROOT / 'out' / (name + '.out')).write_text(oracle(text))


def build():
    write('2_edges', 'aCacaacaa\n')
    write('3_wide', 'a' * 1200 + '\n')
    rng = random.Random(20261126)
    alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    write('4_random', ''.join(rng.choice(alphabet) for _ in range(1000)) + '\n')
    write('5_io', 'ab' * 600 + '\n')
    Path('/tmp/KPARCH_big.txt').write_text('a' * 200000 + '\n')


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE)
build()
