import random
import sys


def expected(data):
    lines = [line for line in data.splitlines() if line.strip() != ""]
    index = 0
    cases = int(lines[index])
    index += 1
    out = []
    for _ in range(cases):
        count = int(lines[index])
        index += 1
        accounts = []
        for _ in range(count):
            accounts.append(" ".join(lines[index].split()))
            index += 1
        accounts.sort()
        position = 0
        while position < len(accounts):
            repeat = 1
            while position + repeat < len(accounts) and accounts[position + repeat] == accounts[position]:
                repeat += 1
            out.append("{} {}\n".format(accounts[position], repeat))
            position += repeat
        out.append("\n")
    return "".join(out)


def account(rng, bank, owner):
    groups = " ".join(owner[i:i + 4] for i in range(0, 16, 4))
    return "{} {} {}".format(bank, groups, rng.choice(["0141", "0142", "0143", "0144"]))


def sample():
    return """2
6
03 10103538 2222 1233 6160 0142
03 10103538 2222 1233 6160 0141
03 10103538 4444 4444 6160 0141
03 10103538 4444 4444 6160 0142
03 10103538 4444 4444 6160 0141
03 10103538 4444 4444 6160 0142

5
03 10103538 4444 4444 6160 0144
03 10103538 4444 4444 6160 0142
03 10103538 4444 4444 6160 0145
03 10103538 4444 4444 6160 0146
03 10103538 4444 4444 6160 0143
"""


def random_case(case_count, account_count, seed):
    rng = random.Random(seed)
    lines = [str(case_count)]
    for _ in range(case_count):
        lines.append(str(account_count))
        for _ in range(account_count):
            bank = "{:08d}".format(rng.randint(0, 99999999))
            owner = "".join("{:04d}".format(rng.randint(0, 9999)) for _ in range(4))
            lines.append(account(rng, bank, owner))
        lines.append("")
    return "\n".join(lines) + "\n"


def max_case():
    lines = ["2"]
    for _ in range(2):
        lines.append("100000")
        rng = random.Random(3)
        for _ in range(100000):
            bank = "{:08d}".format(rng.randint(0, 999))
            owner = "".join("{:04d}".format(rng.randint(0, 99)) for _ in range(4))
            lines.append(account(rng, bank, owner))
        lines.append("")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        for name, data in [("1_sample", sample()), ("2_small", random_case(5, 40, 1)),
                          ("3_random", random_case(5, 4000, 9)), ("4_max", max_case())]:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
