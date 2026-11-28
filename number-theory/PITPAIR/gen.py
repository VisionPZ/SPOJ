#!/usr/bin/env python3
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

PRIMES = []
candidatePrime = 2
while len(PRIMES) < 12:
    if candidatePrime % 4 == 1 and all(candidatePrime % divisor for divisor in range(2, math.isqrt(candidatePrime) + 1)):
        PRIMES.append(candidatePrime)
    candidatePrime += 1

LIMIT = (1 << 63) - 1
MAX_COUNT = 2000

def build_radius_table():
    radii = {}
    factors = {}
    def explore(index, maximumExponent, product, exponents):
        representations = 1
        for exponent in exponents:
            representations *= 2 * exponent + 1
        triangleCount = (representations - 1) // 2
        if 1 <= triangleCount <= MAX_COUNT and (triangleCount not in radii or product < radii[triangleCount]):
            radii[triangleCount] = product
            factors[triangleCount] = exponents
        if index == len(PRIMES):
            return
        for exponent in range(1, maximumExponent + 1):
            nextProduct = product
            for _ in range(exponent):
                if nextProduct > LIMIT // PRIMES[index]:
                    return
                nextProduct *= PRIMES[index]
            explore(index + 1, exponent, nextProduct, exponents + (exponent,))
    explore(0, MAX_COUNT, 1, ())
    return radii, factors

RADII, FACTORS = build_radius_table()

def hensel_root(baseRoot, prime, power):
    current = baseRoot
    for level in range(1, power):
        inverse = pow(2 * current, -1, prime)
        correction = (-(current * current + 1) // (prime ** level) * inverse) % prime
        current = (current + correction * prime ** level) % prime ** (level + 1)
    return current

def combine_congruences(leftValue, leftModulus, rightValue, rightModulus):
    common = math.gcd(leftModulus, rightModulus)
    combinedModulus = leftModulus // common * rightModulus
    scale = (((rightValue - leftValue) // common) * pow(leftModulus // common, -1, rightModulus // common)) % (rightModulus // common)
    return (leftValue + leftModulus * scale) % combinedModulus, combinedModulus

def primitive_pairs(hypotenuse, exponents):
    roots = [(0, 1)]
    for prime, exponent in zip(PRIMES, exponents):
        if exponent == 0:
            continue
        baseRoot = next(root for root in range(1, prime) if root * root % prime == prime - 1)
        root = hensel_root(baseRoot, prime, exponent)
        modulus = prime ** exponent
        roots = [combine_congruences(first, firstModulus, second, modulus) for first, firstModulus in roots for second in (root, modulus - root)]
    pairs = set()
    for residue, _ in roots:
        larger, smaller = hypotenuse, residue
        while smaller * smaller > hypotenuse:
            larger, smaller = smaller, larger % smaller
        first = smaller
        secondSquared = hypotenuse - first * first
        second = math.isqrt(secondSquared)
        if second * second != secondSquared:
            raise ValueError("Cornacchia failed")
        if first > 0 and second > 0:
            pairs.add((min(first, second), max(first, second)))
    return pairs

LEG_CACHE = {}

def oracle_legs(triangleCount):
    if triangleCount in LEG_CACHE:
        return LEG_CACHE[triangleCount]
    radius = RADII[triangleCount]
    storedExponents = FACTORS[triangleCount]
    exponentValues = tuple(storedExponents) + (0,) * (len(PRIMES) - len(storedExponents))
    shorterLegs = set()
    def walk(primeIndex, primitiveHypotenuse, chosen):
        if primeIndex == len(PRIMES):
            if primitiveHypotenuse == 1:
                return
            scale = radius // primitiveHypotenuse
            selectedExponents = [chosen.get(prime, 0) for prime in PRIMES]
            for small, large in primitive_pairs(primitiveHypotenuse, selectedExponents):
                shorterLegs.add(min(scale * (large * large - small * small), scale * 2 * small * large))
            return
        prime = PRIMES[primeIndex]
        for exponent in range(exponentValues[primeIndex] + 1):
            if exponent:
                chosen[prime] = exponent
            walk(primeIndex + 1, primitiveHypotenuse * prime ** exponent, chosen)
            if exponent:
                del chosen[prime]
    walk(0, 1, {})
    result = sorted(shorterLegs)
    if len(result) != triangleCount:
        raise ValueError("oracle leg count mismatch")
    LEG_CACHE[triangleCount] = result
    return result

def brute_legs(radius):
    result = set()
    for primitiveHypotenuse in range(5, radius + 1):
        if radius % primitiveHypotenuse:
            continue
        for large in range(1, math.isqrt(primitiveHypotenuse) + 1):
            remainder = primitiveHypotenuse - large * large
            small = math.isqrt(remainder)
            if small < 1 or large <= small:
                continue
            if large * large + small * small != primitiveHypotenuse:
                continue
            if math.gcd(large, small) != 1 or (large % 2) == (small % 2):
                continue
            scale = radius // primitiveHypotenuse
            result.add(min(scale * (large * large - small * small), scale * 2 * large * small))
    return sorted(result)

def write_case(name, triangleCounts):
    inputText = str(len(triangleCounts)) + "\n" + "".join(f"{count}\n" for count in triangleCounts)
    outputParts = []
    for count in triangleCounts:
        outputParts.append(f"{RADII[count]}\n")
        outputParts.extend(f"{leg}\n" for leg in oracle_legs(count))
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "in" / f"{name}.txt").write_text(inputText)
    (ROOT / "out" / f"{name}.out").write_text("".join(outputParts))

OEIS_PREFIX = [5, 25, 125, 65, 3125, 15625, 325, 390625, 1953125, 1625, 48828125, 4225, 1105, 6103515625, 30517578125, 40625, 21125, 3814697265625, 203125, 95367431640625, 476837158203125, 5525, 11920928955078125, 274625, 5078125, 1490116119384765625, 528125, 25390625]

assert [RADII[1], RADII[2]] == [5, 25] and oracle_legs(1) == [3] and oracle_legs(2) == [7, 15]
assert all(RADII[index + 1] == value for index, value in enumerate(OEIS_PREFIX))
assert all(oracle_legs(count) == brute_legs(RADII[count]) for count in (1, 2, 3, 4, 7, 8, 13, 22))
assert RADII[31] == 27625 and len(oracle_legs(31)) == 31

validCounts = sorted(RADII)
write_case("1_sample", [1, 2])
write_case("2_edges", [count for count in (1, 2, 3, 4, 5, 7, 8, 13, 22, 23, 24, 28, 31, 1996) if count in RADII])
write_case("3_wide", validCounts[-7:] + [1, 2, 3])
randomGenerator = random.Random(20261125)
write_case("4_random", [validCounts[randomGenerator.randrange(len(validCounts))] for _ in range(100)])
write_case("5_io", [1996] * 100)

print("generated oracle cases up to count", max(RADII))
