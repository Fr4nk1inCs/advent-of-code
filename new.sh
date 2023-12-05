#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
TEMPLATE_PATH="$SRC_DIR/bin/template.rs"

echo "Advent of Code Rust template generator"

echo -n "Year: "
read -r year

echo -n "Day: "
read -r day

if [ "$day" -lt 10 ]; then
	day="0$day"
fi

part=""

while [ "$part" != "1" ] && [ "$part" != "2" ]; do
	echo -n "Part[1|2]: "
	read -r part
done

DEST_DIR="$SRC_DIR/bin/$year"

if [ ! -d "$DEST_DIR" ]; then
	mkdir -p "$DEST_DIR"
fi

DEST_FILE_PATH="$DEST_DIR/day-$day-part-$part.rs"

cp "$TEMPLATE_PATH" "$DEST_FILE_PATH"

sed -i "s/<year>/$year/g" "$DEST_FILE_PATH"
sed -i "s/<day>/$day/g" "$DEST_FILE_PATH"
sed -i "s/<part>/$part/g" "$DEST_FILE_PATH"
