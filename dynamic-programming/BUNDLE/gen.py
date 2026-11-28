#!/usr/bin/env python3
import random
from itertools import combinations, product
from pathlib import Path

WILD = 10
TYPES = 11
BASE = Path(__file__).resolve().parent
SLOT_SETS = [tuple() for _ in range(8)]
for mask in range(1, 8):
    SLOT_SETS[mask] = tuple(i for i in range(3) if mask & (1 << i))


def build_template_table(templates):
    table = [[[[False] * TYPES for _ in range(TYPES)] for _ in range(TYPES)] for _ in range(3)]
    for letters, stop in templates:
        values = [ord(letter) - 65 for letter in letters]
        for first in (values[0], WILD):
            for second in (values[1], WILD):
                for third in (values[2], WILD):
                    table[stop][first][second][third] = True
    return table


def dependency_value(dependencies, index):
    value = dependencies[index - 1]
    return value if value > 0 else -1


def precompute_options(types, dependencies, table):
    count = len(types)
    can_skip = [[False] * 4 for _ in range(count + 1)]
    can_stop = [[[False] * 4 for _ in range(4)] for _ in range(count + 1)]
    for start in range(1, count + 1):
        for mask, slots in enumerate(SLOT_SETS):
            if not slots:
                continue
            size = len(slots)
            if start + size - 1 > count:
                continue
            letters = [WILD, WILD, WILD]
            for offset, slot in enumerate(slots):
                letters[slot] = ord(types[start + offset - 1]) - 65
            for stop in range(3):
                if not table[stop][letters[0]][letters[1]][letters[2]]:
                    continue
                if stop == 0:
                    can_skip[start][size] = True
                else:
                    before = sum(1 for slot in slots if slot < stop)
                    can_stop[start][size][before] = True
    return can_skip, can_stop


def dp_oracle(types, dependencies, templates):
    count = len(types)
    table = build_template_table(templates)
    can_skip, can_stop = precompute_options(types, dependencies, table)
    states = [[] for _ in range(count + 1)]
    states[0] = [(0, 0, -1)]
    for end in range(count):
        current = states[end]
        if not current:
            continue
        best_bundles = min(state[0] for state in current)
        kept = []
        for state in current:
            if state[0] != best_bundles:
                continue
            if kept and all(other[1] <= state[1] and other[2] >= state[2] for other in kept):
                continue
            kept.append(state)
        kept.sort(key=lambda state: (state[1], -state[2]))
        frontier = []
        best_last = -2
        for state in kept:
            if state[2] > best_last:
                frontier.append(state)
                best_last = state[2]
        start = end + 1
        for bundles, stops, last_stop in frontier:
            for size in (1, 2, 3):
                next_end = end + size
                if next_end > count:
                    continue
                deps = [dependency_value(dependencies, start + ahead) for ahead in range(size)]
                if can_skip[start][size] and max(deps) <= last_stop:
                    states[next_end].append((bundles + 1, stops, last_stop))
                    if next_end < count:
                        states[next_end].append((bundles + 1, stops + 1, next_end))
                for before in range(size + 1):
                    if not can_stop[start][size][before]:
                        continue
                    template_stop = start + before - 1
                    if before and max(deps[:before]) > last_stop:
                        continue
                    if before < size and max(deps[before:]) > template_stop:
                        continue
                    extra = 1
                    states[next_end].append((bundles + 1, stops + extra, template_stop))
                    if next_end < count and next_end != template_stop:
                        states[next_end].append((bundles + 1, stops + extra + 1, next_end))
    return min((state[0], state[1]) for state in states[count])


def brute_oracle(types, dependencies, templates):
    count = len(types)
    best = None
    seen = {}

    def valid(upto, stops):
        for index in range(1, upto + 1):
            need = dependencies[index - 1]
            if need and not any(need <= gap <= index - 1 for gap in stops):
                return False
        return True

    def explore(pos, bundles, stops, stop_total):
        nonlocal best
        if best is not None and bundles > best[0]:
            return
        key = (pos, frozenset(stops), stop_total)
        if seen.get(key, 10 ** 9) <= bundles:
            return
        seen[key] = bundles
        if pos > count:
            candidate = (bundles, stop_total)
            if best is None or candidate < best:
                best = candidate
            return
        for size in (1, 2, 3):
            end = pos + size - 1
            if end > count:
                continue
            for slots in combinations(range(3), size):
                for letters, stop in templates:
                    if any(ord(letters[slots[j]]) - 65 != ord(types[pos + j - 1]) - 65 for j in range(size)):
                        continue
                    updated = set(stops)
                    template_gap = None
                    extra = 0
                    if stop > 0:
                        before = sum(1 for slot in slots if slot < stop)
                        template_gap = pos + before - 1
                        updated.add(template_gap)
                        extra = 1
                    options = (False, True) if end < count else (False,)
                    for add_boundary in options:
                        final = set(updated)
                        total = stop_total + extra
                        if add_boundary and end != template_gap:
                            final.add(end)
                            total += 1
                        if valid(end, final):
                            explore(end + 1, bundles + 1, final, total)

    explore(1, 0, set(), 0)
    return best


