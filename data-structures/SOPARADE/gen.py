#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    cases = []
    for _ in range(count):
        size = int(tokens[cursor])
        rule_count = int(tokens[cursor + 1])
        cursor += 2
        rules = []
        for _ in range(rule_count):
            bound = int(tokens[cursor])
            cursor += 1
            rule = [int(tokens[cursor + offset]) for offset in range(bound)]
            cursor += bound
            rules.append(rule)
        cases.append((size, rules))
    return cases


def brute(size, rules):
    if size == 0:
        return not rules
    for ranks in itertools.product((1, 2, 3, 4), repeat=size):
        if any(abs(ranks[i] - ranks[i + 1]) < 2 for i in range(size - 1)):
            continue
        if all(len({ranks[p - 1] for p in rule}) == len(rule) for rule in rules):
            return True
    return False


def solver(size, rules):
    nodes = 2 * size
    if nodes == 0:
        return True
    edges = [[] for _ in range(nodes)]

    def add(source, target):
        edges[source].append(target)

    def clause(left_var, left_val, right_var, right_val):
        left = 2 * left_var + left_val
        right = 2 * right_var + right_val
        add(left ^ 1, right)
        add(right ^ 1, left)

    for position in range(size - 1):
        if (position + 1) % 2 == 1:
            clause(position, 1, position + 1, 0)
        else:
            clause(position + 1, 1, position, 0)
    for rule in rules:
        odd = [p - 1 for p in rule if p % 2 == 1]
        even = [p - 1 for p in rule if p % 2 == 0]
        if len(rule) > 4 or len(odd) > 2 or len(even) > 2:
            return False
        for group in (odd, even):
            if len(group) == 2:
                first, second = group
                clause(first, 1, second, 1)
                clause(first, 0, second, 0)

    index = [-1] * nodes
    low = [0] * nodes
    comp = [-1] * nodes
    on_stack = [False] * nodes
    stack = []
    calls = []
    idx_counter = 0
    comp_counter = 0
    for root in range(nodes):
        if index[root] != -1:
            continue
        index[root] = low[root] = idx_counter
        idx_counter += 1
        stack.append(root)
        on_stack[root] = True
        calls.append([root, 0])
        while calls:
            node, edge_at = calls[-1]
            if edge_at < len(edges[node]):
                calls[-1][1] = edge_at + 1
                nxt = edges[node][edge_at]
                if index[nxt] == -1:
                    index[nxt] = low[nxt] = idx_counter
                    idx_counter += 1
                    stack.append(nxt)
                    on_stack[nxt] = True
                    calls.append([nxt, 0])
                elif on_stack[nxt] and index[nxt] < low[node]:
                    low[node] = index[nxt]
            else:
                calls.pop()
                if low[node] == index[node]:
                    while True:
                        member = stack.pop()
                        on_stack[member] = False
                        comp[member] = comp_counter
                        if member == node:
                            break
                    comp_counter += 1
                if calls:
                    parent = calls[-1][0]
                    if low[node] < low[parent]:
                        low[parent] = low[node]
    for var in range(size):
        if comp[2 * var] == comp[2 * var + 1]:
            return False
    return True


def oracle(text):
    answers = []
    for size, rules in parse(text):
        if size <= 8:
            expected = brute(size, rules)
            assert expected == solver(size, rules), (size, rules)
        else:
            expected = solver(size, rules)
        answers.append("approved" if expected else "rejected")
    return "\n".join(answers) + "\n"


def render(cases):
    blocks = []
    for size, rules in cases:
        lines = [f"{size} {len(rules)}"]
        for rule in rules:
            lines.append(" ".join([str(len(rule))] + [str(p) for p in rule]))
        blocks.append("\n".join(lines))
    return str(len(cases)) + "\n\n" + "\n\n".join(blocks) + "\n"


