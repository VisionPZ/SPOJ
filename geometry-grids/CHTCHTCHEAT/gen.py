#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent

COW_SENTENCES = {
    "Cow is a domesticated animal.",
    "She helps mankind in many ways.",
    "Her milk is very healthy for babies.",
    "Cows usually eat green grass but they can survive on other things too.",
    "Blah blah blah.",
}


def oracle(text):
    tokens = iter(text.splitlines())
    count = int(next(tokens))
    answers = []
    for _ in range(count):
        topic = next(tokens).strip()
        size = int(next(tokens))
        sentences = [next(tokens).strip() for _ in range(size)]
        cheating = topic != "cow" and any(s in COW_SENTENCES for s in sentences)
        answers.append("Cheating" if cheating else "Not cheating")
    return "\n".join(answers) + ("\n" if answers else "")


SAMPLE = (
    "3\n"
    "cow\n3\n"
    "Cow is a domesticated animal.\n"
    "She helps mankind in many ways.\n"
    "Her milk is very healthy for babies.\n"
    "gandhi\n3\n"
    "Gandhi was an Indian leader.\n"
    "He loved cows.\n"
    "Cow is a domesticated animal.\n"
    "cat\n4\n"
    "Cat drinks milk.\n"
    "The milk comes from a cow.\n"
    "Cats are familiar and easily kept animals\n"
    "Cats can hear sounds too faint or too high.\n"
)
SAMPLE_OUT = "Not cheating\nCheating\nNot cheating\n"
assert oracle(SAMPLE) == SAMPLE_OUT
assert "Cow is a domesticated animal." in COW_SENTENCES
assert "Blah blah blah." in COW_SENTENCES
assert "Cat drinks milk." not in COW_SENTENCES
assert len(COW_SENTENCES) == 5


def write(name, cases):
    body = [str(len(cases)) + "\n"]
    for topic, sentences in cases:
        body.append(f"{topic}\n{len(sentences)}\n")
        body.extend(f"{sentence}\n" for sentence in sentences)
    text = "".join(body)
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


def build():
    all_cow = sorted(COW_SENTENCES)
    write("2_edges", [
        ("cow", all_cow),
        ("cow", ["Blah blah blah."]),
        ("gandhi", ["Her milk is very healthy for babies."]),
        ("train", ["Cows usually eat green grass but they can survive on other things too."]),
        ("gandhi", ["Gandhi was an Indian leader.", "He loved cows."]),
    ])
    wide = []
    for k in range(49):
        topic = "cow" if k % 7 == 0 else ("gandhi" if k % 2 else "cat")
        sentences = []
        for j in range(99):
            if topic == "cow" or j % 5 != 0:
                sentences.append(f"This is a plain sentence number {j} for case {k}.")
            else:
                sentences.append(all_cow[j % len(all_cow)])
        wide.append((topic, sentences))
    write("3_wide", wide)

    random.seed(2026)
    made_up = [
        "A train is a form of rail transport consisting of many compartments.",
        "Cat drinks milk.",
        "The sky is blue today.",
        "He loved cows.",
        "Gandhi was an Indian leader.",
    ]
    pool = made_up + all_cow
    rnd = []
    for _ in range(30):
        topic = random.choice(["cow", "gandhi", "cat", "train"])
        size = random.randint(1, 99)
        rnd.append((topic, [random.choice(pool) for _ in range(size)]))
    write("4_random", rnd)

    io_cases = []
    for k in range(49):
        sentences = [all_cow[j % len(all_cow)] for j in range(99)]
        io_cases.append(("gandhi", sentences))
    write("5_io", io_cases)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", [
    ("cow", [
        "Cow is a domesticated animal.",
        "She helps mankind in many ways.",
        "Her milk is very healthy for babies.",
    ]),
    ("gandhi", [
        "Gandhi was an Indian leader.",
        "He loved cows.",
        "Cow is a domesticated animal.",
    ]),
    ("cat", [
        "Cat drinks milk.",
        "The milk comes from a cow.",
        "Cats are familiar and easily kept animals",
        "Cats can hear sounds too faint or too high.",
    ]),
])
build()
print("trace: topic=gandhi contains cow sentence -> Cheating; topic=cow -> Not cheating")