def write_case(name, text, expected):
    (BASE / "in" / (name + ".txt")).write_text(text)
    (BASE / "out" / (name + ".out")).write_text(expected)


def format_case(templates, types, dependencies):
    lines = ["%d %d" % (len(templates), len(types))]
    lines.extend("%s %d" % template for template in templates)
    lines.extend("%s %d" % pair for pair in zip(types, dependencies))
    return "\n".join(lines) + "\n"


def make_dataset(seed, count, size, template_pool):
    rng = random.Random(seed)
    templates = rng.sample(template_pool, min(len(template_pool), max(1, count)))
    types = [chr(65 + rng.randrange(10)) for _ in range(size)]
    dependencies = [0]
    for index in range(2, size + 1):
        dependencies.append(rng.randrange(index) if rng.random() < 0.35 else 0)
    for letter in set(types):
        if not any(letter in template[0] for template in templates):
            letters = list(templates[0][0])
            letters[rng.randrange(3)] = letter
            templates.append(("".join(letters), rng.randrange(3)))
    return templates, types, dependencies


def main():
    sample_templates = [("ABB", 0), ("BAD", 1), ("AAB", 0), ("ABB", 2)]
    sample_types = list("BBAABDABB")
    sample_dependencies = [0, 1, 1, 1, 4, 0, 0, 3, 0]
    sample_input = "1\n4 9\nABB 0\nBAD 1\nAAB 0\nABB 2\nB 0\nB 1\nA 1\nA 1\nB 4\nD 0\nA 0\nB 3\nB 0\n"
    assert brute_oracle(sample_types, sample_dependencies, sample_templates) == (4, 3)
    assert dp_oracle(sample_types, sample_dependencies, sample_templates) == (4, 3)
    write_case("1_sample", sample_input, "4 3\n")

    rng = random.Random(20231124)
    for trial in range(25):
        size = rng.randrange(1, 9)
        types = [chr(65 + rng.randrange(4)) for _ in range(size)]
        dependencies = [0] + [rng.randrange(index) if rng.random() < 0.6 else 0 for index in range(2, size + 1)]
        templates = []
        for letter in set(types):
            templates.append((letter + chr(65 + rng.randrange(4)) + chr(65 + rng.randrange(4)), rng.randrange(3)))
        templates = list(set(templates))
        assert brute_oracle(types, dependencies, templates) == dp_oracle(types, dependencies, templates)

    pool = [("".join(letters), stop) for letters in product("ABCDEFGHIJ", repeat=3)
            for stop in range(3)]

    edge_cases = [
        ([("AAA", 0)], ["A"], [0]),
        ([("AAA", 2)], ["A"], [0]),
        ([("AAA", 1)], ["A", "A", "A"], [0, 0, 0]),
        ([("ABC", 0), ("DEF", 0), ("GHI", 0)], list("ABCDEFGHI"), [0] * 9),
        ([("AAA", 0)], ["A"] * 9, [0] * 9),
    ]
    edge_text = "%d\n" % len(edge_cases)
    edge_answers = []
    for templates, types, dependencies in edge_cases:
        edge_text += format_case(templates, types, dependencies)
        edge_answers.append(dp_oracle(types, dependencies, templates))
    write_case("2_edges", edge_text, "".join("%d %d\n" % answer for answer in edge_answers))

    wide = []
    for seed, size, template_count in ((11, 100000, 1500), (29, 100000, 40)):
        templates, types, dependencies = make_dataset(seed, template_count, size, pool)
        wide.append((templates, types, dependencies))
    wide_text = "%d\n" % len(wide)
    wide_answers = []
    for templates, types, dependencies in wide:
        wide_text += format_case([("".join(letters), stop) for letters, stop in templates], types, dependencies)
        wide_answers.append(dp_oracle(types, dependencies, [("".join(letters), stop) for letters, stop in templates]))
    write_case("3_wide", wide_text, "".join("%d %d\n" % answer for answer in wide_answers))

    random_text = ""
    random_answers = []
    for seed in range(10):
        templates, types, dependencies = make_dataset(100 + seed, 1500, 10000, pool)
        converted = [("".join(letters), stop) for letters, stop in templates]
        random_text += format_case(converted, types, dependencies)
        random_answers.append(dp_oracle(types, dependencies, converted))
    write_case("4_random", "%d\n%s" % (len(random_answers), random_text),
               "".join("%d %d\n" % answer for answer in random_answers))

    io_text = ""
    io_templates = [("AAA", 0)]
    for index in range(120000):
        io_text += "1 1\nAAA 0\nA 0\n"
    io_answers = [dp_oracle(["A"], [0], io_templates)] * 120000
    write_case("5_io", "%d\n%s" % (len(io_answers), io_text),
               "".join("%d %d\n" % answer for answer in io_answers))


if __name__ == "__main__":
    main()
