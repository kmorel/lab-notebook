#[==[

Usage: cmake -DINPUT=<file> -DOUTPUT=<file> -P ExtendedMarkdown.cmake

#]==]

cmake_minimum_required(VERSION 3.13)

if(NOT INPUT)
  message(FATAL_ERROR "Must set INPUT variable.")
endif()

if(NOT OUTPUT)
  message(FATAL_ERROR "Must set OUTPUT variable.")
endif()

get_filename_component(input_dir "${INPUT}" DIRECTORY)

# Read input
file(READ "${INPUT}" input)

# Process input
set(output)
set(include_regex "[\r\n]@\\[([^\n()]*)\\]\\(([^\n]*)\\)[ \t]*[\r\n]")

string(REGEX MATCH "${include_regex}" match "${input}")
while(match)
  string(LENGTH "${match}" match_length)
  string(FIND "${input}" "${match}" start_position)
  math(EXPR end_position "${start_position} + ${match_length}")
  math(EXPR start_position "${start_position} + 1") # Pass beginning newline

  # Add the text before the match to output
  string(SUBSTRING "${input}" 0 ${start_position} add_to_output)
  string(APPEND output "${add_to_output}")

  # Get information about file to read
  string(REGEX REPLACE "${include_regex}" "\\1" include_format "${match}")
  string(REGEX REPLACE "${include_regex}" "\\2" include_file "${match}")
  get_filename_component(
    include_file "${include_file}" ABSOLUTE BASE_DIR "${input_dir}"
    )
  if(NOT EXISTS "${include_file}")
    message(FATAL_ERROR "${INPUT}: Cannot find input file `${include_file}`")
  endif()

  # Include the file as a verbatim source  
  file(READ "${include_file}" include_contents)
  string(APPEND output "```${include_format}\n${include_contents}\n```\n")

  # Get ready for next iteration
  string(SUBSTRING "${input}" ${end_position} -1 input)
  string(REGEX MATCH "${include_regex}" match "${input}")
endwhile()

string(APPEND output "${input}")

# Write output
file(WRITE "${OUTPUT}" "${output}")
