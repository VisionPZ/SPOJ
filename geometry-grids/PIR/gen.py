#!/usr/bin/env python3
import random
from decimal import Decimal, localcontext
from itertools import permutations


def permutation_sign(order):
    inversions = 0
    for left in range(len(order)):
        for right in range(left + 1, len(order)):
            if order[left] > order[right]:
                inversions += 1
    return -1 if inversions % 2 else 1


FIVE_PERMUTATIONS = [(order, permutation_sign(order)) for order in permutations(range(5))]


def determinant_five(matrix):
    total = 0
    for order, sign in FIVE_PERMUTATIONS:
        product = 1
        for row, column in enumerate(order):
            product *= matrix[row][column]
        total += sign * product
    return total


def cayley_menger(edges):
    edge_ab, edge_ac, edge_ad, edge_bc, edge_bd, edge_cd = edges
    ab2, ac2, ad2, bc2, bd2, cd2 = [value * value for value in edges]
    matrix = [
        [0, 1, 1, 1, 1],
        [1, 0, ab2, ac2, ad2],
        [1, ab2, 0, bc2, bd2],
        [1, ac2, bc2, 0, cd2],
        [1, ad2, bd2, cd2, 0],
    ]
    return determinant_five(matrix)


def gram_value(edges):
    edge_ab, edge_ac, edge_ad, edge_bc, edge_bd, edge_cd = edges
    ad2, bd2, cd2 = edge_ad * edge_ad, edge_bd * edge_bd, edge_cd * edge_cd
    dot_ab = ad2 + bd2 - edge_ab * edge_ab
    dot_ac = ad2 + cd2 - edge_ac * edge_ac
    dot_bc = bd2 + cd2 - edge_bc * edge_bc
    return (4 * ad2 * bd2 * cd2 + dot_ab * dot_ac * dot_bc
            - ad2 * dot_bc * dot_bc - bd2 * dot_ac * dot_ac - cd2 * dot_ab * dot_ab)


def faces_ok(edges):
    edge_ab, edge_ac, edge_ad, edge_bc, edge_bd, edge_cd = edges
    for first, second, third in ((edge_ab, edge_ac, edge_bc),
                                 (edge_ab, edge_ad, edge_bd),
                                 (edge_ac, edge_ad, edge_cd),
                                 (edge_bc, edge_bd, edge_cd)):
        if first + second <= third or first + third <= second or second + third <= first:
            return False
    return True


def is_valid(edges):
    return min(edges) >= 1 and max(edges) <= 1000 and faces_ok(edges) and gram_value(edges) > 0


def oracle_volume(edges):
    determinant = cayley_menger(edges)
    assert determinant >= 0, edges
    assert determinant == 2 * gram_value(edges), edges
    with localcontext() as context:
        context.prec = 70
        volume = (Decimal(determinant) / Decimal(288)).sqrt()
    return volume


def format_volume(edges):
    return format(oracle_volume(edges), '.4f')


assert cayley_menger((1, 1, 1, 1, 1, 1)) == 4
assert cayley_menger((2, 2, 2, 2, 2, 2)) == 256
assert cayley_menger((1000, 1000, 1000, 1000, 1000, 1000)) == 4 * 10**18
assert cayley_menger((3, 5, 4, 4, 5, 3)) == 0
assert format_volume((1, 1, 1, 1, 1, 1)) == '0.1179'
assert format_volume((1000, 1000, 1000, 3, 4, 5)) == '1999.9937'


def write_case(name, cases):
    with open('in/' + name + '.txt', 'w') as input_file:
        input_file.write(str(len(cases)) + '\n')
        for edges in cases:
            input_file.write(' '.join(str(value) for value in edges) + '\n')
    with open('out/' + name + '.out', 'w') as output_file:
        for edges in cases:
            output_file.write(format_volume(edges) + '\n')


write_case('1_sample', [(1, 1, 1, 1, 1, 1), (1000, 1000, 1000, 3, 4, 5)])


def near_flat_from(base):
    found = []
    for position in range(6):
        for delta in (-3, -2, -1, 1, 2, 3):
            candidate = list(base)
            candidate[position] += delta
            edges = tuple(candidate)
            if is_valid(edges) and edges not in found:
                found.append(edges)
    return found


small_flat = (3, 5, 4, 4, 5, 3)
medium_flat = (60, 100, 80, 80, 100, 60)
large_flat = (600, 1000, 800, 800, 1000, 600)
near_flat = near_flat_from(small_flat) + near_flat_from(medium_flat) + near_flat_from(large_flat)

edge_cases = [
    (1, 1, 1, 1, 1, 1),
    (2, 2, 2, 2, 2, 2),
    (1000, 1000, 1000, 1000, 1000, 1000),
    small_flat,
    medium_flat,
    large_flat,
    (3, 4, 5, 6, 7, 8),
    (7, 8, 9, 10, 11, 12),
    (1, 2, 2, 2, 2, 2),
]
edge_cases = [edges for edges in edge_cases if faces_ok(edges) and gram_value(edges) >= 0]
write_case('2_edges', edge_cases + near_flat[:12])

wide_cases = [
    (1000, 1000, 1000, 1000, 1000, 1000),
    large_flat,
    (1, 1, 1, 1, 1, 1),
]
wide_rng = random.Random(90210)
while len(wide_cases) < 12:
    edges = tuple(wide_rng.randint(900, 1000) for _ in range(6))
    if is_valid(edges) and edges not in wide_cases:
        wide_cases.append(edges)
write_case('3_wide', wide_cases + near_flat[-8:])

random_rng = random.Random(1234567)
random_cases = []
attempts = 0
while len(random_cases) < 5000 and attempts < 400000:
    attempts += 1
    edges = tuple(random_rng.randint(1, 1000) for _ in range(6))
    if is_valid(edges):
        random_cases.append(edges)
assert len(random_cases) == 5000
write_case('4_random', random_cases)

io_template = [
    (1, 1, 1, 1, 1, 1),
    (1000, 1000, 1000, 1000, 1000, 1000),
    (1000, 1000, 1000, 3, 4, 5),
    (600, 1000, 800, 800, 1000, 600),
    (3, 5, 4, 4, 5, 3),
    (999, 1000, 997, 998, 996, 995),
    (7, 8, 9, 10, 11, 12),
    (1000, 999, 998, 997, 996, 995),
    (500, 500, 500, 500, 500, 500),
    (2, 3, 4, 5, 6, 7),
]
io_template = [edges for edges in io_template if faces_ok(edges) and gram_value(edges) >= 0]
io_expected = [format_volume(edges) for edges in io_template]
repeat_count = 20000
with open('in/5_io.txt', 'w') as input_file:
    input_file.write(str(repeat_count * len(io_template)) + '\n')
    for _ in range(repeat_count):
        for edges in io_template:
            input_file.write(' '.join(str(value) for value in edges) + '\n')
with open('out/5_io.out', 'w') as output_file:
    for _ in range(repeat_count):
        for answer in io_expected:
            output_file.write(answer + '\n')
