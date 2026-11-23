import random
from collections import deque

firstDigitValue = 48
sampleInput = """2
5
SET 0 1
JZ 4 0
RANDOM 0
JMP 1
STOP
5
MOV 3 5
NOT 3
AND 3 5
JZ 0 3
STOP
"""
sampleOutput = """6
HANGS
"""


def mentionedRegisters(program):
    registers = set()
    for instruction in program:
        opcode = instruction[0]
        if opcode in ('AND', 'OR', 'XOR', 'MOV'):
            registers.add(int(instruction[1]))
            registers.add(int(instruction[2]))
        elif opcode in ('NOT', 'RANDOM', 'SET'):
            registers.add(int(instruction[1]))
        elif opcode == 'JZ':
            registers.add(int(instruction[2]))
    return sorted(registers)


def oracle(program):
    registers = mentionedRegisters(program)
    startStates = []
    for assignment in range(1 << len(registers)):
        contents = 0
        for position, register in enumerate(registers):
            if (assignment >> position) & 1:
                contents |= 1 << register
        startStates.append(contents)
    queue = deque()
    visited = set()
    for contents in startStates:
        key = (0, contents)
        if key not in visited:
            visited.add(key)
            queue.append((0, contents, 0))
    while queue:
        pc, contents, depth = queue.popleft()
        if depth > 4096:
            return None
        opcode = program[pc][0]
        if opcode == 'STOP':
            return depth + 1
        nextPc = pc + 1
        nextContents = contents
        if opcode == 'SET':
            target = int(program[pc][1])
            value = int(program[pc][2])
            nextContents = (contents & ~(1 << target)) | (value << target)
        elif opcode == 'NOT':
            target = int(program[pc][1])
            bit = (contents >> target) & 1
            nextContents = (contents & ~(1 << target)) | ((1 - bit) << target)
        elif opcode == 'MOV':
            target = int(program[pc][1])
            source = int(program[pc][2])
            bit = (contents >> source) & 1
            nextContents = (contents & ~(1 << target)) | (bit << target)
        elif opcode in ('AND', 'OR', 'XOR'):
            target = int(program[pc][1])
            source = int(program[pc][2])
            left = (contents >> target) & 1
            right = (contents >> source) & 1
            if opcode == 'AND':
                bit = left & right
            elif opcode == 'OR':
                bit = left | right
            else:
                bit = left ^ right
            nextContents = (contents & ~(1 << target)) | (bit << target)
        elif opcode == 'RANDOM':
            target = int(program[pc][1])
            for value in (0, 1):
                altered = (contents & ~(1 << target)) | (value << target)
                key = (nextPc, altered)
                if key not in visited:
                    visited.add(key)
                    queue.append((nextPc, altered, depth + 1))
            continue
        elif opcode == 'JMP':
            nextPc = int(program[pc][1])
        elif opcode == 'JZ':
            target = int(program[pc][2])
            if ((contents >> target) & 1) == 0:
                nextPc = int(program[pc][1])
        key = (nextPc, nextContents)
        if key not in visited:
            visited.add(key)
            queue.append((nextPc, nextContents, depth + 1))
    return None


def answerText(result):
    return 'HANGS' if result is None else str(result)


def render(programs):
    parts = [str(len(programs))]
    for program in programs:
        parts.append(str(len(program)))
        for instruction in program:
            parts.append(' '.join(instruction))
    return '\n'.join(parts) + '\n'


def renderAnswers(results):
    return '\n'.join(answerText(result) for result in results) + '\n'


def deterministicPrograms():
    programs = []
    results = []
    programs.append([['STOP']])
    results.append(1)
    programs.append([['JMP', '0'], ['STOP']])
    results.append(None)
    programs.append([['JZ', '1', '0'], ['STOP']])
    results.append(2)
    programs.append([['RANDOM', '0'], ['JZ', '3', '0'], ['STOP'], ['STOP']])
    results.append(3)
    programs.append([['MOV', '3', '5'], ['NOT', '3'], ['AND', '3', '5'], ['JZ', '0', '3'], ['STOP']])
    results.append(None)
    return programs, results


def widePrograms():
    programs = []
    results = []
    straight = []
    for index in range(15):
        straight.append(['NOT', str(index % 8)])
    straight.append(['STOP'])
    programs.append(straight)
    results.append(16)
    loop = []
    for index in range(15):
        loop.append(['JMP', str(index)])
    loop.append(['STOP'])
    programs.append(loop)
    results.append(None)
    longChain = []
    for index in range(15):
        longChain.append(['MOV', str((index + 1) % 8), str(index % 8)])
    longChain.append(['STOP'])
    programs.append(longChain)
    results.append(16)
    return programs, results


def randomPrograms(count, rng, sizeLimit):
    programs = []
    results = []
    for _ in range(count):
        size = rng.randint(1, sizeLimit)
        program = []
        for _ in range(size - 1):
            kind = rng.choice(['SET', 'NOT', 'MOV', 'AND', 'OR', 'XOR', 'RANDOM', 'JMP', 'JZ', 'JZ'])
            first = str(rng.randint(0, 5))
            second = str(rng.randint(0, 5))
            if kind == 'SET':
                instruction = ['SET', first, str(rng.randint(0, 1))]
            elif kind == 'NOT':
                instruction = ['NOT', first]
            elif kind in ('MOV', 'AND', 'OR', 'XOR'):
                instruction = [kind, first, second]
            elif kind == 'RANDOM':
                instruction = ['RANDOM', first]
            elif kind == 'JMP':
                instruction = ['JMP', str(rng.randint(0, size - 1))]
            else:
                instruction = ['JZ', str(rng.randint(0, size - 1)), first]
            program.append(instruction)
        program.append(['STOP'])
        programs.append(program)
        results.append(oracle(program))
    return programs, results


def writePair(name, programs, results):
    expected = renderAnswers(results)
    with open('in/' + name + '.txt', 'w') as output:
        output.write(render(programs))
    with open('out/' + name + '.out', 'w') as output:
        output.write(expected)


def main():
    samplePrograms = []
    sampleLines = sampleInput.strip().split('\n')
    position = 0
    caseCount = int(sampleLines[position])
    position += 1
    for _ in range(caseCount):
        size = int(sampleLines[position])
        position += 1
        samplePrograms.append([sampleLines[position + index].split() for index in range(size)])
        position += size
    sampleResults = [6, None]
    assert oracle(samplePrograms[0]) == 6
    assert oracle(samplePrograms[1]) is None
    assert oracle([['STOP']]) == 1
    assert oracle([['JMP', '0'], ['STOP']]) is None
    writePair('1_sample', samplePrograms, sampleResults)

    edgePrograms, edgeResults = deterministicPrograms()
    writePair('2_edges', edgePrograms, edgeResults)

    wideProgramsList, wideResults = widePrograms()
    writePair('3_wide', wideProgramsList, wideResults)

    rng = random.Random(20231124)
    randomCases, randomResults = randomPrograms(200, rng, 16)
    writePair('4_random', randomCases, randomResults)

    ioRng = random.Random(90210)
    ioCases, ioResults = randomPrograms(30000, ioRng, 4)
    writePair('5_io', ioCases, ioResults)


if __name__ == '__main__':
    main()
