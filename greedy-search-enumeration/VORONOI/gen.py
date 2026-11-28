#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def diagram(width, height, sites):
    rows = []
    for y in range(height):
        row = ''
        for x in range(width):
            best = min((abs(x - site_x) + abs(y - site_y), letter)
                       for letter, (site_x, site_y) in sites.items())
            row += chr(best[1])
        rows.append(row)
    return rows


def solve(grid, limit=2):
    height = len(grid)
    width = len(grid[0])
    letters = sorted(set(''.join(grid)))
    cells = {letter: [(x, y) for y in range(height) for x in range(width)
                      if grid[y][x] == letter] for letter in letters}

    def compatible(first, first_site, second, second_site):
        smaller = first < second
        for pixel in cells[first]:
            own = abs(pixel[0] - first_site[0]) + abs(pixel[1] - first_site[1])
            other = abs(pixel[0] - second_site[0]) + abs(pixel[1] - second_site[1])
            if smaller:
                if not own <= other:
                    return False
            elif not own < other:
                return False
        for pixel in cells[second]:
            own = abs(pixel[0] - second_site[0]) + abs(pixel[1] - second_site[1])
            other = abs(pixel[0] - first_site[0]) + abs(pixel[1] - first_site[1])
            if smaller:
                if not own < other:
                    return False
            elif not own <= other:
                return False
        return True

    candidates = {letter: cells[letter][:] for letter in letters}
    assigned = {}
    solutions = []

    def backtrack(position):
        if len(solutions) >= limit:
            return
        if position == len(letters):
            solutions.append(dict(assigned))
            return
        letter = letters[position]
        for site in candidates[letter]:
            if not all(compatible(letter, site, other, assigned[other])
                       for other in assigned):
                continue
            saved = {}
            workable = True
            for other in letters[position + 1:]:
                reduced = [candidate for candidate in candidates[other]
                           if compatible(letter, site, other, candidate)]
                if not reduced:
                    workable = False
                    break
                saved[other] = candidates[other]
                candidates[other] = reduced
            if workable:
                assigned[letter] = site
                backtrack(position + 1)
                del assigned[letter]
            for other, original in saved.items():
                candidates[other] = original

    backtrack(0)
    return solutions


def oracle(text):
    tokens = text.split()
    cursor = 0
    answers = []
    case_number = 0
    while True:
        width = int(tokens[cursor]); cursor += 1
        height = int(tokens[cursor]); cursor += 1
        if width == 0 and height == 0:
            break
        case_number += 1
        grid = tokens[cursor:cursor + height]
        cursor += height
        solution = solve(grid, 1)
        answers.append('Case {}:'.format(case_number))
        if solution:
            for letter in sorted(solution[0]):
                site_x, site_y = solution[0][letter]
                answers.append('{} {} {}'.format(letter, site_x, site_y))
        answers.append('')
    return '\n'.join(answers) + '\n'


SAMPLE_IN = '''4 3
ooxx
ooxx
ooxx
4 1
null
4 4
aabb
aabb
ccdd
ccdd
0 0
'''
SAMPLE_OUT = '''Case 1:
o 0 0
x 2 0

Case 2:
l 2 0
n 0 0
u 1 0

Case 3:
a 0 0
b 2 0
c 0 2
d 2 2

'''
assert oracle(SAMPLE_IN) == SAMPLE_OUT
assert solve(['ab'])[0] == {'a': (0, 0), 'b': (1, 0)}
assert solve(['aa', 'aa'])[0] == {'a': (0, 0)}
assert diagram(4, 3, {ord('o'): (0, 0), ord('x'): (2, 0)}) == ['ooxx'] * 3
assert len(solve(['ooxx'] * 3, 5)) >= 2


def write(name, cases):
    lines = []
    for width, height, sites in cases:
        lines.append('{} {}'.format(width, height))
        lines.extend(diagram(width, height, sites))
    lines.append('0 0')
    text = '\n'.join(lines) + '\n'
    (ROOT / 'in' / '{}.txt'.format(name)).write_text(text)
    (ROOT / 'out' / '{}.out'.format(name)).write_text(oracle(text))


def unique_case(rng, width, height, letter_count):
    for _ in range(200):
        cells = [(x, y) for y in range(height) for x in range(width)]
        chosen = rng.sample(cells, letter_count)
        sites = {ord('a') + index: point for index, point in enumerate(chosen)}
        grid = diagram(width, height, sites)
        if len(set(''.join(grid))) != letter_count:
            continue
        if len(solve(grid, 2)) == 1:
            return width, height, sites
    return None


def build():
    edge = unique_case(random.Random(7), 4, 2, 3)
    wide = unique_case(random.Random(8), 12, 10, 6)
    write('2_edges', [edge] if edge else [])
    write('3_wide', [wide] if wide else [])
    rng = random.Random(20261126)
    cases = []
    while len(cases) < 30:
        width = rng.randint(2, 10)
        height = rng.randint(2, 10)
        case = unique_case(rng, width, height, rng.randint(2, 6))
        if case:
            cases.append(case)
    write('4_random', cases)
    cases = []
    while len(cases) < 150:
        case = unique_case(rng, rng.randint(6, 12), rng.randint(6, 12), 5)
        if case:
            cases.append(case)
    write('5_io', cases)


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
