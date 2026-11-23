import os
import random

CASE_COUNT = 10
LIMIT_DIGITS = 101
assert CASE_COUNT == 10


def oracle(total, more):
    assert (total + more) % 2 == 0
    klaudia = (total + more) // 2
    natalia = (total - more) // 2
    assert total == klaudia + natalia and klaudia - natalia == more
    return "%d\n%d\n" % (klaudia, natalia)


def write(name, cases):
    body = "".join("%d\n%d\n" % pair for pair in cases)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write("".join(oracle(*pair) for pair in cases))


def even_big(rng, digits):
    low = 10 ** (digits - 1)
    high = 10 ** digits - 1
    total = rng.randrange(low, high)
    more = rng.randrange(1, total + 1)
    if (total + more) % 2:
        more = more + 1 if more + 1 <= total else more - 1
    if more < 1:
        more = 1
        total = total + 1
    return total, more


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

sample = [(10, 2)]
big = 10 ** 100
sample += [(big, 2), (big - 1, big - 3), (1, 1)]
sample += [(10 ** 50, 2), (10 ** 50, 10 ** 50), (10 ** 50, 10), (10 ** 50, 99998)]
sample += [(10 ** 49 * 3, 10 ** 49), (2, 2)]
write("1_sample", sample)

edges = [(10 ** 100, 10 ** 100), (999999999999999999999999999999999999999999999999,
         999999999999999999999999999999999999999999999997)] + [(10, 2)] * 9
write("2_edges", edges)

wide = [(10 ** 100 - 2, 10 ** 100 - 2)] + [(even_big(random.Random(11), 101)) for _ in range(9)]
write("3_wide", wide)

rng = random.Random(7)
cases = [even_big(rng, 101) for _ in range(CASE_COUNT)]
cases += [even_big(rng, 101) for _ in range(CASE_COUNT)]
cases += [even_big(rng, 101) for _ in range(CASE_COUNT)]
write("4_random", cases)

rng2 = random.Random(101)
write("5_io", [even_big(rng2, 101) for _ in range(20000)])
