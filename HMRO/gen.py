import random
import sys


def expected(data):
    tokens = data.split()
    index = 0
    cases = int(tokens[index]); index += 1
    out = []
    for case in range(cases):
        listed = int(tokens[index]); index += 1
        records = {}
        for _ in range(listed):
            pesel = tokens[index]; office = tokens[index + 1]; index += 2
            records[pesel] = office
        closed = int(tokens[index]); index += 1
        redirect = {}
        for _ in range(closed):
            old = tokens[index]; new = tokens[index + 1]; index += 2
            redirect[old] = new
        recruits = int(tokens[index]); index += 1
        resolved = {}
        for _ in range(recruits):
            pesel = tokens[index]; index += 1
            office = records.get(pesel, "")
            path = []
            while office in redirect and office not in resolved:
                path.append(office)
                office = redirect[office]
                if len(path) > len(redirect):
                    office = ""
                    break
            target = resolved.get(office, office)
            for node in path:
                resolved[node] = target
            out.append("{} {}\n".format(pesel, target))
        if case + 1 < cases:
            out.append("\n")
    return "".join(out)


SAMPLE = """1
4
84101011111 GDA1
84010122222 GDA2
84010233333 GDA2
84020255555 GDY1
1
GDA2 GDA1
3
84101011111
84010122222
84020255555
"""


def office_code(rng):
    return rng.choice("ABCDEFGH") + rng.choice("EFGH") + rng.choice("IJKLM") + str(rng.randint(0, 9))


def chain_set(rng, offices, wanted):
    rank = {}
    for position, office in enumerate(offices):
        rank.setdefault(office, position)
    ordered = sorted(set(offices), key=lambda office: rank[office])
    used = set()
    chains = []
    while len(chains) < wanted and len(chains) < len(ordered) - 1:
        first = rng.randrange(1, len(ordered))
        second = rng.randrange(0, first)
        old = ordered[first]
        new = ordered[second]
        if old in used:
            continue
        used.add(old)
        chains.append((old, new))
    return chains


def one_case(rng, listed, closed, recruits):
    lines = [str(listed)]
    offices = []
    pesels = []
    for _ in range(listed):
        pesel = "{:011d}".format(rng.randint(0, 99999999999))
        office = office_code(rng)
        lines.append("{} {}".format(pesel, office))
        offices.append(office)
        pesels.append(pesel)
    chains = chain_set(rng, offices, min(closed, len(set(offices)) - 1))
    lines.append(str(len(chains)))
    for old, new in chains:
        lines.append("{} {}".format(old, new))
    lines.append(str(recruits))
    for _ in range(recruits):
        if rng.random() < 0.8:
            lines.append(rng.choice(pesels))
        else:
            lines.append("{:011d}".format(rng.randint(0, 99999999999)))
    return lines


def random_cases(case_count, listed, closed, recruits, seed):
    rng = random.Random(seed)
    lines = [str(case_count)]
    for _ in range(case_count):
        lines.extend(one_case(rng, listed, closed, recruits))
        lines.append("")
    return "\n".join(lines) + "\n"


def chain_case():
    size = 100000
    lines = ["1", str(size)]
    for index in range(size):
        lines.append("{:011d} O{:06d}".format(10000000000 + index, index))
    lines.append(str(size - 1))
    for index in range(size - 1):
        lines.append("O{:06d} O{:06d}".format(index, index + 1))
    lines.append(str(size))
    for _ in range(size):
        lines.append("10000000000")
    return "\n".join(lines) + "\n"


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "write"
    if mode == "expected":
        sys.stdout.write(expected(sys.stdin.read()))
    elif mode == "write":
        import pathlib
        pathlib.Path("in").mkdir(exist_ok=True)
        pathlib.Path("out").mkdir(exist_ok=True)
        cases = [("1_sample", SAMPLE),
                 ("2_small", random_cases(4, 30, 12, 20, 3)),
                 ("3_random", random_cases(5, 900, 500, 700, 6)),
                 ("4_big", random_cases(2, 100000, 100000, 100000, 5)),
                 ("5_chain", chain_case())]
        for name, data in cases:
            pathlib.Path("in/{}.txt".format(name)).write_text(data)
            pathlib.Path("out/{}.out".format(name)).write_text(expected(data))
        print("cases written")
    else:
        raise SystemExit("unknown mode")
