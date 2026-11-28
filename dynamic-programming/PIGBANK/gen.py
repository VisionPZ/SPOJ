import random
import sys


def expected(data):
    tokens = data.split()
    position = 0
    cases = int(tokens[position]); position += 1
    out = []
    for _ in range(cases):
        empty = int(tokens[position]); filled = int(tokens[position + 1]); position += 2
        count = int(tokens[position]); position += 1
        coins = []
        for _ in range(count):
            price = int(tokens[position]); weight = int(tokens[position + 1]); position += 2
            coins.append((price, weight))
        target = filled - empty
        unreachable = 10 ** 18
        best = [unreachable] * (target + 1)
        best[0] = 0
        for total in range(1, target + 1):
            for price, weight in coins:
                if weight <= total and best[total - weight] + price < best[total]:
                    best[total] = best[total - weight] + price
        if best[target] < unreachable:
            out.append("The minimum amount of money in the piggy-bank is {}.\n".format(best[target]))
        else:
            out.append("This is impossible.\n")
    return "".join(out)


SAMPLE = """3
10 110
2
1 1
30 50
10 110
2
1 1
50 30
1 6
2
10 3
20 4
"""


def one_case(rng, max_weight, coin_count):
    empty = rng.randint(1, 100)
    target = rng.randint(0, max_weight)
    filled = empty + target
    lines = ["{} {}".format(empty, filled), str(coin_count)]
    for _ in range(coin_count):
        weight = rng.randint(1, max(2, max_weight // 4))
        price = rng.randint(1, 500)
        lines.append("{} {}".format(price, weight))
    return lines, target


def worst_case(rng):
    lines = ["1 10001", "500"]
    for _ in range(500):
        lines.append("{} {}".format(rng.randint(1, 50000), rng.randint(1, 10000)))
    return lines


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        rng = random.Random(4)
        cases = [("1_sample", SAMPLE)]
        edges = [["1 1", "1", "5 7"], ["1 6", "1", "3 2"], ["1 10001", "1", "10 1"],
                 ["5 5", "2", "7 3", "9 4"], ["1 2", "2", "100 4", "1 3"]]
        for case in edges:
            cases.append((None, "1\n" + "\n".join(case) + "\n"))
        for _ in range(6):
            case, _target = one_case(rng, 60, 8)
            cases.append((None, "1\n" + "\n".join(case) + "\n"))
        many = []
        for _ in range(20):
            case, _target = one_case(rng, 400, 40)
            many.append(case)
        cases.append((None, "{}\n".format(len(many)) + "\n".join("\n".join(case) for case in many) + "\n"))
        big = []
        for _ in range(10):
            case, _target = one_case(rng, 3000, 200)
            big.append(case)
        cases.append((None, "{}\n".format(len(big)) + "\n".join("\n".join(case) for case in big) + "\n"))
        cases.append((None, "1\n" + "\n".join(worst_case(rng)) + "\n"))
        index = 2
        for name, data in cases:
            if name is None:
                name = "{}_case".format(index)
                index += 1
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
