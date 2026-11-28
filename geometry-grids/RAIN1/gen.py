#!/usr/bin/env python3
import random
from fractions import Fraction


def height_at(segment, x):
    left_x, left_y, right_x, right_y = segment
    return Fraction(left_y) + Fraction(right_y - left_y, right_x - left_x) * (x - left_x)


def oracle(segments):
    count = len(segments)
    boundaries = sorted({value for seg in segments for value in (seg[0], seg[2])})
    direct = [Fraction(0) for _ in range(count)]
    for index in range(len(boundaries) - 1):
        low, high = boundaries[index], boundaries[index + 1]
        middle = Fraction(low + high, 2)
        top_seg = -1
        top_height = None
        for seg_index, seg in enumerate(segments):
            if seg[0] <= middle <= seg[2]:
                level = height_at(seg, middle)
                if top_height is None or level > top_height:
                    top_height = level
                    top_seg = seg_index
        if top_seg != -1:
            direct[top_seg] += high - low

    receiver = [-1] * count
    for seg_index, seg in enumerate(segments):
        if seg[1] < seg[3]:
            sink_x, sink_y = seg[0], seg[1]
        else:
            sink_x, sink_y = seg[2], seg[3]
        best_seg = -1
        best_height = None
        for other_index, other in enumerate(segments):
            if other_index == seg_index or not (other[0] <= sink_x <= other[2]):
                continue
            level = height_at(other, sink_x)
            if level < sink_y and (best_height is None or level > best_height):
                best_height = level
                best_seg = other_index
        receiver[seg_index] = best_seg

    children = [[] for _ in range(count)]
    for seg_index in range(count):
        if receiver[seg_index] != -1:
            children[receiver[seg_index]].append(seg_index)

    memo = [None] * count

    def collect(seg_index):
        if memo[seg_index] is not None:
            return memo[seg_index]
        total = direct[seg_index]
        for child in children[seg_index]:
            total += collect(child)
        memo[seg_index] = total
        return total

    return [int(collect(index)) for index in range(count)]


def tower_case(tower_count, width):
    segments = []
    expected = []
    for tower in range(tower_count):
        base = tower * (width + 25)
        for level in range(25):
            segments.append((base + level, 2000 - 3 * level,
                             base + width + level, 1999 - 3 * level))
            expected.append(width + level)
    return segments, expected


def segments_intersect(first, second):
    low = max(first[0], second[0])
    high = min(first[2], second[2])
    if low > high:
        return False
    first_low = height_at(first, low) - height_at(second, low)
    first_high = height_at(first, high) - height_at(second, high)
    return first_low <= 0 <= first_high or first_high <= 0 <= first_low


def depth_ok(segments):
    points = sorted({value for seg in segments for value in (seg[0], seg[2])})
    for index in range(len(points) - 1):
        middle = Fraction(points[index] + points[index + 1], 2)
        covering = sum(1 for seg in segments if seg[0] <= middle <= seg[2])
        if covering > 25:
            return False
    return True


def random_case(seed, count):
    rng = random.Random(seed)
    segments = []
    attempts = 0
    while len(segments) < count and attempts < 200000:
        attempts += 1
        left_x = rng.randint(0, 60)
        right_x = rng.randint(left_x + 1, 100)
        left_y = rng.randint(1, 60)
        right_y = rng.randint(1, 60)
        if left_y == right_y:
            continue
        candidate = (left_x, left_y, right_x, right_y)
        if any(segments_intersect(candidate, seg) for seg in segments):
            continue
        if not depth_ok(segments + [candidate]):
            continue
        segments.append(candidate)
    assert len(segments) == count
    return segments


def write_case(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for segments, answers in cases:
        input_lines.append(str(len(segments)))
        for seg in segments:
            input_lines.append("%d %d %d %d" % seg)
        output_lines.extend(str(value) for value in answers)
    with open("in/%s.txt" % name, "w") as handle:
        handle.write("\n".join(input_lines) + "\n")
    with open("out/%s.out" % name, "w") as handle:
        handle.write("\n".join(output_lines) + "\n")


sample_segments = [
    (13, 7, 15, 6),
    (3, 8, 7, 7),
    (1, 7, 5, 6),
    (5, 5, 9, 3),
    (6, 3, 8, 2),
    (9, 6, 12, 8),
]
sample_answers = [2, 4, 2, 11, 0, 3]
assert oracle(sample_segments) == sample_answers

small_tower_segments, small_tower_answers = tower_case(2, 30)
assert oracle(small_tower_segments) == small_tower_answers

single_flat = [(2, 9, 8, 4)]
single_rising = [(2, 4, 8, 9)]
stacked = [(2, 10, 8, 9), (3, 7, 9, 6)]
endpoint_catch = [(1, 12, 5, 10), (5, 8, 9, 7), (7, 6, 11, 5)]
disjoint = [(1, 5, 4, 2), (7, 9, 12, 6)]
edge_cases = []
for group in (single_flat, single_rising, stacked, endpoint_catch, disjoint):
    edge_cases.append((group, oracle(group)))

write_case("1_sample", [(sample_segments, sample_answers)])
write_case("2_edges", edge_cases)
write_case("3_wide", [tower_case(1600, 600)])
write_case("4_random", [(case, oracle(case)) for case in
                        (random_case(1000 + seed, 40) for seed in range(10))])
write_case("5_io", [tower_case(1600, 600) for _ in range(4)])
