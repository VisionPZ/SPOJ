#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CACHE = {}


def pairs_valid(seq):
    size = len(seq)
    for left in range(size):
        for right in range(left + 1, size):
            if abs(seq[right] - seq[left]) < size - (right - left):
                return False
    return True


def brute_optimal(size):
    found = []
    current = [0] * size
    cap = 4 * size

    def walk(pos):
        if pos == size:
            found.append(tuple(current))
            return
        for value in range(1, cap + 1):
            if all(abs(value - current[earlier]) >= size - (pos - earlier)
                   for earlier in range(pos)):
                current[pos] = value
                walk(pos + 1)

    walk(0)
    best = min(max(seq) for seq in found)
    return best, [seq for seq in found if max(seq) == best]


def search_even(size):
    half = size // 2
    best = None
    for step in (size - 1, size, size + 1):
        for start in range(1, size + 3):
            first = [start + i * step for i in range(half)]
            for second in range(1, size + 3):
                seq = first + [second + i * step for i in range(half)]
                if min(seq) < 1:
                    continue
                peak = max(seq)
                if best is not None and peak > best[0]:
                    continue
                if pairs_valid(seq):
                    choice = (peak, start, tuple(seq))
                    if best is None or peak < best[0] or (peak == best[0] and start > best[1]):
                        best = choice
    return best[2]


def search_odd(size):
    half = (size - 1) // 2
    best = None
    for step in (size - 1, size, size + 1):
        for start in range(max(1, half - 2), min(size + 2, half + 4)):
            for shift in range(max(1, half - 2), min(size + 2, half + 4)):
                lower = start + size - 1
                if half >= 2:
                    lower = max(lower, (half - 2) * step + shift + 1)
                for second in range(lower, lower + 2 * size + 5):
                    prefix = [start]
                    for i in range(half - 1):
                        prefix.append(second - i * step)
                    tail = [value - shift for value in prefix]
                    if min(prefix + tail) < 1:
                        continue
                    peak = 1
                    for i, value in enumerate(prefix):
                        peak = max(peak, value + size - (half - i))
                    for i, value in enumerate(tail):
                        peak = max(peak, value + size - (i + 1))
                    seq = prefix + [peak] + tail
                    if pairs_valid(seq):
                        choice = (peak, start, tuple(seq))
                        if best is None or peak < best[0] or (peak == best[0] and start > best[1]):
                            best = choice
                        break
    return best[2]


def reference(size):
    if size == 1:
        return [1]
    if size == 2:
        return [1, 2]
    if size == 3:
        return [2, 4, 1]
    if size % 2 == 0:
        half = size // 2
        return [i * (size - 1) + half + 1 for i in range(half)] + [
            i * (size - 1) + 1 for i in range(half)]
    half = (size - 1) // 2
    tail = (size - 3) // 2
    seq = [half + 1]
    for i in range(tail):
        seq.append((tail - i) * size + 2)
    seq.append((size * size - 2 * size + 7) // 2)
    for i in range(half):
        seq.append(seq[i] - half)
    return seq


def oracle(size):
    if size not in CACHE:
        if size <= 3:
            answer = reference(size)
        elif size % 2 == 0:
            answer = list(search_even(size))
        else:
            answer = list(search_odd(size))
        assert len(answer) == size and min(answer) >= 1
        assert pairs_valid(answer)
        assert answer == reference(size)
        if size <= 8:
            best, options = brute_optimal(size)
            assert max(answer) == best and tuple(answer) in options
        CACHE[size] = answer
    return CACHE[size]


def write_case(name, sizes):
    input_text = str(len(sizes)) + "\n" + "".join(f"{size}\n" for size in sizes)
    output_text = "".join(" ".join(str(value) for value in oracle(size)) + "\n"
                          for size in sizes)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


assert oracle(1) == [1]
assert oracle(2) == [1, 2]
assert oracle(3) == [2, 4, 1]
assert [max(oracle(n)) for n in (4, 5, 6, 7, 8)] == [6, 11, 14, 21, 26]
assert [max(oracle(n)) for n in (99, 100)] == [4805, 4902]

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

(ROOT / "in" / "1_sample.txt").write_text("3\n1\n2\n3\n")
(ROOT / "out" / "1_sample.out").write_text("1\n1 2\n2 4 1\n")

write_case("2_edges", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 50, 99, 100])
write_case("3_wide", [100] * 5 + [99] * 5)
rng = random.Random(20261125)
write_case("4_random", [rng.randint(1, 100) for _ in range(100)])
write_case("5_io", [100] * 100)

print("generated five cases, cached", len(CACHE), "sizes")
