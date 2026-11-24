#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = """2
4
1 4 3 1 2
2 2 1 3 4
3 1 3 4 2
4 4 3 1 2
1 3 2 4 1
2 2 3 1 4
3 3 1 2 4
4 3 2 4 1
7
1 3 4 2 1 6 7 5
2 6 4 2 3 5 1 7
3 6 3 5 7 2 4 1
4 1 6 3 2 4 7 5
5 1 6 5 3 4 7 2
6 1 7 3 4 5 6 2
7 5 6 2 4 3 7 1
1 4 5 3 7 2 6 1
2 5 6 4 7 3 2 1
3 1 6 5 4 3 7 2
4 3 5 6 7 2 4 1
5 1 7 6 4 3 5 2
6 6 3 7 5 2 4 1
7 1 7 4 2 6 5 3
"""

SAMPLE_OUTPUT = """1 3
2 2
3 1
4 4
1 4
2 5
3 1
4 3
5 7
6 6
7 2
"""


def int_stream(data):
    position = 0
    limit = len(data)
    while position < limit:
        while position < limit and data[position] < 48:
            position += 1
        start = position
        while position < limit and data[position] >= 48:
            position += 1
        if start < position:
            yield int(data[start:position])


def parse(text):
    numbers = int_stream(text.encode())
    case_count = next(numbers)
    cases = []
    for _ in range(case_count):
        pair_count = next(numbers)
        women = [[0] * pair_count for _ in range(pair_count)]
        men = [[0] * pair_count for _ in range(pair_count)]
        for _ in range(pair_count):
            woman_id = next(numbers) - 1
            for rank_index in range(pair_count):
                women[woman_id][rank_index] = next(numbers) - 1
        for _ in range(pair_count):
            man_id = next(numbers) - 1
            for rank_index in range(pair_count):
                men[man_id][rank_index] = next(numbers) - 1
        cases.append((women, men))
    return cases


def oracle(text):
    lines = []
    for women, men in parse(text):
        pair_count = len(men)
        woman_rank = [[0] * pair_count for _ in range(pair_count)]
        man_rank = [[0] * pair_count for _ in range(pair_count)]
        for woman_id in range(pair_count):
            for rank_value, man_id in enumerate(women[woman_id]):
                woman_rank[woman_id][man_id] = rank_value
        for man_id in range(pair_count):
            for rank_value, woman_id in enumerate(men[man_id]):
                man_rank[man_id][woman_id] = rank_value
        wife = [-1] * pair_count
        husband = [-1] * pair_count
        next_pick = [0] * pair_count
        changed = True
        while changed:
            changed = False
            for man_id in range(pair_count - 1, -1, -1):
                if wife[man_id] != -1:
                    continue
                changed = True
                while wife[man_id] == -1:
                    woman_id = men[man_id][next_pick[man_id]]
                    next_pick[man_id] += 1
                    held = husband[woman_id]
                    if held == -1 or woman_rank[woman_id][man_id] < woman_rank[woman_id][held]:
                        if held != -1:
                            wife[held] = -1
                        husband[woman_id] = man_id
                        wife[man_id] = woman_id
        for man_id in range(pair_count):
            assert wife[man_id] != -1
            for woman_id in range(pair_count):
                if man_rank[man_id][woman_id] < man_rank[man_id][wife[man_id]]:
                    assert woman_rank[woman_id][husband[woman_id]] < woman_rank[woman_id][man_id]
            lines.append(f"{man_id + 1} {wife[man_id] + 1}")
    return "".join(line + "\n" for line in lines)


def make_text(cases):
    rows = [str(len(cases))]
    for women, men in cases:
        pair_count = len(men)
        rows.append(str(pair_count))
        for woman_id in range(pair_count):
            row = [woman_id + 1] + [man_id + 1 for man_id in women[woman_id]]
            rows.append(" ".join(map(str, row)))
        for man_id in range(pair_count):
            row = [man_id + 1] + [woman_id + 1 for woman_id in men[man_id]]
            rows.append(" ".join(map(str, row)))
    return "\n".join(rows) + "\n"


def identity(pair_count):
    order = list(range(pair_count))
    return ([order[:] for _ in range(pair_count)],
            [order[:] for _ in range(pair_count)])


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle(make_text([identity(1)])) == "1 1\n"
assert oracle(make_text([identity(4)])) == "1 1\n2 2\n3 3\n4 4\n"
assert oracle(make_text([identity(3)])) == "1 1\n2 2\n3 3\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def random_case(pair_count, rng):
    people = list(range(pair_count))
    women = [rng.sample(people, pair_count) for _ in range(pair_count)]
    men = [rng.sample(people, pair_count) for _ in range(pair_count)]
    return women, men


def cyclic_case(pair_count, step):
    women = [[(woman_id + step * rank) % pair_count for rank in range(pair_count)]
             for woman_id in range(pair_count)]
    men = [[(man_id + step * rank + 1) % pair_count for rank in range(pair_count)]
           for man_id in range(pair_count)]
    return women, men


def build():
    edges = [
        identity(1),
        identity(2),
        identity(5),
        cyclic_case(2, 1),
        cyclic_case(3, 2),
        cyclic_case(7, 3),
    ]
    write("2_edges", make_text(edges))

    rng = random.Random(243)
    wide = [cyclic_case(500, 1), cyclic_case(500, 499)]
    wide += [random_case(500, rng) for _ in range(3)]
    write("3_wide", make_text(wide))

    rng = random.Random(2026)
    mixed = [random_case(rng.randint(1, 150), rng) for _ in range(12)]
    write("4_random", make_text(mixed))

    rng = random.Random(50000)
    heavy = [random_case(200, rng) for _ in range(100)]
    write("5_io", make_text(heavy))


def worked_example():
    women, men = parse(SAMPLE_INPUT)[0]
    pair_count = len(men)
    woman_rank = [[0] * pair_count for _ in range(pair_count)]
    for woman_id in range(pair_count):
        for rank_value, man_id in enumerate(women[woman_id]):
            woman_rank[woman_id][man_id] = rank_value + 1
    husband = [-1] * pair_count
    wife = [-1] * pair_count
    next_pick = [0] * pair_count
    events = []
    free_men = list(range(pair_count))
    queue_head = 0
    while queue_head < len(free_men):
        man_id = free_men[queue_head]
        queue_head += 1
        while wife[man_id] == -1:
            woman_id = men[man_id][next_pick[man_id]]
            next_pick[man_id] += 1
            held = husband[woman_id]
            if held == -1:
                verdict = "accept"
                husband[woman_id] = man_id
                wife[man_id] = woman_id
            elif woman_rank[woman_id][man_id] < woman_rank[woman_id][held]:
                verdict = f"replace man {held + 1}"
                husband[woman_id] = man_id
                wife[man_id] = woman_id
                wife[held] = -1
                free_men.append(held)
            else:
                verdict = f"reject, keeps man {held + 1}"
            events.append(f"| {man_id + 1} | {woman_id + 1} | {verdict} |")
    print("| Man | Woman | Result |")
    print("| --- | --- | --- |")
    print("\n".join(events))
    print()
    print("Final matching")
    print()
    print("| Man | Woman |")
    print("| --- | --- |")
    for man_id in range(pair_count):
        print(f"| {man_id + 1} | {wife[man_id] + 1} |")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_INPUT)
build()
worked_example()
