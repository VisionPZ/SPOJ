#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def primes_by_trial(count):
    found = [2]
    candidate = 3
    while len(found) < count:
        root = int(candidate ** 0.5)
        is_prime = True
        for prime in found:
            if prime > root:
                break
            if candidate % prime == 0:
                is_prime = False
                break
        if is_prime:
            found.append(candidate)
        candidate += 2
    return found


PRIMES = primes_by_trial(3 * 10000)
TERMS = [PRIMES[3 * index] * PRIMES[3 * index + 1] + PRIMES[3 * index + 2]
         for index in range(10000)]


def oracle(counts):
    return "".join(" ".join(str(term) for term in TERMS[:count]) + "\n"
                   for count in counts)


SAMPLE = [1, 2, 3]
SAMPLE_OUT = "11\n11 90\n11 90 346\n"

assert oracle(SAMPLE) == SAMPLE_OUT
assert TERMS[0] == 11 and TERMS[1] == 90 and TERMS[2] == 346
assert TERMS[3] == 936 and TERMS[4] == 1810
assert PRIMES[0] == 2 and PRIMES[9] == 29 and PRIMES[29996] == 350293


def write(name, counts):
    input_text = str(len(counts)) + "\n" + "".join(f"{count}\n" for count in counts)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(counts))


write("1_sample", SAMPLE)
write("2_edges", [1, 1, 2, 2, 3, 1, 9999])

random.seed(2026)
write("3_wide", [random.randint(1, 9999) for _ in range(50)])
write("4_random", [random.randint(1, 9999) for _ in range(100)])
write("5_io", [9999 for _ in range(20)])
