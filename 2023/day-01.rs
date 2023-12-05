/*
Advent of Code 2023, Day 01
Title: Trebuchet?!
PART 1
  Something is wrong with global snow production, and you've been selected to
  take a look. The Elves have even given you a map; on it, they've used stars to
  mark the top fifty locations that are likely to be having problems.

  You've been doing this long enough to know that to restore snow operations,
  you need to check all fifty stars by December 25th.

  Collect stars by solving puzzles. Two puzzles will be made available on each
  day in the Advent calendar; the second puzzle is unlocked when you complete
  the first. Each puzzle grants one star. Good luck!

  You try to ask why they can't just use a weather machine ("not powerful
  enough") and where they're even sending you ("the sky") and why your map looks
  mostly blank ("you sure ask a lot of questions") and hang on did you just say
  the sky ("of course, where do you think snow comes from") when you realize
  that the Elves are already loading you into a trebuchet ("please hold still,
  we need to strap you in").

  As they're making the final adjustments, they discover that their
  calibration document (your puzzle input) has been amended by a very young Elf
  who was apparently just excited to show off her art skills. Consequently, the
  Elves are having trouble reading the values on the document.

  The newly-improved calibration document consists of lines of text; each line
  originally contained a specific calibration value that the Elves now need to
  recover. On each line, the calibration value can be found by combining the
  first digit and the last digit (in that order) to form a single two-digit
  number.

  For example:

  1abc2
  pqr3stu8vwx
  a1b2c3d4e5f
  treb7uchet

  In this example, the calibration values of these four lines are 12, 38,
  15, and 77. Adding these together produces 142.

PART 2:
  Your calculation isn't quite right. It looks like some of the digits are
  actually spelled out with letters: one, two, three, four, five, six, seven,
  eight, and nine also count as valid "digits".

  Equipped with this new information, you now need to find the real first and
  last digit on each line. For example:

  two1nine
  eightwothree
  abcone2threexyz
  xtwone3four
  4nineeightseven2
  zoneight234
  7pqrstsixteen

  In this example, the calibration values are 29, 83, 13, 24, 42, 14, and 76.
  Adding these together produces 281.

  What is the sum of all of the calibration values?
 */

use std::env;

const YEAR: usize = 2023;
const DAY: usize = 01;

const USAGE: &str = "Usage: ./day-01 <part(1|2)> [test]";

fn solve_part_1(input: &str) -> u32 {
    let lines = input.lines();
    let mut sum: u32 = 0;

    for line in lines {
        let digits: Vec<u32> = line.chars().filter_map(|c| c.to_digit(10)).collect();
        sum += 10 * digits.first().unwrap_or(&0) + digits.last().unwrap_or(&0);
    }
    sum
}

fn test_part_1() {
    let input = "1abc2
pqr3stu8vwx
a1b2c3d4e5f
treb7uchet";
    assert_eq!(solve_part_1(input), 142);
}

fn solve_part_2(input: &str) -> u32 {
    let digit_lits = vec![
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    ];
    let mut input = input.to_string();
    for (i, digit_lit) in digit_lits.iter().enumerate() {
        input = input.replace(digit_lit, &format!("{}{}{}", digit_lit, i + 1, digit_lit));
    }
    solve_part_1(&input)
}

fn test_part_2() {
    let input = "two1nine
eightwothree
abcone2threexyz
xtwone3four
4nineeightseven2
zoneight234
7pqrstsixteen
";
    assert_eq!(solve_part_2(input), 281)
}

fn get_input_str() -> String {
    let exe = match env::current_exe() {
        Ok(exe) => exe,
        Err(e) => panic!("Couldn't get current exe: {}", e),
    };
    let base_dir = match exe.parent() {
        Some(base_dir) => base_dir,
        None => panic!("Couldn't get parent dir of exe"),
    };
    let mut input_path = base_dir.to_path_buf();
    if !input_path.pop() {
        panic!("Couldn't pop parent dir of exe");
    }
    input_path.push("inputs");
    input_path.push(format!("{}", YEAR));
    input_path.push(format!("day-{:02}.txt", DAY));
    match std::fs::read_to_string(input_path) {
        Ok(input) => input,
        Err(e) => panic!("Couldn't read input file: {}", e),
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        panic!("Missing part\n{}", USAGE);
    }
    if args.len() > 3 {
        panic!("Too many arguments\n{}", USAGE);
    }
    let part = match args[1].parse::<u32>() {
        Ok(part) => part,
        Err(e) => panic!("Couldn't parse part: {}\n{}", e, USAGE),
    };

    if args.len() == 3 {
        if args[2] == "test" {
            test(part);
            return;
        } else {
            panic!("Unknown usage: {}\n{}", args[1], USAGE);
        }
    }

    println!("{}", solve(&get_input_str(), part));
}

fn solve(input: &str, part: u32) -> u32 {
    match part {
        1 => solve_part_1(input),
        2 => solve_part_2(input),
        _ => panic!("Unknown part: {}\n{}", part, USAGE),
    }
}

fn test(part: u32) {
    match part {
        1 => test_part_1(),
        2 => test_part_2(),
        _ => panic!("Unknown part: {}", part),
    }
}
