import math
import os
import random


def direct_factorial(number, prime):
    if number >= prime:
        return 0
    result = 1
    for value in range(2, number + 1):
        result = result * value % prime
    return result


def block_factorial(number, prime):
    if number >= prime:
        return 0
    block = math.isqrt(prime - 1) + 1
    quotient = number // block
    remainder = number % block
    if quotient == 0:
        return direct_factorial(number, prime)
    coefficients = [1]
    for offset in range(1, block + 1):
        following = [0] * (len(coefficients) + 1)
        for degree, coefficient in enumerate(coefficients):
            following[degree] = (following[degree] + coefficient * offset) % prime
            following[degree + 1] = (following[degree + 1] + coefficient) % prime
        coefficients = following
    answer = 1
    for step in range(quotient):
        point = step * block % prime
        value = 0
        for coefficient in reversed(coefficients):
            value = (value * point + coefficient) % prime
        answer = answer * value % prime
    for offset in range(1, remainder + 1):
        answer = answer * (quotient * block + offset) % prime
    return answer


def oracle(number, prime):
    assert prime >= 2
    if number >= prime:
        return 0
    if math.isqrt(prime - 1) + 1 <= 2500:
        return block_factorial(number, prime)
    if number <= 2000000:
        return direct_factorial(number, prime)
    raise AssertionError(("no independent oracle for", number, prime))


SAMPLE = [(1000, 9907), (1000000, 9999907), (10000000000, 99999999907)]
SAMPLE_OUT = [4494, 3354924, 40583077821]
assert oracle(SAMPLE[0][0], SAMPLE[0][1]) == SAMPLE_OUT[0]
assert oracle(SAMPLE[1][0], SAMPLE[1][1]) == SAMPLE_OUT[1]


def emit(name, cases, answers):
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)
    with open(os.path.join("in", name + ".txt"), "w", encoding="utf-8") as stream:
        stream.write(str(len(cases)) + "\n")
        stream.write("\n".join(f"{number} {prime}" for number, prime in cases) + "\n")
    with open(os.path.join("out", name + ".out"), "w", encoding="utf-8") as stream:
        stream.write(" ".join(str(answer) for answer in answers) + "\n")


def main():
    os.makedirs("in", exist_ok=True)
    os.makedirs("out", exist_ok=True)

    emit("1_sample", SAMPLE, SAMPLE_OUT)

    edges = [(0, 2), (1, 2), (2, 2), (1, 3), (4, 5), (5, 5), (6, 5), (0, 101), (100, 101)]
    emit("2_edges", edges, [oracle(number, prime) for number, prime in edges])

    rng = random.Random(20261129)
    limit = 300000
    composite = bytearray(limit)
    for divisor in range(2, math.isqrt(limit - 1) + 1):
        if not composite[divisor]:
            composite[divisor * divisor::divisor] = b"\x01" * len(composite[divisor * divisor::divisor])
    primes = [candidate for candidate in range(2, limit) if not composite[candidate]]
    wide = [(prime - 1, prime) for prime in primes[-5:]]
    emit("3_wide", wide, [oracle(number, prime) for number, prime in wide])

    random_cases = []
    for _ in range(60):
        prime = rng.choice(primes)
        number = rng.randint(0, 2 * prime)
        random_cases.append((number, prime))
    emit("4_random", random_cases, [oracle(number, prime) for number, prime in random_cases])

    heavy = [(10000000000, 99999999907), (1000000, 9999907)]
    heavy_answers = [40583077821, 3354924]
    emit("6_heavy", heavy, heavy_answers)

    io_cases = [(rng.randint(0, 5), 2) for _ in range(100000)]
    emit("5_io", io_cases, [oracle(number, prime) for number, prime in io_cases])


if __name__ == "__main__":
    main()
