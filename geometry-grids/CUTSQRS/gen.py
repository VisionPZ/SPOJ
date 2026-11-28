#!/usr/bin/env python3
import random
from decimal import Decimal, getcontext
from functools import lru_cache

getcontext().prec = 100
LOG_TEN_TWO = Decimal(2).ln() / Decimal(10).ln()


@lru_cache(None)
def brute_sequences(shorter, longer):
    if shorter > longer:
        shorter, longer = longer, shorter
    quotient = longer // shorter
    remainder = longer % shorter
    total = 0
    odd_length = 0
    even_length = 0
    for cut_count in range(1, quotient + 1):
        leftover = longer - cut_count * shorter
        if leftover == 0:
            total += 1
            odd_length += 1
        else:
            if cut_count == quotient:
                next_short, next_long = remainder, shorter
            else:
                next_short, next_long = shorter, leftover
            sub_total, sub_odd, sub_even, _ = brute_sequences(next_short, next_long)
            total += sub_total
            odd_length += sub_even
            even_length += sub_odd
    first_player_wins = False
    for cut_count in range(1, quotient + 1):
        leftover = longer - cut_count * shorter
        if leftover == 0:
            first_player_wins = True
            break
        if cut_count == quotient:
            next_short, next_long = remainder, shorter
        else:
            next_short, next_long = shorter, leftover
        if not brute_sequences(next_short, next_long)[3]:
            first_player_wins = True
            break
    return total, odd_length, even_length, first_player_wins


def euclid_quotients(side_short, side_long):
    quotients = []
    while side_short != 0:
        quotients.append(side_long // side_short)
        side_short, side_long = side_long % side_short, side_short
    return quotients


def digits_of_power_of_two(exponent):
    return int(Decimal(exponent) * LOG_TEN_TWO) + 1


def oracle(side_short, side_long):
    quotients = euclid_quotients(side_short, side_long)
    exponent = sum(quotient - 1 for quotient in quotients)
    if exponent == 0:
        return 7
    leading_ones = 0
    for quotient in quotients:
        if quotient == 1:
            leading_ones += 1
        else:
            break
    word_length = 5 if leading_ones % 2 == 0 else 6
    return digits_of_power_of_two(exponent) + digits_of_power_of_two(exponent - 1) + word_length


def oracle_brute(side_short, side_long):
    total, odd_length, _, first_player_wins = brute_sequences(side_short, side_long)
    return len(str(total)) + len(str(odd_length)) + (5 if first_player_wins else 6)


assert digits_of_power_of_two(10) == 4
assert digits_of_power_of_two(1000) == 302
assert oracle(1, 1) == 7
assert oracle(2, 3) == 8
for small_short in range(1, 26):
    for small_long in range(small_short, 26):
        expected_total, expected_odd, _, _ = brute_sequences(small_short, small_long)
        exponent = sum(quotient - 1 for quotient in euclid_quotients(small_short, small_long))
        assert expected_total == 2 ** exponent
        assert expected_odd == (2 ** (exponent - 1) if exponent else 1)
        assert oracle(small_short, small_long) == oracle_brute(small_short, small_long)


def write_case(name, pairs):
    with open('in/' + name + '.txt', 'w') as input_file:
        input_file.write(str(len(pairs)) + '\n')
        for side_short, side_long in pairs:
            input_file.write(str(side_short) + ' ' + str(side_long) + '\n')
    with open('out/' + name + '.out', 'w') as output_file:
        for side_short, side_long in pairs:
            output_file.write(str(oracle(side_short, side_long)) + '\n')


write_case('1_sample', [(1, 1), (2, 3)])
write_case('2_edges', [
    (1, 1), (1, 2), (2, 2), (7, 8), (5, 8), (8, 13),
    (2, 3), (3, 4), (500000000, 1000000000),
    (1000000000, 1000000000), (999999937, 1000000000),
])
write_case('3_wide', [
    (1, 1000000000), (1, 999999999), (2, 1000000000),
    (43, 100), (123456789, 987654321), (999999937, 1000000000),
    (1000000000, 1000000000), (500000000, 999999999),
])
rng = random.Random(20261124)
random_pairs = []
for _ in range(200):
    first = rng.randint(1, 1000000000)
    second = rng.randint(1, 1000000000)
    random_pairs.append((min(first, second), max(first, second)))
write_case('4_random', random_pairs)
io_pairs = []
for index in range(10000):
    if index % 3 == 0:
        io_pairs.append((1, rng.randint(500000000, 1000000000)))
    elif index % 3 == 1:
        first = rng.randint(1, 1000000000)
        second = rng.randint(1, 1000000000)
        io_pairs.append((min(first, second), max(first, second)))
    else:
        io_pairs.append((rng.randint(400000000, 600000000), rng.randint(800000000, 1000000000)))
write_case('5_io', io_pairs)
stress_pairs = []
for index in range(200000):
    if index % 2 == 0:
        stress_pairs.append((1, rng.randint(1, 1000000000)))
    else:
        first = rng.randint(1, 1000000000)
        second = rng.randint(1, 1000000000)
        stress_pairs.append((min(first, second), max(first, second)))
with open('/tmp/CUTSQRS_big.txt', 'w') as stress_file:
    stress_file.write(str(len(stress_pairs)) + '\n')
    for side_short, side_long in stress_pairs:
        stress_file.write(str(side_short) + ' ' + str(side_long) + '\n')
