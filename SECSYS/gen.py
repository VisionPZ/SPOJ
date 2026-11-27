import os
import random


def oracle(vault_count, start_vault, step_count, coeffs, password):
    _ = start_vault
    val = sum(int(ch) for ch in password)
    vault = val % vault_count
    for _ in range(step_count):
        a, b = coeffs[vault]
        val = a * val + b
        vault = val % vault_count
    return vault, val


assert oracle(6, 3, 2, [(10, 25), (4, 45), (10, 99), (8, 7), (0, 0), (1, 81)], "908710") == (1, 625)
assert oracle(10, 5, 8, [(100, 100)] * 10, "999999") == (0, 550101010101010100)


def emit(name, cases):
    in_lines = []
    out_lines = []
    for vault_count, start_vault, step_count, coeffs, password in cases:
        in_lines.append(f"{vault_count} {start_vault} {step_count}")
        for a, b in coeffs:
            in_lines.append(f"{a} {b}")
        in_lines.append(password)
        final_vault, final_val = oracle(vault_count, start_vault, step_count, coeffs, password)
        out_lines.append(f"{final_vault} {final_val}")
    in_lines.append("0 0 0")
    with open(os.path.join("in", f"{name}.txt"), "w", encoding="utf-8") as fin:
        fin.write("\n".join(in_lines) + "\n")
    with open(os.path.join("out", f"{name}.out"), "w", encoding="utf-8") as fout:
        fout.write("\n".join(out_lines) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    sample = [
        (6, 3, 2, [(10, 25), (4, 45), (10, 99), (8, 7), (0, 0), (1, 81)], "908710"),
        (10, 5, 8, [(100, 100)] * 10, "999999"),
    ]
    emit("1_sample", sample)

    edges = [
        (3, 0, 1, [(0, 0), (0, 0), (0, 0)], "000000"),
        (3, 2, 1, [(1, 0), (1, 1), (0, 5)], "000001"),
        (10, 0, 8, [(100, 100)] * 10, "999999"),
        (10, 9, 1, [(0, 100)] * 10, "000000"),
        (4, 1, 2, [(100, 0), (0, 100), (50, 50), (1, 99)], "090909"),
    ]
    emit("2_edges", edges)

    rng = random.Random(20260202)

    wide = []
    for _ in range(1000):
        coeffs = [(rng.randint(80, 100), rng.randint(80, 100)) for _ in range(10)]
        pwd = "".join(str(rng.randint(0, 9)) for _ in range(6))
        wide.append((10, rng.randint(0, 9), 8, coeffs, pwd))
    emit("3_wide", wide)

    rand_cases = []
    for _ in range(2000):
        c = rng.randint(3, 10)
        p = rng.randint(0, c - 1)
        steps = rng.randint(1, c - 2)
        coeffs = [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(c)]
        pwd = "".join(str(rng.randint(0, 9)) for _ in range(6))
        rand_cases.append((c, p, steps, coeffs, pwd))
    emit("4_random", rand_cases)

    io_cases = []
    for _ in range(10000):
        c = rng.randint(3, 10)
        p = rng.randint(0, c - 1)
        steps = rng.randint(1, c - 2)
        coeffs = [(rng.randint(0, 100), rng.randint(0, 100)) for _ in range(c)]
        pwd = "".join(str(rng.randint(0, 9)) for _ in range(6))
        io_cases.append((c, p, steps, coeffs, pwd))
    emit("5_io", io_cases)


if __name__ == "__main__":
    main()
