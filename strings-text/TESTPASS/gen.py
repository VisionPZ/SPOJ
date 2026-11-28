import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

SAMPLE_INPUT = (
    "8\n"
    "PASS\n"
    "P@ss\n"
    "P@ss123123\n"
    "Alabama@#1\n"
    "nonoP@ssw0rd\n"
    "My2P@SSword\n"
    "abcddcba123#\n"
    "MyP@sswordIsReallyLong@RosesAreBlue\n"
)
SAMPLE_OUTPUT = "NO\nNO\nNO\nYES\nNO\nYES\nNO\nNO\n"


def oracle(text):
    tokens = text.split()
    count = int(tokens[0])
    answers = []
    for password in tokens[1:count + 1]:
        good = 6 <= len(password) <= 20
        classes = set()
        for ch in password:
            if ch.isupper():
                classes.add("upper")
            elif ch.islower():
                classes.add("lower")
            elif ch.isdigit():
                classes.add("digit")
            else:
                classes.add("special")
        good = good and classes == {"upper", "lower", "digit", "special"}
        pairs = [password[i:i + 2] for i in range(len(password) - 1)]
        triples = [password[i:i + 3] for i in range(len(password) - 2)]
        good = good and all(pairs[i] != pairs[i + 2]
                            for i in range(len(pairs) - 2))
        good = good and all(triples[i] != triples[i + 3]
                            for i in range(len(triples) - 3))
        answers.append("YES" if good else "NO")
    return "\n".join(answers) + "\n"


assert oracle(SAMPLE_INPUT) == SAMPLE_OUTPUT
assert oracle("1\nAb1@xy\n") == "YES\n"
assert oracle("1\nabcdef\n") == "NO\n"
assert oracle("1\nAb1@aaaa\n") == "NO\n"
assert oracle("1\nAb1@xyzxyz\n") == "NO\n"


def write(name, passwords):
    input_text = str(len(passwords)) + "\n" + "\n".join(passwords) + "\n"
    (ROOT / "in" / (name + ".txt")).write_text(input_text)
    (ROOT / "out" / (name + ".out")).write_text(oracle(input_text))


def build():
    edges = [
        "Ab1@xy", "Ab1@xyz", "Ab1@xy!" * 2, "Ab1@xy!"[:5],
        "abcdef", "ABCDEF", "123456", "!!!!!!", "Ab1@aaaa",
        "Ab1@xyzxyz", "Aaaaaaa1!", "A@1bcde", "A@1bcde" + "fg",
        "A@1bcdefghijklmnopqrs", "A@1bcdefghijklmnopqrst",
    ]
    write("2_edges", edges)
    rng = random.Random(2026)
    alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    wide = ["".join(rng.choice(alphabet) for _ in range(20)) for _ in range(100)]
    write("3_wide", wide)
    random_passwords = []
    for _ in range(500):
        size = rng.randint(1, 24)
        random_passwords.append("".join(rng.choice(alphabet) for _ in range(size)))
    write("4_random", random_passwords)
    io = ["".join(rng.choice(alphabet) for _ in range(rng.randint(6, 20)))
          for _ in range(10000)]
    write("5_io", io)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    "PASS", "P@ss", "P@ss123123", "Alabama@#1", "nonoP@ssw0rd",
    "My2P@SSword", "abcddcba123#", "MyP@sswordIsReallyLong@RosesAreBlue",
])
build()
