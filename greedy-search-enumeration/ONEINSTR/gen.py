#!/usr/bin/env python3
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class Compiler:
    def __init__(self):
        self.instructions = []
        self.next_data = 9000
        self.constant_count = 0
        self.one_cell = -1
        self.jump_cell = -1

    def emit(self, first, second, target):
        self.instructions.append([first, second, target])
        return 9 + 3 * (len(self.instructions) - 1)

    def next_pc(self):
        return 9 + 3 * len(self.instructions)

    def flow(self, first, second):
        return self.emit(first, second, self.next_pc() + 3)

    def allocate(self):
        cell = self.next_data
        self.next_data += 1
        return cell

    def clear(self, cell):
        self.flow(cell, cell)

    def add_const(self, cell, amount):
        if amount:
            self.flow(-amount, cell)

    def load_constant_cell(self, value):
        cell = self.allocate()
        self.clear(cell)
        self.add_const(cell, value)
        return cell

    def sub_const(self, cell, amount):
        if amount:
            source = self.load_constant_cell(amount)
            self.flow(source, cell)

    def ensure_one(self):
        if self.one_cell < 0:
            self.one_cell = self.allocate()
            self.clear(self.one_cell)
            self.add_const(self.one_cell, 1)

    def ensure_jump(self):
        if self.jump_cell < 0:
            self.jump_cell = self.allocate()

    def negate_into(self, source, target):
        self.clear(target)
        self.flow(source, target)

    def copy_positive(self, source, target):
        holding = self.allocate()
        self.negate_into(source, holding)
        self.clear(target)
        self.flow(holding, target)

    @staticmethod
    def address(cell, negated):
        return (False, 0, cell, negated)

    @staticmethod
    def constant(value):
        return (True, value, -1, False)

    def make_positive(self, slot):
        is_constant, value, cell, negated = slot
        if is_constant or not negated:
            return slot
        target = self.allocate()
        self.negate_into(cell, target)
        return self.address(target, False)

    def subtract(self, left, right):
        left = self.make_positive(left)
        right = self.make_positive(right)
        if left[0] and right[0]:
            cell = self.allocate()
            self.clear(cell)
            self.add_const(cell, right[1])
            self.sub_const(cell, left[1])
            return self.address(cell, True)
        if left[0]:
            self.sub_const(right[2], left[1])
            return self.address(right[2], True)
        if right[0]:
            cell = self.allocate()
            self.clear(cell)
            self.add_const(cell, right[1])
            self.flow(left[2], cell)
            return self.address(cell, True)
        self.flow(left[2], right[2])
        return self.address(right[2], True)

    def add(self, left, right):
        left = self.make_positive(left)
        right = self.make_positive(right)
        cell = self.allocate()
        self.clear(cell)
        if left[0]:
            self.sub_const(cell, left[1])
        else:
            self.flow(left[2], cell)
        if right[0]:
            self.sub_const(cell, right[1])
        else:
            self.flow(right[2], cell)
        return self.address(cell, True)

    def multiply(self, left, right):
        left = self.make_positive(left)
        right = self.make_positive(right)
        self.ensure_one()
        self.ensure_jump()
        counter = self.allocate()
        accumulator = self.allocate()
        if left[0]:
            self.clear(counter)
            self.add_const(counter, left[1] + 1)
        else:
            self.copy_positive(left[2], counter)
            self.add_const(counter, 1)
        self.clear(accumulator)
        loop_start = self.next_pc()
        decrement = len(self.instructions)
        self.emit(self.one_cell, counter, 0)
        if right[0]:
            self.sub_const(accumulator, right[1])
        else:
            self.flow(right[2], accumulator)
        self.emit(self.jump_cell, self.jump_cell, loop_start)
        self.instructions[decrement][2] = self.next_pc()
        return self.address(accumulator, True)

    def divide(self, left, right):
        left = self.make_positive(left)
        right = self.make_positive(right)
        if left[0] and left[1] == 0:
            return self.constant(0)
        self.ensure_one()
        work = self.allocate()
        quotient = self.allocate()
        if left[0]:
            self.clear(work)
            self.add_const(work, left[1])
        else:
            self.copy_positive(left[2], work)
        self.clear(quotient)
        check = self.allocate()
        self.copy_positive(work, check)
        self.add_const(check, 1)
        empty = len(self.instructions)
        self.emit(self.one_cell, check, 0)
        self.flow(self.one_cell, quotient)
        if right[0]:
            divisor = self.load_constant_cell(right[1])
        else:
            divisor = right[2]
        loop_start = self.next_pc()
        subtract = len(self.instructions)
        self.emit(divisor, work, 0)
        self.emit(self.one_cell, quotient, loop_start)
        after_loop = self.next_pc()
        self.instructions[empty][2] = after_loop
        self.instructions[subtract][2] = after_loop
        return self.address(quotient, True)

    def finish(self, slot):
        is_constant, value, cell, negated = slot
        if is_constant:
            if value > 0:
                self.emit(-value, 0, 0)
            return
        if negated:
            if cell == 0:
                holding = self.allocate()
                self.negate_into(0, holding)
                self.flow(holding, 0)
            else:
                self.flow(cell, 0)
            return
        if cell != 0:
            holding = self.allocate()
            self.negate_into(cell, holding)
            self.flow(holding, 0)

    def compile(self, expression):
        tokens = expression.split()
        lone_zero = tokens == ["M0"]
        uses_zero = "M0" in tokens
        saved_zero = -1
        if uses_zero and not lone_zero:
            saved_zero = self.allocate()
            self.copy_positive(0, saved_zero)
        if not lone_zero:
            self.clear(0)
        stack = []
        for token in tokens:
            if token == '+':
                right = stack.pop(); left = stack.pop(); stack.append(self.add(left, right))
            elif token == '-':
                right = stack.pop(); left = stack.pop(); stack.append(self.subtract(left, right))
            elif token == '*':
                right = stack.pop(); left = stack.pop(); stack.append(self.multiply(left, right))
            elif token == '/':
                right = stack.pop(); left = stack.pop(); stack.append(self.divide(left, right))
            elif token.startswith('M'):
                variable_index = int(token[1])
                if variable_index == 0 and saved_zero >= 0:
                    stack.append(self.address(saved_zero, False))
                else:
                    stack.append(self.address(variable_index, False))
            else:
                self.constant_count += 1
                stack.append(self.constant(int(token)))
        self.finish(stack[-1])
        halt_index = len(self.instructions)
        self.emit(0, 0, 10000)
        halt_cell = 9 + 3 * len(self.instructions) + self.constant_count
        self.instructions[halt_index][0] = halt_cell
        self.instructions[halt_index][1] = halt_cell
        return [line[:] for line in self.instructions]

    def text(self, expression):
        program = self.compile(expression)
        return str(len(program)) + "\n" + "".join(
            " ".join(map(str, line)) + "\n" for line in program)


