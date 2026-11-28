import math
import random

BALANCE = "Ecological balance will develop."
HARES_DIE = "Hares will die out while foxes will overgrow."
HARES_OVER = "Hares will overgrow while foxes will die out."
BOTH_DIE = "Both hares and foxes will die out."
BOTH_OVER = "Both hares and foxes will overgrow."
CHAOS = "Chaos will develop."


def split_exponent(value):
    if value == 0.0:
        return 0.0, -1000000
    mantissa, exponent = math.frexp(value)
    return mantissa, exponent


def scaled_term(coefficient, mantissa, exponent):
    if coefficient == 0.0 or mantissa == 0.0:
        return None
    product = coefficient * mantissa
    new_mantissa, shift = math.frexp(product)
    return new_mantissa, exponent + shift


def combine_terms(first, second):
    if first is None:
        return second
    if second is None:
        return first
    first_m, first_e = first
    second_m, second_e = second
    shared_exponent = max(first_e, second_e)
    first_scaled = (math.ldexp(first_m, first_e - shared_exponent)
                    if first_e >= shared_exponent - 900 else 0.0)
    second_scaled = (math.ldexp(second_m, second_e - shared_exponent)
                     if second_e >= shared_exponent - 900 else 0.0)
    mantissa, shift = split_exponent(first_scaled + second_scaled)
    return mantissa, shared_exponent + shift


def sequence_kind(record, tail):
    recent = record[-tail:]
    valid = [(index, math.log2(abs(mantissa)) + exponent)
             for index, (mantissa, exponent) in enumerate(recent)
             if mantissa != 0.0 and exponent > -900]
    if not valid:
        return 0
    x_values = [index for index, _ in valid]
    y_values = [level for _, level in valid]
    count = len(x_values)
    mean_x = sum(x_values) / count
    mean_y = sum(y_values) / count
    covariance = sum((x_values[i] - mean_x) * (y_values[i] - mean_y)
                     for i in range(count))
    variance = sum((x_values[i] - mean_x) ** 2 for i in range(count))
    slope = covariance / variance if variance else 0.0
    if max(y_values) < -500:
        return 0
    if slope < -0.0001:
        return 0
    signs = [1 if recent[index][0] > 0 else -1 for index, _ in valid]
    steady = bool(signs) and all(sign == signs[0] for sign in signs)
    if slope > 0.0001 and steady:
        return 1 if signs[0] > 0 else 2
    return 3


def oracle(a, b, c, d, h, f, steps=2400, tail=500):
    hares = float(h)
    foxes = float(f)
    h_mantissa, h_exponent = split_exponent(hares)
    f_mantissa, f_exponent = split_exponent(foxes)
    hare_record = []
    fox_record = []
    for _ in range(steps):
        h_from_h = scaled_term(a, h_mantissa, h_exponent)
        h_from_f = scaled_term(-b, f_mantissa, f_exponent)
        f_from_f = scaled_term(c, f_mantissa, f_exponent)
        f_from_h = scaled_term(d, h_mantissa, h_exponent)
        new_h = combine_terms(h_from_h, h_from_f)
        new_f = combine_terms(f_from_f, f_from_h)
        if new_h is None:
            h_mantissa, h_exponent = 0.0, -1000000
        else:
            h_mantissa, h_exponent = new_h
        if new_f is None:
            f_mantissa, f_exponent = 0.0, -1000000
        else:
            f_mantissa, f_exponent = new_f
        hare_record.append((h_mantissa, h_exponent))
        fox_record.append((f_mantissa, f_exponent))
    hare_kind = sequence_kind(hare_record, tail)
    fox_kind = sequence_kind(fox_record, tail)
    if hare_kind == 0 and fox_kind == 0:
        return BALANCE
    if hare_kind == 1 and fox_kind == 1:
        return BOTH_OVER
    if hare_kind == 2 and fox_kind == 2:
        return BOTH_DIE
    if hare_kind == 2 and fox_kind == 1:
        return HARES_DIE
    if hare_kind == 1 and fox_kind == 2:
        return HARES_OVER
    return CHAOS


def format_number(value):
    if isinstance(value, int):
        return str(value)
    return "%.6f" % value


def write_case(handle, values):
    handle.write(format_number(values[0]) + " " + format_number(values[1]) + "\n")
    handle.write(format_number(values[2]) + " " + format_number(values[3]) + "\n")
    handle.write(format_number(values[4]) + " " + format_number(values[5]) + "\n")
    handle.write("\n")


def build_sample():
    values = [(2, 0.5, 0.5, 0.6, 2, 3), (0.1, 1, 2, 0.1, 1, 1)]
    with open("in/1_sample.txt", "w") as handle:
        handle.write("2\n")
        for row in values:
            write_case(handle, row)
    expected = [BOTH_OVER, HARES_DIE]
    assert oracle(*values[0]) == expected[0]
    assert oracle(*values[1]) == expected[1]
    with open("out/1_sample.out", "w") as handle:
        for text in expected:
            handle.write(text + "\n")


