#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_WEIGHT = (1 << 63) - 1


def find_root(node_count, left, right):
    is_child = [False] * (node_count + 1)
    for child in left[1:] + right[1:]:
        if child != -1:
            is_child[child] = True
    for node in range(1, node_count + 1):
        if not is_child[node]:
            return node
    raise ValueError("tree has no root")


def intervals_of(node_count, left, right, root):
    intervals = {}
    stack = [(root, False)]
    while stack:
        node, expanded = stack.pop()
        if not expanded:
            stack.append((node, True))
            if right[node] != -1:
                stack.append((right[node], False))
            if left[node] != -1:
                stack.append((left[node], False))
        else:
            low = intervals[left[node]][0] if left[node] != -1 else node
            high = intervals[right[node]][1] if right[node] != -1 else node
            intervals[node] = (low, high)
    return intervals


def oracle_case(node_count, left, right):
    root = find_root(node_count, left, right)
    depth = [0] * (node_count + 1)
    stack = [(root, 0)]
    while stack:
        node, level = stack.pop()
        depth[node] = level
        if left[node] != -1:
            stack.append((left[node], level + 1))
        if right[node] != -1:
            stack.append((right[node], level + 1))
    intervals = intervals_of(node_count, left, right, root)
    powers = [1 << level for level in range(node_count + 1)]
    weights = [0] * (node_count + 1)
    for node in range(1, node_count + 1):
        low, high = intervals[node]
        total = sum(powers[depth[label] - depth[node]]
                    for label in range(low, high + 1))
        assert total % 2 == 1
        weights[node] = (total + 1) // 2
        assert weights[node] <= MAX_WEIGHT
    return weights


def unique_optimal(node_count, left, right, weights):
    size = node_count + 2
    cost = [[0] * size for _ in range(size)]
    ties = [[0] * size for _ in range(size)]
    chosen = [[0] * size for _ in range(size)]
    prefix = [0] * (node_count + 1)
    for label in range(1, node_count + 1):
        prefix[label] = prefix[label - 1] + weights[label]
    for length in range(1, node_count + 1):
        for low in range(1, node_count - length + 2):
            high = low + length - 1
            window = prefix[high] - prefix[low - 1]
            best = None
            winners = 0
            for root in range(low, high + 1):
                candidate = window + cost[low][root - 1] + cost[root + 1][high]
                if best is None or candidate < best:
                    best = candidate
                    winners = 1
                    winner = root
                elif candidate == best:
                    winners += 1
            cost[low][high] = best
            ties[low][high] = winners
            chosen[low][high] = winner
    root = find_root(node_count, left, right)
    intervals = intervals_of(node_count, left, right, root)
    for node in range(1, node_count + 1):
        low, high = intervals[node]
        if chosen[low][high] != node or ties[low][high] != 1:
            return False
    return True


def all_shapes(node_count):
    def build(low, high):
        if low > high:
            yield [-1] * (node_count + 1), [-1] * (node_count + 1), -1
            return
        for root in range(low, high + 1):
            for left_left, left_right, left_root in build(low, root - 1):
                for right_left, right_right, right_root in build(root + 1, high):
                    left = [first if first != -1 else second
                            for first, second in zip(left_left, right_left)]
                    right = [first if first != -1 else second
                             for first, second in zip(left_right, right_right)]
                    left[root] = left_root
                    right[root] = right_root
                    yield left, right, root
    for left, right, _ in build(1, node_count):
        yield left, right


def chain_right(node_count):
    left = [-1] * (node_count + 1)
    right = [i + 1 if i < node_count else -1 for i in range(node_count + 1)]
    right[0] = -1
    return left, right


def chain_left(node_count):
    left = [i - 1 if i > 1 else -1 for i in range(node_count + 1)]
    left[0] = -1
    right = [-1] * (node_count + 1)
    return left, right


def balanced(node_count, low=1, high=None):
    if high is None:
        high = node_count
    left = [-1] * (node_count + 1)
    right = [-1] * (node_count + 1)

    def build(lo, hi):
        if lo > hi:
            return -1
        root = (lo + hi) // 2
        left[root] = build(lo, root - 1)
        right[root] = build(root + 1, hi)
        return root

    build(low, high)
    return left, right


