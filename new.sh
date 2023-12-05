#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_PATH="$SCRIPT_DIR/template.rs"

echo "Advent of Code Rust template generator"

echo -n "Year: "
read -r year

echo -n "Day: "
read -r day

if [ "$day" -lt 10 ]; then
	day="0$day"
fi

DEST_DIR="$SCRIPT_DIR/$year"

if [ ! -d "$DEST_DIR" ]; then
	mkdir -p "$DEST_DIR"
fi

DEST_FILE_PATH="$DEST_DIR/day-$day.rs"

cp "$TEMPLATE_PATH" "$DEST_FILE_PATH"

sed -i "s/<year>/$year/g" "$DEST_FILE_PATH"
sed -i "s/<day>/$day/g" "$DEST_FILE_PATH"

INPUT_DIR="$SCRIPT_DIR/inputs/$year"
if [ ! -d "$INPUT_DIR" ]; then
	mkdir -p "$INPUT_DIR"
fi

INPUT_FILE_PATH="$INPUT_DIR/day-$day.txt"
touch "$INPUT_FILE_PATH"
