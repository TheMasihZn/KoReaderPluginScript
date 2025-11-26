#!/bin/bash

# rand.sh: A simple Linear Congruential Generator (LCG) in bash

A=1103515245  # Multiplier
C=12345       # Increment
M=2147483647  # Modulus (2^31 - 1)

gen_seed() {
    # current time in milliseconds
    echo $(($(date +%s%N)/1000000))
}

# Function to generate the next pseudo-random number
gen_prn() {
    local current_seed=$1
    # Use shell arithmetic (( )) for calculations
    local next_seed=$(( (A * current_seed + C) % M ))
    echo "$next_seed"
}

next_rand(){
    # Use the current time as the seed and advance once
    local seed
    seed=$(gen_seed)
    local rand
    rand=$(gen_prn "$seed")

    # Map to an odd number in [1, 603]
    local mod=$((( ${rand#-} % 302 * 2) + 1 ))
    echo "$mod"
}

next_file(){
    # Produce a path like html/<n>.html
    local n
    n=$(next_rand)
    echo "html/${n}.html"
}

check_xmllint() {
    if ! command -v xmllint &> /dev/null; then
        echo "Error: xmllint is not installed. Please install libxml2-utils package."
        exit 1
    fi
}

# Detect target output encoding for the terminal and provide a safe printer.
# Usage: print_encoded "text"
# Behavior:
# - Defaults to UTF-8 on all systems (recommended for Farsi and most languages).
# - You can override by exporting OUTPUT_ENCODING, e.g. OUTPUT_ENCODING=CP866 for legacy consoles.
print_encoded() {
    local text="$1"

    # Determine OS type
    local os=${OSTYPE:-}
    local default_enc="UTF-8"

    local enc=${OUTPUT_ENCODING:-$default_enc}

    if [ "$enc" = "UTF-8" ] || ! command -v iconv >/dev/null 2>&1; then
        printf '%s\n' "$text"
    else
        # Best-effort conversion from UTF-8 source to requested encoding
        printf '%s' "$text" | iconv -f UTF-8 -t "$enc//TRANSLIT//IGNORE" 2>/dev/null || printf '%s\n' "$text"
        # Ensure newline when using iconv path
        [ -n "$text" ] && printf '\n'
    fi
}

get_xpath_value() {
    local file_path=$1
    local xpath=$2
    # Force UTF-8 locale for xmllint output, then print with proper encoding
    local val
    # Use normalize-space(string(node)) to:
    # - decode entities (e.g., &#13;)
    # - trim and collapse whitespace, removing stray CR/LF artifacts
    # - concatenate text across child text nodes
    val=$(LANG=C.UTF-8 xmllint --html --recover --nowrap --nocdata \
         --xpath "normalize-space(string($xpath))" "$file_path" 2>/dev/null || echo "")
    # Ensure we always print a line (possibly empty) in the correct encoding
    print_encoded "$val"
}

read_file() {
    local file_path=$1
    if [[ ! -f "$file_path" ]]; then
        print_encoded "File not found: $file_path"
        exit 1
    fi

    check_xmllint

    print_encoded "============="
    get_xpath_value "$file_path" "/html/body/div[1]/div[2]/span"
    get_xpath_value "$file_path" "/html/body/div[7]/p"
    get_xpath_value "$file_path" "/html/body/div[2]/div[2]/span"
    get_xpath_value "$file_path" "/html/body/div[4]/div[2]/span"
    print_encoded "============="
}

file=$(next_file)
read_file "$file"



