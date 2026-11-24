#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAX_N = (1 << 63) - 1
BASES = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)


def jacobi(top, bottom):
    top %= bottom
    sign = 1
    while top:
        while top % 2 == 0:
            top //= 2
            if bottom % 8 in (3, 5):
                sign = -sign
        top, bottom = bottom, top
        if top % 4 == 3 and bottom % 4 == 3:
            sign = -sign
        top %= bottom
    return sign if bottom == 1 else 0


def selfridge(number):
    disc = 5
    while True:
        value = jacobi(disc, number)
        if value == -1:
            return disc
        if value == 0:
            return None
        disc = -(disc + 2) if disc > 0 else -(disc - 2)


def lucas_double(state, number, param):
    u, v, q_power = state
    q = (1 - param) // 4
    u, v = u * v % number, (v * v - 2 * q_power) % number
    q_power = q_power * q_power % number
    return u, v, q_power


def strong_lucas(number):
    param = selfridge(number)
    if param is None:
        return False
    odd = number + 1
    twos = 0
    while odd % 2 == 0:
        odd //= 2
        twos += 1
    state = (1, 1, ((1 - param) // 4) % number)
    for bit in bin(odd)[3:]:
        state = lucas_double(state, number, param)
        if bit == '1':
            u, v, q_power = state
            doubled_u = (u + v) % number
            if doubled_u % 2:
                doubled_u += number
            doubled_v = (param * u + v) % number
            if doubled_v % 2:
                doubled_v += number
            state = (doubled_u // 2 % number, doubled_v // 2 % number,
                     q_power * ((1 - param) // 4) % number)
    for round_index in range(twos + 1):
        if state[0] == 0 or state[1] == 0:
            return True
        if round_index < twos:
            state = lucas_double(state, number, param)
    return False


def is_prime(number):
    if number < 2:
        return False
    for base in BASES:
        if number % base == 0:
            return number == base
    odd = number - 1
    twos = 0
    while odd % 2 == 0:
        odd //= 2
        twos += 1
    term = pow(2, odd, number)
    if term not in (1, number - 1):
        for _ in range(twos - 1):
            term = term * term % number
            if term == number - 1:
                break
        else:
            return False
    return strong_lucas(number)


def miller_oracle(number):
    if number < 2:
        return False
    for base in BASES:
        if number % base == 0:
            return number == base
    odd = number - 1
    twos = 0
    while odd % 2 == 0:
        odd //= 2
        twos += 1
    for base in BASES:
        term = pow(base, odd, number)
        if term in (1, number - 1):
            continue
        for _ in range(twos - 1):
            term = term * term % number
            if term == number - 1:
                break
        else:
            return False
    return True


def trial_prime(number):
    if number < 2:
        return False
    factor = 2
    while factor * factor <= number:
        if number % factor == 0:
            return False
        factor += 1
    return True


def oracle(text):
    tokens = text.split()
    cursor = 0
    count = int(tokens[cursor])
    cursor += 1
    answers = []
    for _ in range(count):
        number = int(tokens[cursor])
        cursor += 1
        answer = is_prime(number)
        assert answer == miller_oracle(number), ('BPSW/MR mismatch', number)
        answers.append('YES' if answer else 'NO')
    return '\n'.join(answers) + '\n'


def write(name, numbers):
    input_text = str(len(numbers)) + '\n' + ''.join(f'{number}\n' for number in numbers)
    (ROOT / 'in' / f'{name}.txt').write_text(input_text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle(input_text))


SAMPLE = [2, 3, 4, 5, 6]
SAMPLE_INPUT = '5\n2\n3\n4\n5\n6\n'
SAMPLE_OUTPUT = 'YES\nYES\nNO\nYES\nNO\n'
assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert sum(1 for number in range(2, 100000) if is_prime(number)) == 9592
assert sum(1 for number in range(2, 1000000) if is_prime(number)) == 78498
assert all(is_prime(number) == trial_prime(number) for number in range(2, 20000))
assert is_prime((1 << 61) - 1)
assert is_prime(9223372036854775783)
assert not is_prime(MAX_N)
assert not is_prime(3825123056546413051)
assert not is_prime(3215031751)

EDGES = [
    2, 3, 4, 5, 9, 25, 49, 2 * 3 * 5 * 7,
    561, 1105, 1729, 2465, 2821, 6601, 8911,
    3215031751, 25326001, 161304001, 3825123056546413051,
    2147483647, 2147483646, (1 << 61) - 1,
    9223372036854775783, 9223372036854775807,
    9223372036854775806, 9223372036854775782,
]


def primes_near(center, count, rng):
    found = []
    candidate = center
    while len(found) < count:
        candidate -= 1
        if is_prime(candidate):
            found.append(candidate)
        candidate = max(2, candidate - rng.randint(1, 97))
    return found


def build():
    write('2_edges', EDGES)

    wide = primes_near(MAX_N, 250, random.Random(1))
    wide += [MAX_N - 1000 + k for k in range(250)]
    write('3_wide', wide)

    rng = random.Random(20261124)
    random_values = []
    for _ in range(250):
        bit_width = rng.randint(2, 63)
        random_values.append(rng.randrange(2, min(1 << bit_width, MAX_N + 1)))
    for _ in range(250):
        first = rng.randrange(2**30, 2**31)
        second = rng.randrange(2**30, 2**31)
        random_values.append(first * second)
    write('4_random', random_values)

    io_values = primes_near(MAX_N, 500, random.Random(7))
    write('5_io', io_values)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
write('1_sample', SAMPLE)
assert (ROOT / 'in' / '1_sample.txt').read_text() == SAMPLE_INPUT
assert (ROOT / 'out' / '1_sample.out').read_text() == SAMPLE_OUTPUT
build()
