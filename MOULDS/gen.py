import os
import random

SIZE = 250
HEIGHT = 30

rng = random.Random(20261123)


def parse_number(text, pos):
    sign = 1
    if pos < len(text) and text[pos] == '-':
        sign = -1
        pos += 1
    elif pos < len(text) and text[pos] == '+':
        pos += 1
    value = 0
    while pos < len(text) and '0' <= text[pos] <= '9':
        value = value * 10 + int(text[pos])
        pos += 1
    return sign * value, pos


def parse_block(text, pos):
    assert text[pos] == '['
    pos += 1
    commands = []
    while pos < len(text) and text[pos] != ']':
        char = text[pos]
        if char == ';':
            pos += 1
        elif char == '[':
            nested, pos = parse_block(text, pos)
            commands.extend(nested)
        elif char == '^':
            value, pos = parse_number(text, pos + 1)
            commands.append(('lift', value))
        elif char == '@':
            direction = text[pos + 1]
            value, pos = parse_number(text, pos + 2)
            commands.append(('shift', direction, value))
        else:
            raise ValueError('bad command char ' + char)
    assert pos < len(text) and text[pos] == ']'
    return commands, pos + 1


def simulate(program):
    commands, _ = parse_block(program, 0)
    removed = bytearray(SIZE * SIZE * HEIGHT)
    row, col, depth = 0, 0, -1

    def cut(cell_row, cell_col, cut_depth):
        if cut_depth <= 0 or not (0 <= cell_row < SIZE and 0 <= cell_col < SIZE):
            return
        top = min(cut_depth, HEIGHT)
        base = (cell_row * SIZE + cell_col) * HEIGHT
        for layer in range(top):
            removed[base + layer] = 1

    for command in commands:
        if command[0] == 'lift':
            depth = min(depth + command[1], HEIGHT)
            cut(row, col, depth)
        else:
            direction, distance = command[1], command[2]
            old_row, old_col = row, col
            if direction == 'N':
                row -= distance
            elif direction == 'S':
                row += distance
            elif direction == 'W':
                col -= distance
            elif direction == 'E':
                col += distance
            else:
                raise ValueError('bad direction ' + direction)
            if row == old_row:
                step = 1 if col > old_col else -1
                for sweep_col in range(old_col, col + step, step):
                    cut(old_row, sweep_col, depth)
            else:
                step = 1 if row > old_row else -1
                for sweep_row in range(old_row, row + step, step):
                    cut(sweep_row, old_col, depth)
    return sum(removed)


assert simulate('[]') == 0
assert simulate('[^0;]') == 0
assert simulate('[^1;]') == 0
assert simulate('[^2;]') == 1
assert simulate('[^31;]') == 30
assert simulate('[^50;]') == 30
assert simulate('[^-5;]') == 0
assert simulate('[^2;@S2;]') == 3
assert simulate('[^2;@S249;]') == 250
assert simulate('[@E250;^2;]') == 0
assert simulate('[[^2;@S1;];^2;]') == 4
assert simulate('[^2;@N-2;]') == 3
assert simulate('[^31;@S249;]') == 7500


def write_case(name, programs):
    assert len(programs) <= 10
    for program in programs:
        assert len(program) <= 10000
        assert simulate(program) >= 0
    with open('in/' + name + '.txt', 'w') as handle:
        handle.write(str(len(programs)) + '\n')
        for program in programs:
            handle.write(program + '\n')
    with open('out/' + name + '.out', 'w') as handle:
        for program in programs:
            handle.write(str(simulate(program)) + '\n')


def make_lift():
    distance = rng.choice([0, 1, 2, 3, 5, 10, 15, 30, 31, 40])
    return '^' + rng.choice(['', '', '+', '-']) + str(distance) + ';'


def make_shift(state):
    direction = rng.choice('NSEW')
    distance = rng.randint(0, 280) * rng.choice([1, 1, 1, -1])
    delta_row, delta_col = 0, 0
    if direction == 'N':
        delta_row = -distance
    elif direction == 'S':
        delta_row = distance
    elif direction == 'W':
        delta_col = -distance
    else:
        delta_col = distance
    new_row, new_col = state[0] + delta_row, state[1] + delta_col
    if not (-1000 <= new_row <= 1000 and -1000 <= new_col <= 1000):
        distance = 0
        delta_row, delta_col = 0, 0
        new_row, new_col = state[0], state[1]
    state[0], state[1] = new_row, new_col
    return '@' + direction + ('+' if distance >= 0 else '-') + str(abs(distance)) + ';'


def make_block(state, max_depth):
    parts = []
    for _ in range(rng.randint(0, 8)):
        choice = rng.random()
        if choice < 0.35:
            parts.append(make_lift())
        elif choice < 0.85 or max_depth == 0:
            parts.append(make_shift(state))
        else:
            parts.append(make_block(state, max_depth - 1))
    return '[' + ''.join(parts) + ']'


def serpentine():
    parts = ['^31;']
    for column in range(SIZE):
        parts.append('@S249;' if column % 2 == 0 else '@N249;')
        if column != SIZE - 1:
            parts.append('@E1;')
    return '[' + ''.join(parts) + ']'


def wide_sweep():
    parts = ['^31;']
    for _ in range(190):
        parts.append('@S249;@N249;@E249;@W249;')
    return '[' + ''.join(parts) + ']'


os.makedirs('in', exist_ok=True)
os.makedirs('out', exist_ok=True)

write_case('1_sample', ['[^2;@S2;]'])

write_case('2_edges', [
    '[]', '[^0;]', '[^2;]', '[^31;]', '[^50;]', '[^-5;]',
    '[^2;@S249;]', '[@E250;^2;]', '[[^2;@S1;];^2;]', '[^2;@N-2;]',
])

write_case('3_wide', [serpentine(), wide_sweep()])

write_case('4_random', [make_block([0, 0], 3) for _ in range(10)])

io_cases = []
for _ in range(10):
    parts = []
    while len('[' + ''.join(parts) + ']') <= 9990:
        parts.append(rng.choice(['@S97;', '@N97;', '@E89;', '@W89;', '^3;', '^-2;']))
    io_cases.append('[' + ''.join(parts) + ']')
write_case('5_io', io_cases)

print('generated five pairs, serpentine volume', simulate(serpentine()))
