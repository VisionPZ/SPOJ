#!/usr/bin/env python3
import random
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE = "80 20 20 10 10\n105 10 25 05 05\n"
SAMPLE_OUT = "YES\nNO\n"


def oracle(text):
    values = [int(token) for token in re.findall(r"\d+", text)]
    values += [0] * ((-len(values)) % 5)
    answers = []
    for case_start in range(0, len(values), 5):
        contestant_count = values[case_start]
        awarded_count = sum(values[case_start + 1:case_start + 5])
        threshold = (contestant_count + 1) // 2
        answers.append("YES" if awarded_count >= threshold else "NO")
    return "".join(answer + "\n" for answer in answers)


assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("10 5 0 0 0\n") == "YES\n"
assert oracle("11 5 0 0 0\n") == "NO\n"
assert oracle("0 0 0 0 0\n") == "YES\n"
assert oracle("2 1 0 0 0\n") == "YES\n"


def write(name, cases):
    input_text = "".join(" ".join(str(value) for value in case) + "\n"
                         for case in cases)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(input_text))


def build():
    write("2_edges", [(0, 0, 0, 0, 0), (1, 0, 0, 0, 0), (2, 1, 0, 0, 0),
                      (3, 1, 0, 0, 0), (100, 50, 0, 0, 0), (101, 50, 0, 0, 0),
                      (200, 0, "05", 95, 5), (201, 0, 0, 100, 0)])
    write("3_wide", [(10**9, 5 * 10**8, 0, 0, 0),
                     (10**9, 5 * 10**8 - 1, 0, 0, 0)] * 10)
    rng = random.Random(20261125)
    write("4_random", [(rng.randint(1, 10**9),
                        rng.randint(0, 10**8), rng.randint(0, 10**8),
                        rng.randint(0, 10**8), rng.randint(0, 10**8))
                       for _ in range(300)])
    write("5_io", [(rng.randint(1, 1000), rng.randint(0, 500),
                    rng.randint(0, 500), rng.randint(0, 500), rng.randint(0, 500))
                   for _ in range(20000)])


def worked_example():
    contestant_count = 80
    prizes = [20, 20, 10, 10]
    awarded = sum(prizes)
    threshold = (contestant_count + 1) // 2
    print(f"contestants: {contestant_count}")
    print(f"prizes: {prizes}")
    print(f"awarded: {awarded}, threshold: {threshold}")
    print(f"verdict: {'YES' if awarded >= threshold else 'NO'}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [(80, 20, 20, 10, 10), (105, 10, 25, 5, 5)])
    build()
    if "--trace" in sys.argv:
        worked_example()


if __name__ == "__main__":
    main()
