import random
import sys


def expected(data):
    lines = data.splitlines()
    index = 0
    out = []
    while index < len(lines):
        if lines[index].strip() == "":
            index += 1
            continue
        length = int(lines[index])
        needle = lines[index + 1]
        haystack = lines[index + 2]
        index += 3
        start = haystack.find(needle)
        while start != -1:
            out.append("{}\n".format(start))
            start = haystack.find(needle, start + 1)
        out.append("\n")
    return "".join(out)


SAMPLE = """2
na
banananobano
6
foobar
foo
9
foobarfoo
barfoobarfoobarfoobarfoobarfoo
"""


def random_case(count, seed, needle_len=6, haystack_len=200):
    rng = random.Random(seed)
    lines = []
    for _ in range(count):
        needle = "".join(rng.choice("ab") for _ in range(needle_len))
        haystack = "".join(rng.choice("ab") for _ in range(haystack_len))
        lines.extend([str(len(needle)), needle, haystack])
    return "\n".join(lines) + "\n"


def big_case():
    rng = random.Random(4)
    needle = "".join(rng.choice("abcdefgh") for _ in range(100000))
    haystack = "".join(rng.choice("abcdefghij") for _ in range(1000000))
    small_needle = "ab" * 50000
    small_hay = ("ab" * 250000) + "c" + ("ab" * 250000)
    return "\n".join([
        str(len(needle)), needle, haystack,
        str(len(small_needle)), small_needle, small_hay,
    ]) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        for name, data in [("1_sample", SAMPLE), ("2_small", random_case(30, 2)),
                          ("3_random", random_case(120, 8, 12, 3000)), ("4_big", big_case())]:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
