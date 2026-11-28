#!/usr/bin/env python3
import random
from math import gcd
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def extended_gcd(a, b):
    if b == 0:
        return (a, 1, 0)
    quotient, remainder = divmod(a, b)
    common, left, right = extended_gcd(b, remainder)
    return (common, right, left - quotient * right)


def modular_inverse(value, modulus):
    if modulus == 1:
        return 0
    common, left, _ = extended_gcd(value, modulus)
    assert common == 1
    return left % modulus


def brute(divisor):
    length = 1
    while True:
        if length == 1:
            candidates = ["1"]
        else:
            width = length - 1
            candidates = (
                "1" + format(mask, "0" + str(width) + "b")
                for mask in range(1 << width)
            )
        for candidate in candidates:
            if int(candidate) % divisor == 0:
                return candidate
        length += 1
        assert length < 20


def oracle(divisor):
    if divisor == 1:
        return "1"
    reachable = {1 % divisor}
    layers = [reachable]
    while 0 not in reachable:
        reachable = {(rem * 10) % divisor for rem in reachable} | {
            (rem * 10 + 1) % divisor for rem in reachable
        }
        layers.append(reachable)
        assert len(layers) < 100
    layer_count = len(layers)
    usable = [set() for _ in range(layer_count)]
    usable[-1] = {0}
    common = gcd(10, divisor)
    reduced_modulus = divisor // common
    inverse = modular_inverse(10 // common, reduced_modulus)
    for layer in range(layer_count - 2, -1, -1):
        target = usable[layer + 1]
        previous = set()
        for remainder in target:
            for digit in (0, 1):
                difference = remainder - digit
                if difference % common:
                    continue
                base = (difference // common) * inverse
                start = base % reduced_modulus if reduced_modulus > 1 else 0
                for offset in range(common):
                    previous.add(start + offset * reduced_modulus)
        usable[layer] = previous
    digits = ["1"]
    remainder = 1 % divisor
    for layer in range(1, layer_count):
        for digit in (0, 1):
            candidate = (remainder * 10 + digit) % divisor
            if candidate in usable[layer]:
                digits.append(str(digit))
                remainder = candidate
                break
        else:
            raise AssertionError("no usable digit")
    return "".join(digits)


def write(name, divisors):
    input_text = str(len(divisors)) + "\n" + "".join(
        f"{divisor}\n" for divisor in divisors
    )
    answers = []
    seen = {}
    for divisor in divisors:
        if divisor not in seen:
            seen[divisor] = oracle(divisor)
        answers.append(seen[divisor])
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text("\n".join(answers) + "\n")


assert oracle(1) == "1"
assert oracle(8) == "1000"
assert oracle(17) == "11101"
assert oracle(11011) == "11011"
assert all(oracle(value) == brute(value) for value in range(1, 81))
assert len(oracle(9999)) == 36
assert len(oracle(19998)) == 37

LONG = [19998, 10989, 9999, 15984, 13986, 11988, 7992, 19980, 19512, 18981]

(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)

write("1_sample", [17, 11011, 17])
write("2_edges", [1, 2, 5, 8, 17, 11011, 9999, 19998, 1, 20000, 3, 7])
write("3_wide", [19999, 19998, 19997, 20000, 10000, 9999, 15984, 10989])

rng = random.Random(20261125)
pool = [rng.randint(1, 20000) for _ in range(60)]
write("4_random", [rng.choice(pool) for _ in range(200)])

io_pool = LONG + [rng.randint(1, 20000) for _ in range(30)]
write("5_io", [io_pool[index % len(io_pool)] for index in range(1000)])

print("generated five test pairs")
