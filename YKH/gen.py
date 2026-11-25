#!/usr/bin/env python3
import math
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def exact_group_revenue(clients):
    amount_sum = sum(client[0] for client in clients)
    rate_sum = sum(client[1] for client in clients)
    return Fraction(amount_sum * amount_sum, 4 * rate_sum)


def exact_brute(bribe, clients):
    ordered = sorted(clients, key=lambda pair: Fraction(pair[0], pair[1]))
    count = len(ordered)
    best = Fraction(0)
    for served_mask in range(1 << count):
        served = [ordered[index] for index in range(count)
                  if served_mask >> index & 1]
        if not served:
            continue
        for boundaries in range(1 << max(0, len(served) - 1)):
            groups = []
            start = 0
            for index in range(len(served) - 1):
                if boundaries >> index & 1:
                    groups.append(served[start:index + 1])
                    start = index + 1
            groups.append(served[start:])
            total = sum((exact_group_revenue(group) for group in groups), Fraction(0))
            total -= bribe * len(groups)
            if total > best:
                best = total
    return best


def exact_dp(bribe, clients):
    ordered = sorted(clients, key=lambda pair: Fraction(pair[0], pair[1]))
    count = len(ordered)
    prefix_a = [0] * (count + 1)
    prefix_b = [0] * (count + 1)
    for index, (amount, rate) in enumerate(ordered):
        prefix_a[index + 1] = prefix_a[index] + amount
        prefix_b[index + 1] = prefix_b[index] + rate
    dp = [Fraction(0)] * (count + 1)
    for length in range(1, count + 1):
        best = dp[length - 1]
        for start in range(length):
            amount_sum = prefix_a[length] - prefix_a[start]
            rate_sum = prefix_b[length] - prefix_b[start]
            candidate = dp[start] + Fraction(amount_sum * amount_sum, 4 * rate_sum) - bribe
            if candidate > best:
                best = candidate
        dp[length] = best
    return max(dp[count], Fraction(0))


def fast_dp(bribe, clients):
    ordered = sorted(clients, key=lambda pair: pair[0] / pair[1])
    count = len(ordered)
    prefix_a = [0.0] * (count + 1)
    prefix_b = [0.0] * (count + 1)
    for index, (amount, rate) in enumerate(ordered):
        prefix_a[index + 1] = prefix_a[index] + amount
        prefix_b[index + 1] = prefix_b[index] + rate
    dp = [0.0] * (count + 1)
    for length in range(1, count + 1):
        best = dp[length - 1]
        for start in range(length):
            amount_sum = prefix_a[length] - prefix_a[start]
            rate_sum = prefix_b[length] - prefix_b[start]
            candidate = dp[start] + amount_sum * amount_sum / (4.0 * rate_sum) - bribe
            if candidate > best:
                best = candidate
        dp[length] = best
    return max(dp[count], 0.0)


def format_value(value):
    if value == 0:
        return "0"
    return f"{float(value):.6f}".rstrip("0").rstrip(".")


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        bribe = int(tokens[cursor]); cursor += 1
        client_count = int(tokens[cursor]); cursor += 1
        clients = []
        for _ in range(client_count):
            clients.append((int(tokens[cursor]), int(tokens[cursor + 1])))
            cursor += 2
        if client_count <= 12:
            value = exact_brute(bribe, clients)
        else:
            value = fast_dp(bribe, clients)
        answers.append(format_value(value))
    return "\n".join(answers) + "\n"


def write(name, cases):
    text = str(len(cases)) + "\n" + "".join(
        f"{bribe} {len(clients)}\n" +
        "".join(f"{amount} {rate}\n" for amount, rate in clients)
        for bribe, clients in cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE = "2\n10 2\n10 1\n20 3\n100 1\n5 1\n"
SAMPLE_OUT = "46.25\n0\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert exact_brute(10, [(10, 1), (20, 3)]) == Fraction(185, 4)
assert exact_dp(10, [(10, 1), (20, 3)]) == Fraction(185, 4)
assert exact_brute(100, [(5, 1)]) == 0
assert format_value(Fraction(1, 3)) == "0.333333"


def build():
    write("2_edges", [
        (0, [(10, 1)]), (100000, [(1, 2000)]),
        (1, [(1, 1), (1, 1), (1, 1)]),
        (7, [(2000, 1), (1, 2000), (1000, 1000)]),
        (2, [(2000, 2000)]),
    ])
    rng = random.Random(20261126)
    wide = []
    for _ in range(6):
        count = rng.randint(150, 2000)
        wide.append((rng.randint(0, 2000),
                     [(rng.randint(1, 2000), rng.randint(1, 2000))
                      for _ in range(count)]))
    write("3_wide", wide)
    random_cases = []
    for _ in range(40):
        count = rng.randint(1, 10)
        clients = [(rng.randint(1, 2000), rng.randint(1, 2000))
                   for _ in range(count)]
        bribe = rng.randint(0, 2000)
        assert exact_brute(bribe, clients) == exact_dp(bribe, clients)
        random_cases.append((bribe, clients))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(19):
        clients = [(rng.randint(1, 2000), rng.randint(1, 2000))
                   for _ in range(2000)]
        io_cases.append((rng.randint(0, 2000), clients))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
