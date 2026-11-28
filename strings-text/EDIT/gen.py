import os
import random


def oracle(word):
    dp_upper = 0
    dp_lower = 0
    for ch in word:
        cost_upper = 0 if ch.isupper() else 1
        cost_lower = 0 if ch.islower() else 1
        next_upper = dp_lower + cost_upper
        next_lower = dp_upper + cost_lower
        dp_upper, dp_lower = next_upper, next_lower
    return min(dp_upper, dp_lower)


assert oracle("AaAaB") == 0
assert oracle("ABaa") == 2
assert oracle("a") == 0
assert oracle("AAAA") == 2


def emit(name, lines):
    with open(os.path.join("in", f"{name}.txt"), "w", encoding="utf-8") as fin:
        fin.write("\n".join(lines) + "\n")
    answers = [str(oracle(line)) for line in lines]
    with open(os.path.join("out", f"{name}.out"), "w", encoding="utf-8") as fout:
        fout.write("\n".join(answers) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", ["AaAaB", "ABaa", "a"])

    edges = [
        "a",
        "Z",
        "Aa",
        "aA",
        "AA",
        "zz",
        "AaAaAbB",
        "aBaCdEf",
        "A" * 1000,
        "z" * 1000,
        "Aa" * 500,
        "aA" * 500,
        "A" * 500 + "a" * 500,
    ]
    emit("2_edges", edges)

    rng = random.Random(20260101)
    letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

    wide = [
        "".join(rng.choice(letters) for _ in range(1000))
        for _ in range(400)
    ]
    emit("3_wide", wide)

    rand_lines = [
        "".join(rng.choice(letters) for _ in range(rng.randint(1, 1000)))
        for _ in range(1000)
    ]
    emit("4_random", rand_lines)

    io_lines = [
        "".join(rng.choice(letters) for _ in range(rng.randint(50, 100)))
        for _ in range(25000)
    ]
    emit("5_io", io_lines)


if __name__ == "__main__":
    main()
