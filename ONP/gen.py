#!/usr/bin/env python3
import random
from os import makedirs

PREC = {'+': 1, '-': 1, '*': 2, '/': 2, '^': 3}
LETTERS = 'abcdefghijklmnopqrstuvwxyz'
ONE = 1
MAXLEN = 400
BIG = 60
SLACK = 20


def oracle(e):
    toks = list(e)
    pos = 0
    out = []

    def peek():
        if pos < len(toks):
            return toks[pos]
        return None

    def take():
        nonlocal pos
        c = toks[pos]
        pos += 1
        return c

    def atom():
        c = take()
        if c == '(':
            expr()
            take()
        else:
            out.append(c)

    def factor():
        atom()
        if peek() == '^':
            take()
            factor()
            out.append('^')

    def term():
        factor()
        while peek() in ('*', '/'):
            op = take()
            factor()
            out.append(op)

    def expr():
        term()
        while peek() in ('+', '-'):
            op = take()
            term()
            out.append(op)

    expr()
    assert pos == len(toks)
    return ''.join(out)


def leaf(rng):
    return rng.choice(LETTERS)


def tree(rng, depth):
    if depth < ONE or rng.random() < 0.3:
        return leaf(rng)
    op = rng.choice('+-*/^')
    return (op, tree(rng, depth - ONE), tree(rng, depth - ONE))


def emit(node, minp, full):
    if isinstance(node, str):
        return node
    op = node[0]
    p = PREC[op]
    s = emit(node[1], p + 1, full) + op + emit(node[2], p + 1, full)
    if full or p < minp:
        s = '(' + s + ')'
    return s


def term(rng, full):
    parts = [leaf(rng)]
    op = rng.choice('*/')
    while rng.random() < 0.5:
        parts.append(op)
        parts.append(leaf(rng))
        op = '/' if op == '*' else '*'
    s = ''.join(parts)
    if full:
        s = '(' + s + ')'
    return s


def chain(rng, target, full):
    parts = []
    cand = ''
    while len(cand) < target - SLACK:
        parts.append(term(rng, full))
        cand = '+'.join(parts)
    while len(cand) > MAXLEN:
        parts.pop()
        cand = '+'.join(parts)
    return cand


def make(rng, target, full):
    if target > BIG:
        return chain(rng, target, bool(full))
    best = 'a'
    d = 1
    while d < 12:
        s = emit(tree(rng, d), 0, full)
        if len(s) > target:
            break
        best = s
        d += 1
    return best


def exprs_random(seed, count, lo, hi, fullish):
    rng = random.Random(seed)
    res = []
    for _ in range(count):
        target = rng.randint(lo, hi)
        res.append(make(rng, target, bool(rng.random() < fullish)))
    return res


def write_case(name, exprs):
    assert all(len(e) <= 400 for e in exprs)
    with open('in/%s.txt' % name, 'w') as f:
        f.write('%d\n' % len(exprs))
        for e in exprs:
            f.write(e + '\n')
    with open('out/%s.out' % name, 'w') as f:
        for e in exprs:
            f.write(oracle(e) + '\n')


assert oracle('(a+(b*c))') == 'abc*+'
assert oracle('((a+b)*(z+x))') == 'ab+zx+*'
assert oracle('((a+t)*((b+(a+c))^(c+d)))') == 'at+bac++cd+^*'
assert oracle('(a-b)-c') == 'ab-c-'
assert oracle('(a-(b-c))') == 'abc--'
assert oracle('a^b^c') == 'abc^^'
assert oracle('(a^b)^c') == 'ab^c^'
assert oracle('(a)') == 'a'

makedirs('in', exist_ok=True)
makedirs('out', exist_ok=True)

sample = ['(a+(b*c))', '((a+b)*(z+x))', '((a+t)*((b+(a+c))^(c+d)))']
write_case('1_sample', sample)

edges = sample + ['a', '(a)', '((a))', '((((((a))))))', 'a+(b*c)', '(a+b)*z',
                 '(a-b)-c', '(a-(b-c))', 'a/(b+c)', 'a^b^c', '(a^b)^c',
                 'a^b^c^d', '(a^b)^(c^d)', '(a-(b*(c/(d^e))))', 'a+b+c',
                 'a*b*c/d', 'z^y^x^w']
write_case('2_edges', edges)

write_case('3_max', exprs_random(7, 100, 380, 400, 1))
write_case('4_random', exprs_random(11, 100, 1, 400, 2))

big = exprs_random(5, 100, 396, 400, 0)
write_case('5_io', big)

print('cases written')
