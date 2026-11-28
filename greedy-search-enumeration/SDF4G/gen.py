#!/usr/bin/env python3
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def is_jumping(value):
    digits = str(value)
    return all(abs(int(a) - int(b)) == 1 for a, b in zip(digits, digits[1:]))


def brute(limit):
    kept = [str(value) for value in range(limit + 1) if is_jumping(value)]
    return " ".join(kept) + " \nAilafyuU\n"


def oracle(text):
    limit = int(text.split()[0])
    out = ["0"]
    queue = deque(range(1, min(limit, 9) + 1))
    while queue:
        cur = queue.popleft()
        out.append(str(cur))
        last = cur % 10
        if last > 0:
            nxt = cur * 10 + last - 1
            if nxt <= limit:
                queue.append(nxt)
        if last < 9:
            nxt = cur * 10 + last + 1
            if nxt <= limit:
                queue.append(nxt)
    return " ".join(out) + " \nAilafyuU\n"


SAMPLE = "15\n"
SAMPLE_OUT = "0 1 2 3 4 5 6 7 8 9 10 12 \nAilafyuU\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("3\n") == "0 1 2 3 \nAilafyuU\n"
for probe in (0, 1, 9, 10, 11, 12, 22, 101, 500, 3000):
    assert oracle(f"{probe}\n") == brute(probe)


def write(name, limit):
    text = f"{limit}\n"
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    write("2_edges", 0)
    write("3_wide", 10**9)
    write("4_random", 987654321)
    write("5_io", 10**11)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
