cmake_minimum_required(VERSION 3.13)

set(_labnotes_templates_dir ${CMAKE_CURRENT_LIST_DIR}/templates)

function(_labnotes_get_file_date yearvar monthvar dayvar filename months)
  get_filename_component(dayfile ${filename} NAME)
  string(REGEX MATCH "([0-9]+)\\.md" dayfile "${dayfile}")
  string(REGEX REPLACE "([0-9]+)\\.md" "\\1" day "${dayfile}")
  set(${dayvar} "${day}" PARENT_SCOPE)

  get_filename_component(filename ${filename} DIRECTORY)
  get_filename_component(monthdir ${filename} NAME)
  string(REGEX MATCH "[0-9]+$" month_num "${monthdir}")
  if(month_num)
    list(GET months "${month_num}" month)
  else()
    set(month)
  endif()
  set(${monthvar} "${month}" PARENT_SCOPE)

  get_filename_component(filename ${filename} DIRECTORY)
  get_filename_component(yeardir ${filename} NAME)
  string(REGEX MATCH "[0-9]+$" year "${yeardir}")
  set(${yearvar} "${year}" PARENT_SCOPE)
endfunction()

# See Readme.md for documentation on using this function.
function(add_labnotes)
  set(_options
    NEWEST_FIRST
    OLDEST_FIRST
    EXCLUDE_FROM_ALL
    )
  set(_single_arg
    TARGET
    OUTPUT_FILE
    )
  set(_multi_arg
    )
  cmake_parse_arguments(
    _labnotes "${_options}" "${_single_arg}" "${_multi_arg}" ${ARGN}
    )

  #
  # Set up programs
  #

  find_program(PANDOC_EXECUTABLE pandoc
    DOC "Location of pandoc executable. (See https://pandoc.org)"
    )

  if(NOT PANDOC_EXECUTABLE)
    message(FATAL_ERROR "Could not find pandoc. Set PANDOC_EXECUTABLE.")
  endif()

  find_program(PDFTK_EXECUTABLE pdftk
    DOC "Location of PDFtk Server executable. (See https://www.pdflabs.com/tools/pdftk-server)"
    )

  find_program(GS_EXECUTABLE gs
    DOC "Location of ghostscript (gs) executable. (See https://www.ghostscript.com)"
    )

  if(NOT PDFTK_EXECUTABLE)
    message("Could not find PDFtk. This program constructs the pdf file better. Consider downloading PDFtk from https://www.pdflabs.com/tools/pdftk-server/ or https://gitlab.com/pdftk-java/pdftk.")
    if(NOT GS_EXECUTABLE)
      message(FATAL_ERROR "Could not find PDFtk or ghostscript. Set PDFTK_EXECUTABLE or GS_EXECUTABLE.")
    endif()
  endif()

  if(_labnotes_NEWEST_FIRST)
    set(labnotes_NEWEST_FIRST ON)
  elseif(_labnotes_OLDEST_FIRST)
    set(labnotes_OLDEST_FIRST)
  else()
    option(labnotes_NEWEST_FIRST
      "When ON, the notebook entries are listed in reverse chronological order.
When writing a notebook by hand, it is natural to start at the front and
move to the back as days pass. However, in this electronic version, it is
often more convenient to put the most recent entries in the front as they
will be most relevant to current work."
      ON
      )
  endif()

  #
  # Find all lab entries
  #

  file(GLOB_RECURSE markdown_files CONFIGURE_DEPENDS *.md)
  if(labnotes_NEWEST_FIRST)
    list(SORT markdown_files ORDER DESCENDING)
  else()
    list(SORT markdown_files ORDER ASCENDING)
  endif()

  #
  # Build lookup from number to month string
  #

  set(months
    ""
    January
    February
    March
    April
    May
    June
    July
    August
    September
    October
    November
    December
    )

  #
  # Add commands to convert each day's labnotes to a pdf file.
  #

  set(_pdf_files)
  set(_pdf_dir ${CMAKE_CURRENT_BINARY_DIR}/pdf_directory)
  set(_header_dir ${CMAKE_CURRENT_BINARY_DIR}/headers)
  foreach(file ${markdown_files})
    _labnotes_get_file_date(year month day ${file} "${months}")
    if(year AND month AND day)
      # Make a header for the entry that gives the date.
      set(_entry_header ${_header_dir}/${year}${month}${day})
      configure_file(
        ${_labnotes_templates_dir}/entry_header.md
        ${_entry_header}
        )

      # Establish files and directories
      get_filename_component(_resource_path ${file} DIRECTORY)
      set(_pdf_file ${_pdf_dir}/${year}${month}${day}.pdf)

      add_custom_command(OUTPUT ${_pdf_file}
        COMMAND ${PANDOC_EXECUTABLE}
          --from=markdown --to=pdf
          --output=${_pdf_file}
	  --resource-path=${_resource_path}
	  --standalone
          ${_entry_header} ${file}
        DEPENDS ${_entry_header} ${file}
        COMMENT "Building ${file}"
        )
      list(APPEND _pdf_files ${_pdf_file})
    endif()
  endforeach()

  #
  # Add command to combine the individual pdf's and create target
  #

  if(NOT _labnotes_TARGET)
    set(_labnotes_TARGET labnotes)
  endif()
  if(NOT _labnotes_OUTPUT_FILE)
    set(_labnotes_OUTPUT_FILE ${_labnotes_TARGET}.pdf)
  endif()

  if(PDFTK_EXECUTABLE)
    add_custom_command(OUTPUT ${_labnotes_OUTPUT_FILE}
      COMMAND ${PDFTK_EXECUTABLE} ${_pdf_files} cat output ${_labnotes_OUTPUT_FILE}
      DEPENDS ${_pdf_files}
      COMMENT "Combining PDFs"
      )
  else()
    add_custom_command(OUTPUT ${_labnotes_OUTPUT_FILE}
      COMMAND ${GS_EXECUTABLE} -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite
        -sOutputFile=${_labnotes_OUTPUT_FILE}
        ${_pdf_files}
      DEPENDS ${_pdf_files}
      COMMENT "Combining PDFs"
      )
  endif()

  if(_labnotes_EXCLUDE_FROM_ALL)
    set(_all)
  else()
    set(_all ALL)
  endif()
  add_custom_target(${_labnotes_TARGET} ${_all}
    DEPENDS ${_labnotes_OUTPUT_FILE}
    )
endfunction()
