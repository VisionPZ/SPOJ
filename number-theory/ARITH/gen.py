import random
import sys


def render_pair(first, operator, second):
    rows = []

    def text_row(left, right, text):
        rows.append([left, right, text])

    def dash_row(upper, lower):
        left = min(upper[0], lower[0])
        right = max(upper[1], lower[1])
        rows.append([left, right, "-" * (right - left)])

    width = max(len(first), len(second) + 1)
    top_row = [width - len(first), width, first]
    operator_row = [width - len(second) - 1, width, operator + second]
    text_row(top_row[0], top_row[1], top_row[2])
    text_row(operator_row[0], operator_row[1], operator_row[2])

    if operator in "+-":
        if operator == "+":
            result = str(int(first) + int(second))
        else:
            result = str(int(first) - int(second))
        result_row = [width - len(result), width, result]
        dash_row(operator_row, result_row)
        text_row(result_row[0], result_row[1], result_row[2])
    else:
        partials = []
        for index in range(len(second) - 1, -1, -1):
            digit = int(second[index])
            value = int(first) * digit
            shift = len(second) - 1 - index
            partials.append([width - shift - len(str(value)), width - shift, str(value)])
        result = str(int(first) * int(second))
        result_row = [width - len(result), width, result]
        dash_row(operator_row, partials[0])
        if len(second) == 1:
            text_row(result_row[0], result_row[1], result_row[2])
        else:
            for row in partials:
                text_row(row[0], row[1], row[2])
            dash_row(partials[-1], result_row)
            text_row(result_row[0], result_row[1], result_row[2])

    shift = -min(row[0] for row in rows)
    lines = []
    for left, right, text in rows:
        lines.append(" " * (left + shift) + text)
    return "\n".join(lines) + "\n"


def split_line(line):
    for index, char in enumerate(line):
        if char in "+-*":
            return line[:index], char, line[index + 1:]
    raise ValueError("no operator in " + repr(line))


def expected_output(data):
    lines = data.splitlines()
    pair_count = int(lines[0])
    blocks = []
    for line in lines[1:1 + pair_count]:
        first, operator, second = split_line(line)
        blocks.append(render_pair(first, operator, second))
    return "".join(block + "\n" for block in blocks)


SAMPLE = """4
12345+67890
324-111
325*4405
1234*4
"""

SAMPLE_OUT = """ 12345
+67890
------
 80235

 324
-111
----
 213

    325
  *4405
  -----
   1625
     0
 1300
1300
-------
1431625

1234
  *4
----
4936

"""


def number(rng, digits):
    text = rng.choice("123456789") + "".join(
        rng.choice("0123456789") for _ in range(digits - 1)
    )
    return int(text)


def random_line(rng, max_digits):
    first = number(rng, rng.randint(1, max_digits))
    second = number(rng, rng.randint(1, max_digits))
    operator = rng.choice("+-*")
    if operator == "-" and second > first:
        first, second = second, first
    return "{}{}{}".format(first, operator, second)


def cases(count, seed, max_digits=30):
    rng = random.Random(seed)
    lines = [str(count)]
    for _ in range(count):
        lines.append(random_line(rng, max_digits))
    return "\n".join(lines) + "\n"


def edges():
    lines = [
        "1+1", "9+1", "10-1", "100-99", "1000-1", "1*1", "9*9", "10*10",
        "100*100", "1000*1000", "100000*100000", "1*100000", "100000*1",
        "2*90909", "99999+1", "999999-999999", "2*5", "12*21", "123-123",
        "10-9", "100-1", "5*101010", "101010*5", "1000000-999999",
    ]
    return str(len(lines)) + "\n" + "\n".join(lines) + "\n"


def wide(max_digits=100, seed=7):
    rng = random.Random(seed)
    lines = []
    for _ in range(20):
        lines.append("9" * max_digits + "+" + "9" * max_digits)
        lines.append("1" + "0" * max_digits + "-" + "1")
        lines.append("9" * max_digits + "*" + "9" * max_digits)
        lines.append("1" + "0" * max_digits + "*" + "9" * max_digits)
    for _ in range(40):
        a = number(rng, max_digits)
        b = number(rng, max_digits)
        lines.append("{}+{}".format(a, b))
        lines.append("{}-{}".format(max(a, b), min(a, b)))
        lines.append("{}*{}".format(a, b))
    return str(len(lines)) + "\n" + "\n".join(lines) + "\n"


def io_max():
    lines = []
    for _ in range(40):
        lines.append("9" * 100 + "*" + "9" * 100)
        lines.append("9" * 100 + "+" + "9" * 100)
        lines.append("9" * 100 + "-" + "1")
    return str(len(lines)) + "\n" + "\n".join(lines) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected_output(sys.stdin.read()))
    elif mode == "check-sample":
        assert expected_output(SAMPLE) == SAMPLE_OUT, repr(expected_output(SAMPLE))
        print("sample layout OK")
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        for name, data in [("1_sample", SAMPLE), ("2_edges", edges()),
                          ("3_wide", wide()), ("4_random", cases(600, 5)),
                          ("5_io", io_max())]:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected_output(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
