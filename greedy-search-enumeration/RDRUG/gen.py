#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def components(atom_count, bonds):
    parent = list(range(atom_count))

    def find(atom):
        while parent[atom] != atom:
            atom = parent[atom]
        return atom

    for left, right in bonds:
        left_root = find(left - 1)
        right_root = find(right - 1)
        if left_root != right_root:
            parent[right_root] = left_root
    groups = {}
    for atom in range(atom_count):
        groups.setdefault(find(atom), []).append(atom)
    return list(groups.values())


def oracle(text):
    tokens = [int(value) for value in text.split()]
    position = 0
    case_count = tokens[position]
    position += 1
    answers = []
    for _ in range(case_count):
        atom_count = tokens[position]
        bond_count = tokens[position + 1]
        position += 2
        bonds = []
        for _ in range(bond_count):
            bonds.append((tokens[position], tokens[position + 1]))
            position += 2
        masses = tokens[position:position + atom_count]
        position += atom_count
        groups = components(atom_count, bonds)
        if len(groups) == 1:
            answers.append("0")
            continue
        needed = 2 * (len(groups) - 1)
        best = None
        for chosen in itertools.combinations(range(atom_count), needed):
            covered = set()
            for atom in chosen:
                for group_index, group in enumerate(groups):
                    if atom in group:
                        covered.add(group_index)
            if len(covered) != len(groups):
                continue
            energy = sum(masses[atom] for atom in chosen)
            if best is None or energy < best:
                best = energy
        answers.append("-1" if best is None else str(best))
    return "\n".join(answers) + "\n"


SAMPLE = """2
6 6
1 2
2 3
1 3
4 5
5 6
4 6
1
3
5
2
4
6
4 0
1
2
3
4
"""
SAMPLE_OUT = """3
-1
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n1 0\n7\n") == "0\n"
assert oracle("1\n2 0\n1\n2\n") == "3\n"
assert oracle("1\n3 0\n1\n2\n3\n") == "-1\n"
assert oracle("1\n3 1\n1 2\n1\n5\n7\n") == "8\n"


def write(name, cases):
    blocks = [str(len(cases))]
    for atom_count, bonds, masses in cases:
        blocks.append(f"{atom_count} {len(bonds)}")
        for left, right in bonds:
            blocks.append(f"{left} {right}")
        blocks.extend(str(mass) for mass in masses)
    text = "\n".join(blocks) + "\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", [
        (1, [], [5]),
        (2, [], [1, 2]),
        (3, [(1, 2)], [4, 7, 9]),
        (4, [(1, 2), (3, 4)], [8, 2, 6, 3]),
        (5, [(1, 2), (2, 3)], [5, 1, 9, 4, 2]),
    ])
    write("3_wide", [
        (8, [(1, 2), (2, 3), (4, 5), (6, 7)], [10000, 1, 2, 3, 4, 5, 6, 7]),
        (6, [(1, 2), (2, 3), (1, 3), (4, 5), (5, 6), (4, 6)], [1, 3, 5, 2, 4, 6]),
    ])
    rng = random.Random(20261126)
    cases = []
    for _ in range(8):
        atoms = rng.randint(2, 9)
        bonds = []
        for left in range(1, atoms + 1):
            for right in range(left + 1, atoms + 1):
                if rng.random() < 0.18:
                    bonds.append((left, right))
        cases.append((atoms, bonds, [rng.randint(1, 10000) for _ in range(atoms)]))
    write("4_random", cases)
    write("5_io", [
        (9, [], [1, 2, 3, 4, 5, 6, 7, 8, 9]),
        (9, [(1, 2), (3, 4), (5, 6), (7, 8)], [9, 8, 7, 6, 5, 4, 3, 2, 1]),
        (10, [(1, 2), (2, 3), (4, 5), (5, 6), (7, 8), (8, 9)], [10, 1, 10, 1, 10, 1, 10, 1, 10, 1]),
        (10, [], [10000] * 10),
    ])


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    (6, [(1, 2), (2, 3), (1, 3), (4, 5), (5, 6), (4, 6)], [1, 3, 5, 2, 4, 6]),
    (4, [], [1, 2, 3, 4]),
])
build()
