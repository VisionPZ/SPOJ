import os, random


def is_prime(x):
    if x < 2:
        return False
    for p in (2, 3, 5, 7, 11, 13, 17, 19):
        if x == p:
            return True
        if x < p:
            return False
    d, s = x - 1, 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for a in (2, 3, 5, 7):
        y = pow(a, d, x)
        if y == 1 or y == x - 1:
            continue
        for _ in range(s - 1):
            y = y * y % x
            if y == x - 1:
                break
        else:
            return False
    return True


assert [p for p in range(1, 11) if is_prime(p)] == [2, 3, 5, 7]
assert sum(1 for x in range(2, 10**5) if is_prime(x)) == 9592
assert is_prime(999999937) and not is_prime(999999938)
assert sum(1 for x in range(999900000, 10**9 + 1) if is_prime(x)) == 4832


def write(name, cases):
    body = []
    for m, n in cases:
        body += [f"{x}\n" for x in range(m, n + 1) if is_prime(x)] + ["\n"]
    with open(f"in/{name}.txt", "w") as f:
        f.write(f"{len(cases)}\n" + "".join(f"{m} {n}\n" for m, n in cases))
    with open(f"out/{name}.out", "w") as f:
        f.write("".join(body))


LO, HI, W = 1, 10**9, 100000

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write("1_sample", [(1, 10), (3, 5)])

write("2_edges", [
    (1, 1), (1, 2), (2, 2), (3, 3), (4, 4), (24, 24),
    (1, 10), (2, 3), (999999937, 999999937), (999999938, 10**9),
    (1, 100), (999500000, 999500001),
])

write("3_wide", [
    (1, 100001),
    (2, 100002),
    (999900000, 10**9),
    (500000000, 500100000),
    (999999900, 10**9),
])

rng = random.Random(20261122)
rnd = []
for _ in range(10):
    m = rng.randint(LO, HI - W)
    rnd.append((m, min(HI, m + rng.randint(0, W))))
write("4_random", rnd)

write("5_io", [(10 * k + 1, 10 * k + 100001) for k in range(10)])

print("generated", len(rnd), "random windows")
