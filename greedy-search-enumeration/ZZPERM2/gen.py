#!/usr/bin/env python3
import itertools
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def zigzag(word):
    length = len(word)
    if length <= 1:
        return True
    down_up = all(word[pos] > word[pos + 1] for pos in range(0, length - 1, 2)) and all(
        word[pos] < word[pos + 1] for pos in range(1, length - 1, 2))
    up_down = all(word[pos] > word[pos + 1] for pos in range(1, length - 1, 2)) and all(
        word[pos] < word[pos + 1] for pos in range(0, length - 1, 2))
    return down_up or up_down


def oracle(word, divisor):
    permutations = sorted(set(''.join(items) for items in itertools.permutations(word)))
    zigzags = [item for item in permutations if zigzag(item)]
    chosen = [item for rank, item in enumerate(zigzags, 1) if rank % divisor == 0]
    return ''.join(item + '\n' for item in chosen) + str(len(zigzags)) + '\n\n'


def oracle_text(cases):
    return ''.join(oracle(word, divisor) for word, divisor in cases)


assert oracle('j', 1) == 'j\n1\n\n'
assert oracle('abc', 2) == 'bac\ncab\n4\n\n'
assert oracle('aaabc', 1) == 'abaca\nacaba\n2\n\n'
assert oracle('aaabb', 2) == '1\n\n'
assert oracle('aabcc', 1) == 'acacb\nacbca\nbacac\nbcaca\ncabac\ncacab\n6\n\n'
assert oracle('abc', 1) == 'acb\nbac\nbca\ncab\n4\n\n'