EDGE_CASES = [
    (0, 0, 0, 0, 1, 1),
    (1, 0, 1, 0, 1, 1),
    (1, 0, 1, 0, 0, 0),
    (0.5, 0, 0.5, 0, 3, 4),
    (2, 0, 2, 0, 1, 1),
    (-2, 0, 0, 0, 1, 1),
    (0.5, 0.5, 0.5, 0.5, 1, 1),
    (1, 1, 1, 1, 1, 1),
    (2, 0, 0.5, 0, 0, 2),
    (2, 0, 3, 0, -5, 7),
    (2, 0, 3, 0, 5, -7),
    (2, 0, 3, 0, -5, -7),
    (2, 0, 3, 0, 5, 7),
    (-1, 0, -1, 0, 1, 1),
]

EDGE_EXPECTED = [
    BALANCE, CHAOS, BALANCE, BALANCE, BOTH_OVER, CHAOS,
    BALANCE, CHAOS, BALANCE, HARES_DIE, HARES_OVER,
    BOTH_DIE, BOTH_OVER, CHAOS,
]


def build_edges():
    assert len(EDGE_CASES) == len(EDGE_EXPECTED)
    for values, expected in zip(EDGE_CASES, EDGE_EXPECTED):
        assert oracle(*values) == expected, (values, oracle(*values), expected)
    with open("in/2_edges.txt", "w") as handle:
        handle.write(str(len(EDGE_CASES)) + "\n")
        for row in EDGE_CASES:
            write_case(handle, row)
    with open("out/2_edges.out", "w") as handle:
        for text in EDGE_EXPECTED:
            handle.write(text + "\n")


WIDE_CASES = [
    (999999999, 0, 999999998, 0, -999999999, 999999998),
    (999999999, 0, 999999998, 0, 999999999, -999999998),
    (999999999, 0, 999999998, 0, -999999999, -999999998),
    (999999999, 0, 999999998, 0, 999999999, 999999998),
    (0.0000001, 0, 0.0000002, 0, 999999999, -999999999),
    (100000, 100000, 100000, 100000, 999999999, -999999999),
    (-999999999, 0, -999999998, 0, 999999999, 999999998),
]


def build_wide():
    expected = [oracle(*row) for row in WIDE_CASES]
    assert expected[0] == HARES_DIE
    assert expected[1] == HARES_OVER
    assert expected[2] == BOTH_DIE
    assert expected[3] == BOTH_OVER
    assert expected[4] == BALANCE
    assert expected[5] == CHAOS
    assert expected[6] == CHAOS
    with open("in/3_wide.txt", "w") as handle:
        handle.write(str(len(WIDE_CASES)) + "\n")
        for row in WIDE_CASES:
            write_case(handle, row)
    with open("out/3_wide.out", "w") as handle:
        for text in expected:
            handle.write(text + "\n")


def build_random():
    rng = random.Random(20261123)
    cases = []
    while len(cases) < 500:
        row = tuple(rng.uniform(-5.0, 5.0) for _ in range(6))
        a, b, c, d, h, f = row
        trace = a + c
        determinant = a * c + b * d
        discriminant = trace * trace - 4.0 * determinant
        if abs(discriminant) < 0.02:
            continue
        if discriminant > 0:
            root_gap = math.sqrt(discriminant)
            larger = (trace + root_gap) / 2.0
            smaller = (trace - root_gap) / 2.0
            if abs(abs(larger) - 1.0) < 0.02 or abs(abs(smaller) - 1.0) < 0.02:
                continue
            if larger * smaller < 0 and abs(abs(larger) - abs(smaller)) < 0.02:
                continue
        else:
            if abs(math.sqrt(max(determinant, 0.0)) - 1.0) < 0.02:
                continue
        cases.append(row)
    expected = [oracle(*row) for row in cases]
    with open("in/4_random.txt", "w") as handle:
        handle.write(str(len(cases)) + "\n")
        for row in cases:
            write_case(handle, row)
    with open("out/4_random.out", "w") as handle:
        for text in expected:
            handle.write(text + "\n")


IO_TEMPLATES = [
    (2, 0, 3, 0, 5, 7),
    (2, 0, 3, 0, -5, 7),
    (2, 0, 3, 0, 5, -7),
    (2, 0, 3, 0, -5, -7),
    (0.5, 0, 0.5, 0, 5, 7),
    (1, 1, 1, 1, 5, 7),
]


def build_io():
    case_count = 5000
    expected = []
    with open("in/5_io.txt", "w") as handle:
        handle.write(str(case_count) + "\n")
        for index in range(case_count):
            row = IO_TEMPLATES[index % len(IO_TEMPLATES)]
            write_case(handle, row)
            expected.append(oracle(*row))
    with open("out/5_io.out", "w") as handle:
        for text in expected:
            handle.write(text + "\n")


build_sample()
build_edges()
build_wide()
build_random()
build_io()
print("gen.py done")
