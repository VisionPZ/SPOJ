#!/usr/bin/env python3
import itertools
import random
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor]); cursor += 1
    cases = []
    for _ in range(count):
        city_count = int(tokens[cursor]); cursor += 1
        road_count = int(tokens[cursor]); cursor += 1
        start_time = int(tokens[cursor]); cursor += 1
        end_time = int(tokens[cursor]); cursor += 1
        edges = []
        for _ in range(road_count):
            frm = int(tokens[cursor]); cursor += 1
            to = int(tokens[cursor]); cursor += 1
            slope = int(tokens[cursor]); cursor += 1
            base = int(tokens[cursor]); cursor += 1
            edges.append((frm, to, slope, base))
        cases.append((city_count, start_time, end_time, edges))
    return cases


def render(cases):
    parts = [str(len(cases))]
    for city_count, start_time, end_time, edges in cases:
        parts.append(f"{city_count} {len(edges)}")
        parts.append(f"{start_time} {end_time}")
        for frm, to, slope, base in edges:
            parts.append(f"{frm} {to} {slope} {base}")
    return "\n".join(parts) + "\n"


def tree_lines(city_count, edges):
    road_count = len(edges)
    need = city_count - 1
    lines = set()
    for chosen in itertools.combinations(range(road_count), need):
        parent = list(range(city_count))
        ok = True
        for idx in chosen:
            frm, to, _, _ = edges[idx]
            left = frm
            while parent[left] != left:
                left = parent[left]
            right = to
            while parent[right] != right:
                right = parent[right]
            if left == right:
                ok = False
                break
            parent[left] = right
        if ok:
            base_sum = sum(edges[idx][3] for idx in chosen)
            slope_sum = sum(edges[idx][2] for idx in chosen)
            lines.add((base_sum, slope_sum))
    return lines


def envelope(lines):
    by_slope = {}
    for base, slope in lines:
        if slope not in by_slope or base < by_slope[slope]:
            by_slope[slope] = base
    ordered = sorted(((slope, base) for slope, base in by_slope.items()),
                     key=lambda item: (-item[0], item[1]))
    hull = []
    for slope, base in ordered:
        while hull:
            last_slope, last_base, last_left = hull[-1]
            cross = Fraction(base - last_base, last_slope - slope)
            if last_left is not None and cross <= last_left:
                hull.pop()
            else:
                break
        left = None if not hull else Fraction(
            base - hull[-1][1], hull[-1][0] - slope)
        hull.append((slope, base, left))
    return hull


def brute_exact(city_count, start_time, end_time, edges):
    hull = envelope(tree_lines(city_count, edges))
    candidates = [Fraction(start_time), Fraction(end_time)]
    for _, _, left in hull:
        if left is not None and start_time <= left <= end_time:
            candidates.append(left)
    best_value = None
    best_moment = None
    for moment in candidates:
        value = min(slope * moment + base for slope, base, _ in hull)
        if best_value is None or value > best_value or (
                value == best_value and moment < best_moment):
            best_value = value
            best_moment = moment
    return best_moment, best_value


def brute_oracle(city_count, start_time, end_time, edges):
    moment, value = brute_exact(city_count, start_time, end_time, edges)
    return float(moment), float(value)


def near_halfway(value):
    scaled = value * 1000
    low = scaled.numerator // scaled.denominator
    return abs(scaled - (low + Fraction(1, 2))) < Fraction(1, 1000)


def safe_case(rng, factory):
    while True:
        case = factory()
        if len(case[3]) <= 12:
            moment, value = brute_exact(*case)
            if near_halfway(moment) or near_halfway(value):
                continue
        return case


def prim_value(moment, city_count, edges):
    used = [False] * city_count
    dist = [float('inf')] * city_count
    dist[0] = 0.0
    total = 0.0
    for _ in range(city_count):
        node = -1
        for candidate in range(city_count):
            if not used[candidate] and (node == -1 or dist[candidate] < dist[node]):
                node = candidate
        used[node] = True
        total += dist[node]
        for frm, to, slope, base in edges:
            weight = base + moment * slope
            if frm == node and not used[to] and weight < dist[to]:
                dist[to] = weight
            elif to == node and not used[frm] and weight < dist[frm]:
                dist[frm] = weight
    return total


def prim_oracle(city_count, start_time, end_time, edges):
    low = float(start_time)
    high = float(end_time)
    for _ in range(120):
        left = low + (high - low) / 3
        right = high - (high - low) / 3
        if prim_value(left, city_count, edges) <= prim_value(right, city_count, edges):
            low = left
        else:
            high = right
    moment = (low + high) / 2
    best = prim_value(moment, city_count, edges)
    tolerance = 1e-10 * max(1.0, abs(best))
    left = float(start_time)
    right = moment
    for _ in range(90):
        mid = (left + right) / 2
        if prim_value(mid, city_count, edges) >= best - tolerance:
            right = mid
        else:
            left = mid
    return right, prim_value(right, city_count, edges)


