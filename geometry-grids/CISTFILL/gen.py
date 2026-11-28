import os
import random
from fractions import Fraction

HERE = os.path.dirname(os.path.abspath(__file__))
BIG_PATH = "/tmp/CISTFILL_big.txt"

SAMPLE_INPUT = """3
2
0 1 1 1
2 1 1 1
1
4
11 7 5 1
15 6 2 2
5 8 5 1
19 4 8 1
132
4
11 7 5 1
15 6 2 2
5 8 5 1
19 4 8 1
78
"""

SAMPLE_CISTERN = [(11, 7, 5, 1), (15, 6, 2, 2), (5, 8, 5, 1), (19, 4, 8, 1)]


def oracle(cisterns, volume):
    events = []
    for base, height, width, depth in cisterns:
        area = width * depth
        events.append((base, area))
        events.append((base + height, -area))
    if not events:
        return None
    events.sort(key=lambda event: event[0])
    active = 0
    filled = 0
    previous = events[0][0]
    index = 0
    while index < len(events):
        level = events[index][0]
        if active > 0:
            segment_volume = active * (level - previous)
            if filled + segment_volume >= volume:
                needed = volume - filled
                return float(Fraction(previous * active + needed, active))
            filled += segment_volume
        while index < len(events) and events[index][0] == level:
            active += events[index][1]
            index += 1
        previous = level
    return None


def brute(cisterns, volume):
    if not cisterns:
        return None
    low = min(base for base, _, _, _ in cisterns)
    high = max(base + height for base, height, _, _ in cisterns)

    def filled_below(level):
        total = 0
        for base, height, width, depth in cisterns:
            covered = min(level - base, height)
            if covered > 0:
                total += width * depth * covered
        return total

    if filled_below(high) < volume:
        return None
    for _ in range(90):
        middle = (low + high) / 2.0
        if filled_below(middle) < volume:
            low = middle
        else:
            high = middle
    return (low + high) / 2.0


def format_answer(value):
    if value is None:
        return "OVERFLOW"
    return format(value, ".2f")


def write_pair(name, datasets):
    with open(os.path.join(HERE, "in", name + ".txt"), "w") as source:
        source.write(str(len(datasets)) + "\n")
        for cisterns, volume in datasets:
            source.write(str(len(cisterns)) + "\n")
            for base, height, width, depth in cisterns:
                source.write("%d %d %d %d\n" % (base, height, width, depth))
            source.write(str(volume) + "\n")
    with open(os.path.join(HERE, "out", name + ".out"), "w") as expected:
        for cisterns, volume in datasets:
            expected.write(format_answer(oracle(cisterns, volume)) + "\n")


def random_cistern(rng):
    height = rng.randint(1, 40000)
    remaining = 40000 // height
    width = rng.randint(1, remaining)
    depth = rng.randint(1, remaining // width)
    return (rng.randint(0, 1000000), height, width, depth)


def total_capacity(cisterns):
    return sum(height * width * depth for _, height, width, depth in cisterns)


def verify():
    assert oracle([(0, 1, 1, 1)], 1) == 1.0
    assert oracle([(0, 1, 1, 1)], 2) is None
    assert oracle(SAMPLE_CISTERN, 78) == 17.0
    assert oracle(SAMPLE_CISTERN, 132) is None
    assert format_answer(oracle([(0, 1, 1, 3)], 2)) == "0.67"
    assert format_answer(oracle([(0, 1, 1, 8)], 1)) == "0.12"
    assert format_answer(oracle([(10, 5, 2, 2), (10, 3, 1, 1)], 10)) == "12.00"
    assert format_answer(oracle([(1000000, 1, 1, 1)], 1)) == "1000001.00"
    check = random.Random(2026)
    for _ in range(400):
        cisterns = [random_cistern(check) for _ in range(check.randint(1, 9))]
        capacity = total_capacity(cisterns)
        volume = check.randint(1, max(1, capacity))
        exact = oracle(cisterns, volume)
        approx = brute(cisterns, volume)
        assert exact is not None and abs(exact - approx) < 1e-7
        assert format_answer(exact) == format_answer(approx)


def build_edges():
    datasets = [
        ([(0, 1, 1, 1)], 1),
        ([(0, 1, 1, 1)], 2),
        ([(0, 1, 1, 3)], 2),
        ([(0, 1, 1, 1), (5, 1, 1, 1)], 2),
        ([(10, 5, 2, 2), (10, 3, 1, 1)], 10),
        ([(1000000, 1, 1, 1)], 1),
        ([(0, 40000, 1, 1)], 20000),
        ([(0, 1, 1, 8)], 1),
        ([(0, 1, 200, 200)], 1),
        ([(0, 2, 1, 1), (2, 2, 1, 1)], 4),
    ]
    write_pair("2_edges", datasets)


def build_wide():
    stacked = ([(0, 1, 1, 1) for _ in range(50000)], 25000)
    spread = ([((index * 20), 1, 1, 1) for index in range(50000)], 12345)
    write_pair("3_wide", [stacked, spread])


def build_random():
    rng = random.Random(314159)
    datasets = []
    for _ in range(8):
        size = rng.randint(20000, 50000)
        cisterns = [random_cistern(rng) for _ in range(size)]
        capacity = total_capacity(cisterns)
        if rng.random() < 0.75:
            volume = rng.randint(1, capacity)
        else:
            volume = rng.randint(capacity + 1, 2000000000)
        datasets.append((cisterns, volume))
    write_pair("4_random", datasets)


def build_io():
    rng = random.Random(99991)
    datasets = []
    for data_set_index in range(30):
        cisterns = []
        for cistern_index in range(50000):
            base = (cistern_index * 17 + data_set_index * 3) % 1000001
            height = 1
            width = 1
            depth = 20000 if cistern_index % 7 == 0 else 1
            cisterns.append((base, height, width, depth))
        capacity = total_capacity(cisterns)
        volume = capacity - 1 if data_set_index % 2 == 0 else rng.randint(1, 2 * 10**9)
        datasets.append((cisterns, volume))
    write_pair("5_io", datasets)


def build_stress():
    with open(BIG_PATH, "w") as stream:
        stream.write("60\n")
        for data_set_index in range(60):
            stream.write("50000\n")
            for cistern_index in range(50000):
                base = (cistern_index * 13 + data_set_index * 7) % 1000001
                stream.write("%d 1 1 %d\n" % (base, 40000 if cistern_index % 11 == 0 else 1))
            stream.write("%d\n" % (10**9 + data_set_index))


def main():
    verify()
    with open(os.path.join(HERE, "in", "1_sample.txt"), "w") as source:
        source.write(SAMPLE_INPUT)
    with open(os.path.join(HERE, "out", "1_sample.out"), "w") as expected:
        for cisterns, volume in [
            ([(0, 1, 1, 1), (2, 1, 1, 1)], 1),
            ([(4, 11, 5, 1)], 132),
            (SAMPLE_CISTERN, 78),
        ]:
            expected.write(format_answer(oracle(cisterns, volume)) + "\n")
    build_edges()
    build_wide()
    build_random()
    build_io()
    build_stress()


if __name__ == "__main__":
    main()
