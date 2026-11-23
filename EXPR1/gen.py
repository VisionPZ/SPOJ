import os
import random

INF = 99

def tree_oracle(expression):
    length = len(expression)
    term_count = length // 2
    digits = [int(expression[2 * i + 1]) for i in range(term_count)]
    operators = [expression[2 * i] for i in range(term_count)]
    sign_of = lambda op: 1 if op == '+' else -1

    inside = [[None] * term_count for _ in range(term_count)]
    for left in range(term_count - 1, -1, -1):
        for right in range(left, term_count):
            if left == right:
                inside[left][right] = {digits[left]: 0}
                continue
            result = {}
            for split in range(left, right):
                pairs_left = inside[left][split]
                pairs_right = inside[split + 1][right]
                extra = 0 if split + 1 == right else 1
                op_sign = sign_of(operators[split + 1])
                for value_left, cost_left in pairs_left.items():
                    for value_right, cost_right in pairs_right.items():
                        value = value_left + op_sign * value_right
                        cost = cost_left + cost_right + extra
                        if value not in result or cost < result[value]:
                            result[value] = cost
            inside[left][right] = result

    prefix = [dict() for _ in range(term_count)]
    for wrap_end in range(term_count):
        wrap_pairs = 0 if wrap_end == 0 else 1
        head_sign = sign_of(operators[0])
        for inner_value, inner_pairs in inside[0][wrap_end].items():
            value = head_sign * inner_value
            cost = inner_pairs + wrap_pairs
            if value not in prefix[wrap_end] or cost < prefix[wrap_end][value]:
                prefix[wrap_end][value] = cost

    for right in range(1, term_count):
        for left in range(right):
            tail = inside[left + 1][right]
            extra = 0 if left + 1 == right else 1
            op_sign = sign_of(operators[left + 1])
            for head_value, head_cost in prefix[left].items():
                for tail_value, tail_cost in tail.items():
                    value = head_value + op_sign * tail_value
                    cost = head_cost + tail_cost + extra
                    if value not in prefix[right] or cost < prefix[right][value]:
                        prefix[right][value] = cost
    return prefix[term_count - 1]

class Parser:
    def __init__(self, text):
        self.text = text
        self.pos = 0

    def expression(self):
        sign = 1
        if self.pos < len(self.text) and self.text[self.pos] in '+-':
            sign = 1 if self.text[self.pos] == '+' else -1
            self.pos += 1
        value = sign * self.operand()
        while self.pos < len(self.text) and self.text[self.pos] in '+-':
            op_sign = 1 if self.text[self.pos] == '+' else -1
            self.pos += 1
            value += op_sign * self.operand()
        return value

    def operand(self):
        if self.pos < len(self.text) and self.text[self.pos].isdigit():
            value = int(self.text[self.pos])
            self.pos += 1
            return value
        if self.pos < len(self.text) and self.text[self.pos] == '(':
            self.pos += 1
            value = self.expression()
            if self.pos < len(self.text) and self.text[self.pos] == ')':
                self.pos += 1
                return value
            raise ValueError('unbalanced')
        raise ValueError('bad operand')


def evaluate(text):
    parser = Parser(text)
    try:
        value = parser.expression()
        return value if parser.pos == len(text) else None
    except ValueError:
        return None


def enumerate_strings(digits, operators, left, right):
    if left == right:
        yield str(digits[left])
        return
    for split in range(left, right):
        for head in enumerate_strings(digits, operators, left, split):
            for tail in enumerate_strings(digits, operators, split + 1, right):
                middle = tail if split + 1 == right else '(' + tail + ')'
                yield head + operators[split + 1] + middle


def extend_strings(digits, operators, start, end, right):
    if start == end:
        yield right
        return
    for split in range(start, end):
        for head in extend_strings(digits, operators, start, split, right):
            for tail in enumerate_strings(digits, operators, split + 1, end):
                middle = tail if split + 1 == end else '(' + tail + ')'
                yield head + operators[split + 1] + middle


def brute_oracle(expression):
    term_count = len(expression) // 2
    digits = [int(expression[2 * i + 1]) for i in range(term_count)]
    operators = [expression[2 * i] for i in range(term_count)]
    best = {}
    for wrap_end in range(term_count):
        for inner in enumerate_strings(digits, operators, 0, wrap_end):
            base = operators[0] + (inner if wrap_end == 0 else '(' + inner + ')')
            for text in extend_strings(digits, operators, wrap_end, term_count - 1, base):
                value = evaluate(text)
                if value is None:
                    continue
                pairs = text.count('(')
                if value not in best or pairs < best[value]:
                    best[value] = pairs
    return best


