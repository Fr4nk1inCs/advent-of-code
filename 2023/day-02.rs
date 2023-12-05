/*
Advent of Code 2023, Day 02
Title: <title>
PART 1
  You're launched high into the atmosphere! The apex of your trajectory just
  barely reaches the surface of a large island floating in the sky. You gently
  land in a fluffy pile of leaves. It's quite cold, but you don't see much snow.
  An Elf runs over to greet you.

  The Elf explains that you've arrived at Snow Island and apologizes for the
  lack of snow. He'll be happy to explain the situation, but it's a bit of a
  walk, so you have some time. They don't get many visitors up here; would you
  like to play a game in the meantime?

  As you walk, the Elf shows you a small bag and some cubes which are either
  red, green, or blue. Each time you play this game, he will hide a secret
  number of cubes of each color in the bag, and your goal is to figure out
  information about the number of cubes.

  To get information, once a bag has been loaded with cubes, the Elf will reach
  into the bag, grab a handful of random cubes, show them to you, and then put
  them back in the bag. He'll do this a few times per game.

  You play several games and record the information from each game (your puzzle
  input). Each game is listed with its ID number (like the 11 in Game 11: ...)
  followed by a semicolon-separated list of subsets of cubes that were revealed
  from the bag (like 3 red, 5 green, 4 blue).

  For example, the record of a few games might look like this:

  Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
  Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
  Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
  Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
  Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green

  The Elf would first like to know which games would have been possible if the
  bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?

  In the example above, games 1, 2, and 5 would have been possible if the bag
  had been loaded with that configuration. However, game 3 would have been
  impossible because at one point the Elf showed you 20 red cubes at once;
  similarly, game 4 would also have been impossible because the Elf showed you
  15 blue cubes at once. If you add up the IDs of the games that would have been
  possible, you get 8.

  Determine which games would have been possible if the bag had been loaded with
  only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the
  IDs of those games?

PART 2:
  The Elf says they've stopped producing snow because they aren't getting any
  water! He isn't sure why the water stopped; however, he can show you how to
  get to the water source to check it out for yourself. It's just up ahead!

  As you continue your walk, the Elf poses a second question: in each game you
  played, what is the fewest number of cubes of each color that could have been
  in the bag to make the game possible?

  Again consider the example games from earlier:

  Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
  Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
  Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
  Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
  Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green

  - In game 1, the game could have been played with as few as 4 red, 2 green,
    and 6 blue cubes. If any color had even one fewer cube, the game would have
    been impossible.
  - Game 2 could have been played with a minimum of 1 red, 3 green, and 4 blue
    cubes.
  - Game 3 must have been played with at least 20 red, 13 green, and 6 blue
    cubes.
  - Game 4 required at least 14 red, 3 green, and 15 blue cubes.
  - Game 5 needed no fewer than 6 red, 3 green, and 2 blue cubes in the bag.

  The power of a set of cubes is equal to the numbers of red, green, and blue
  cubes multiplied together. The power of the minimum set of cubes in game 1 is
  48. In games 2-5 it was 12, 1560, 630, and 36, respectively. Adding up these
  five powers produces the sum 2286.

  For each game, find the minimum set of cubes that must have been present. What
  is the sum of the power of these sets?
 */

use std::cmp::max;
use std::env;

const YEAR: usize = 2023;
const DAY: usize = 02;

const USAGE: &str = "Usage: ./day-02 <part(1|2)> [test]";

struct CubeCount {
    red: u32,
    green: u32,
    blue: u32,
}

fn parse_line(line: &str) -> (u32, CubeCount) {
    let mut count = CubeCount {
        red: 0,
        green: 0,
        blue: 0,
    };

    let parts: Vec<&str> = line.split(": ").collect();

    let id = parts[0].split(" ").nth(1).unwrap().parse::<u32>().unwrap();

    let grabs = parts[1].split("; ");
    for grab in grabs {
        let cubes: Vec<&str> = grab.split(", ").collect();
        for cube in cubes {
            let parts: Vec<&str> = cube.split(" ").collect();
            let num = parts[0].parse::<u32>().unwrap();
            let color = parts[1];
            match color {
                "red" => count.red = max(count.red, num),
                "green" => count.green = max(count.green, num),
                "blue" => count.blue = max(count.blue, num),
                _ => panic!("Unknown color: {}", color),
            }
        }
    }
    (id, count)
}

fn solve_part_1(input: &str) -> u32 {
    const MAGIC_COUNT: CubeCount = CubeCount {
        red: 12,
        green: 13,
        blue: 14,
    };

    fn fit(count: CubeCount) -> bool {
        let magic = &MAGIC_COUNT;
        count.red <= magic.red && count.green <= magic.green && count.blue <= magic.blue
    }

    input.lines().fold(0 as u32, |acc, line| {
        let (id, count) = parse_line(line);
        if fit(count) {
            id + acc
        } else {
            acc
        }
    })
}

fn test_part_1() {
    let input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green";
    assert_eq!(solve_part_1(input), 8);
}

fn solve_part_2(input: &str) -> u32 {
    fn power(count: CubeCount) -> u32 {
        count.red * count.green * count.blue
    }

    input.lines().fold(0 as u32, |acc, line| {
        let (_, count) = parse_line(line);
        power(count) + acc
    })
}

fn test_part_2() {
    let input = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green";
    assert_eq!(solve_part_2(input), 2286);
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