SAMPLE_IN = 'j 1\nabc 2\naaabc 1\naaabb 2\naaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbcccdd 123456\naaaaaaaaabbbbbbbbbcccccccccddddddddd 1000000000\n'
SAMPLE_OUT = 'j\n1\n\nbac\ncab\n4\n\nabaca\nacaba\n2\n\n1\n\nbabacbcabacabadabababababababababadab\n213216\n\nabacbcacbdadcdbcadbdacbdacbdadbcbcad\nabadadcdcdcdbdbdadbcabacacbdbcbcacab\nacabacbcbdbcbdcdadadacbcadbcbcadadbd\nacacbcbdacbdcdacbcadbdbcbcadadbdabad\nacadbcadbdbcacadbdbcacbdbdacbdbcadac\nacbcacbcadbdadadadbcbdcdabacacbdbdbc\nacbcbdadbdcdbcbcbcacbdadadadadbcacab\nacbdadcdcdadadbdababacbcbcbcacbdbdac\nacbdcdbdbcacbcbcadabadbcabadbdcdacad\nadacbcacbcbcbdcdcdbdadadabadbdbcacab\nadadbcbcadbcabacadbdbcbdabadcdcdacbc\nadbcadbcabacbdacacbcbcbdcdadbdadbdac\nadbdacababacadadcdbcbcadbdacbcbdcdbc\nadbdcdacbdbcbdbcadadadbcadacbcacbcab\nadcdbdacadacbdbcbdadacbcbcadbdbcacab\nbabacbdcdbdcdbcadcdbcabacacadadbdacb\nbacacadbdcdbcbdbdcdacbdacabacadbcadb\nbacadcdbcbdabacbcacacadadadcdbdbdbcb\nbacbdadacabacadacbdcdbcadbcbdbcbdadc\nbadacadbcadacbcbdadbdbcacbcbdcdabadc\nbadbcacbdabadcdbcadbdacabacbdacbdcdc\nbadbdcdbdadacbcbcacacbdbdacbdadbcaca\nbcabacadbdbdacacbdadcdadbcbcbcadacbd\nbcacadacbcbdcdbdbcbdbdadadabacbdacac\nbcacbdbdcdcdababadacbcadacacbdbdbcad\nbcadbcadbdbdcdcdadbcbcacbcababadacad\nbcbcabadacadcdadacbdadbcbdcdbcacbdab\nbcbcbcadbcadbcadbdadbcbcadabacadadcd\nbcbdacbdacbdbcbdadacacbdcdbdadacabac\nbcbdbdbdcdacacacbdbcadadbcababacadcd\nbdabadcdbdadbcadcdbcbdcdbcabacabacac\nbdacbcbcbcadadbcadcdabadbcacbdcdabad\nbdadbcabacbcbcababadacadcdcdbdcdacbd\nbdbcacacbdbcadbcbdabacbcadacadadbdcd\nbdbcbdacacbdadbdcdababadadcdbcacbcac\nbdbdbcadbcacadbcadacadbdbdcdbcacacab\nbdcdacbdadadbcbcacacbcacabadbdbcadbd\nbdcdcdadacadcdbdbcababadbcacbcadbcab\ncabacbdcdbdadacacadbcbcacadbcbdbdadb\ncacabadcdbdbdbcbcbdacabadbdacbdacadc\ncacadcdbcbcbdcdacababacbcadbdbdbdada\ncacbdadbdadacbdababacbcbdcdcdcdabacb\ncadacadbdabacbcacbdbdcdadbcadadbcbcb\ncadbcacbcbdcdbdbcadbcbdadabacbdacada\ncadbdbcbdacadbdacadacbdbcbcadbcabadc\ncbcabacbcbdadabacbcadbdadcdcdadacbdb\ncbcadacadadbdbcacbcadbdbdacbcabadcdb\ncbcbcadacbcadadadbcbdacadbcbdbdacadb\ncbcbdbcadcdacbdadacbdbcacadacbdabadb\ncbdacadacbcbdcdbdabadbcbcacabadcdadb\ncbdadbdadabadcdabadcdacbcbcabacbcbdc\ncbdbcbdcdbcbdacacbdadadcdababacabadc\ncbdcdacbdbcbdadacacadbcabababadcdbdc\ncdabadacabadcdbdcdbdbcabadbcbcacadbc\ncdacbcbcadabadcdbdbcbcacbdadadabadbc\ncdadbcacacbcadadbdbdbcabadbcbcbcadad\ncdbcacadbcbdbcadbdadadbdbcacbcadabac\ncdbcbdadadacbdbcabacbcbcabadacadcdbd\ncdbdbcabadcdbdbdcdacacababadbdacacbc\ncdcdacacbcadbcabadbdcdbcbcabadadbdab\ndababacbcbcadbdacacbcacbdbdcdadcdadb\ndabadbdcdacacadabadcdbdbcbcbcacbdbca\ndacadacbdbdbcacbcadbdbcacbcadbdcdaba\ndacbcbdadadcdbdacadcdababacbcacbdbcb\ndadabadbcbcadcdbdacbcadacadbcbcbdbca\ndadbcadadbdcdcdabacbcbdbcacbdbcabaca\ndadcdbcacabadadbcabadbcadcdadbcbcbcb\ndbcacbcadacadbcacbdadacbcbdacbdbdadb\ndbcadcdbcbdbdadbdadbcacbcacacbcabada\ndbcbdacbcadbdacbdadbdacbcadbcacadacb\ndbdacacbdadbcbcbcbcadbdadbcadbcadaca\ndbdbcacadacabacbcadacbdadcdbdbdbcbca\ndbdcdabacadadbcbdcdbcacacbcbdbdacaba\ndcdacadadbcbcabacbcacbdbcbdbcadadadb\ndcdbcadadbcbcadbcbcadabadbdcdbcacaba\ndcdcdacabadbdbdacacbcacbdababadbcbdc\n76317369490\n\n'
assert len(SAMPLE_IN.splitlines()) == 6
assert SAMPLE_OUT.count('\n') > 80
assert '213216\n' in SAMPLE_OUT and SAMPLE_OUT.endswith('76317369490\n\n')


def write(name, cases):
    text = ''.join(f'{word} {divisor}\n' for word, divisor in cases)
    (ROOT / 'in' / f'{name}.txt').write_text(text)
    (ROOT / 'out' / f'{name}.out').write_text(oracle_text(cases))


def build():
    write('2_edges', [('a', 1), ('aa', 1), ('ab', 1), ('abc', 3), ('aba', 2)])
    write('3_wide', [('aaaabbbb', 1), ('aabbcc', 2), ('abcd', 5)])
    rng = random.Random(20261126)
    random_cases = []
    for _ in range(8):
        length = rng.randint(1, 9)
        word = ''.join(rng.choice('abcd') for _ in range(length))
        random_cases.append((word, rng.randint(1, 8)))
    write('4_random', random_cases)
    write('5_io', [('aabbcc', 1), ('aaabbbccc', 1), ('abcabc', 1), ('abcd', 1)])


(ROOT / 'in').mkdir(exist_ok=True)
(ROOT / 'out').mkdir(exist_ok=True)
(ROOT / 'in' / '1_sample.txt').write_text(SAMPLE_IN)
(ROOT / 'out' / '1_sample.out').write_text(SAMPLE_OUT)
build()
