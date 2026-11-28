#!/usr/bin/env python3
import random
from collections import Counter
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_SMALL = 100000


def normalize(blocks, limit):
    ordered = sorted(blocks)
    result = []
    position = 0
    for start, end, count in ordered:
        if start >= limit:
            break
        end = min(end, limit)
        if start > position:
            result.append((position, start, 0))
        if result and result[-1][1] == start and result[-1][2] == count:
            result[-1] = (result[-1][0], end, count)
        else:
            result.append((start, end, count))
        position = end
    if position < limit:
        result.append((position, limit, 0))
    return result


def histogram_blocks(first_side, second_side):
    if first_side == 0 or second_side == 0:
        return []
    larger = max(first_side, second_side)
    smaller = min(first_side, second_side)
    power = 1 << (larger.bit_length() - 1)
    extent = 1 << larger.bit_length()
    if larger == power:
        return [(0, power, smaller), (power, extent, 0)]
    remainder = larger - power
    if smaller > power:
        small_remainder = smaller - power
        child = normalize(histogram_blocks(remainder, small_remainder), power)
        lower = [(start, end, count + power) for start, end, count in child]
        upper = [(power, extent, remainder + small_remainder)]
        return lower + upper
    child = normalize(histogram_blocks(remainder, smaller), power)
    lower = [(0, power, smaller)]
    upper = [(start + power, end + power, count) for start, end, count in child]
    return lower + upper


def brute_answer(first_side, second_side, facts):
    counts = Counter()
    for row in range(first_side):
        for column in range(second_side):
            counts[row ^ column] += 1
    multiplicity = Counter()
    extent = 1 << max(first_side, second_side).bit_length()
    for value in range(extent):
        multiplicity[counts[value]] += 1
    answer = 1
    for count, amount in multiplicity.items():
        answer = answer * pow(facts[count], amount, MODULUS) % MODULUS
    return answer


def build_facts(prime):
    global MODULUS
    MODULUS = prime
    facts = [1] * (MAX_SMALL + 1)
    for value in range(1, MAX_SMALL + 1):
        facts[value] = facts[value - 1] * value % prime
    return facts


FACTS = build_facts(1000000007)
MODULUS = 1000000007


@lru_cache(maxsize=None)
def answer_for(rows, columns):
    answer = 1
    for start, end, count in histogram_blocks(rows, columns):
        answer = answer * pow(FACTS[count], end - start, MODULUS) % MODULUS
    return answer


def oracle(text):
    tokens = [int(value) for value in text.split()]
    case_count = tokens[0]
    build_facts(tokens[1])
    lines = []
    position = 2
    for _ in range(case_count):
        rows = tokens[position]
        columns = tokens[position + 1]
        position += 2
        lines.append(str(answer_for(rows, columns)))
    return "\n".join(lines) + "\n"


SAMPLE = """2 1000000007
2 2
997 799
"""
SAMPLE_OUT = """4
828630475
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1 1000000007\n1 1\n") == "1\n"
assert oracle("1 1000000007\n3 4\n") == str(brute_answer(3, 4, FACTS)) + "\n"
assert oracle("1 1000000007\n5 6\n") == str(brute_answer(5, 6, FACTS)) + "\n"
assert oracle("1 1000000007\n6 7\n") == str(brute_answer(6, 7, FACTS)) + "\n"
for first_side in range(1, 15):
    for second_side in range(1, 15):
        assert answer_for(first_side, second_side) == brute_answer(first_side, second_side, FACTS)


def write(name, cases, prime=1000000007):
    text = f"{len(cases)} {prime}\n" + "".join(f"{rows} {columns}\n" for rows, columns in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [(1, 1), (1, 100000), (100000, 1), (3, 5), (5, 3), (2, 3), (3, 2), (7, 6)])
    write("3_wide", [(1000000000, 100000), (999999937, 99999), (123456789, 65536), (100000, 100000)])
    rng = random.Random(20261126)
    write("4_random", [(rng.randint(1, 1000000000), rng.randint(1, 100000)) for _ in range(100)])
    write("5_io", [(rng.randint(1, 1000000000), rng.randint(1, 100000)) for _ in range(10000)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [(2, 2), (997, 799)])
build()
