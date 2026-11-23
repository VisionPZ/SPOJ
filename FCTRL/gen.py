import random
import sys


def zeros(number):
    answer = 0
    divisor = 5
    while divisor <= number:
        answer += number // divisor
        divisor *= 5
    return answer


def expected(data):
    lines = data.split()
    case_count = int(lines[0])
    answers = [str(zeros(int(lines[index + 1]))) for index in range(case_count)]
    return "\n".join(answers) + "\n"


def edges():
    numbers = [1, 4, 5, 24, 25, 100, 1024, 8735373, 10 ** 9, 999999999,
               5 ** 13, 5 ** 14, 125, 625]
    return "{}\n".format(len(numbers)) + "".join("{}\n".format(n) for n in numbers)


def io_max():
    rng = random.Random(4)
    lines = ["100000"]
    for _ in range(100000):
        lines.append(str(rng.randint(1, 10 ** 9)))
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        sample = "6\n3\n60\n100\n1024\n23456\n8735373\n"
        rng = random.Random(5)
        random_cases = "{}\n".format(2000) + "".join(
            "{}\n".format(rng.randint(1, 10 ** 9)) for _ in range(2000))
        for name, data in [("1_sample", sample), ("2_edges", edges()),
                           ("3_random", random_cases), ("4_io", io_max())]:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
