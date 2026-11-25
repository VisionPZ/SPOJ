import re
import sys

input_text = sys.stdin.buffer.read().decode()
number_pattern = re.compile(r'-?\d+')
found_numbers = number_pattern.findall(input_text)
answer = 0
if len(found_numbers) >= 5:
    fifth_value = int(found_numbers[4])
    answer = fifth_value * fifth_value
sys.stdout.write(str(answer) + "\n")
