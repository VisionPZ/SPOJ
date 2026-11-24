#!/usr/bin/env python3
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def ranks(n, parents):
    rank = [0] * (n + 1)
    done = [False] * (n + 1)

    def rec(node):
        if done[node]:
            return rank[node]
        first, _ = parents[node]
        if first == 0:
            rank[node] = 0
        else:
            rank[node] = 1 + max(rec(parents[node][0]), rec(parents[node][1]))
        done[node] = True
        return rank[node]

    for member in range(1, n + 1):
        rec(member)
    return rank


def joint_oracle(n, parents):
    rank = ranks(n, parents)
    marginal = [dict() for _ in range(n + 1)]
    for member in range(1, n + 1):
        first, second = parents[member]
        if first == 0:
            marginal[member][member] = Fraction(1)
        else:
            combined = dict()
            for founder, value in marginal[first].items():
                combined[founder] = combined.get(founder, Fraction(0)) + value / 2
            for founder, value in marginal[second].items():
                combined[founder] = combined.get(founder, Fraction(0)) + value / 2
            marginal[member] = combined

    memo = dict()

    def joint(left, right):
        key = (left, right) if left <= right else (right, left)
        if key in memo:
            return memo[key]
        if left == right:
            result = {(founder, founder): value for founder, value in marginal[left].items()}
        elif parents[left][0] == 0 and parents[right][0] == 0:
            result = {(left, right): Fraction(1)}
        else:
            if rank[left] < rank[right]:
                older, younger = right, left
            else:
                older, younger = left, right
            result = dict()
            for source in parents[older]:
                for pair, value in joint(source, younger).items():
                    result[pair] = result.get(pair, Fraction(0)) + value / 2
        memo[key] = result
        return result

    def relation(left, right):
        if left == right:
            return Fraction(1)
        distribution = joint(left, right)
        return sum(value for (first_founder, second_founder), value in distribution.items()
                   if first_founder == second_founder)

    return relation


def scalar_oracle(n, parents):
    rank = ranks(n, parents)
    memo = dict()

    def relation(left, right):
        key = (left, right) if left <= right else (right, left)
        if key in memo:
            return memo[key]
        if left == right:
            result = Fraction(1)
        elif rank[left] < rank[right]:
            result = relation(right, left)
        else:
            first, second = parents[left]
            result = Fraction(0) if first == 0 else (relation(first, right) + relation(second, right)) / 2
        memo[key] = result
        return result

    return relation


def percentage(value):
    numerator = value.numerator
    denominator = value.denominator
    assert denominator > 0 and denominator & (denominator - 1) == 0
    digits = denominator.bit_length() - 1
    scaled = 100 * numerator * (5 ** digits)
    text = str(scaled).zfill(digits + 1)
    if digits == 0:
        return text + "%"
    whole = text[:-digits]
    fractional = text[-digits:].rstrip("0")
    return whole + ("." + fractional if fractional else "") + "%"


def oracle(cases, use_joint=False):
    lines = []
    for _, members, parents, queries in cases:
        relation = joint_oracle(members, parents) if use_joint else scalar_oracle(members, parents)
        for left, right in queries:
            lines.append(percentage(relation(left, right)))
    return "\n".join(lines) + "\n"


def pack(cases):
    parts = [str(len(cases))]
    for _, members, parents, queries in cases:
        parts.append("%d %d" % (members, sum(1 for entry in parents[1:] if entry[0] != 0)))
        for member in range(1, members + 1):
            first, second = parents[member]
            if first != 0:
                parts.append("%d %d %d" % (member, first, second))
        parts.append(str(len(queries)))
        for left, right in queries:
            parts.append("%d %d" % (left, right))
    return "\n".join(parts) + "\n"


def case(members, triples, queries):
    parents = [(0, 0)] * (members + 1)
    for child, first, second in triples:
        parents[child] = (first, second)
    return (0, members, parents, queries)