def write_cases(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "2\n\n2 1\n2 1 2\n\n5 2\n3 1 3 2\n4 2 3 4 5\n"

assert oracle(SAMPLE) == "approved\nrejected\n"
assert solver(2, [[1, 2]]) is True
assert solver(5, [[1, 3, 2], [2, 3, 4, 5]]) is False
assert brute(9, [[1, 3, 5, 7, 9]]) is False
assert solver(9, [[1, 3, 5, 7, 9]]) is False

probe = random.Random(20261124)
for _ in range(1500):
    probe_size = probe.randint(1, 6)
    probe_rules = [
        [probe.randint(1, probe_size) for _ in range(probe.randint(2, 4))]
        for _ in range(probe.randint(0, 4))
    ]
    assert brute(probe_size, probe_rules) == solver(probe_size, probe_rules)


def built_value(position):
    return (1, 0, 0, 0, 1, 1)[(position - 1) % 6]


def write_io():
    size = 100000
    odd_zero = [p for p in range(1, size + 1, 2) if built_value(p) == 0]
    odd_one = [p for p in range(1, size + 1, 2) if built_value(p) == 1]
    even_zero = [p for p in range(2, size + 1, 2) if built_value(p) == 0]
    even_one = [p for p in range(2, size + 1, 2) if built_value(p) == 1]
    rng = random.Random(9000)
    lines = ["10"]
    for _ in range(10):
        lines.append(f"{size} 100000")
        for _ in range(100000):
            rule = [
                rng.choice(odd_zero), rng.choice(odd_one),
                rng.choice(even_zero), rng.choice(even_one),
            ]
            rng.shuffle(rule)
            lines.append(" ".join(["4"] + [str(p) for p in rule]))
    (ROOT / "in" / "5_io.txt").write_text("\n".join(lines) + "\n")
    (ROOT / "out" / "5_io.out").write_text("approved\n" * 10)


for position in range(1, 12):
    odd_position, even_position = (
        (position, position + 1) if position % 2 == 1 else (position + 1, position)
    )
    assert not (built_value(odd_position) == 0 and built_value(even_position) == 1)
assert brute(6, [[1, 3, 2, 6]]) is True
assert solver(6, [[1, 3, 2, 6]]) is True


def worked_example():
    size = 5
    rules = [[1, 3, 2], [2, 3, 4, 5]]
    valid = 0
    for values in itertools.product((0, 1), repeat=size):
        good = True
        for position in range(1, size):
            odd, even = (
                (position, position + 1) if position % 2 == 1
                else (position + 1, position)
            )
            if values[odd - 1] == 0 and values[even - 1] == 1:
                good = False
        for rule in rules:
            odd = [p for p in rule if p % 2 == 1]
            even = [p for p in rule if p % 2 == 0]
            for group in (odd, even):
                if len(group) == 2 and values[group[0] - 1] == values[group[1] - 1]:
                    good = False
        if good:
            valid += 1
    return valid


assert worked_example() == 0


def build():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
    (ROOT / "out" / "1_sample.out").write_text(oracle(SAMPLE))

    write_cases("2_edges", [
        (1, []),
        (2, []),
        (4, [[1, 3]]),
        (5, [[1, 2, 3, 4, 5]]),
        (5, [[1, 3, 5]]),
        (3, [[1, 1]]),
        (8, [[1, 4, 5], [2, 6], [3, 7, 8]]),
    ])

    wide_rng = random.Random(31415)
    wide_rules = [
        [wide_rng.randint(1, 100000) for _ in range(wide_rng.randint(2, 4))]
        for _ in range(20000)
    ]
    write_cases("3_wide", [
        (100000, []),
        (100000, [[1, 2, 3, 4, 5]]),
        (100000, wide_rules),
    ])

    random_rng = random.Random(424242)
    random_cases = []
    for case in range(10):
        size = random_rng.randint(3, 1000)
        rule_count = random_rng.randint(0, 15)
        rules = []
        for _ in range(rule_count):
            bound = random_rng.randint(2, 4)
            if case % 2 == 0:
                rules.append([random_rng.randint(1, size) for _ in range(bound)])
            else:
                odds = list(range(1, size + 1, 2))
                evens = list(range(2, size + 1, 2))
                odd_pick = random_rng.sample(odds, min(bound, 2, len(odds)))
                even_pick = random_rng.sample(evens, min(bound - len(odd_pick), 2, len(evens)))
                rule = odd_pick + even_pick
                if len(rule) < bound:
                    rule += [rule[0]] * (bound - len(rule))
                rules.append(rule)
        random_cases.append((size, rules))
    write_cases("4_random", random_cases)

    write_io()


build()