def oracle(text):
    cases = parse(text)
    answers = []
    for city_count, start_time, end_time, edges in cases:
        if len(edges) <= 12:
            moment, value = brute_oracle(city_count, start_time, end_time, edges)
        else:
            moment, value = prim_oracle(city_count, start_time, end_time, edges)
        if abs(moment) < 0.0005:
            moment = 0.0
        if abs(value) < 0.0005:
            value = 0.0
        answers.append(f"{moment:.3f} {value:.3f}")
    return "\n".join(answers) + "\n"


def connected_case(rng, city_count, road_count, time_range=10000, coeff=32000):
    road_count = min(road_count, city_count * (city_count - 1) // 2)
    edges = [(i - 1, i, rng.randint(-coeff, coeff), rng.randint(-coeff, coeff))
             for i in range(1, city_count)]
    while len(edges) < road_count:
        frm = rng.randrange(city_count)
        to = rng.randrange(city_count)
        if frm != to and all((a, b) != (frm, to) and (a, b) != (to, frm)
                             for a, b, _, _ in edges):
            edges.append((frm, to, rng.randint(-coeff, coeff),
                          rng.randint(-coeff, coeff)))
    left = rng.randint(-time_range, time_range)
    right = rng.randint(left, time_range)
    return (city_count, left, right, edges)


def write(name, cases):
    input_text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE_IN = ("2\n5 6\n0 5\n1 0 -6 -4\n2 0 3 -3\n3 0 1 5\n"
             "3 1 -2 -3\n4 1 -3 -2\n4 3 -2 -3\n5 7\n-20 20\n"
             "1 0 1 2\n2 1 -7 4\n3 1 -9 0\n3 2 4 9\n"
             "4 1 0 -2\n4 2 2 3\n4 3 6 -5\n")
SAMPLE_OUT = "0.000 -13.000\n0.111 -1.000\n"

assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert brute_oracle(2, 0, 10, [(0, 1, 1, 0), (0, 1, 0, 5)]) == (5.0, 5.0)
assert brute_oracle(2, -10, 10, [(0, 1, 2, 0), (0, 1, -3, 5)]) == (1.0, 2.0)
assert brute_oracle(1, -5, 5, [(0, 0, 3, 7)]) == (-5.0, 0.0)

check_rng = random.Random(11)
for _ in range(120):
    case = connected_case(check_rng, check_rng.randint(2, 5), check_rng.randint(1, 8),
                          time_range=30, coeff=40)
    exact = brute_oracle(*case)
    approx = prim_oracle(*case)
    assert abs(exact[0] - approx[0]) < 2e-3, (case, exact, approx)
    assert abs(exact[1] - approx[1]) < 2e-3, (case, exact, approx)


def build():
    edges_cases = [
        (1, -5, 5, [(0, 0, 3, 7)]),
        (2, 0, 0, [(0, 1, 5, -10)]),
        (2, -10, 10, [(0, 1, 2, 0), (0, 1, -3, 5)]),
        (3, 0, 1, [(0, 1, 1, 0), (1, 2, 2, 0), (0, 2, 3, 0)]),
        (3, 0, 1, [(0, 1, -1, 10), (1, 2, -2, 10), (0, 2, -3, 10)]),
        (2, 0, 10, [(0, 1, 1, 0), (0, 1, 0, 5), (0, 1, -1, 10)]),
        (4, 7, 7, [(0, 1, -2, 9), (1, 2, 3, -4), (2, 3, -5, 6),
                   (0, 3, 4, -7), (0, 2, 1, 2), (1, 3, -3, -8)]),
    ]
    write("2_edges", edges_cases)

    wide_rng = random.Random(2026)
    write("3_wide", [connected_case(wide_rng, 120, 820),
                     connected_case(wide_rng, 120, 820)])

    random_rng = random.Random(77)
    random_cases = []
    for _ in range(80):
        random_cases.append(safe_case(
            random_rng,
            lambda: connected_case(random_rng, random_rng.randint(2, 7),
                                   random_rng.randint(1, 12))))
    write("4_random", random_cases)

    io_rng = random.Random(999)
    io_cases = []
    for _ in range(8000):
        io_cases.append(safe_case(
            io_rng,
            lambda: connected_case(io_rng, io_rng.randint(2, 5),
                                   io_rng.randint(1, 7), time_range=50, coeff=100)))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
