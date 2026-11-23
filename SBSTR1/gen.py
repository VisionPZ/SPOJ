#!/usr/bin/env python3
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))


def oracle(long_string, short_string):
    return 1 if short_string in long_string else 0


assert oracle('1010110010', '10110') == 1
assert oracle('1110111011', '10011') == 0
assert oracle('0000000000', '00000') == 1
assert oracle('0000000000', '11111') == 0


def write_case(name, pairs):
    assert len(pairs) == 24
    in_path = os.path.join(HERE, 'in', name + '.txt')
    out_path = os.path.join(HERE, 'out', name + '.out')
    with open(in_path, 'w') as in_file:
        for long_string, short_string in pairs:
            in_file.write(long_string + ' ' + short_string + '\n')
    with open(out_path, 'w') as out_file:
        for long_string, short_string in pairs:
            out_file.write(str(oracle(long_string, short_string)) + '\n')


sample_prefix = [
    ('1010110010', '10110'),
    ('1110111011', '10011'),
]
sample_fill_seed = random.Random(20240501)
sample_fill = []
for _ in range(22):
    long_string = ''.join(sample_fill_seed.choice('01') for _ in range(10))
    short_string = ''.join(sample_fill_seed.choice('01') for _ in range(5))
    sample_fill.append((long_string, short_string))
write_case('1_sample', sample_prefix + sample_fill)

edges = [
    ('0000000000', '00000'),
    ('0000000000', '11111'),
    ('1111111111', '11111'),
    ('1111111111', '00000'),
    ('0000011111', '11111'),
    ('1111100000', '11111'),
    ('0010110101', '00101'),
    ('0010110101', '10101'),
    ('0101010101', '01010'),
    ('0101010101', '10101'),
    ('0101010101', '11011'),
    ('1000000001', '00000'),
    ('1000000001', '00001'),
    ('1010101010', '01010'),
    ('1010101010', '10101'),
    ('1010101010', '11111'),
    ('0111111110', '11111'),
    ('0111111110', '00000'),
    ('1100110011', '00110'),
    ('1100110011', '10011'),
    ('1100110011', '01100'),
    ('0000000001', '00001'),
    ('1000000000', '10000'),
    ('0111111111', '11110'),
]
write_case('2_edges', edges)

wide_offsets = []
for offset in range(6):
    wide_offsets.append(('0' * offset + '10110' + '0' * (5 - offset), '10110'))
write_case('3_wide', wide_offsets * 4)

random_gen = random.Random(918273)
random_pairs = []
for _ in range(24):
    long_string = ''.join(random_gen.choice('01') for _ in range(10))
    short_string = ''.join(random_gen.choice('01') for _ in range(5))
    random_pairs.append((long_string, short_string))
write_case('4_random', random_pairs)

io_pairs = [('0000000000', '00000') for _ in range(24)]
write_case('5_io', io_pairs)
