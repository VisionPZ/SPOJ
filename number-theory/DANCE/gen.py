import random
from fractions import Fraction

def oracle(word):
    q = Fraction(0)
    run = 0
    def flush(current):
        nonlocal q
        if run > 0 and q is not None:
            q += run
    for letter in word:
        if letter == 'S':
            run += 1
        else:
            if run > 0 and q is not None:
                q += run
            run = 0
            if q == 0 or q is None:
                q = None if q == 0 else Fraction(0)
            else:
                q = -1 / q
    if run > 0 and q is not None:
        q += run
    if q is None:
        return 1
    steps = 0
    while q != 0:
        if q > 0:
            q = -1 / q
        else:
            q += 1
        steps += 1
    return steps

assert oracle('') == 0
assert oracle('S') == 2
assert oracle('SS') == 5
assert oracle('SSS') == 8
assert oracle('R') == 1
assert oracle('RR') == 0
assert oracle('SR') == 1
assert oracle('SRS') == 0
assert oracle('RSRSS') == 5
assert oracle('SRSRSR') == 0
assert oracle('RRSS') == 5

def runs_word(run_lengths):
    return ''.join(('S' if index % 2 == 0 else 'R') * length
                   for index, length in enumerate(run_lengths))

def write_case(name, cases):
    with open('in/' + name + '.txt', 'w') as source:
        with open('out/' + name + '.out', 'w') as expected:
            for word in cases:
                source.write(str(len(word)) + '\n')
                source.write(word + '\n')
                expected.write(str(oracle(word)) + '\n')

write_case('1_sample', ['SS'])

edges = ['', 'S', 'R', 'SR', 'RS', 'SRS', 'RSR', 'SRSR', 'RSRS',
         'SSRSRSS', 'RRSS', 'RRRR', 'SRSRSR', 'SSSS']
write_case('2_edges', edges)

wide_a = runs_word([1000] * 1000)
wide_b = runs_word([900] + [1000] * 999 + [100])
write_case('3_wide', [wide_a, wide_b])

rng = random.Random(20261123)
random_cases = []
for _ in range(10):
    lengths = [rng.randint(1, 1200) for _ in range(900)]
    random_cases.append(runs_word(lengths))
write_case('4_random', random_cases)

io_cases = []
for _ in range(10):
    lengths = [1000] * 1000
    io_cases.append(runs_word(lengths))
write_case('5_io', io_cases)
