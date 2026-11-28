#!/usr/bin/env python3
import os
import random

ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'


def brute_force(plain, cipher, bound):
    length = len(plain)
    diffs = [None] * length
    for index in range(length):
        if plain[index] != '*' and cipher[index] != '*':
            diffs[index] = (ord(cipher[index]) - ord(plain[index])) % 26
    consistent = []
    for modulus in range(1, bound + 1):
        forced = [None] * modulus
        ok = True
        for index in range(length):
            if diffs[index] is None:
                continue
            residue = index % modulus
            if forced[residue] is None:
                forced[residue] = diffs[index]
            elif forced[residue] != diffs[index]:
                ok = False
                break
        if ok:
            consistent.append(forced)
    answer = []
    for index in range(length):
        if plain[index] != '*':
            answer.append(plain[index])
            continue
        if cipher[index] == '*' or not consistent:
            answer.append('*')
            continue
        values = set()
        possible = True
        for forced in consistent:
            shift = forced[index % len(forced)]
            if shift is None:
                possible = False
                break
            values.add((ord(cipher[index]) - 65 - shift) % 26)
        if possible and len(values) == 1:
            answer.append(ALPHABET[values.pop()])
        else:
            answer.append('*')
    return ''.join(answer)


def encrypt(plain, key):
    return ''.join('*' if ch == '*' else ALPHABET[(ord(ch) - 65 + key[index % len(key)]) % 26]
                   for index, ch in enumerate(plain))


def damage(text, rng, rate):
    return ''.join('*' if rng.random() < rate else ch for ch in text)


def write_case(name, cases):
    with open('in/%s.txt' % name, 'w') as source:
        source.write('%d\n' % len(cases))
        for bound, plain, cipher in cases:
            source.write('%d\n%s\n%s\n' % (bound, plain, cipher))
    with open('out/%s.out' % name, 'w') as target:
        for bound, plain, cipher in cases:
            target.write(brute_force(plain, cipher, bound) + '\n')


def check_samples():
    samples = [
        (1, 'A*X*C', '**CM*', 'A*XHC'),
        (4, '*B***A', 'AAAAAA', '*BA*BA'),
        (6, '*B***A', 'AAAAAA', '*B***A'),
        (4, '*AA*******', 'AAAAAAAAAA', '*AA**A****'),
    ]
    for bound, plain, cipher, expected in samples:
        actual = brute_force(plain, cipher, bound)
        assert actual == expected, (bound, plain, actual, expected)


def main():
    os.makedirs('in', exist_ok=True)
    os.makedirs('out', exist_ok=True)
    check_samples()
    write_case('1_sample', [
        (1, 'A*X*C', '**CM*'),
        (4, '*B***A', 'AAAAAA'),
        (6, '*B***A', 'AAAAAA'),
        (4, '*AA*******', 'AAAAAAAAAA'),
    ])
    rng = random.Random(20261123)

    edges = [
        (1, 'A', 'A', None),
        (1, '*', 'A', None),
        (1, '*', '*', None),
        (1, 'A*', 'B*', None),
        (2, 'AAAA', 'BBBB', None),
        (2, 'ABAB', 'BABA', None),
        (3, 'AAA*AA', '*AAAAA', None),
        (5, '*A*A*A*A*A*', 'AAAAAAAAAAA', None),
        (7, 'A*B*C*D*E*F*G', 'ZZZZZZZZZZZZZ', None),
        (4, 'ABCDABCDABCD', 'BCDEBCDEBCDE', None),
    ]
    cases = [(bound, plain, cipher) for bound, plain, cipher, _ in edges]
    write_case('2_edges', cases)

    wide = []
    plain = 'AB' * 5000
    wide.append((10000, plain, encrypt(plain, [1, 3])))
    wide.append((10000, '*' * 10000, 'A' * 10000))
    plain = 'A' * 10000
    wide.append((10000, plain, plain))
    with open('in/3_wide.txt', 'w') as source:
        source.write('%d\n' % len(wide))
        for bound, text_plain, text_cipher in wide:
            source.write('%d\n%s\n%s\n' % (bound, text_plain, text_cipher))
    with open('out/3_wide.out', 'w') as target:
        target.write('AB' * 5000 + '\n')
        target.write('*' * 10000 + '\n')
        target.write('A' * 10000 + '\n')

    random_cases = []
    for _ in range(120):
        length = rng.randint(1, 34)
        bound = rng.randint(1, min(length + 3, 16))
        key = [rng.randrange(26) for _ in range(rng.randint(1, bound))]
        plain = damage(''.join(rng.choice(ALPHABET) for _ in range(length)), rng, 0.45)
        cipher = damage(encrypt(plain, key), rng, 0.25)
        random_cases.append((bound, plain, cipher))
    write_case('4_random', random_cases)

    io_cases = []
    for _ in range(20):
        length = 1000
        bound = rng.randint(1, 2000)
        plain = '*' * length
        cipher = ''.join(rng.choice(ALPHABET) for _ in range(length))
        io_cases.append((bound, plain, cipher))
    with open('in/5_io.txt', 'w') as source:
        source.write('%d\n' % len(io_cases))
        for bound, text_plain, text_cipher in io_cases:
            source.write('%d\n%s\n%s\n' % (bound, text_plain, text_cipher))
    with open('out/5_io.out', 'w') as target:
        for bound, text_plain, text_cipher in io_cases:
            target.write('*' * len(text_plain) + '\n')


if __name__ == '__main__':
    main()
