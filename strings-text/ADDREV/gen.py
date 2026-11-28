import random
import sys


def reverse_number(value):
    return int(str(value)[::-1])


def expected(data):
    lines = data.split()
    pair_count = int(lines[0])
    answers = []
    index = 1
    for _ in range(pair_count):
        first = int(lines[index])
        second = int(lines[index + 1])
        index += 2
        answers.append(str(reverse_number(reverse_number(first) + reverse_number(second))))
    return "\n".join(answers) + "\n"


def sample_input():
    return "3\n24 1\n4358 754\n305 794\n"


def edges():
    pairs = [(0, 0), (1, 1), (10, 20), (100, 1), (1200, 21), (305, 794),
             (10 ** 18, 10 ** 18), (10 ** 18 + 5, 10 ** 18 + 5),
             (int("9" * 60), int("9" * 60)), (int("1" + "0" * 59), 1),
             (123456789012345678901234567890, 1), (10, 10), (90, 90),
             (int("1" + "0" * 99), int("9" * 100))]
    return "{}\n".format(len(pairs)) + "".join("{} {}\n".format(a, b) for a, b in pairs)


def random_cases(count, seed):
    rng = random.Random(seed)
    lines = [str(count)]
    for _ in range(count):
        digits = rng.randint(1, 40)
        first = rng.randint(1, 10 ** digits - 1)
        second = rng.randint(1, 10 ** rng.randint(1, 40) - 1)
        lines.append("{} {}".format(first, second))
    return "\n".join(lines) + "\n"


def io_max():
    rng = random.Random(9)
    lines = ["10000"]
    for _ in range(10000):
        lines.append("{} {}".format(rng.randint(1, 10 ** 60), rng.randint(1, 10 ** 60)))
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        cases = [("1_sample", sample_input()), ("2_edges", edges()),
                 ("3_random", random_cases(2000, 5)), ("4_io", io_max())]
        for name, data in cases:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
