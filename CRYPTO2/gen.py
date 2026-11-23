#!/usr/bin/env python3
import os
import random


def oracle(encrypted_token):
    digits = list(encrypted_token.rjust(3, '0'))
    carry = 1
    index = len(digits) - 1
    while index >= 0 and carry:
        summed = int(digits[index]) + carry
        if summed == 10:
            digits[index] = '0'
        else:
            digits[index] = str(summed)
            carry = 0
        index -= 1
    result = ''.join(digits)
    if carry:
        result = '1' + result
    return result


assert oracle('699') == '700'
assert oracle('000') == '001'
assert oracle('998') == '999'
assert oracle('999') == '1000'


def write_case(case_name, tokens):
    with open(os.path.join('in', case_name + '.txt'), 'w') as source_file:
        source_file.write('\n'.join(tokens) + '\n')
    with open(os.path.join('out', case_name + '.out'), 'w') as answer_file:
        answer_file.write('\n'.join(oracle(token) for token in tokens) + '\n')


os.makedirs('in', exist_ok=True)
os.makedirs('out', exist_ok=True)

write_case('1_sample', ['699'])

edge_tokens = ['000', '001', '009', '010', '011', '099', '100', '101', '109', '190', '499', '500', '699', '998', '999']
write_case('2_edges', edge_tokens)

wide_tokens = ['000', '999', '001', '998', '100', '899']
write_case('3_wide', wide_tokens)

random_generator = random.Random(20201123)
random_tokens = []
for _ in range(240):
    encrypted_number = random_generator.randint(0, 999)
    random_tokens.append(f'{encrypted_number:03d}')
write_case('4_random', random_tokens)

io_tokens = ['999']
write_case('5_io', io_tokens)
