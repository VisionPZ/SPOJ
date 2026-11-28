import os
import random

LEFT_REQ = {'+': 1, '-': 1, '*': 2, '/': 2}
RIGHT_REQ = {'+': 1, '-': 2, '*': 2, '/': 3}
NODE_VALUE = {'+': 1, '-': 1, '*': 2, '/': 2}
VARIABLES = 'abcdefghij'
OPERATORS = '+-*/'


class Parser:
    def __init__(self, text):
        self.text = text
        self.pos = 0

    def peek(self):
        if self.pos < len(self.text):
            return self.text[self.pos]
        return None

    def parse(self):
        return self.parse_additive()

    def parse_additive(self):
        node = self.parse_multiplicative()
        while self.peek() in ('+', '-'):
            op = self.text[self.pos]
            self.pos += 1
            right_node = self.parse_multiplicative()
            node = (op, node, right_node)
        return node

    def parse_multiplicative(self):
        node = self.parse_atom()
        while self.peek() in ('*', '/'):
            op = self.text[self.pos]
            self.pos += 1
            right_node = self.parse_atom()
            node = (op, node, right_node)
        return node

    def parse_atom(self):
        current = self.text[self.pos]
        self.pos += 1
        if current == '(':
            node = self.parse_additive()
            assert self.pos < len(self.text) and self.text[self.pos] == ')'
            self.pos += 1
            return node
        return ('var', current)


def node_value(node):
    if node[0] == 'var':
        return 99
    return NODE_VALUE[node[0]]


def render(node, parent_op, side, pieces):
    need_parens = False
    if side != 0 and node[0] != 'var':
        requirement = LEFT_REQ[parent_op] if side == 1 else RIGHT_REQ[parent_op]
        if node_value(node) < requirement:
            need_parens = True
    if need_parens:
        pieces.append('(')
    if node[0] == 'var':
        pieces.append(node[1])
    else:
        render(node[1], node[0], 1, pieces)
        pieces.append(node[0])
        render(node[2], node[0], 2, pieces)
    if need_parens:
        pieces.append(')')


def solve(expression):
    tree = Parser(expression).parse()
    pieces = []
    render(tree, ' ', 0, pieces)
    return ''.join(pieces)


SAMPLE = [
    ('(a+(b*c))', 'a+b*c'),
    ('((a+b)*c)', '(a+b)*c'),
    ('(a*(b*c))', 'a*b*c'),
    ('(a*(b/c)*d)', 'a*b/c*d'),
    ('((a/(b/c))/d)', 'a/(b/c)/d'),
    ('((x))', 'x'),
    ('(a+b)-(c-d)-(e/f)', 'a+b-(c-d)-e/f'),
    ('(a+b)+(c-d)-(e+f)', 'a+b+c-d-(e+f)'),
]

EXTRA = [
    ('a/(((b+c)))', 'a/(b+c)'),
    ('(((a+b)*(b*f))/w)', '(a+b)*b*f/w'),
    ('a/(b)/c', 'a/b/c'),
    ('(a-b*c+d)', 'a-b*c+d'),
]

for source, expected in SAMPLE:
    assert solve(source) == expected, (source, solve(source), expected)

for source, expected in EXTRA:
    assert solve(source) == expected, (source, solve(source), expected)


def wrap(rng, text):
    layers = rng.randint(0, 3)
    return '(' * layers + text + ')' * layers


def random_expr(rng, depth):
    if depth <= 0 or rng.random() < 0.25:
        return wrap(rng, rng.choice(VARIABLES))
    op = rng.choice(OPERATORS)
    left_part = random_expr(rng, depth - 1)
    right_part = random_expr(rng, depth - 1)
    return wrap(rng, left_part + op + right_part)


def bounded_expr(rng, depth):
    while True:
        candidate = random_expr(rng, depth)
        if len(candidate) <= 250:
            return candidate


def long_chain(rng, target_length):
    result = rng.choice(VARIABLES)
    while len(result) + 2 <= target_length:
        result += rng.choice(OPERATORS) + rng.choice(VARIABLES)
    return result


def write_case(name, expressions):
    for expression in expressions:
        assert 1 <= len(expression) <= 250, (name, len(expression))
    with open('in/%s.txt' % name, 'w') as input_file:
        input_file.write(str(len(expressions)) + '\n')
        for expression in expressions:
            input_file.write(expression + '\n')
    with open('out/%s.out' % name, 'w') as output_file:
        for expression in expressions:
            output_file.write(solve(expression) + '\n')


sample_expressions = [source for source, _ in SAMPLE]
write_case('1_sample', sample_expressions)

edge_expressions = [
    'a', '((a))', '((((x))))', 'x+y', '(x+y)',
    'a+(b+c)', 'a-(b+c)', 'a-(b-c)', 'a+(b-c)',
    'a*(b/c)', 'a/(b*c)', 'a/(b/c)', 'a*(b*c)',
    '(a/b)*c', '(a*b)/c', 'a/(((b+c)))', 'a/(b)/c',
    '(((a+b)*(b*f))/w)', '(a-b*c+d)',
    '(a+(b+(c+(d+e))))', '((((a+b)+c)+d)+e)',
    '(a-(b-(c-(d-e))))', '(a*(b*(c*(d*e))))', '(a/(b/(c/(d/e))))',
    'a+b-c+d-e', 'a*b/c*d/e', '(a+b)*(c+d)', '(a-b)*(c-d)',
    'a+(b*c)+(d*e)', 'a-(b*c)-(d*e)',
    '(a)', '((a+b))', '((a*b))', 'a/(b)/(c)/(d)',
    '(a+b)-((c+d)-(e+f))', '(a*b)/((c*d)/(e*f))',
]
write_case('2_edges', edge_expressions)

rng_wide = random.Random(20261123)
wide_expressions = []
while len(wide_expressions) < 60:
    candidate = bounded_expr(rng_wide, 5)
    if len(candidate) >= 180:
        wide_expressions.append(candidate)
write_case('3_wide', wide_expressions)

rng_random = random.Random(424242)
random_expressions = [bounded_expr(rng_random, 5) for _ in range(3000)]
write_case('4_random', random_expressions)

rng_io = random.Random(777001)
io_expressions = [long_chain(rng_io, 249) for _ in range(10000)]
write_case('5_io', io_expressions)
