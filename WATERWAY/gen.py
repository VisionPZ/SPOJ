#!/usr/bin/env python3
import random
from itertools import product
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def brute_answer(text):
    n = len(text)
    forward = {}
    backward = {}
    for u in range(n):
        fset = set()
        x = u
        for _ in range(n):
            arc = x
            if text[arc] == 'A':
                break
            x = (x + 1) % n
            if x == u:
                break
            fset.add(x)
        bset = set()
        x = u
        for _ in range(n):
            arc = (x - 1) % n
            if text[arc] == 'C':
                break
            x = (x - 1) % n
            if x == u:
                break
            bset.add(x)
        forward[u] = fset
        backward[u] = bset
    only_clock = [(u, v) for u in range(n) for v in forward[u] if v not in backward[u]]
    only_anticlock = [(u, v) for u in range(n) for v in backward[u] if v not in forward[u]]
    shared = [(u, v) for u in range(n) for v in forward[u] if v in backward[u]]

    def peak(clock, anticlock):
        size = 2 * n + 2
        dc = [0] * size
        da = [0] * size
        for u, v in clock:
            dist = (v - u) % n
            dc[u] += 1
            dc[u + dist] -= 1
        for u, v in anticlock:
            low = v + n if v < u else v
            high = (u - 1) + n
            da[low] += 1
            da[high + 1] -= 1
        cc = [0] * n
        ca = [0] * n
        run_c = 0
        run_a = 0
        for k in range(2 * n):
            run_c += dc[k]
            run_a += da[k]
            if k < n:
                cc[k] = run_c
                ca[k] = run_a
            else:
                cc[k - n] += run_c
                ca[k - n] += run_a
        return max(cc), max(ca)

    best = None
    for mask in range(1 << len(shared)):
        clock = list(only_clock)
        anticlock = list(only_anticlock)
        for k, pair in enumerate(shared):
            if mask >> k & 1:
                clock.append(pair)
            else:
                anticlock.append(pair)
        high_clock, high_anticlock = peak(clock, anticlock)
        total = high_clock + high_anticlock
        if best is None or total < best:
            best = total
    return best


def both_pair_count(text):
    n = len(text)
    limit = n
    to_a = [limit] * n
    to_c = [limit] * n
    for k in range(2 * n - 1, -1, -1):
        place = k % n
        if text[place] == 'A':
            to_a[place] = 0
        else:
            step = to_a[(k + 1) % n] + 1
            to_a[place] = min(limit, step)
    for k in range(2 * n):
        place = k % n
        if text[(k - 1) % n] == 'C':
            to_c[place] = 1
        else:
            step = to_c[(k - 1) % n] + 1
            to_c[place] = min(limit, step)
    total = 0
    for u in range(n):
        far = min(u + to_a[u], u + n - 1)
        near = u - to_c[u] + 1 + n
        low = max(u + 1, near)
        if far >= low:
            total += far - low + 1
    return total


def longest_run(text, allowed):
    n = len(text)
    best = 0
    run = 0
    for k in range(2 * n):
        if text[k % n] in allowed:
            run += 1
            best = max(best, run)
        else:
            run = 0
    return min(best, n)


def one_sided_answer(text):
    n = len(text)
    full = n * (n - 1) // 2
    runs = []
    current = 0
    for ch in text:
        if ch == 'B':
            current += 1
        elif current > 0:
            runs.append(current)
            current = 0
    if current > 0:
        if runs and text[0] == 'B' and text[-1] == 'B':
            runs[0] += current
        else:
            runs.append(current)
    if not runs:
        return full
    pair_total = sum(length * (length + 1) // 2 for length in runs)
    capacities = [(length + 1) ** 2 // 4 for length in runs]
    best = 0
    for idx, length in enumerate(runs):
        outside = max(capacities[:idx] + capacities[idx + 1:], default=-1)
        for take in range(1, length + 1):
            base = take * (length - take + 1)
            if outside >= 0:
                best = max(best, base + outside)
            best = max(best, take * take // 4 + base)
            if take < length:
                vertex = (length + 1 + take) // 2
                for value_at in (max(take + 1, min(length, vertex)),
                                 max(take + 1, min(length, vertex + 1))):
                    best = max(best, value_at * (length + 1 + take - value_at) - take * take)
    return full - pair_total + best


def oracle(text):
    n = len(text)
    count_a = text.count('A')
    count_c = text.count('C')
    full = n * (n - 1) // 2
    if count_a == 0 and count_c == 0:
        return min(t * (t + 1) // 2 + (n - t - 1) * (n - t) // 2 for t in range(n))
    if count_a == 0 or count_c == 0:
        return one_sided_answer(text)
    cap_clock = (longest_run(text, set('BC')) + 1) ** 2 // 4
    cap_anticlock = (longest_run(text, set('AB')) + 1) ** 2 // 4
    return cap_clock + cap_anticlock - both_pair_count(text)


SAMPLE_INPUT = "2\n3\nAAA\n4\nBACB\n"
SAMPLE_OUTPUT = "3\n5\n"

assert oracle("AAA") == 3
assert oracle("BACB") == 5
assert oracle("ABC") == 2
assert oracle("BBB") == 2
assert oracle("ACAC") == 2
for n in range(3, 6):
    for chars in product('ABC', repeat=n):
        text = ''.join(chars)
        assert oracle(text) == brute_answer(text), text


def write_case(name, cases):
    input_text = str(len(cases)) + "\n"
    for n, text in cases:
        input_text += str(n) + "\n" + text + "\n"
    output_text = "".join(str(oracle(text)) + "\n" for n, text in cases)
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(output_text)


def build():
    edges = [
        (3, "AAA"), (3, "CCC"), (3, "BBB"), (3, "ABC"), (3, "BAC"),
        (3, "AAB"), (3, "BBC"), (4, "ACAC"), (4, "BACB"), (4, "ABCA"),
        (5, "AACCC"), (5, "CCCAA"), (5, "BABAB"), (5, "AABBC"),
    ]
    write_case("2_edges", edges)

    big = 100000
    wide = [
        (big, "A" * big),
        (big, "C" * big),
        (big, "B" * big),
        (big, "A" * (big // 2) + "C" * (big // 2)),
        (big, "AC" * (big // 2)),
        (big, "B" + "A" * (big - 1)),
        (big, "B" + "C" * (big - 1)),
        (big, "A" + "B" * (big - 1)),
        (big, "C" + "B" * (big - 1)),
        (big, ("ABC" * ((big + 2) // 3))[:big]),
    ]
    write_case("3_wide", wide)

    rng = random.Random(2026)
    random_cases = []
    for _ in range(40):
        n = rng.randint(3, 20000)
        text = ''.join(rng.choice('ABC') for _ in range(n))
        random_cases.append((n, text))
    write_case("4_random", random_cases)

    io_cases = []
    for _ in range(100):
        n = 100000
        text = ''.join(rng.choice('ABC') for _ in range(n))
        io_cases.append((n, text))
    write_case("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_INPUT)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUTPUT)
build()
