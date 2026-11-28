#!/usr/bin/env python3
import itertools
import random
from decimal import Decimal, getcontext
from fractions import Fraction
from pathlib import Path

ROOT = Path(__file__).resolve().parent
getcontext().prec = 60


def parse_case(lines, cursor):
    header = lines[cursor].split()
    nexus_count = int(header[0])
    modification_limit = int(header[1])
    keep_factor = Fraction(header[2])
    parents = [int(value) - 1 for value in lines[cursor + 1].split()]
    costs = [Fraction(value) for value in lines[cursor + 2].split()]
    return nexus_count, modification_limit, keep_factor, parents, costs, cursor + 3


def exact_for_cut(nexus_count, keep_factor, parents, costs, effective, budget, forbidden):
    children = [[] for _ in range(nexus_count)]
    for node in range(1, nexus_count):
        children[effective[node]].append(node)

    def frontier(node):
        result = {0: [(costs[node], Fraction(0))]}
        for child in children[node]:
            child_result = frontier(child)
            updated = {used: [] for used in range(budget + 1)}
            for total_used in range(budget + 1):
                pairs = []
                for child_used in range(total_used + 1):
                    for left_scaled, left_fixed in result.get(total_used - child_used, []):
                        for right_scaled, right_fixed in child_result.get(child_used, []):
                            pairs.append((left_scaled + keep_factor * right_scaled,
                                          left_fixed + right_fixed))
                    if child_used + 1 <= total_used and child not in forbidden:
                        for left_scaled, left_fixed in result.get(total_used - child_used - 1, []):
                            for right_scaled, right_fixed in child_result.get(child_used, []):
                                pairs.append((left_scaled,
                                              left_fixed + keep_factor * right_scaled + right_fixed))
                unique = []
                for pair in pairs:
                    if any(other[0] >= pair[0] and other[1] >= pair[1] and
                           (other[0] > pair[0] or other[1] > pair[1])
                           for other in pairs):
                        continue
                    if pair not in unique:
                        unique.append(pair)
                updated[total_used] = unique
            result = updated
        return result

    return frontier(0)

def oracle_case(nexus_count, modification_limit, keep_factor, parents, costs):
    cycle = [0]
    current = parents[0]
    while current != 0:
        cycle.append(current)
        current = parents[current]
    cycle_length = len(cycle)
    best = None
    for cut_position in range(1, cycle_length + 1):
        effective = list(parents)
        effective[0] = -1
        cycle_cuts = 0
        if cut_position < cycle_length:
            effective[cycle[cut_position]] = 0
            cycle_cuts = 1
        budget = modification_limit - cycle_cuts
        if budget < 0:
            continue
        forbidden = set(cycle[1:cut_position])
        frontier = exact_for_cut(nexus_count, keep_factor, parents, costs,
                                 effective, budget, forbidden)
        final_length = cut_position + 1 if cut_position < cycle_length else cycle_length
        cycle_gain = 1 / (1 - keep_factor ** final_length)
        for used in range(budget + 1):
            for scaled, fixed in frontier.get(used, []):
                value = cycle_gain * (scaled + fixed)
                if best is None or value > best:
                    best = value
    return best


def brute_case(nexus_count, modification_limit, keep_factor, parents, costs):
    best = None
    nodes = list(range(1, nexus_count))
    for size in range(modification_limit + 1):
        for chosen in itertools.combinations(nodes, size):
            effective = list(parents)
            for node in chosen:
                effective[node] = 0
            matrix = []
            values = []
            for node in range(nexus_count):
                row = [Fraction(0)] * nexus_count
                row[node] = Fraction(1)
                for child in range(nexus_count):
                    if effective[child] == node:
                        row[child] -= keep_factor
                matrix.append(row)
                values.append(costs[node])
            for column in range(nexus_count):
                pivot = column
                while matrix[pivot][column] == 0:
                    pivot += 1
                matrix[column], matrix[pivot] = matrix[pivot], matrix[column]
                values[column], values[pivot] = values[pivot], values[column]
                divisor = matrix[column][column]
                matrix[column] = [value / divisor for value in matrix[column]]
                values[column] /= divisor
                for row_index in range(nexus_count):
                    if row_index == column:
                        continue
                    factor = matrix[row_index][column]
                    if factor:
                        matrix[row_index] = [entry - factor * pivot_entry
                                             for entry, pivot_entry in
                                             zip(matrix[row_index], matrix[column])]
                        values[row_index] -= factor * values[column]
            if best is None or values[0] > best:
                best = values[0]
    return best