def simulate(program, inputs):
    memory = [0] * 9999
    for index, value in enumerate(inputs):
        memory[index] = value
    for index, instruction in enumerate(program):
        for offset, value in enumerate(instruction):
            memory[9 + 3 * index + offset] = value
    pc = 9
    cycles = 0
    while pc < 9997:
        first = memory[pc]
        second = memory[pc + 1]
        target = memory[pc + 2]
        if first >= 0:
            memory[second] = memory[second] - memory[first]
        else:
            memory[second] = memory[second] - first
        if memory[second] > 0:
            pc += 3
        else:
            pc = target
        cycles += 1
        if cycles > 10000000:
            return None
    return memory[0]


def evaluate(expression, inputs):
    stack = []
    for token in expression.split():
        if token in "+-*/" and len(token) == 1:
            right = stack.pop(); left = stack.pop()
            if token == '+': stack.append(left + right)
            elif token == '-': stack.append(left - right)
            elif token == '*': stack.append(left * right)
            else: stack.append(left // right)
        elif token.startswith('M'):
            stack.append(inputs[int(token[1])])
        else:
            stack.append(int(token))
    return stack[-1]


def check(expression, assignment):
    inputs = [0] * 9
    for index, value in assignment.items():
        inputs[index] = value
    program = Compiler().compile(expression)
    result = simulate(program, inputs)
    assert result == evaluate(expression, inputs), (expression, assignment, result)
    assert len(program) < 3000
    return Compiler().text(expression)


SAMPLE_IN = "100\nM1 M2 -\n"
SAMPLE_OUT = ("3\n0 0 12\n-100 0 0\n19 19 10000\n"
              "4\n0 0 12\n1 2 15\n2 0 18\n21 21 10000\n")
assert "".join(Compiler().text(expression) for expression in SAMPLE_IN.splitlines()) == SAMPLE_OUT


def write(name, expressions):
    input_text = "\n".join(expressions) + "\n"
    output_text = "".join(Compiler().text(expression) for expression in expressions)
    (ROOT / "in" / f"{name}.txt").write_text(input_text)
    (ROOT / "out" / f"{name}.out").write_text(output_text)


def build():
    check("100", {})
    check("M1 M2 -", {1: 9, 2: 4})
    check("M1 M2 +", {1: 9, 2: 4})
    check("M1 M2 *", {1: 9, 2: 4})
    check("M1 M2 /", {1: 12, 2: 4})
    check("0", {})
    check("M0", {0: 7})
    check("M1 M0 -", {0: 7, 1: 12})
    check("10 3 +", {})
    check("10 3 -", {})
    write("2_edges", [
        "0", "100", "M0", "M1 M0 -", "10 3 +", "120 4 /",
        "M3 M4 + M5 *", "M6 M2 - 3 *", "7 5 * 2 +",
    ])
    write("3_wide", [
        "1000 2000 + 3 * 9 /",
        "M1 M2 + M3 M4 + + M5 M6 + +",
        "120 4 / 2 * 10 + 5 /",
        "M7 M8 + 2 * 3 +",
    ])
    rng = random.Random(20261126)
    random_expressions = []
    for _ in range(25):
        term_count = rng.randint(2, 4)
        terms = []
        for _ in range(term_count):
            if rng.randrange(3) == 0:
                terms.append(f"M{rng.randint(1, 8)}")
            else:
                terms.append(str(rng.randint(1, 50)))
        operators = [rng.choice("+-*") for _ in range(term_count - 1)]
        expression = " ".join(terms + operators)
        assignment = {index: rng.randint(5, 40) for index in range(1, 9)}
        check(expression, assignment)
        random_expressions.append(expression)
    write("4_random", random_expressions)
    io_expressions = [f"{index + 1} {index + 2} + 2 *" for index in range(3000)]
    write("5_io", io_expressions)


(ROOT / "in").mkdir(exist_ok=True)
(ROOT / "out").mkdir(exist_ok=True)
(ROOT / "in" / "1_sample.txt").write_text(SAMPLE_IN)
(ROOT / "out" / "1_sample.out").write_text(SAMPLE_OUT)
build()
