import math, random, sys

def expected(data):
    lines = data.split()
    case_count = int(lines[0])
    answers = [str(math.factorial(int(lines[index + 1]))) for index in range(case_count)]
    return "\n".join(answers) + "\n"

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    else:
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        rng = random.Random(3)
        cases = [("1_sample", "4\n1\n2\n5\n3\n"),
                 ("2_edges", "10\n1\n2\n10\n20\n25\n50\n99\n100\n0\n5\n"),
                 ("3_random", "{}\n".format(100) + "".join("{}\n".format(rng.randint(1, 100)) for _ in range(100))),
                 ("4_io", "{}\n".format(5000) + "".join("{}\n".format(rng.randint(1, 100)) for _ in range(5000)))]
        for name, data in cases:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
