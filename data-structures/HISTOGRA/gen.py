import os
import random


def oracle_dsu(heights):
    n = len(heights)
    parent = list(range(n))
    comp_size = [0] * n
    active = [False] * n

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(a, b):
        ra = find(a)
        rb = find(b)
        if ra == rb:
            return ra
        if comp_size[ra] < comp_size[rb]:
            ra, rb = rb, ra
        parent[rb] = ra
        comp_size[ra] += comp_size[rb]
        return ra

    order = sorted(range(n), key=lambda i: heights[i], reverse=True)
    best = 0
    for idx in order:
        active[idx] = True
        comp_size[idx] = 1
        root = idx
        if idx > 0 and active[idx - 1]:
            root = union(root, idx - 1)
        if idx + 1 < n and active[idx + 1]:
            root = union(root, idx + 1)
        area = heights[idx] * comp_size[root]
        if area > best:
            best = area
    return best


def brute_hist(heights):
    best = 0
    n = len(heights)
    for i in range(n):
        mn = heights[i]
        for j in range(i, n):
            if heights[j] < mn:
                mn = heights[j]
            area = mn * (j - i + 1)
            if area > best:
                best = area
    return best


assert oracle_dsu([2, 1, 4, 5, 1, 3, 3]) == 8
assert oracle_dsu([1000, 1000, 1000, 1000]) == 4000
assert oracle_dsu([0, 0, 0]) == 0
for _trial in range(25):
    _rng = random.Random(200 + _trial)
    _bars = [_rng.randint(0, 20) for _ in range(30)]
    assert oracle_dsu(_bars) == brute_hist(_bars)


def emit(name, cases):
    in_lines = []
    out_lines = []
    for bars in cases:
        in_lines.append(str(len(bars)) + " " + " ".join(str(h) for h in bars))
        out_lines.append(str(oracle_dsu(bars)))
    in_lines.append("0")
    with open(os.path.join("in", f"{name}.txt"), "w", encoding="utf-8") as fin:
        fin.write("\n".join(in_lines) + "\n")
    with open(os.path.join("out", f"{name}.out"), "w", encoding="utf-8") as fout:
        fout.write("\n".join(out_lines) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", [[2, 1, 4, 5, 1, 3, 3], [1000, 1000, 1000, 1000]])

    edges = [
        [0],
        [1000000000],
        [0, 0, 0, 0],
        [1, 2, 3, 4, 5, 6, 7],
        [7, 6, 5, 4, 3, 2, 1],
        [1000000000] * 100,
        [5, 0, 5, 0, 5],
    ]
    emit("2_edges", edges)

    wide = [
        [1000000000] * 100000,
        list(range(1, 100001)),
        list(range(100000, 0, -1)),
    ]
    emit("3_wide", wide)

    rng = random.Random(20260404)
    rand_cases = [
        [rng.randint(0, 1000000000) for _ in range(50000)]
        for _ in range(4)
    ]
    emit("4_random", rand_cases)

    io_cases = [
        [rng.randint(0, 1000000000) for _ in range(1000)]
        for _ in range(300)
    ]
    emit("5_io", io_cases)


if __name__ == "__main__":
    main()
