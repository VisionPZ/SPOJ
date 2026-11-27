import os
import random


def oracle_fenwick(arr):
    sorted_vals = sorted(set(arr))
    rank = {v: i + 1 for i, v in enumerate(sorted_vals)}
    size = len(sorted_vals)
    bit = [0] * (size + 1)
    inversions = 0
    for seen, val in enumerate(arr):
        r = rank[val]
        less_or_equal = 0
        idx = r
        while idx > 0:
            less_or_equal += bit[idx]
            idx -= idx & -idx
        inversions += seen - less_or_equal
        idx = r
        while idx <= size:
            bit[idx] += 1
            idx += idx & -idx
    return inversions


def brute_inversions(arr):
    total = 0
    for i in range(len(arr)):
        for j in range(i + 1, len(arr)):
            if arr[i] > arr[j]:
                total += 1
    return total


assert oracle_fenwick([3, 1, 2]) == 2
assert oracle_fenwick([2, 3, 8, 6, 1]) == 5
assert oracle_fenwick([5, 4, 3, 2, 1]) == 10
assert oracle_fenwick([1, 2, 3, 4, 5]) == 0
for _trial in range(20):
    _rng = random.Random(100 + _trial)
    _sample = _rng.sample(range(1, 500), 30)
    assert oracle_fenwick(_sample) == brute_inversions(_sample)


def emit(name, cases):
    in_lines = [str(len(cases)), ""]
    out_lines = []
    for arr in cases:
        in_lines.append(str(len(arr)))
        for val in arr:
            in_lines.append(str(val))
        in_lines.append("")
        out_lines.append(str(oracle_fenwick(arr)))
    with open(os.path.join("in", f"{name}.txt"), "w", encoding="utf-8") as fin:
        fin.write("\n".join(in_lines) + "\n")
    with open(os.path.join("out", f"{name}.out"), "w", encoding="utf-8") as fout:
        fout.write("\n".join(out_lines) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", [[3, 1, 2], [2, 3, 8, 6, 1]])

    edges = [
        [1],
        [1, 2],
        [2, 1],
        [1, 2, 3, 4, 5, 6, 7, 8],
        [8, 7, 6, 5, 4, 3, 2, 1],
        [10000000, 1, 9999999, 2],
    ]
    emit("2_edges", edges)

    wide = [
        list(range(200000, 0, -1)),
        list(range(1, 200001)),
    ]
    emit("3_wide", wide)

    rng = random.Random(20260303)
    rand_cases = [
        rng.sample(range(1, 10000001), 40000)
        for _ in range(5)
    ]
    emit("4_random", rand_cases)

    io_cases = [
        rng.sample(range(1, 10000001), 50000)
        for _ in range(4)
    ]
    emit("5_io", io_cases)


if __name__ == "__main__":
    main()