def enumerate_pairs(members):
    return [(left, right) for left in range(1, members + 1) for right in range(1, members + 1)]


SAMPLE_TEXT = """1
7 4
4 1 2
5 2 3
6 4 5
7 5 6
4
1 2
2 6
7 5
3 3
"""
SAMPLE_OUTPUT = "0%\n50%\n81.25%\n100%\n"

sample_cases = [case(7, [(4, 1, 2), (5, 2, 3), (6, 4, 5), (7, 5, 6)], [(1, 2), (2, 6), (7, 5), (3, 3)])]
assert pack(sample_cases) == SAMPLE_TEXT
assert oracle(sample_cases, use_joint=True) == SAMPLE_OUTPUT
assert oracle(sample_cases) == SAMPLE_OUTPUT

sibling = case(4, [(3, 1, 2), (4, 1, 2)], [(3, 4), (1, 3), (3, 1), (1, 2), (3, 3)])
assert oracle([sibling], use_joint=True) == "50%\n50%\n50%\n0%\n100%\n"

random.seed(4242)
for trial in range(40):
    small_members = random.randint(2, 8)
    small_triples = []
    for child in range(3, small_members + 1):
        if random.random() < 0.7:
            first, second = random.sample(range(1, child), 2)
            small_triples.append((child, first, second))
    small_case = case(small_members, small_triples, enumerate_pairs(small_members))
    assert oracle([small_case], use_joint=True) == oracle([small_case]), trial


def build_edges():
    only_founders = case(2, [], [(1, 1), (1, 2), (2, 1), (2, 2)])
    one_child = case(3, [(3, 1, 2)], [(1, 2), (3, 3), (3, 1), (1, 3), (2, 3)])
    chain = case(12, [(member, member - 1, 2) for member in range(4, 13)],
                 [(12, 1), (12, 12), (11, 12), (2, 2), (1, 2)])
    shared_parent = case(5, [(3, 1, 2), (4, 1, 3), (5, 3, 4)],
                         [(5, 3), (4, 3), (5, 4), (2, 5), (5, 5)])
    return [only_founders, one_child, chain, shared_parent]


def build_wide():
    chain_triples = [(member, member - 1, max(1, member - 2)) for member in range(3, 301)]
    wide_chain = case(300, chain_triples, enumerate_pairs(300))
    wide_founders = case(300, [], enumerate_pairs(300))
    return [wide_chain, wide_founders]


def build_random():
    random.seed(20261124)
    cases = []
    for _ in range(6):
        members = random.randint(30, 300)
        triples = []
        for child in range(3, members + 1):
            if random.random() < 0.85:
                first, second = random.sample(range(1, child), 2)
                triples.append((child, first, second))
        all_pairs = enumerate_pairs(members)
        queries = random.sample(all_pairs, min(len(all_pairs), random.randint(500, 4000)))
        cases.append(case(members, triples, queries))
    return cases


def build_io():
    random.seed(777001)
    cases = []
    for _ in range(4):
        members = 300
        triples = []
        for child in range(3, members + 1):
            first, second = random.sample(range(1, child), 2)
            triples.append((child, first, second))
        cases.append(case(members, triples, enumerate_pairs(members)))
    return cases


def write(name, cases):
    text = pack(cases)
    (ROOT / "in" / (name + ".txt")).write_text(text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(cases))


def worked_example():
    parents = [(0, 0)] * 8
    parents[4] = (1, 2)
    parents[5] = (2, 3)
    parents[6] = (4, 5)
    parents[7] = (5, 6)
    relation = joint_oracle(7, parents)
    for left, right in [(4, 2), (4, 3), (4, 5), (6, 5), (5, 5), (7, 5)]:
        value = relation(left, right)
        print("R(%d,%d) = %s = %g%%" % (left, right, value, float(value) * 100))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

worked_example()
write("1_sample", sample_cases)
write("2_edges", build_edges())
write("3_wide", build_wide())
write("4_random", build_random())
write("5_io", build_io())
