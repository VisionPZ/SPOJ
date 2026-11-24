#!/usr/bin/env python3
import random
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 10**9

SAMPLE_INPUT = """1
3 10 2 3
2 3 1
2 1 1 2 2 1 2 1 2 1
3 1 2
3 3 3
3 1 3 2
"""
SAMPLE_TARGET = (2, 1, 1, 2, 2, 1, 2, 1, 2, 1)
SAMPLE_RULES = ((3, 1, 2), (3, 3, 3), (3, 1, 3, 2))


def dp_oracle(source, target, rules):
    target_length = len(target)
    by_left = {}
    for rule in rules:
        by_left.setdefault(rule[0], []).append(rule[1:])
    pair_ids = {}
    for productions in by_left.values():
        for produced in productions:
            pair = (produced[0], produced[1])
            if pair not in pair_ids:
                pair_ids[pair] = len(pair_ids)
    area = target_length * target_length
    derive = {}
    relevant = set(source) | set(target) | set(by_left)
    for productions in by_left.values():
        for produced in productions:
            relevant.update(produced)
    for value in relevant:
        derive[value] = [INF] * area
    pair_cost = [[INF] * area for _ in pair_ids]

    for span_length in range(1, target_length + 1):
        for low in range(target_length - span_length + 1):
            high = low + span_length - 1
            span = low * target_length + high
            if span_length == 1:
                for value in derive:
                    derive[value][span] = 0 if target[low] == value else INF
                continue
            for pair, pair_id in pair_ids.items():
                best = INF
                first, second = pair
                for split in range(low, high):
                    cost = (derive[first][low * target_length + split]
                            + derive[second][(split + 1) * target_length + high])
                    if cost < best:
                        best = cost
                pair_cost[pair_id][span] = best
            for left, productions in by_left.items():
                best = INF
                for produced in productions:
                    pair_id = pair_ids[(produced[0], produced[1])]
                    if len(produced) == 2:
                        cost = pair_cost[pair_id][span] + 1
                        if cost < best:
                            best = cost
                    else:
                        tail = derive.get(produced[2])
                        if tail is None:
                            continue
                        for split in range(low + 1, high):
                            cost = (pair_cost[pair_id][low * target_length + split]
                                    + tail[(split + 1) * target_length + high] + 1)
                            if cost < best:
                                best = cost
                derive[left][span] = best

    previous = [INF] * (target_length + 1)
    previous[0] = 0
    for symbol in source:
        current = [INF] * (target_length + 1)
        costs = derive.get(symbol)
        for matched in range(1, target_length + 1):
            best = INF
            for split in range(matched):
                head = previous[split]
                if head >= INF or costs is None:
                    continue
                cost = head + costs[split * target_length + matched - 1]
                if cost < best:
                    best = cost
            current[matched] = best
        previous = current
    return -1 if previous[target_length] >= INF else previous[target_length]


@lru_cache(maxsize=None)
def top_down_derive(target, by_left, symbol, low, high):
    if low == high:
        return 0 if target[low] == symbol else INF
    best = INF
    for produced in dict(by_left).get(symbol, ()):
        if len(produced) == 2:
            for split in range(low, high):
                cost = (top_down_derive(target, by_left, produced[0], low, split)
                        + top_down_derive(target, by_left, produced[1], split + 1, high) + 1)
                if cost < best:
                    best = cost
        else:
            for first_end in range(low, high - 1):
                for second_end in range(first_end + 1, high):
                    cost = (top_down_derive(target, by_left, produced[0], low, first_end)
                            + top_down_derive(target, by_left, produced[1], first_end + 1, second_end)
                            + top_down_derive(target, by_left, produced[2], second_end + 1, high) + 1)
                    if cost < best:
                        best = cost
    return best


def top_down_oracle(source, target, rules):
    by_left = {}
    for rule in rules:
        by_left.setdefault(rule[0], []).append(rule[1:])
    frozen = tuple((key, tuple(value)) for key, value in by_left.items())
    target = tuple(target)

    @lru_cache(maxsize=None)
    def match(source_index, matched):
        if source_index == 0:
            return 0 if matched == 0 else INF
        best = INF
        symbol = source[source_index - 1]
        for split in range(matched):
            cost = match(source_index - 1, split) + top_down_derive(
                target, frozen, symbol, split, matched - 1)
            if cost < best:
                best = cost
        return best

    result = match(len(source), len(target))
    top_down_derive.cache_clear()
    return -1 if result >= INF else result


def bfs_oracle(source, target, rules, step_limit):
    start = tuple(source)
    goal = tuple(target)
    if start == goal:
        return 0
    length_limit = len(goal)
    frontier = {start}
    for steps in range(1, step_limit + 1):
        next_frontier = set()
        for state in frontier:
            for position, value in enumerate(state):
                for rule in rules:
                    if rule[0] != value:
                        continue
                    produced = rule[1:]
                    if len(state) + len(produced) - 2 > length_limit:
                        continue
                    candidate = state[:position] + produced + state[position + 1:]
                    if candidate == goal:
                        return steps
                    next_frontier.add(candidate)
        frontier = next_frontier
    return -1