def answer_for(expression, target):
    table = tree_oracle(expression)
    return table.get(target)


def render_answer(answer):
    return 'NO' if answer is None else str(answer)


def write_files(name, cases):
    input_lines = [str(len(cases))]
    output_lines = []
    for expression, target in cases:
        input_lines.append(f'{len(expression)} {target}')
        input_lines.append(expression)
        answer = answer_for(expression, target)
        assert answer is None or 0 <= answer <= len(expression) // 2
        if len(expression) <= 12:
            assert answer_for(expression, target) == brute_oracle(expression).get(target)
        output_lines.append(render_answer(answer))
    with open(f'in/{name}.txt', 'w') as handle:
        handle.write('\n'.join(input_lines) + '\n')
    with open(f'out/{name}.out', 'w') as handle:
        handle.write('\n'.join(output_lines) + '\n')


sample = [
    ('+5-4+5', -4),
    ('+1', 1),
    ('-1+1', 1),
    ('-1+1', 0),
    ('-1+1', -2),
]

assert [render_answer(answer_for(expression, target)) for expression, target in sample] == ['1', '0', 'NO', '0', '1']
assert answer_for('+9' * 20, 180) == 0
assert answer_for('-9' * 20, -180) == 0
assert answer_for('+0' * 20, 0) == 0
assert answer_for('-1+1', -2) == 1
assert answer_for('+1+1', 2) == 0
assert answer_for('+1+1', 3) is None

check_rng = random.Random(555)
for term_count in range(1, 6):
    for _ in range(30):
        text = ''.join(check_rng.choice('+-') + str(check_rng.randint(0, 9)) for _ in range(term_count))
        assert tree_oracle(text) == brute_oracle(text)

os.makedirs('in', exist_ok=True)
os.makedirs('out', exist_ok=True)

write_files('1_sample', sample)

write_files('2_edges', [
    ('+5', 5), ('-5', -5), ('+5', 6), ('+0', 0), ('-0', 0),
    ('+1+1', 2), ('+1-1', 0), ('-1-1', -2), ('-1+1', -2),
    ('-1+1', 1), ('+9-9', 0), ('+5-4+5', -4), ('+5-4+5', 6),
    ('+9' * 20, 180), ('-9' * 20, -180), ('+0' * 20, 0),
])

write_files('3_wide', [
    ('+9' * 20, 180), ('+9' * 20, 90), ('+9' * 20, 0), ('+9' * 20, -180),
    ('-9' * 20, -180), ('-9' * 20, 0), ('-9' * 20, 180),
    ('+9-9' * 10, 0), ('+9-9' * 10, 180), ('+9-9' * 10, -180),
    ('+1' * 20, 20), ('-1' * 20, -20),
])

rng = random.Random(20261123)
random_cases = []
for _ in range(10):
    term_count = rng.randint(1, 20)
    text = ''.join(rng.choice('+-') + str(rng.randint(0, 9)) for _ in range(term_count))
    target = rng.randint(-180, 180)
    random_cases.append((text, target))
write_files('4_random', random_cases)

io_cases = []
for case_index in range(10):
    term_count = 20
    text = ''.join(rng.choice('+-') + str(rng.randint(0, 9)) for _ in range(term_count))
    table = tree_oracle(text)
    reachable = sorted(table)
    target = reachable[case_index % len(reachable)] if reachable else 0
    io_cases.append((text, target))
write_files('5_io', io_cases)

stress_cases = []
for _ in range(1000):
    text = ''.join(rng.choice('+-') + str(rng.randint(0, 9)) for _ in range(20))
    stress_cases.append((text, rng.choice([-180, -90, 0, 90, 180])))
stress_lines = [str(len(stress_cases))]
for text, target in stress_cases:
    stress_lines.append(f'{len(text)} {target}')
    stress_lines.append(text)
with open('/tmp/EXPR1_big.txt', 'w') as handle:
    handle.write('\n'.join(stress_lines) + '\n')

print('generated 5 case pairs plus stress file')
