import os
import random
from collections import defaultdict
from decimal import Decimal, ROUND_HALF_UP

os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

SAMPLE_INPUT = """1
12 
10 wawu1 B R 
100 chau1 A A 
2000 uwr2 B A 
2010 wawu1 A R 
2020 wawu1 A A 
2020 wawu1 B A 
4000 wawu2 C R 
6000 chau1 A R 
7000 chau1 A A 
8000 pp1 A A 
8000 zil2 B R 
9000 zil2 B A 

"""

SAMPLE_OUTPUT = """A 3 1.33 3373.33 
B 3 1.67 4340.00 
C 0 
D 0 
E 0 
F 0 
G 0 
H 0 
I 0 
"""


def oracle(input_text):
    """Group submissions by (team, problem), then reduce each group separately."""
    tokens = input_text.split()
    position = 0
    case_count = int(tokens[position])
    position += 1
    answer_lines = []
    for _ in range(case_count):
        submission_total = int(tokens[position])
        position += 1
        groups = defaultdict(list)
        for _ in range(submission_total):
            submit_time = int(tokens[position])
            team_name = tokens[position + 1]
            problem_name = tokens[position + 2]
            verdict = tokens[position + 3]
            position += 4
            groups[(team_name, problem_name)].append((submit_time, verdict))
        statistics = [[0, 0, 0] for _ in range(9)]
        for (team_name, problem_name), entries in groups.items():
            first_accept = None
            for entry_index, entry in enumerate(entries):
                if entry[1] == 'A':
                    first_accept = entry_index
                    break
            if first_accept is None:
                continue
            problem_index = ord(problem_name) - ord('A')
            statistics[problem_index][0] += 1
            statistics[problem_index][1] += first_accept + 1
            statistics[problem_index][2] += entries[first_accept][0]
        for problem_index in range(9):
            letter = chr(ord('A') + problem_index)
            accepted_count, submission_sum, time_sum = statistics[problem_index]
            if accepted_count == 0:
                answer_lines.append("%s 0 " % letter)
                continue
            average_submissions = money(submission_sum, accepted_count)
            average_time = money(time_sum, accepted_count)
            answer_lines.append("%s %d %s %s " % (
                letter, accepted_count, average_submissions, average_time))
    return "\n".join(answer_lines) + "\n"


def money(numerator, denominator):
    exact = Decimal(numerator) / Decimal(denominator)
    return str(exact.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))


def random_case(rng, submission_total, team_pool, trailing_space=True):
    lines = [str(submission_total)]
    submit_time = 0
    tail = " " if trailing_space else ""
    for _ in range(submission_total):
        submit_time = min(18000, submit_time + rng.randint(0, 25))
        team_name = rng.choice(team_pool)
        problem_name = chr(ord('A') + rng.randrange(9))
        verdict = 'A' if rng.random() < 0.4 else 'R'
        lines.append("%d %s %s %s%s" % (submit_time, team_name, problem_name, verdict, tail))
    return "\n".join(lines) + "\n"


def write(name, cases):
    body = "%d\n" % len(cases) + "".join(cases)
    expected = oracle(body)
    open("in/%s.txt" % name, "w").write(body)
    open("out/%s.out" % name, "w").write(expected)


TEAM_POOL = ["team%d" % index for index in range(50)]
TEAM_POOL += ["abc12", "z9", "qqqqq", "wawu1", "chau1", "uwr2", "pp1",
              "zil2", "x", "y", "zz", "q1"]
assert len(TEAM_POOL) == 62 and len(set(TEAM_POOL)) == 62

assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\n1\n5 aaa A A \n") == \
    "A 1 1.00 5.00 \nB 0 \nC 0 \nD 0 \nE 0 \nF 0 \nG 0 \nH 0 \nI 0 \n"
assert oracle("1\n3\n1 x A R \n2 x A R \n3 x A R \n") == \
    "A 0 \nB 0 \nC 0 \nD 0 \nE 0 \nF 0 \nG 0 \nH 0 \nI 0 \n"
tie_case = "1\n16\n"
for tie_index in range(16):
    tie_time = 1 if tie_index < 14 else 2
    tie_case += "%d team%d A A \n" % (tie_time, tie_index)
assert oracle(tie_case).startswith("A 16 1.00 1.13 ")

open("in/1_sample.txt", "w").write(SAMPLE_INPUT)
open("out/1_sample.out", "w").write(SAMPLE_OUTPUT)

edges = []
edges.append("1\n1 aaa A A \n")
edges.append("1\n18000 zzz9 I A \n")
edges.append("3\n10 x A R \n11 x A R \n12 x A A \n")
edges.append("4\n5 x A A \n6 x A R \n7 x A A \n8 x B R \n")
edges.append("2\n1 a I R \n2 b I R \n")
edges.append(tie_case[2:])
edges.append(random_case(random.Random(1), 2000, TEAM_POOL))
write("2_edges", edges)

wide = [random_case(random.Random(100 + index), 2000, TEAM_POOL)
        for index in range(8)]
write("3_wide", wide)

many = [random_case(random.Random(300 + index), 2000, TEAM_POOL)
        for index in range(60)]
write("4_random", many)

output_cases = [random_case(random.Random(700 + index), 2000, TEAM_POOL)
                for index in range(250)]
write("5_io", output_cases)
