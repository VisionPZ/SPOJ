import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
IN_DIR = ROOT / "in"
OUT_DIR = ROOT / "out"

SAMPLE = [(0, 4, 4), (0, 3, 1), (3, 4, 2), (0, 2, 2), (0, 2, 3)]


def is_visible(first, second, segments):
    x_first = first[2]
    x_second = second[2]
    if x_first == x_second:
        return False
    if x_first > x_second:
        x_first, x_second = x_second, x_first
    overlap_low = max(first[0], second[0])
    overlap_high = min(first[1], second[1])
    if overlap_low > overlap_high:
        return False
    blockers = []
    for segment in segments:
        x_segment = segment[2]
        if x_first < x_segment < x_second and segment[0] <= overlap_high and segment[1] >= overlap_low:
            blockers.append((segment[0], segment[1]))
    if not blockers:
        return True
    blockers.sort()
    covered_until = overlap_low
    for block_low, block_high in blockers:
        if block_low > covered_until:
            return True
        if block_high > covered_until:
            covered_until = block_high
        if covered_until >= overlap_high:
            return False
    return covered_until < overlap_high


def oracle(segments):
    count = len(segments)
    visible_pairs = [[False] * count for _ in range(count)]
    for first_index in range(count):
        for second_index in range(first_index + 1, count):
            answer = is_visible(segments[first_index], segments[second_index], segments)
            visible_pairs[first_index][second_index] = answer
            visible_pairs[second_index][first_index] = answer
    triangles = 0
    for first_index in range(count):
        for second_index in range(first_index + 1, count):
            if not visible_pairs[first_index][second_index]:
                continue
            for third_index in range(second_index + 1, count):
                if visible_pairs[first_index][third_index] and visible_pairs[second_index][third_index]:
                    triangles += 1
    return triangles


def assert_valid(segments):
    assert 1 <= len(segments) <= 8000
    seen_x = {}
    for low, high, x_position in segments:
        assert 0 <= low < high <= 8000
        assert 0 <= x_position <= 8000
        for other_low, other_high in seen_x.get(x_position, []):
            assert high < other_low or other_high < low
        seen_x.setdefault(x_position, []).append((low, high))


def band_case(band_count):
    segments = []
    for band_index in range(band_count):
        base = 3 * band_index
        x_base = 3 * band_index
        segments.append((base, base + 2, x_base))
        segments.append((base + 1, base + 2, x_base + 1))
        segments.append((base, base + 2, x_base + 2))
    return segments


def encode(datasets):
    parts = [str(len(datasets))]
    for segments in datasets:
        parts.append(str(len(segments)))
        for low, high, x_position in segments:
            parts.append("%d %d %d" % (low, high, x_position))
    return "\n".join(parts) + "\n"


def write_case(name, datasets, expected):
    assert len(datasets) == len(expected)
    for segments, answer in zip(datasets, expected):
        assert_valid(segments)
        assert oracle(segments) == answer if len(segments) <= 260 else True
    (IN_DIR / (name + ".txt")).write_text(encode(datasets))
    (OUT_DIR / (name + ".out")).write_text("".join("%d\n" % answer for answer in expected))


def main():
    IN_DIR.mkdir(exist_ok=True)
    OUT_DIR.mkdir(exist_ok=True)

    assert oracle(SAMPLE) == 1
    assert oracle([(0, 2, 0), (0, 2, 1), (0, 2, 2)]) == 0
    assert oracle([(0, 4, 0), (1, 2, 1), (0, 4, 2)]) == 1
    assert oracle([(0, 4, 0), (0, 4, 1), (0, 4, 3)]) == 0
    assert oracle([(0, 3, 0), (3, 4, 1), (0, 4, 2)]) == 1
    assert oracle(band_case(3)) == 3
    assert oracle([(0, 8000, x_position) for x_position in range(6)]) == 0
    assert_valid(SAMPLE)

    write_case("1_sample", [SAMPLE], [1])

    edge_sets = [
        [(0, 1, 0)],
        [(0, 2, 0), (0, 2, 1)],
        [(0, 4, 0), (1, 2, 1), (0, 4, 2)],
        [(0, 3, 0), (3, 4, 1), (0, 4, 2)],
        [(0, 4, 0), (0, 4, 1), (0, 4, 2), (0, 4, 3)],
        [(0, 2, 0), (3, 4, 1)],
    ]
    write_case("2_edges", edge_sets, [oracle(segments) for segments in edge_sets])

    wide_path = [(0, 8000, x_position) for x_position in range(8000)]
    wide_bands = band_case(2666)
    wide_bands.extend([(7998, 8000, 7998), (7998, 8000, 7999)])
    assert len(wide_bands) == 8000
    write_case("3_wide", [wide_path, wide_bands], [0, 2666])

    rng = random.Random(20241124)
    random_sets = []
    for segment_count in (120, 180, 200, 160):
        x_positions = rng.sample(range(8001), segment_count)
        segments = []
        for x_position in x_positions:
            low = rng.randrange(0, 7999)
            high = rng.randrange(low + 1, 8001)
            segments.append((low, high, x_position))
        random_sets.append(segments)
    write_case("4_random", random_sets, [oracle(segments) for segments in random_sets])

    io_sets = [[(0, 8000, x_position) for x_position in range(8000)] for _ in range(20)]
    write_case("5_io", io_sets, [0] * 20)


main()
