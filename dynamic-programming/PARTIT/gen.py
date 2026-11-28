#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_SUM = 220
MAX_PARTS = 10

exact_ways = [[0] * (MAX_PARTS + 1) for _ in range(MAX_SUM + 1)]
for total in range(MAX_SUM + 1):
    for parts in range(MAX_PARTS + 1):
        if total == 0 and parts == 0:
            exact_ways[total][parts] = 1
        elif total == 0 or parts == 0:
            exact_ways[total][parts] = 0
        else:
            value = exact_ways[total - 1][parts - 1]
            if total >= parts:
                value += exact_ways[total - parts][parts]
            exact_ways[total][parts] = value


def block_count(remaining, parts_left, min_value):
    shifted = remaining - parts_left * (min_value - 1)
    if parts_left < 0 or parts_left > MAX_PARTS or shifted < 0 or shifted > MAX_SUM:
        return 0
    return exact_ways[shifted][parts_left]


def unrank(total_sum, part_count, rank):
    remaining, parts_left, min_value = total_sum, part_count, 1
    result = []
    while parts_left > 0:
        if parts_left == 1:
            result.append(remaining)
            break
        for candidate in range(min_value, remaining // parts_left + 1):
            block = block_count(remaining - candidate, parts_left - 1, candidate)
            if rank > block:
                rank -= block
            else:
                result.append(candidate)
                remaining -= candidate
                parts_left -= 1
                min_value = candidate
                break
    return " ".join(str(value) for value in result)


def oracle(text):
    tokens = text.split()
    cursor = 0
    case_count = int(tokens[cursor]); cursor += 1
    answers = []
    for _ in range(case_count):
        total_sum = int(tokens[cursor]); cursor += 1
        part_count = int(tokens[cursor]); cursor += 1
        rank = int(tokens[cursor]); cursor += 1
        answers.append(unrank(total_sum, part_count, rank))
    return "\n".join(answers) + "\n"


def enumerate_partitions(total_sum, part_count, limit):
    chosen = []

    def walk(remaining, parts_left, min_value):
        if parts_left == 0:
            if remaining == 0:
                yield tuple(chosen)
            return
        for value in range(min_value, remaining // parts_left + 1):
            chosen.append(value)
            yield from walk(remaining - value, parts_left - 1, value)
            chosen.pop()

    found = []
    for partition in walk(total_sum, part_count, 1):
        found.append(partition)
        if len(found) >= limit:
            break
    return found


def write(name, cases):
    input_text = str(len(cases)) + "\n" + "".join(
        f"{total_sum}\n{part_count}\n{rank}\n"
        for total_sum, part_count, rank in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


SAMPLE = [(9, 4, 3)]
assert oracle("1\n9\n4\n3\n") == "1 1 3 4\n"
assert exact_ways[9][4] == 6
assert exact_ways[220][10] == 1788625426
assert block_count(8, 3, 1) == 5
assert block_count(5, 3, 1) == 2
for total in range(1, 26):
    for parts in range(1, min(total, 6) + 1):
        total_count = exact_ways[total][parts]
        brute = enumerate_partitions(total, parts, total_count)
        assert len(brute) == total_count
        for index, partition in enumerate(brute, start=1):
            got = unrank(total, parts, index)
            assert got == " ".join(str(value) for value in partition)


def worked_example():
    remaining, parts_left, min_value, rank = 9, 4, 1, 3
    lines = ["start remaining=9 partsLeft=4 minValue=1 rank=3"]
    while parts_left > 0:
        if parts_left == 1:
            lines.append(f"last part = {remaining}")
            break
        for candidate in range(min_value, remaining // parts_left + 1):
            block = block_count(remaining - candidate, parts_left - 1, candidate)
            if rank > block:
                lines.append(f"candidate {candidate}: block {block}, skip, rank {rank} -> {rank - block}")
                rank -= block
            else:
                lines.append(f"candidate {candidate}: block {block}, choose, rank {rank} <= {block}")
                remaining -= candidate
                parts_left -= 1
                min_value = candidate
                break
    return "\n".join(lines)


def build():
    max_count = exact_ways[220][10]
    write("2_edges", [
        (1, 1, 1),
        (5, 5, 1),
        (9, 4, 1),
        (9, 4, 3),
        (9, 4, 6),
        (10, 10, 1),
        (11, 10, 1),
        (220, 1, 1),
        (220, 10, 1),
        (220, 10, max_count),
        (220, 10, max_count // 2),
        (220, 9, 1),
        (220, 9, exact_ways[220][9]),
        (219, 10, exact_ways[219][10]),
    ])
    write("3_wide", [
        (220, 10, offset)
        for offset in (1, 2, 3, max_count // 4, max_count // 2,
                       3 * max_count // 4, max_count - 1, max_count)
    ] + [
        (220, 9, exact_ways[220][9]),
        (219, 10, exact_ways[219][10]),
        (218, 10, exact_ways[218][10] // 2),
        (220, 1, 1),
        (1, 1, 1),
    ])
    generator = random.Random(2026)
    random_cases = []
    for _ in range(200):
        part_count = generator.randint(1, MAX_PARTS)
        total_sum = generator.randint(part_count, MAX_SUM)
        rank = generator.randint(1, exact_ways[total_sum][part_count])
        random_cases.append((total_sum, part_count, rank))
    write("4_random", random_cases)
    io_cases = []
    for _ in range(20000):
        rank = generator.randint(1, max_count)
        io_cases.append((220, 10, rank))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE)
build()
print(worked_example())
