#!/usr/bin/env python3
import bisect
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
INF = 1 << 60


def oracle_dp(n, w):
    """Exact recurrence: F(m) = min over a k-way split of sum(t*w_t + F(t))."""
    letter_count = len(w)
    best = [0] * (n + 1)
    for m in range(2, n + 1):
        layer = [INF] * (m + 1)
        layer[0] = 0
        for j in range(letter_count):
            next_layer = [INF] * (m + 1)
            for used in range(m + 1):
                if layer[used] == INF:
                    continue
                for part in range(0, m - used + 1):
                    if part == m:
                        continue
                    cost = layer[used] + part * w[j] + best[part]
                    if cost < next_layer[used + part]:
                        next_layer[used + part] = cost
            layer = next_layer
        best[m] = layer[m]
    return best[n]


def oracle_expand(n, k, w):
    """Independent frontier expansion with a Python sorted list."""
    ordered = sorted(w)
    leaves = sorted(ordered[:min(n, k)])
    total = sum(leaves)
    weight_sum = sum(ordered)
    answer = INF
    for _ in range(2000000):
        if total >= answer:
            break
        if len(leaves) == n:
            if total < answer:
                answer = total
            else:
                break
        lightest = leaves.pop(0)
        total += weight_sum + (k - 1) * lightest
        for weight in ordered:
            bisect.insort(leaves, lightest + weight)
        while len(leaves) > n:
            total -= leaves.pop()
    return answer


def brute(n, k, w, maxlen=6):
    words = []

    def grow(prefix, depth, weight):
        if depth > 0:
            words.append((prefix, weight))
        if depth == maxlen:
            return
        for i in range(k):
            grow(prefix + str(i), depth + 1, weight + w[i])

    grow("", 0, 0)
    words.sort(key=lambda item: item[1])
    chosen = []
    best = [INF]

    def search(start, remaining, cost):
        if cost >= best[0]:
            return
        if remaining == 0:
            best[0] = cost
            return
        for idx in range(start, len(words)):
            word, weight = words[idx]
            if any(word.startswith(p) or p.startswith(word) for p, _ in chosen):
                continue
            chosen.append((word, weight))
            search(idx + 1, remaining - 1, cost + weight)
            chosen.pop()

    search(0, n, 0)
    return best[0]


def oracle(n, k, w):
    if n <= 40:
        return oracle_dp(n, sorted(w))
    return oracle_expand(n, k, w)


def verdict(cases):
    lines = [str(len(cases))]
    for n, k, weights in cases:
        lines.append(f"{n} {k}")
        lines.append(" ".join(str(weight) for weight in weights))
    return "\n".join(lines) + "\n"


def expected(cases, use_expand=False):
    return "\n".join(
        str(oracle_expand(n, k, w) if use_expand else oracle(n, k, w))
        for n, k, w in cases) + "\n"


def write(name, cases, use_expand=False):
    input_text = verdict(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(expected(cases, use_expand))


def trace(n, k, w):
    ordered = sorted(w)
    leaves = sorted(ordered[:min(n, k)])
    total = sum(leaves)
    weight_sum = sum(ordered)
    best = INF
    rows = [(list(leaves), total, "start")]
    while total < best:
        if len(leaves) == n:
            best = total
        lightest = leaves.pop(0)
        total += weight_sum + (k - 1) * lightest
        for weight in ordered:
            bisect.insort(leaves, lightest + weight)
        while len(leaves) > n:
            total -= leaves.pop()
        rows.append((list(leaves), total, "expand " + str(lightest)))
    return rows


SAMPLE = [(3, 2, [2, 5])]
assert trace(3, 2, [2, 5]) == [([2, 5], 7, "start"),
                                ([4, 5, 7], 16, "expand 2"),
                                ([5, 6, 7], 18, "expand 4")]
assert oracle(3, 2, [2, 5]) == 16
assert oracle(2, 26, [1] * 26) == 2
assert oracle(4, 4, [7, 11, 1, 2]) == 12
for n, k, weights in [(2, 2, [2, 5]), (3, 2, [2, 5]), (5, 3, [4, 1, 7]),
                      (4, 4, [7, 11, 1, 2]), (6, 2, [1, 5])]:
    assert oracle(n, k, weights) == brute(n, k, weights)
for n, k, weights in [(16, 3, [2, 5, 2]), (40, 2, [1, 5]),
                      (40, 4, [7, 11, 1, 2]), (25, 26, list(range(26, 0, -1)))]:
    assert oracle_dp(n, sorted(weights)) == oracle_expand(n, k, weights)


def build():
    edges = [
        (2, 2, [1, 1]),
        (2, 26, [1] * 26),
        (2, 26, [10000, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
        (26, 26, list(range(1, 27))),
        (25, 26, list(range(26, 0, -1))),
        (27, 26, list(range(1, 27))),
        (10000, 2, [1, 1]),
        (10000, 26, [1] * 26),
        (10000, 2, [1, 10000]),
        (10000, 26, [10000] * 26),
    ]
    write("2_edges", edges)

    wide = [
        (10000, 2, [1, 1]),
        (10000, 2, [10000, 10000]),
        (10000, 26, [1] * 26),
        (10000, 26, [10000] * 26),
        (9999, 25, list(range(1, 26))),
        (2, 26, [10000] + [1] * 25),
    ]
    write("3_wide", wide)

    random.seed(2026)
    mixed = []
    for _ in range(120):
        k = random.randint(2, 26)
        n = random.randint(2, 10000)
        weights = [random.randint(1, 10000) for _ in range(k)]
        mixed.append((n, k, weights))
    write("4_random", mixed)

    many = []
    for _ in range(20000):
        k = random.randint(2, 26)
        n = random.randint(2, 40)
        weights = [random.randint(1, 10000) for _ in range(k)]
        many.append((n, k, weights))
    write("5_io", many, use_expand=True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
