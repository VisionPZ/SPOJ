import os
import random


def oracle_states(coins):
    take = 0
    skip = 0
    for c in coins:
        new_take = skip + c
        new_skip = max(take, skip)
        take, skip = new_take, new_skip
    return max(take, skip)


def brute_coins(coins):
    n = len(coins)
    best = 0
    for mask in range(1 << n):
        if mask & (mask >> 1):
            continue
        total = 0
        for i in range(n):
            if (mask >> i) & 1:
                total += coins[i]
        if total > best:
            best = total
    return best


assert oracle_states([1, 2, 3, 4, 5]) == 9
assert oracle_states([10]) == 10
assert oracle_states([]) == 0
for _trial in range(20):
    _rng = random.Random(300 + _trial)
    _arr = [_rng.randint(0, 50) for _ in range(14)]
    assert oracle_states(_arr) == brute_coins(_arr)


def emit(name, cases):
    in_lines = [str(len(cases))]
    out_lines = []
    for idx, coins in enumerate(cases, start=1):
        in_lines.append(str(len(coins)))
        if coins:
            in_lines.append(" ".join(str(c) for c in coins))
        else:
            in_lines.append("")
        out_lines.append(f"Case {idx}: {oracle_states(coins)}")
    with open(os.path.join("in", f"{name}.txt"), "w", encoding="utf-8") as fin:
        fin.write("\n".join(in_lines) + "\n")
    with open(os.path.join("out", f"{name}.out"), "w", encoding="utf-8") as fout:
        fout.write("\n".join(out_lines) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", [[1, 2, 3, 4, 5], [10]])

    edges = [
        [],
        [0],
        [1000000000],
        [0, 0, 0, 0],
        [1000000000, 1000000000],
        [5, 10, 5],
        [10, 1, 1, 10],
        [1000000000] * 10000,
    ]
    emit("2_edges", edges)

    rng = random.Random(20260505)
    wide = [
        [rng.randint(0, 1000000000) for _ in range(10000)]
        for _ in range(25)
    ]
    emit("3_wide", wide)

    rand_cases = [
        [rng.randint(0, 1000000000) for _ in range(rng.randint(0, 10000))]
        for _ in range(50)
    ]
    emit("4_random", rand_cases)

    io_cases = [
        [rng.randint(0, 1000000000) for _ in range(500)]
        for _ in range(1000)
    ]
    emit("5_io", io_cases)


if __name__ == "__main__":
    main()
