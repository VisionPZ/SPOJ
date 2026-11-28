#!/usr/bin/env python3
import os, random, sys

sys.set_int_max_str_digits(20000000)

DIGITS = "0123456789"


def is_greater(first, second):
    return len(first) > len(second) or (len(first) == len(second) and first > second)


def palindromes_from_prefix(prefix):
    return [prefix + prefix[-2::-1], prefix + prefix[::-1]]


def next_palindromes(number_text):
    number_text = number_text.lstrip("0") or "0"
    length = len(number_text)
    candidates = []
    for half_length in ((length + 1) // 2, (length + 3) // 2):
        smallest_prefix = 10 ** (half_length - 1)
        prefix_values = {smallest_prefix + step for step in (0, 1, 2, 3)}
        if half_length <= length:
            center_prefix = int(number_text[:half_length])
            prefix_values |= {center_prefix + step for step in (-1, 0, 1, 2, 3)}
        for prefix_value in prefix_values:
            prefix = str(prefix_value)
            if len(prefix) != half_length or prefix[0] == "0":
                continue
            for form in palindromes_from_prefix(prefix):
                if len(form) >= length and form[0] != "0" and is_greater(form, number_text):
                    candidates.append(form)
    return sorted(set(candidates), key=lambda s: (len(s), s))[:3]


def largest_palindrome_below(number_text):
    number_text = number_text.lstrip("0") or "0"
    length = len(number_text)
    if length == 1:
        return ""
    candidates = ["9" * (length - 1)]
    half_length = (length + 1) // 2
    center_prefix = int(number_text[:half_length])
    for prefix_value in range(center_prefix - 1, center_prefix + 2):
        prefix = str(prefix_value)
        if len(prefix) != half_length or prefix[0] == "0":
            continue
        for form in palindromes_from_prefix(prefix):
            if len(form) == length and form[0] != "0" and is_greater(number_text, form):
                candidates.append(form)
    return max(candidates, key=lambda s: (len(s), s))


def sweep_next_palindromes(number_text, window):
    value = int(number_text)
    answers = []
    for probe in range(value + 1, value + window):
        probe_text = str(probe)
        if probe_text == probe_text[::-1]:
            answers.append(probe_text)
            if len(answers) == 3:
                break
    return answers


assert next_palindromes("808") == ["818", "828", "838"]
assert next_palindromes("99") == ["101", "111", "121"]
assert next_palindromes("9999") == ["10001", "10101", "10201"]
assert next_palindromes("123") == ["131", "141", "151"]
assert next_palindromes("0") == ["1", "2", "3"]
assert next_palindromes("99999999999999999999") == [
    "100000000000000000001", "100000000010000000001", "100000000020000000001"]
assert next_palindromes("1" + "0" * 999_999)[0] == "1" + "0" * 999_998 + "1"
assert next_palindromes("9" * 999_999 + "0")[0] == "9" * 1_000_000
assert next_palindromes("9" * 1_000_000)[0] == "1" + "0" * 999_999 + "1"
assert largest_palindrome_below("100") == "99"
assert largest_palindrome_below("1000000") == "999999"
assert largest_palindrome_below("10") == "9"
assert largest_palindrome_below("121") == "111"
for small_number in range(10 ** 4):
    small_text = str(small_number)
    assert next_palindromes(small_text) == sweep_next_palindromes(small_text, 500), small_text
spot_generator = random.Random(999)
for _ in range(200):
    spot_value = spot_generator.randint(10 ** 4, 10 ** 7)
    spot_text = str(spot_value)
    assert next_palindromes(spot_text) == sweep_next_palindromes(spot_text, 50000), spot_text
print("oracle cross-check OK")


def write_case(case_name, input_lines, output_lines):
    with open(f"in/{case_name}.txt", "w") as input_file:
        input_file.write("\n".join(input_lines) + "\n")
    with open(f"out/{case_name}.out", "w") as output_file:
        output_file.write("\n".join(output_lines) + "\n")


def expected_answer_lines(numbers):
    return [next_palindromes(n)[0] for n in numbers]


os.makedirs("in", exist_ok=True)
os.makedirs("out", exist_ok=True)

write_case("1_sample", ["2", "808", "2133"], ["818", "2222"])

edge_numbers = ["0", "1", "9", "10", "11", "12", "99", "100", "101", "109", "110",
                "999", "1000", "1001", "1099", "1100", "9999", "10000", "10001",
                "99999", "100000", "12345", "54321", "121", "122", "120",
                "1000000000", "999999999", "1000000001"]
write_case("2_edges", [str(len(edge_numbers))] + edge_numbers,
           expected_answer_lines(edge_numbers))

middle_palindrome = "9" * 499_999 + "9" + "9" * 499_999
wide_numbers = ["9" * 1_000_000, "1" * 1_000_000, middle_palindrome,
                "1" + "0" * 999_998 + "1", "9" * 999_999 + "0",
                "1" + "0" * 999_999, "9" * 499_999 + "8" + "9" * 499_999]
write_case("3_wide", [str(len(wide_numbers))] + wide_numbers,
           expected_answer_lines(wide_numbers))

random_generator = random.Random(12345)
random_numbers = []
for _ in range(360):
    digit_count = random_generator.randint(1, 12)
    leading_digit = random_generator.randint(1, 9)
    random_numbers.append(str(leading_digit) + "".join(
        random_generator.choice(DIGITS) for _ in range(digit_count - 1)))
for _ in range(40):
    digit_count = random_generator.choice([17, 25, 40])
    leading_digit = random_generator.randint(1, 9)
    random_numbers.append(str(leading_digit) + "".join(
        random_generator.choice(DIGITS) for _ in range(digit_count - 1)))
write_case("4_random", [str(len(random_numbers))] + random_numbers,
           expected_answer_lines(random_numbers))

io_stress_numbers = []
for _ in range(20):
    digit_count = random_generator.randint(50_000, 100_000)
    leading_digit = random_generator.randint(1, 9)
    io_stress_numbers.append(str(leading_digit) + "".join(
        random_generator.choice(DIGITS) for _ in range(digit_count - 1)))
write_case("5_io", [str(len(io_stress_numbers))] + io_stress_numbers,
           expected_answer_lines(io_stress_numbers))

noise_numbers = ["00012345", "0011", "000000099", "0012345", "000000",
                 "009", "000", "00099", "0001", "00000"]
noise_lines = [str(len(noise_numbers))]
for index, number_text in enumerate(noise_numbers):
    if index % 3 == 2:
        noise_lines.append("")
    noise_lines.append("  " + number_text if index % 4 == 3 else number_text)
write_case("6_noise", noise_lines, expected_answer_lines(noise_numbers))

no_eol_numbers = ["9999", "808", "2133", "12345", "9"]
with open("in/7_noeol.txt", "w") as input_file:
    input_file.write(str(len(no_eol_numbers)) + "\n" + "\n".join(no_eol_numbers))
with open("out/7_noeol.out", "w") as output_file:
    output_file.write("\n".join(next_palindromes(n)[0] for n in no_eol_numbers) + "\n")

tight_numbers = ["11", "12", "19", "20", "99", "100", "101", "111", "112", "199", "200"]
for number_text in tight_numbers:
    previous_palindrome = largest_palindrome_below(number_text)
    assert previous_palindrome == previous_palindrome[::-1], number_text
    assert is_greater(number_text, previous_palindrome), number_text

print("oracle OK")
