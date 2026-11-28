#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def perfect_matchings(matrix):
    size = len(matrix)
    found = []

    def options_for(person, assigned):
        taken = set(assigned)
        return [button for button in range(size)
                if matrix[person][button] == 'Y' and button not in taken]

    def solve(assigned):
        assigned = list(assigned)
        while True:
            changed = False
            for person in range(size):
                if assigned[person] != -1:
                    continue
                available = options_for(person, [value for value in assigned if value != -1])
                if not available:
                    return
                if len(available) == 1:
                    assigned[person] = available[0]
                    changed = True
            if not changed:
                break
        if all(value != -1 for value in assigned):
            person_for_button = [0] * size
            for person, button in enumerate(assigned):
                person_for_button[button] = person + 1
            found.append(tuple(person_for_button))
            return
        best_person = None
        best_options = None
        for person in range(size):
            if assigned[person] == -1:
                available = options_for(person, [value for value in assigned if value != -1])
                if best_options is None or len(available) < len(best_options):
                    best_person = person
                    best_options = available
        for button in best_options:
            next_assignment = list(assigned)
            next_assignment[best_person] = button
            solve(next_assignment)

    solve([-1] * size)
    return found


def oracle(matrix):
    matchings = perfect_matchings(matrix)
    if not matchings:
        return "NO SCIENCE\n"
    size = len(matrix)
    edge_sets = [frozenset((person, match[person]) for person in range(size)) for match in matchings]
    best = []

    def search(start, chosen, used):
        if len(chosen) > len(best):
            best[:] = chosen[:]
        for index in range(start, len(matchings)):
            if used.isdisjoint(edge_sets[index]):
                chosen.append(matchings[index])
                search(index + 1, chosen, used | edge_sets[index])
                chosen.pop()

    search(0, [], frozenset())
    if not best:
        return "NO SCIENCE\n"
    variants = set()

    def count_variants(start, chosen, used):
        if len(chosen) == len(best):
            variants.add(frozenset(chosen))
            return
        for index in range(start, len(matchings)):
            if used.isdisjoint(edge_sets[index]):
                chosen.append(matchings[index])
                count_variants(index + 1, chosen, used | edge_sets[index])
                chosen.pop()

    count_variants(0, [], frozenset())
    if len(variants) != 1:
        raise ValueError("matrix does not have a unique decomposition")
    lines = [str(len(best))]
    for match in sorted(best):
        lines.append(" ".join(str(value) for value in match))
    return "\n".join(lines) + "\n"


SAMPLE_MATRIX = ["YYY", "NYY", "YNY"]
SAMPLE_OUT = """2
1 2 3
3 1 2
"""
assert oracle(SAMPLE_MATRIX) == SAMPLE_OUT
assert oracle(["YN", "YN"]) == "NO SCIENCE\n"
assert oracle(["Y"]) == "1\n1\n"
assert oracle(["YY", "YN"]) == "1\n2 1\n"


def write(name, matrices):
    lines = []
    for matrix in matrices:
        lines.append(str(len(matrix)))
        lines.extend(matrix)
    lines.append("0")
    text = "\n".join(lines) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    outputs = [oracle(matrix).rstrip("\n") for matrix in matrices]
    (ROOT / "out" / f"{name}.out").write_text("\n".join(outputs) + "\n")


def permuted_cycle(rng, size):
    rows = list(range(size))
    columns = list(range(size))
    rng.shuffle(rows)
    rng.shuffle(columns)
    matrix = []
    for person in range(size):
        original = rows[person]
        allowed = [original, (original + 1) % size]
        row = ['N'] * size
        for button in range(size):
            if columns[button] in allowed:
                row[button] = 'Y'
        matrix.append("".join(row))
    return matrix


def identity_matrix(size):
    return ["".join('Y' if person == button else 'N' for button in range(size)) for person in range(size)]


def build():
    rng = random.Random(20261126)
    write("2_edges", [["YN", "YN"], ["Y"], ["YY", "YN"], identity_matrix(3), permuted_cycle(rng, 4)])
    write("3_wide", [permuted_cycle(rng, 200), permuted_cycle(rng, 150), permuted_cycle(rng, 120)])
    write("4_random", [permuted_cycle(rng, rng.randint(3, 9)) for _ in range(25)])
    write("5_io", [permuted_cycle(rng, 200) for _ in range(6)])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [SAMPLE_MATRIX])
build()
