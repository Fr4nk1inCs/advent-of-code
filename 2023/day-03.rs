/*
Advent of Code 2023, Day 03
Title: Gear Ratios
PART 1
  You and the Elf eventually reach a gondola lift station; he says the gondola
  lift will take you up to the water source, but this is as far as he can bring
  you. You go inside.

  It doesn't take long to find the gondolas, but there seems to be a problem:
  they're not moving.

  "Aaah!"

  You turn around to see a slightly-greasy Elf with a wrench and a look of
  surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working
  right now; it'll still be a while before I can fix it." You offer to help.

  The engineer explains that an engine part seems to be missing from the engine,
  but nobody can figure out which one. If you can add up all the part numbers in
  the engine schematic, it should be easy to work out which part is missing.

  The engine schematic (your puzzle input) consists of a visual representation
  of the engine. There are lots of numbers and symbols you don't really
  understand, but apparently any number adjacent to a symbol, even diagonally,
  is a "part number" and should be included in your sum. (Periods (.) do not
  count as a symbol.)

  Here is an example engine schematic:

  467..114..
  ...*......
  ..35..633.
  ......#...
  617*......
  .....+.58.
  ..592.....
  ......755.
  ...$.*....
  .664.598..

  In this schematic, two numbers are not part numbers because they are not
  adjacent to a symbol: 114 (top right) and 58 (middle right). Every other
  number is adjacent to a symbol and so is a part number; their sum is 4361.

  Of course, the actual engine schematic is much larger. What is the sum of all
  of the part numbers in the engine schematic?

PART 2:
 */

use std::cmp::{max, min};
use std::collections::HashMap;
use std::env;

const YEAR: usize = 2023;
const DAY: usize = 03;

const USAGE: &str = "Usage: ./day-03 <part(1|2)> [test]";

fn solve_part_1(input: &str) -> u32 {
    let lines: Vec<&str> = input.lines().collect();
    let char_matrix: Vec<Vec<char>> = lines.iter().map(|line| line.chars().collect()).collect();
    let mut sum = 0;

    let height = lines.len();
    let width = lines[0].len();

    for (y, line) in lines.iter().enumerate() {
        let mut lx = 0;
        while lx < width {
            // Get to next number
            if !char_matrix[y][lx].is_digit(10) {
                lx += 1;
                continue;
            }
            let mut rx = lx + 1;
            while rx < width && char_matrix[y][rx].is_digit(10) {
                rx += 1;
            }
            let number = line[lx..rx].parse::<u32>().unwrap();
            // Check if number is adjacent to symbol
            let left = max(0, lx as isize - 1) as usize;
            let right = min(width - 1, rx + 1);
            // Check above
            if y > 0 {
                let above: Vec<char> = lines[y - 1][left..right]
                    .chars()
                    .filter(|x| x != &'.' && !x.is_digit(10))
                    .collect();
                if above.len() > 0 {
                    sum += number;
                }
            }
            // Check left and right
            if lx > 0 {
                if char_matrix[y][lx - 1] != '.' {
                    sum += number;
                }
            }
            if rx < width {
                if char_matrix[y][rx] != '.' {
                    sum += number;
                }
            }
            // Check below
            if y < height - 1 {
                let below: Vec<char> = lines[y + 1][left..right]
                    .chars()
                    .filter(|x| x != &'.' && !x.is_digit(10))
                    .collect();
                if below.len() > 0 {
                    sum += number;
                }
            }
            lx = rx;
        }
    }

    sum
}

fn test_part_1() {
    let input = "467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..";
    assert_eq!(solve_part_1(input), 4361);
}

fn solve_part_2(input: &str) -> u32 {
    let lines: Vec<&str> = input.lines().collect();
    let char_matrix: Vec<Vec<char>> = lines.iter().map(|line| line.chars().collect()).collect();

    let height = lines.len();
    let width = lines[0].len();

    let mut star_to_numbers: HashMap<(usize, usize), Vec<u32>> = Default::default();

    let mut update_or_insert = |x: usize, y: usize, number: u32| {
        if let Some(numbers) = star_to_numbers.get_mut(&(x, y)) {
            numbers.push(number);
        } else {
            star_to_numbers.insert((x, y), vec![number]);
        }
    };

    for (y, line) in lines.iter().enumerate() {
        let mut lx = 0;
        while lx < width {
            // Get to next number
            if !char_matrix[y][lx].is_digit(10) {
                lx += 1;
                continue;
            }
            let mut rx = lx + 1;
            while rx < width && char_matrix[y][rx].is_digit(10) {
                rx += 1;
            }
            let number = line[lx..rx].parse::<u32>().unwrap();
            // Check if number is adjacent to symbol
            let left = max(0, lx as isize - 1) as usize;
            let right = min(width - 1, rx + 1);
            // Check above
            if y > 0 {
                for x in left..right {
                    if char_matrix[y - 1][x] != '*' {
                        continue;
                    }
                    update_or_insert(x, y - 1, number);
                }
            }
            // Check left and right
            if lx > 0 {
                if char_matrix[y][lx - 1] == '*' {
                    update_or_insert(lx - 1, y, number);
                }
            }
            if rx < width {
                if char_matrix[y][rx] == '*' {
                    update_or_insert(rx, y, number);
                }
            }
            // Check below
            if y < height - 1 {
                for x in left..right {
                    if char_matrix[y + 1][x] != '*' {
                        continue;
                    }
                    update_or_insert(x, y + 1, number);
                }
            }
            lx = rx;
        }
    }

    star_to_numbers
        .values()
        .filter_map(|numbers| {
            if numbers.len() == 2 {
                Some(numbers[0] * numbers[1])
            } else {
                None
            }
        })
        .reduce(|acc, number| acc + number)
        .unwrap()
}

fn test_part_2() {
    let input = "467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598..";
    assert_eq!(solve_part_2(input), 467835);
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

fn test(part: u32) {
    match part {
        1 => test_part_1(),
        2 => test_part_2(),
        _ => panic!("Unknown part: {}", part),
    }
}

fn solve(input: &str, part: u32) -> u32 {
    match part {
        1 => solve_part_1(input),
        2 => solve_part_2(input),
        _ => panic!("Unknown part: {}\n{}", part, USAGE),
    }
}
