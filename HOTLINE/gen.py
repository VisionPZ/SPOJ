#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SUBJECTS = ["I", "you", "Joe", "Michal", "Ann"]
VERBS = ["like", "smile", "walk", "hurt", "know"]
OBJECTS = ["", "hotdogs", "to work", "there", "sometimes", "now"]


def normalize(raw_verb, inflected):
    return raw_verb[:-1] if inflected and raw_verb.endswith("s") else raw_verb


def read_fact(line):
    sentence = line[:-1]
    subject, remainder = sentence.split(" ", 1)
    negative = False
    if remainder.startswith("don't "):
        negative = True
        remainder = remainder[6:]
    elif remainder.startswith("doesn't "):
        negative = True
        remainder = remainder[8:]
    else:
        negative = subject == "nobody"
    pieces = remainder.split(" ", 1)
    raw_verb = pieces[0]
    object_text = pieces[1] if len(pieces) > 1 else ""
    inflected = subject == "nobody" or (
        not negative and subject not in ("I", "you"))
    return dict(subject=subject, verb=normalize(raw_verb, inflected),
                obj=object_text, negative=negative)


def read_question(line):
    sentence = line[:-1]
    pieces = sentence.split(" ")
    if pieces[0] == "who":
        return dict(kind="who", verb=normalize(pieces[1], True),
                    obj=" ".join(pieces[2:]))
    if pieces[0] == "what":
        return dict(kind="what", subject=pieces[2])
    return dict(kind="yesno", subject=pieces[1], verb=pieces[2],
                obj=" ".join(pieces[3:]))


def applies(fact, subject):
    if fact["negative"]:
        return fact["subject"] in (subject, "nobody")
    return fact["subject"] in (subject, "everybody")


def same(fact, verb, object_text):
    return fact["verb"] == verb and fact["obj"] == object_text


def swap(subject):
    return {"I": "you", "you": "I"}.get(subject, subject)


def conjugate(verb, subject):
    return verb if subject in ("I", "you") else verb + "s"


def attach(text, object_text):
    return text + " " + object_text if object_text else text


def contradicts(facts):
    for good in facts:
        if good["negative"]:
            continue
        for bad in facts:
            if not bad["negative"] or not same(bad, good["verb"], good["obj"]):
                continue
            if ("everybody" in (good["subject"],) or
                    "nobody" in (bad["subject"],) or
                    good["subject"] == bad["subject"]):
                return True
    return False


def answer_yesno(question, facts):
    speaker = swap(question["subject"])
    positive = any(applies(f, question["subject"]) and
                   same(f, question["verb"], question["obj"]) and
                   not f["negative"] for f in facts)
    negative = any(applies(f, question["subject"]) and
                   same(f, question["verb"], question["obj"]) and
                   f["negative"] for f in facts)
    if positive:
        core = attach(speaker + " " + conjugate(question["verb"], speaker),
                      question["obj"])
        return "yes, " + core + "."
    if negative:
        denial = "don't" if speaker in ("I", "you") else "doesn't"
        core = attach(speaker + " " + denial + " " + question["verb"],
                      question["obj"])
        return "no, " + core + "."
    return "maybe."


def answer_who(question, facts):
    matching = [f for f in facts
                if not f["negative"] and same(f, question["verb"], question["obj"])]
    nobody = any(f["negative"] and f["subject"] == "nobody" and
                 same(f, question["verb"], question["obj"]) for f in facts)
    if any(f["subject"] == "everybody" for f in matching):
        return ("everybody " + attach(conjugate(question["verb"], "everybody"),
                                      question["obj"]) + ".")
    if matching:
        names = [swap(f["subject"]) for f in matching]
        if len(names) == 1:
            listing = names[0]
            verb = conjugate(question["verb"], names[0])
        else:
            listing = ", ".join(names[:-1]) + " and " + names[-1]
            verb = question["verb"]
        return listing + " " + attach(verb, question["obj"]) + "."
    if nobody:
        return attach("nobody " + conjugate(question["verb"], "nobody"),
                      question["obj"]) + "."
    return "I don't know."


def answer_what(question, facts):
    speaker = swap(question["subject"])
    denial = "don't" if speaker in ("I", "you") else "doesn't"
    clauses = []
    seen = set()
    for fact in facts:
        if not applies(fact, question["subject"]):
            continue
        key = (fact["verb"], fact["obj"])
        if key in seen:
            continue
        seen.add(key)
        if fact["negative"]:
            clause = denial + " " + fact["verb"]
        else:
            clause = conjugate(fact["verb"], speaker)
        clauses.append(attach(clause, fact["obj"]))
    if not clauses:
        return "I don't know."
    if len(clauses) == 1:
        body = clauses[0]
    elif len(clauses) == 2:
        body = clauses[0] + ", and " + clauses[1]
    else:
        body = ", ".join(clauses[:-1]) + ", and " + clauses[-1]
    return speaker + " " + body + "."


