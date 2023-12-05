/*
Advent of Code <year>, Day <day>
Title: <title>
PART 1

PART 2:
 */

use std::env;

const YEAR: usize = <year>;
const DAY: usize = <day>;

const USAGE: &str = "Usage: ./day-<day> <part(1|2)> [test]";

fn solve_part_1(input: &str) -> u32 {
    unimplemented!()
}

fn test_part_1() {
    let input = "";
    assert_eq!(solve_part_1(input), 0);
}


fn solve_part_2(input: &str) -> u32 {
    unimplemented!()
}

fn test_part_2() {
    let input = "";
    assert_eq!(solve_part_2(input), 0);
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

