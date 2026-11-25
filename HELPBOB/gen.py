#!/usr/bin/env python3
import itertools
import random
from fractions import Fraction
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def parse_cases(text):
    tokens = [int(value) for value in text.split()]
    cursor = 0
    cases = []
    while True:
        pizza_count = tokens[cursor]
        cursor += 1
        if pizza_count == 0:
            break
        pizzas = []
        for _ in range(pizza_count):
            price = tokens[cursor]
            area = tokens[cursor + 1]
            coupon_count = tokens[cursor + 2]
            cursor += 3
            coupons = []
            for _ in range(coupon_count):
                coupons.append((tokens[cursor] - 1, Fraction(100 - tokens[cursor + 1], 100)))
                cursor += 2
            pizzas.append((price, area, coupons))
        cases.append(pizzas)
    return cases


def format_ratio(ratio):
    scaled = (2 * ratio.numerator * 10000 + ratio.denominator) // (2 * ratio.denominator)
    return f"{scaled // 10000}.{scaled % 10000:04d}"


def brute_case(pizzas):
    pizza_count = len(pizzas)
    best = None
    for size in range(1, pizza_count + 1):
        for subset in itertools.combinations(range(pizza_count), size):
            for order in itertools.permutations(subset):
                cost = Fraction(0)
                total_area = 0
                bought = []
                for index in order:
                    factor = Fraction(1)
                    for previous in bought:
                        for target, discount in pizzas[previous][2]:
                            if target == index:
                                factor *= discount
                    cost += pizzas[index][0] * factor
                    total_area += pizzas[index][1]
                    bought.append(index)
                ratio = cost / total_area
                if best is None or ratio < best:
                    best = ratio
    return format_ratio(best)


def fraction_case(pizzas):
    pizza_count = len(pizzas)
    discount_table = [[Fraction(1) for _ in range(pizza_count)] for _ in range(pizza_count)]
    for source, (_, _, coupons) in enumerate(pizzas):
        for target, discount in coupons:
            discount_table[source][target] *= discount

    @lru_cache(maxsize=None)
    def minimum_cost(mask):
        if mask == 0:
            return Fraction(0)
        best = None
        for index in range(pizza_count):
            bit = 1 << index
            if not mask & bit:
                continue
            previous = mask ^ bit
            factor = Fraction(1)
            for source in range(pizza_count):
                if previous & (1 << source):
                    factor *= discount_table[source][index]
            candidate = minimum_cost(previous) + pizzas[index][0] * factor
            if best is None or candidate < best:
                best = candidate
        return best

    best = None
    for mask in range(1, 1 << pizza_count):
        total_area = sum(pizzas[index][1] for index in range(pizza_count) if mask & (1 << index))
        ratio = minimum_cost(mask) / total_area
        if best is None or ratio < best:
            best = ratio
    return format_ratio(best)


def oracle(text):
    answers = []
    for pizzas in parse_cases(text):
        if len(pizzas) <= 7:
            answers.append(brute_case(pizzas))
        else:
            answers.append(fraction_case(pizzas))
    return "\n".join(answers) + "\n"


SAMPLE = """1
80 30 0
2
200 100 1 2 50
200 100 0
5
100 100 2 3 50 2 50
100 100 1 4 50
100 100 1 2 40
600 600 1 5 10
1000 10 1 1 50
0
"""
SAMPLE_OUT = """2.6667
1.5000
0.5333
"""
assert oracle(SAMPLE) == SAMPLE_OUT
assert oracle("1\n7 3 0\n0\n") == "2.3333\n"
assert oracle("2\n100 10 1 2 50\n100 10 0\n0\n") == "7.5000\n"
assert oracle("1\n1 10000 0\n0\n") == "0.0001\n"
assert brute_case([(10, 10, [])]) == fraction_case([(10, 10, [])])


def format_case(cases):
    blocks = []
    for pizzas in cases:
        block = f"{len(pizzas)}\n"
        for price, area, coupons in pizzas:
            block += f"{price} {area} {len(coupons)}"
            for target, discount in coupons:
                block += f" {target + 1} {100 - discount.numerator * 100 // discount.denominator}"
            block += "\n"
        blocks.append(block)
    return "".join(blocks) + "0\n"


def write(name, cases):
    text = format_case(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def pizza(price, area, coupons):
    return (price, area, [(target - 1, Fraction(100 - percent, 100)) for target, percent in coupons])


def build():
    write("2_edges", [
        [pizza(80, 30, [])],
        [pizza(100, 10, []), pizza(100, 10, [(2, 50)])],
        [pizza(10000, 1, []), pizza(1, 10000, [])],
        [pizza(200, 100, [(2, 50), (3, 50)]), pizza(200, 100, [(3, 20)]), pizza(200, 100, [])],
    ])
    write("3_wide", [
        [pizza(10000, 1, []), pizza(9000, 5000, [(2, 50)]), pizza(8000, 9000, [(1, 50), (2, 50)]),
         pizza(10000, 10000, [(4, 50)]), pizza(7000, 6000, [(2, 30), (3, 20)]),
         pizza(100, 100, [(1, 50)]), pizza(1, 1, [])],
    ])
    rng = random.Random(20261128)
    random_cases = []
    for _ in range(8):
        count = rng.randint(2, 6)
        case = []
        for index in range(count):
            coupons = []
            for target in range(count):
                if target != index and rng.random() < 0.5:
                    coupons.append((target + 1, rng.randint(1, 50)))
            case.append(pizza(rng.randint(1, 10000), rng.randint(1, 10000), coupons))
        random_cases.append(case)
    write("4_random", random_cases)
    io_cases = []
    for _ in range(160):
        count = rng.randint(1, 5)
        case = []
        for index in range(count):
            coupons = []
            for target in range(count):
                if target != index and rng.random() < 0.4:
                    coupons.append((target + 1, rng.randint(1, 50)))
            case.append(pizza(rng.randint(1, 10000), rng.randint(1, 10000), coupons))
        io_cases.append(case)
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    [pizza(80, 30, [])],
    [pizza(200, 100, [(2, 50)]), pizza(200, 100, [])],
    [pizza(100, 100, [(3, 50), (2, 50)]), pizza(100, 100, [(4, 50)]),
     pizza(100, 100, [(2, 40)]), pizza(600, 600, [(5, 10)]), pizza(1000, 10, [(1, 50)])],
])
build()