def oracle(text):
    lines = text.splitlines()
    cursor = 0
    case_count = int(lines[cursor]); cursor += 1
    result = []
    for case_number in range(1, case_count + 1):
        result.append("Dialogue #" + str(case_number) + ":")
        facts = []
        while True:
            line = lines[cursor]; cursor += 1
            if line.endswith("!"):
                result.append(line)
                result.append("")
                break
            if line.endswith("."):
                facts.append(read_fact(line))
                continue
            result.append(line)
            if contradicts(facts):
                result.append("I am abroad.")
            else:
                question = read_question(line)
                if question["kind"] == "yesno":
                    result.append(answer_yesno(question, facts))
                elif question["kind"] == "who":
                    result.append(answer_who(question, facts))
                else:
                    result.append(answer_what(question, facts))
            result.append("")
    return "\n".join(result) + "\n"


def write(name, text):
    (ROOT / "in" / f"{name}.txt").write_text(text)
    (ROOT / "out" / f"{name}.out").write_text(oracle(text))


SAMPLE_IN = """1
I like hotdogs.
nobody likes to work.
everybody smiles.
what do I do?
who smiles?
what do you do?
does Joe smile?
do I like to work?
everybody hurts sometimes.
who walks there?
Michal walks there.
who walks there?
what does Michal do?
do you understand?
nobody walks there.
do you understand now?
bye!
"""
SAMPLE_OUT = """Dialogue #1:
what do I do?
you like hotdogs, don't like to work, and smile.

who smiles?
everybody smiles.

what do you do?
I don't like to work, and smile.

does Joe smile?
yes, Joe smiles.

do I like to work?
no, you don't like to work.

who walks there?
I don't know.

who walks there?
Michal walks there.

what does Michal do?
Michal doesn't like to work, smiles, hurts sometimes, and walks there.

do you understand?
maybe.

do you understand now?
I am abroad.

bye!

"""
assert oracle(SAMPLE_IN) == SAMPLE_OUT


def statement(subject, verb, obj, negative=False):
    verb_part = verb
    if not negative and subject not in ("I", "you"):
        verb_part += "s"
    object_part = " " + obj if obj else ""
    if negative:
        denial = "don't" if subject in ("I", "you") else "doesn't"
        return f"{subject} {denial} {verb}{object_part}."
    return f"{subject} {verb_part}{object_part}."


def generic_statement(positive, verb, obj):
    object_part = " " + obj if obj else ""
    who = "everybody" if positive else "nobody"
    return f"{who} {verb}s{object_part}."


def yesno_question(subject, verb, obj):
    helper = "do" if subject in ("I", "you") else "does"
    object_part = " " + obj if obj else ""
    return f"{helper} {subject} {verb}{object_part}?"


def who_question(verb, obj):
    object_part = " " + obj if obj else ""
    return f"who {verb}s{object_part}?"


def what_question(subject):
    helper = "do" if subject in ("I", "you") else "does"
    return f"what {helper} {subject} do?"


def dialogue(randomizer, statement_count, question_count):
    lines = []
    used = set()
    for _ in range(statement_count):
        style = randomizer.randrange(4)
        if style == 0:
            line = generic_statement(True, randomizer.choice(VERBS),
                                     randomizer.choice(OBJECTS))
        elif style == 1:
            line = generic_statement(False, randomizer.choice(VERBS),
                                     randomizer.choice(OBJECTS))
        else:
            line = statement(randomizer.choice(SUBJECTS),
                             randomizer.choice(VERBS),
                             randomizer.choice(OBJECTS), style == 3)
        if line not in used:
            used.add(line)
            lines.append(line)
    for _ in range(question_count):
        style = randomizer.randrange(3)
        if style == 0:
            lines.append(yesno_question(randomizer.choice(SUBJECTS),
                                        randomizer.choice(VERBS),
                                        randomizer.choice(OBJECTS)))
        elif style == 1:
            lines.append(who_question(randomizer.choice(VERBS),
                                      randomizer.choice(OBJECTS)))
        else:
            lines.append(what_question(randomizer.choice(SUBJECTS)))
    lines.append("bye!")
    return lines


def build():
    random.seed(161803)

    edge_lines = [
        "what do I do?",
        "who likes hotdogs?",
        "does Joe smile?",
        "everybody smiles.",
        "who smiles?",
        "does Joe smile?",
        "I walk there.",
        "you walk there.",
        "who walks there?",
        "what do I do?",
        "what do you do?",
        "nobody walks there.",
        "who walks there?",
        "what does Joe do?",
        "I don't smile.",
        "everybody smiles.",
        "who smiles?",
        "bye!",
    ]
    write("2_edges", "1\n" + "\n".join(edge_lines) + "\n")

    wide_lines = dialogue(random, 100, 60)
    write("3_wide", "1\n" + "\n".join(wide_lines) + "\n")

    random_lines = []
    for _ in range(16):
        random_lines.extend(dialogue(random, random.randint(1, 30),
                                     random.randint(3, 18)))
    write("4_random", str(16) + "\n" + "\n".join(random_lines) + "\n")

    io_lines = []
    for _ in range(120):
        io_lines.extend(dialogue(random, 12, 12))
    write("5_io", str(120) + "\n" + "\n".join(io_lines) + "\n")


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
write("1_sample", SAMPLE_IN)
build()