def random_tree(node_count, rng):
    left = [-1] * (node_count + 1)
    right = [-1] * (node_count + 1)

    def build(low, high):
        if low > high:
            return -1
        root = rng.randint(low, high)
        left[root] = build(low, root - 1)
        right[root] = build(root + 1, high)
        return root

    build(1, node_count)
    return left, right


def input_text(cases):
    parts = []
    for node_count, left, right in cases:
        parts.append(str(node_count) + "\n")
        for node in range(1, node_count + 1):
            parts.append(f"{left[node]} {right[node]}\n")
    parts.append("0\n")
    return "".join(parts)


def oracle(cases):
    lines = []
    for node_count, left, right in cases:
        weights = oracle_case(node_count, left, right)
        lines.append(" ".join(str(weight) for weight in weights[1:]) + "\n")
    return "".join(lines)


def write(name, cases):
    text = input_text(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(cases))
    return len(text)


SAMPLE_TEXT = (
    "3\n-1 -1\n1 3\n-1 -1\n"
    "10\n-1 2\n-1 3\n-1 4\n-1 5\n-1 6\n"
    "-1 7\n-1 8\n-1 9\n-1 10\n-1 -1\n0\n"
)
SAMPLE_OUTPUT = (
    "1 3 1\n"
    "512 256 128 64 32 16 8 4 2 1\n"
)


def parse(text):
    tokens = text.split()
    cursor = 0
    cases = []
    while True:
        node_count = int(tokens[cursor])
        cursor += 1
        if node_count == 0:
            break
        left = [-1] * (node_count + 1)
        right = [-1] * (node_count + 1)
        for node in range(1, node_count + 1):
            left[node] = int(tokens[cursor])
            right[node] = int(tokens[cursor + 1])
            cursor += 2
        cases.append((node_count, left, right))
    return cases


SAMPLE_CASES = parse(SAMPLE_TEXT)
assert oracle(SAMPLE_CASES) == SAMPLE_OUTPUT
assert oracle_case(10, *chain_right(10))[1:] == [512, 256, 128, 64, 32, 16, 8, 4, 2, 1]
assert oracle_case(50, *chain_right(50))[1] == 1 << 49 <= MAX_WEIGHT
for size in range(1, 7):
    for left, right in all_shapes(size):
        weights = oracle_case(size, left, right)
        assert unique_optimal(size, left, right, weights)


def trace(node_count, left, right, label):
    weights = oracle_case(node_count, left, right)
    root = find_root(node_count, left, right)
    order = []
    stack = [(root, False)]
    while stack:
        node, expanded = stack.pop()
        if not expanded:
            stack.append((node, True))
            if right[node] != -1:
                stack.append((right[node], False))
            if left[node] != -1:
                stack.append((left[node], False))
        else:
            order.append(node)
    lines = [f"{label}: root {root}"]
    for node in order:
        left_total = 2 * weights[left[node]] - 1 if left[node] != -1 else 0
        right_total = 2 * weights[right[node]] - 1 if right[node] != -1 else 0
        lines.append(f"  node {node}: totals {left_total} {right_total} -> weight {weights[node]}")
    lines.append("  output: " + " ".join(str(weight) for weight in weights[1:]))
    return "\n".join(lines)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write("1_sample", SAMPLE_CASES)

edges = [
    (1, *chain_right(1)),
    (2, *chain_right(2)),
    (2, *chain_left(2)),
    (3, *balanced(3)),
    (3, *chain_right(3)),
    (50, *chain_right(50)),
    (50, *chain_left(50)),
    (50, *balanced(50)),
]
write("2_edges", edges)

write("3_wide", [
    (50, *chain_right(50)),
    (50, *chain_left(50)),
    (50, *balanced(50)),
])

rng = random.Random(20261125)
random_cases = [(50, *random_tree(50, rng)) for _ in range(40)]
write("4_random", random_cases)

io_cases = [(50, *chain_right(50)) for _ in range(6000)]
io_bytes = write("5_io", io_cases)

print(trace(3, *balanced(3), "tree 1"))
print(trace(10, *chain_right(10), "tree 2"))
print("generated", len(random_cases), "random trees,", io_bytes, "input bytes")