def oracle_text(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        source_length = int(tokens[cursor])
        target_length = int(tokens[cursor + 1])
        two_count = int(tokens[cursor + 2])
        rule_count = int(tokens[cursor + 3])
        cursor += 4
        source = [int(tokens[cursor + offset]) for offset in range(source_length)]
        cursor += source_length
        target = [int(tokens[cursor + offset]) for offset in range(target_length)]
        cursor += target_length
        rules = []
        for rule_index in range(rule_count):
            width = 3 if rule_index < two_count else 4
            rules.append(tuple(int(tokens[cursor + offset]) for offset in range(width)))
            cursor += width
        answers.append(str(dp_oracle(source, target, rules)))
    return "\n".join(answers) + "\n"


def encode_case(source, target, rules):
    two_count = sum(1 for rule in rules if len(rule) == 3)
    lines = [f"{len(source)} {len(target)} {two_count} {len(rules)}"]
    lines.append(" ".join(str(value) for value in source))
    lines.append(" ".join(str(value) for value in target))
    for rule in rules:
        lines.append(" ".join(str(value) for value in rule))
    return "\n".join(lines)


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        encode_case(*case) + "\n" for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_text(input_text))


def make_rules(rng, count, three_only=False):
    rules = []
    for _ in range(count):
        left = rng.randint(1, 30)
        width = 4 if three_only or rng.random() < 0.5 else 3
        rules.append((left,) + tuple(rng.randint(1, 30) for _ in range(width - 1)))
    return rules


def grow(rng, source, rules, target_length):
    sequence = list(source)
    while len(sequence) < target_length:
        choices = []
        for position, value in enumerate(sequence):
            for rule in rules:
                if rule[0] == value and len(sequence) + len(rule) - 2 <= target_length:
                    choices.append((position, rule))
        if not choices:
            return None
        position, rule = rng.choice(choices)
        sequence = sequence[:position] + list(rule[1:]) + sequence[position + 1:]
    return sequence


assert oracle_text(SAMPLE_INPUT) == "6\n"
assert top_down_oracle([2, 3, 1], list(SAMPLE_TARGET), list(SAMPLE_RULES)) == 6
assert bfs_oracle([1], [2, 3], [(1, 2, 3)], 2) == 1
assert bfs_oracle([1], [4, 5, 6], [(1, 4, 5, 6)], 2) == 1
assert bfs_oracle([1], [4, 5, 3], [(1, 2, 3), (2, 4, 5)], 3) == 2
assert dp_oracle([1], [4, 5, 3], [(1, 2, 3), (2, 4, 5)]) == 2
assert bfs_oracle([1], [7], [], 3) == -1
assert dp_oracle([1], [7], []) == -1

check_rng = random.Random(9001)
for _ in range(80):
    check_rules = make_rules(check_rng, check_rng.randint(1, 4))
    check_source = [check_rng.randint(1, 4) for _ in range(check_rng.randint(1, 2))]
    check_target = [check_rng.randint(1, 4) for _ in range(check_rng.randint(1, 4))]
    expected = bfs_oracle(check_source, check_target, check_rules, 3)
    assert dp_oracle(check_source, check_target, check_rules) == expected
    assert top_down_oracle(check_source, check_target, check_rules) == expected

for _ in range(20):
    check_rules = make_rules(check_rng, 6)
    check_source = [check_rng.randint(1, 8) for _ in range(check_rng.randint(1, 3))]
    check_target = [check_rng.randint(1, 8) for _ in range(check_rng.randint(1, 8))]
    assert dp_oracle(check_source, check_target, check_rules) == top_down_oracle(
        check_source, check_target, check_rules)


def build():
    chain_rules = [(1, 2, 2), (2, 3, 3), (3, 3, 3)]
    chain_target = grow(random.Random(7), [1], chain_rules, 50)
    assert chain_target is not None and len(chain_target) == 50
    write("2_edges", [
        ([5], [5], []),
        ([1], [2], []),
        ([1], [4, 5, 6], [(1, 4, 5, 6)]),
        ([7], [8, 9], []),
        ([1], [2, 3], [(1, 2, 3)]),
        ([1, 2], [1, 2], []),
        ([1], chain_target, chain_rules),
    ])

    doubling_rules = [(value, value, value) for value in range(1, 31)]
    write("3_wide", [
        (list(range(1, 51)), list(range(1, 51)), make_rules(random.Random(11), 30)),
        ([1], [1] * 50, doubling_rules),
    ])

    rng = random.Random(20261124)
    random_cases = []
    for _ in range(30):
        rules = make_rules(rng, rng.randint(0, 30))
        source = [rng.randint(1, 30) for _ in range(rng.randint(1, 50))]
        target_length = rng.randint(1, 50)
        target = grow(rng, source, rules, target_length)
        if target is None:
            target = [rng.randint(1, 30) for _ in range(target_length)]
        random_cases.append((source, target, rules))
    write("4_random", random_cases)

    io_cases = []
    for _ in range(30):
        for _attempt in range(200):
            rules = make_rules(rng, 30, three_only=True)
            source = [rng.randint(1, 30) for _ in range(24)]
            target = grow(rng, source, rules, 50)
            if target is not None:
                break
        assert target is not None and len(target) == 50
        io_cases.append((source, target, rules))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [([2, 3, 1], list(SAMPLE_TARGET), list(SAMPLE_RULES))])
build()
by_left = {3: [(1, 2), (3, 3), (1, 3, 2)]}
example_cost = top_down_derive(SAMPLE_TARGET, tuple(
    (key, tuple(value)) for key, value in by_left.items()), 3, 1, 8)
print(f"derive_cost(3, 1, 8) = {example_cost}")
