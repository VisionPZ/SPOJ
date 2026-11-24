#!/usr/bin/env python3
import random
from collections import defaultdict

ROOT = __import__('pathlib').Path(__file__).resolve().parent
INF = 10**15


def oracle_solve(cases):
    answers = []
    for boxes, needs in cases:
        answers.append(str(_oracle_case(boxes, needs)))
    return "\n".join(answers) + "\n"


def _oracle_case(boxes, needs):
    sizes = [s for s, _ in boxes] + list(needs.keys()) + [0]
    top = max(sizes)
    by_size = defaultdict(list)
    for size, value in boxes:
        by_size[size].append(value)
    counts = {}
    prefix = {}
    widest = 0
    for size in range(top + 1):
        values = sorted(by_size.get(size, []))
        counts[size] = len(values)
        widest = max(widest, len(values))
        running = [0]
        for value in values:
            running.append(running[-1] + value)
        prefix[size] = running
    dp = [INF] * (widest + 1)
    dp[0] = 0
    for size in range(top + 1):
        next_dp = [INF] * (widest + 1)
        need = needs.get(size, 0)
        box_count = counts[size]
        sums = prefix[size]
        for carried in range(widest + 1):
            if dp[carried] >= INF:
                continue
            for used in range(box_count + 1):
                flow = carried + used - need
                if flow < 0 or flow % 2:
                    continue
                above = flow // 2
                if above > widest:
                    continue
                cost = dp[carried] + sums[used]
                if cost < next_dp[above]:
                    next_dp[above] = cost
        dp = next_dp
    return "No" if dp[0] >= INF else dp[0]


def brute_check(boxes, needs):
    sizes = [s for s, _ in boxes] + list(needs.keys()) + [0]
    top = max(sizes)
    best = None
    for mask in range(1 << len(boxes)):
        chosen = defaultdict(int)
        value = 0
        for i, (size, cost) in enumerate(boxes):
            if mask & (1 << i):
                chosen[size] += 1
                value += cost
        if best is not None and value >= best:
            continue
        low = [0] * (top + 2)
        high = [0] * (top + 2)
        low[top + 1] = high[top + 1] = 0
        for size in range(top, -1, -1):
            need = needs.get(size, 0)
            have = chosen.get(size, 0)
            low[size] = max(0, need + 2 * low[size + 1] - have)
            high[size] = need + 2 * high[size + 1]
            if low[size] > high[size]:
                break
        else:
            if low[0] <= 0 <= high[0]:
                best = value
    return "No" if best is None else best


def render(cases):
    lines = [str(len(cases))]
    for boxes, needs in cases:
        lines.append(str(len(boxes)))
        for size, value in boxes:
            lines.append(f"{size} {value}")
        lines.append(str(len(needs)))
        for size, count in sorted(needs.items()):
            lines.append(f"{size} {count}")
    return "\n".join(lines) + "\n"


def write(name, cases):
    text = render(cases)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle_solve(cases))


SAMPLE = (
    [(1, 3), (1, 2), (3, 5), (2, 1), (1, 4)],
    {1: 1, 2: 1},
)

assert _oracle_case(*SAMPLE) == 3
assert _oracle_case([(0, 5)], {0: 1}) == 5
assert _oracle_case([(0, 5)], {1: 1}) == "No"
assert _oracle_case([(0, 2), (0, 3)], {1: 1}) == 5
assert _oracle_case([(0, 1), (0, 2), (0, 3), (0, 4)], {1: 2}) == 10
for _check in range(200):
    _boxes = [(random.randint(0, 3), random.randint(0, 5))
              for _ in range(random.randint(0, 7))]
    _needs = {}
    for _size in range(4):
        _c = random.randint(0, 2)
        if _c:
            _needs[_size] = _c
    assert str(_oracle_case(_boxes, _needs)) == str(brute_check(_boxes, _needs))


def build():
    edges = [
        ([(0, 5)], {0: 1}),
        ([(0, 5)], {1: 1}),
        ([(0, 2), (0, 3)], {1: 1}),
        ([(1000, 7)], {1000: 1}),
        ([(0, 0), (0, 0)], {1: 1}),
        ([(0, 1), (0, 2), (0, 3), (0, 4)], {1: 2}),
        ([(2, 9), (2, 1)], {2: 2}),
        ([(2, 9), (2, 1)], {3: 1}),
        ([(0, 4)], {1000: 1}),
    ]
    write("2_edges", edges)

    wide = []
    for _ in range(2):
        boxes = [(size, random.randint(0, 10000)) for size in range(1000)
                 for _ in range(10)]
        needs = {size: 5 for size in range(0, 1000, 100)}
        wide.append((boxes, needs))
    write("3_wide", wide)

    random.seed(2026)
    randoms = []
    for _ in range(200):
        box_total = random.randint(1, 50)
        boxes = [(random.randint(0, 20), random.randint(0, 10000))
                 for _ in range(box_total)]
        needs = {}
        for _ in range(random.randint(1, 5)):
            size = random.randint(0, 20)
            needs[size] = random.randint(1, 10)
        randoms.append((boxes, needs))
    write("4_random", randoms)

    io_cases = []
    for _ in range(50000):
        size = random.randint(0, 12)
        count = random.randint(3, 9)
        boxes = [(size, random.randint(6000, 10000)) for _ in range(count)]
        boxes.append((random.randint(0, 12), random.randint(0, 10000)))
        io_cases.append((boxes, {size: count}))
    write("5_io", io_cases)


def worked_example():
    boxes, needs = SAMPLE
    by_size = defaultdict(list)
    for size, value in boxes:
        by_size[size].append(value)
    top = max([s for s, _ in boxes] + list(needs.keys()))
    pool = []
    total = 0
    print(f"top size = {top}")
    for size in range(top + 1):
        added = sorted(by_size.get(size, []))
        pool = sorted(pool + added)
        need = needs.get(size, 0)
        taken = pool[:need]
        total += sum(taken)
        rest = pool[need:]
        paired = [rest[k] + rest[k + 1] for k in range(0, len(rest) - 1, 2)]
        print(f"size {size}: add {added} -> sorted {pool}; need {need}; "
              f"take {taken} (total {total}); pair {rest} -> {paired}")
        pool = paired
    print(f"answer = {total}")


def main():
    (ROOT / "in").mkdir(exist_ok=True)
    (ROOT / "out").mkdir(exist_ok=True)
    write("1_sample", [SAMPLE])
    build()
    worked_example()


if __name__ == "__main__":
    main()
