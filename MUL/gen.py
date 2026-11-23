import random
import sys

sys.set_int_max_str_digits(1000000)


def expected(data):
    tokens = data.split()
    case_count = int(tokens[0])
    answers = []
    index = 1
    for _ in range(case_count):
        answers.append(str(int(tokens[index]) * int(tokens[index + 1])))
        index += 2
    return "\n".join(answers) + "\n"


def io_max():
    rng = random.Random(2)
    lines = ["4"]
    for _ in range(4):
        first = "".join(rng.choice("123456789") if i == 0 else rng.choice("0123456789")
                        for i in range(10000))
        second = "".join(rng.choice("123456789") if i == 0 else rng.choice("0123456789")
                         for i in range(10000))
        lines.append(first + " " + second)
    return "\n".join(lines) + "\n"


def edge_pairs():
    pairs = ["0 123", "123 0", "0000000012 5", "1 1", "9999 12345",
             "9" * 61 + " 3", "5 5", "10000 10000",
             "1 " + "1" + "0" * 47, "99 101", "12345678901234567890123456789 987654321"]
    return [str(len(pairs))] + pairs


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    else:
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        rng = random.Random(7)
        random_cases = ["200"]
        for _ in range(200):
            first = str(rng.randint(1, 10 ** rng.randint(1, 60)))
            second = str(rng.randint(1, 10 ** rng.randint(1, 60)))
            random_cases.append(first + " " + second)
        cases = [("1_sample", "5\n4 2\n123 43\n324 342\n0 12\n9999 12345\n"),
                 ("2_edges", "\n".join(edge_pairs()) + "\n"),
                 ("3_random", "\n".join(random_cases) + "\n"),
                 ("4_io", io_max())]
        for name, data in cases:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
