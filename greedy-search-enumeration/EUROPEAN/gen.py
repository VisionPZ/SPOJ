#!/usr/bin/env python3
from itertools import combinations
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def coverage(marks, gauges):
    mask = 0
    for left_index in range(len(marks)):
        for right_index in range(left_index + 1, len(marks)):
            distance = marks[right_index] - marks[left_index]
            for gauge_index, gauge in enumerate(gauges):
                if distance == gauge:
                    mask |= 1 << gauge_index
    return mask


def oracle(gauges):
    gauges = sorted(set(gauges))
    full_mask = (1 << len(gauges)) - 1
    position_limit = sum(gauges)
    level = {(0,): coverage((0,), gauges)}
    seen = set(level)
    for rail_count in range(2, 6):
        next_level = {}
        for marks, covered in level.items():
            candidates = set()
            for base in marks:
                for gauge in gauges:
                    for position in (base + gauge, base - gauge):
                        if 0 <= position <= position_limit and position not in marks:
                            candidates.add(position)
            for position in candidates:
                new_marks = tuple(sorted(marks + (position,)))
                if new_marks in seen:
                    continue
                seen.add(new_marks)
                next_level[new_marks] = coverage(new_marks, gauges)
        complete = [marks for marks, covered in next_level.items() if covered == full_mask]
        if complete:
            return min(complete), rail_count
        level = next_level
    raise ValueError("no ruler within five rails: " + repr(gauges))


def brute_force(gauges):
    gauges = sorted(set(gauges))
    full_mask = (1 << len(gauges)) - 1
    pool = {0}
    for count in range(1, len(gauges) + 1):
        for chosen in combinations(gauges, count):
            pool.add(sum(chosen))
    candidates = sorted(pool - {0})
    for rail_count in range(2, 6):
        for rest in combinations(candidates, rail_count - 1):
            marks = tuple(sorted((0,) + rest))
            if coverage(marks, gauges) == full_mask:
                return rail_count
    return None


def format_answer(case_index, gauges):
    marks, rail_count = oracle(gauges)
    return "Scenario #%d\n%d: %s\n\n" % (case_index, rail_count, " ".join(map(str, marks)))


def write(name, cases):
    lines = [str(len(cases))]
    for gauges in cases:
        lines.append(str(len(gauges)))
        lines.append(" ".join(map(str, gauges)))
    (ROOT / "in" / (name + ".txt")).write_text("\n".join(lines) + "\n")
    answers = []
    for case_index, gauges in enumerate(cases, 1):
        answers.append(format_answer(case_index, gauges))
    (ROOT / "out" / (name + ".out")).write_text("".join(answers))


SAMPLE = [
    [1524, 1520, 1609, 1435],
    [1000, 1520, 1600],
    [1000, 2000, 3000, 4000, 1500, 2500],
]

assert oracle([1000]) == ((0, 1000), 2)
assert oracle(SAMPLE[0]) == ((0, 85, 1520, 1609), 4)
assert oracle(SAMPLE[2])[1] == 5
assert brute_force([1000, 2000, 3000]) == oracle([1000, 2000, 3000])[1]
assert brute_force([1000, 1500, 2500, 3500]) == oracle([1000, 1500, 2500, 3500])[1]
assert brute_force([1000, 2000, 4000]) == oracle([1000, 2000, 4000])[1]


def ruler_case(rng, gauge_count, wide=False):
    while True:
        if wide:
            marks = sorted(rng.sample(range(0, 5001), 5))
            marks[0] = 0
            marks[4] = 5000
            marks = sorted(set(marks))
            if len(marks) < 5:
                continue
        else:
            marks = sorted(rng.sample(range(0, 5001), 5))
        distances = set()
        for left_index in range(5):
            for right_index in range(left_index + 1, 5):
                distance = marks[right_index] - marks[left_index]
                if 1000 <= distance <= 5000:
                    distances.add(distance)
        if len(distances) >= gauge_count:
            return sorted(rng.sample(sorted(distances), gauge_count))


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write("1_sample", SAMPLE)

write("2_edges", [
    [1000],
    [5000],
    [1000, 5000],
    [1000, 2000, 3000],
    [1000, 1520, 1600],
    [1000, 2000, 3000, 4000, 1500, 2500],
])

wide_rng = __import__("random").Random(20261125)
write("3_wide", [ruler_case(wide_rng, 8, wide=True) for _ in range(12)])

random_rng = __import__("random").Random(20261126)
random_cases = []
for _ in range(60):
    count = random_rng.randint(1, 8)
    random_cases.append(ruler_case(random_rng, count))
write("4_random", random_cases)

io_rng = __import__("random").Random(20261127)
write("5_io", [ruler_case(io_rng, 8) for _ in range(80)])

print("generated five test pairs")