def oracle(text):
    lines = [line for line in text.splitlines() if line.strip()]
    cursor = 0
    answers = []
    case_index = 0
    while cursor < len(lines):
        nexus_count, limit, factor, parents, costs, cursor = parse_case(lines, cursor)
        if nexus_count == 0:
            break
        case_index += 1
        value = oracle_case(nexus_count, limit, factor, parents, costs)
        decimal_value = Decimal(value.numerator) / Decimal(value.denominator)
        answers.append(f"{decimal_value:.2f}")
    return "\n".join(answers) + "\n"


SAMPLE = """4 1 0.5
2 3 1 3
10.0 10.0 10.0 10.0
"""
SAMPLE_OUT = """30.00
"""
assert oracle(SAMPLE) == SAMPLE_OUT
small = (4, 1, Fraction(1, 2), [1, 2, 0, 2],
         [Fraction(10)] * 4)
assert oracle_case(*small) == brute_case(*small)
second = (3, 0, Fraction(1, 2), [1, 0, 1],
          [Fraction(5), Fraction(7), Fraction(2)])
assert oracle_case(*second) == brute_case(*second)


def render_case(nexus_count, limit, factor_text, parents, costs):
    lines = [f"{nexus_count} {limit} {factor_text}",
             " ".join(str(parent + 1) for parent in parents),
             " ".join(str(cost) for cost in costs)]
    return "\n".join(lines) + "\n"


def stable_case(nexus_count, limit, factor_text, parents, costs_text):
    costs = [Fraction(value) for value in costs_text]
    base_units = int(round(float(factor_text) * 1000000))
    for offset in range(60):
        units = 300000 + ((base_units - 300000 + offset) % 650000)
        candidate = f"0.{units:06d}"
        factor = Fraction(candidate)
        value = oracle_case(nexus_count, limit, factor, parents, costs)
        decimal_value = Decimal(value.numerator) / Decimal(value.denominator)
        scaled = decimal_value * 100
        margin = abs(scaled - (int(scaled) + Decimal("0.5")))
        if margin > Decimal("0.05"):
            return nexus_count, limit, candidate, parents, costs_text
    return nexus_count, limit, "0.500000", parents, costs_text


def build_cases(rng, nexus_count, limit, count, stabilize=False):
    cases = []
    for case_index in range(count):
        cycle_length = rng.randint(2, min(3, nexus_count))
        cycle_nodes = list(range(cycle_length))
        rng.shuffle(cycle_nodes)
        parents = [-1] * nexus_count
        for cycle_index in range(cycle_length):
            parents[cycle_nodes[cycle_index]] = cycle_nodes[(cycle_index + 1) % cycle_length]
        for node in range(cycle_length, nexus_count):
            parents[node] = rng.randrange(node)
        costs = [f"{rng.randint(1, 40)}.{rng.randint(0, 9):03d}"
                 for _ in range(nexus_count)]
        factor_text = f"0.{rng.randint(300000, 950000):06d}"
        case = (nexus_count, limit, factor_text, parents, costs)
        if stabilize:
            costs_fraction = [Fraction(cost) for cost in costs]
            case = stable_case(nexus_count, limit, None, parents, costs_fraction, case_index)
        cases.append(case)
    return cases


def write(name, cases, stabilize=False):
    prepared = []
    for case in cases:
        nexus_count, limit, factor_text, parents, costs = case
        if stabilize:
            prepared.append(stable_case(nexus_count, limit, factor_text, parents, costs))
        else:
            prepared.append(case)
    input_text = "".join(render_case(*case) for case in prepared)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    rng = random.Random(20261126)
    edges = [(3, 0, "0.500000", [1, 0, 1], ["10.0", "10.0", "10.0"]),
             (4, 1, "0.500000", [1, 2, 0, 2], ["10.0"] * 4),
             (5, 2, "0.700000", [1, 2, 3, 0, 2], ["1.0", "2.5", "3.0", "4.0", "5.0"])]
    write("2_edges", edges * 3, stabilize=True)
    write("3_wide", build_cases(rng, 10, 3, 10), stabilize=True)
    write("4_random", build_cases(rng, 9, 2, 20), stabilize=True)
    write("5_io", build_cases(rng, 8, 4, 100), stabilize=True)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
