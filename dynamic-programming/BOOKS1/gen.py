import os
import random

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE_IN = """2
9 3
100 200 300 400 500 600 700 800 900
5 4
100 100 100 100 100
"""

SAMPLE_OUT = """100 200 300 400 500 / 600 700 / 800 900
100 / 100 / 100 / 100 100
"""


def oracle(book_total, scribe_total, pages):
    """Suffix DP: best[i][j] is the smallest possible largest part sum when
    books i..book_total-1 are split into j nonempty contiguous parts."""
    inf = 10**18
    prefix = [0] * (book_total + 1)
    for idx in range(book_total):
        prefix[idx + 1] = prefix[idx] + pages[idx]
    best = [[inf] * (scribe_total + 1) for _ in range(book_total + 1)]
    best[book_total][0] = 0
    for parts in range(1, scribe_total + 1):
        for start in range(book_total - 1, -1, -1):
            row = best[start]
            value = inf
            for cut in range(start + 1, book_total - parts + 2):
                tail = best[cut][parts - 1]
                if tail == inf:
                    continue
                head = prefix[cut] - prefix[start]
                cand = head if head > tail else tail
                if cand < value:
                    value = cand
            row[parts] = value
    limit = best[0][scribe_total]
    cuts = []
    position = 0
    parts_left = scribe_total
    while parts_left > 1:
        for cut in range(position + 1, book_total - parts_left + 2):
            if prefix[cut] - prefix[position] <= limit and best[cut][parts_left - 1] <= limit:
                cuts.append(cut)
                position = cut
                parts_left -= 1
                break
        else:
            raise RuntimeError("no valid cut found")
    parts = []
    prev = 0
    for cut in cuts + [book_total]:
        parts.append(" ".join(str(v) for v in pages[prev:cut]))
        prev = cut
    return " / ".join(parts)


def write_case(name, cases_text, answers):
    with open(f"in/{name}.txt", "w") as fh:
        fh.write(cases_text)
    with open(f"out/{name}.out", "w") as fh:
        fh.write("".join(a + "\n" for a in answers))


assert oracle(9, 3, [100, 200, 300, 400, 500, 600, 700, 800, 900]) == \
    "100 200 300 400 500 / 600 700 / 800 900"
assert oracle(5, 4, [100, 100, 100, 100, 100]) == "100 / 100 / 100 / 100 100"
assert oracle(8, 4, [10, 1199, 20, 1200, 10, 10, 20, 1200]) == \
    "10 / 1199 20 / 1200 10 10 / 20 1200"
assert oracle(6, 3, [3, 3, 3, 3, 3, 3]) == "3 3 / 3 3 / 3 3"

with open("in/1_sample.txt", "w") as fh:
    fh.write(SAMPLE_IN)
with open("out/1_sample.out", "w") as fh:
    fh.write(SAMPLE_OUT)

edge_cases = [(1, 1, [7]), (3, 3, [5, 6, 7]), (4, 1, [1, 2, 3, 4]),
              (2, 2, [9999999, 9999999]), (6, 3, [3, 3, 3, 3, 3, 3]),
              (8, 4, [10, 1199, 20, 1200, 10, 10, 20, 1200]),
              (5, 5, [1, 2, 3, 4, 5]), (10, 1, [1000000, 2000000, 3000000, 4000000,
                                                5000000, 6000000, 7000000, 8000000,
                                                9000000, 9999999])]
text = f"{len(edge_cases)}\n" + "".join(
    f"{m} {k}\n{' '.join(map(str, pages))}\n" for m, k, pages in edge_cases)
write_case("2_edges", text, [oracle(m, k, p) for m, k, p in edge_cases])

rng = random.Random(11)
wide_cases = []
wide_cases.append((500, 1, [rng.randint(1, 9999999) for _ in range(500)]))
wide_cases.append((500, 500, [rng.randint(1, 9999999) for _ in range(500)]))
wide_cases.append((500, 2, [rng.randint(1, 9999999) for _ in range(500)]))
wide_cases.append((500, 3, [rng.randint(1, 9999999) for _ in range(500)]))
wide_cases.append((500, 250, [100] * 500))
text = f"{len(wide_cases)}\n" + "".join(
    f"{m} {k}\n{' '.join(map(str, pages))}\n" for m, k, pages in wide_cases)
answers = []
for m, k, pages in wide_cases:
    if k == 250:
        answers.append(" / ".join("100 100" for _ in range(250)))
    else:
        answers.append(oracle(m, k, pages))
write_case("3_wide", text, answers)

random_cases = []
for _ in range(200):
    m = rng.randint(1, 45)
    k = rng.randint(1, m)
    pages = [rng.randint(1, 9999999) for _ in range(m)]
    random_cases.append((m, k, pages))
text = f"{len(random_cases)}\n" + "".join(
    f"{m} {k}\n{' '.join(map(str, pages))}\n" for m, k, pages in random_cases)
write_case("4_random", text, [oracle(m, k, p) for m, k, p in random_cases])

io_cases = []
for _ in range(200):
    pages = [rng.randint(1, 9999999) for _ in range(500)]
    io_cases.append((500, 2, pages))
text = f"{len(io_cases)}\n" + "".join(
    f"{m} {k}\n{' '.join(map(str, pages))}\n" for m, k, pages in io_cases)
write_case("5_io", text, [oracle(m, k, p) for m, k, p in io_cases])