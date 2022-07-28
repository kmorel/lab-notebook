# Laboratory Notebook

This repository holds CMake build files that make it easy to create a
running laboratory notebook. To create an entry for a day, simply create a
text file in a specific directory and edit it.

The text files respect markdown, which creates readable text files but also
lets you reference links and images.

See the [building](#building) section for information on how to get starting on your
own notebook. But to start, here is an overview of how the notebook works.

## Editing a notebook

These build files allow you to edit a running notebook simply by creating
and editing text files in your favorite editor. New entries are created by
creating a markdown file with the relative path `YYYY/MM/DD.md`. The build
system will automatically find all files with this naming convention and
build a PDF document containing a compendium of all laboratory notes.


### Creating a new entry

As stated, to create a new notebook entry, simply create a new markdown
file in the appropriate subdirectory and name based on the date. The
entries are organized in subdirectories for years and then subdirectories
for months. Each day is in its own file. So the directory structure (under
this directory) looks like

```
+-+-2021        # Subdirectory for 2021
| |
| +-+-11        # Subdirectory for November, 2021
| | +--- 06.md  # Notebook entry for November 6, 2021
| | +--- 17.md  # Notebook entry for November 17, 2021
| |
| +-+- 12       # Subdirectory for December, 2021
|   +--- 09.md  # Notebook entry for December 9, 2021
|   +--- 16.md  # Notebook entry for December 16, 2021
|   +--- 25.md  # Notebook entry for December 25, 2021
|
+-+-2022        # Subdirectory for 2022
| |
| +-+- 01       # Subdirectory for January 2022
| | +--- 04.md  # Notebook entry for January 4, 2022
...
```

So each entry is in a path named `YYYY/MM/DD.md`. For example, if you were
to create an entry for April 19, 2021, then create a file named
`2021/04/19.md`.

A date will automatically be created as a title for each notebook entry
when the pdf of the notebook is built. Thus, it is not necessary to date
the notebook entries (other than following the filename convention).

_Note that files that do not follow this file naming convention will not be
built as part of the notebook._


### Markdown

Each journal entry is created using Markdown. Pandoc is used to convert the
markdown to pdf, so you can use any extensions supported by [Pandoc
Markdown].

As mentioned previously, each notebook entry will automatically be titled
with the current date. This date is placed using the first heading level.
Thus, it is recommended to start all sections of the notebook at the second
heading level (i.e. as `##`).

``` markdown
## Cross-Dimensional Travel

Today I met with John Smallberries and John O'Connor at Yoyodyne about our
recent ideas about cross-dimensional travel. They seem very excited about
our ideas for an overthruster. John mentioned that McKinley at the DOD
would be interested in providing a grant for R&D.

## Jet Propulsion

We are still collecting data from the jet car experiment run yesterday.
Preliminary results show promising acceleration but unstable vibrations at
high speeds. The following plot shows the virtual accelerometer readings
for the first 300 seconds of the experiment.

![](19/accelerometer-plot.png)
```

[Pandoc Markdown]: https://pandoc.org/MANUAL.html#pandocs-markdown


### Images

Inserting images into a laboratory notebook is common. The `![](file)`
syntax is of course supported. Filenames can (and should be) given relative
to the markdown file being created.

When a journal entry involves more than text, I suggest creating a
directory next to the markdown file with the same number to store all
images and other artifacts. For example, if editing `2021/04/19.md`, create
a directory named `2021/04/19` to contain any images referred to by the
journal entry. Keeping each journal entry's files in their own directory
means you do not have to worry about using the same filename for two
different days.


### Text Files

The lab notebook build does some extra processing of your markdown files to
include further support for formatting common to lab notebooks. One common
feature is the ability to insert the content of a text file into your
laboratory notebook.

The format for inserting a text file is the format
`@[<format>](<filename>)`. You will notice that this is very similar to the
markdown syntax for inserting an image except that the `!` is replaced with
a `@`. Also note that instead of alternate text, you specify the format of
the text file being inserted. (You can leave this field blank for a
standard text file.) Also, this substitution only works if the item is on
its own line.

Here is a simple example of its use.

```md
## Python class

Today I am learning how to program in Python. Here is my first program.

@[python](04/helloworld.py)
```

This will be expanded to something like the following markdown before being
processed by pandoc.

    ## Python class
    
    Today I am learning how to program in Python. Here is my first program.
    
    ```python
    print('hello world')
    ```


## Building

Here are some details on building the compiled laboratory notebook.

### Prerequisites

This system requires the following tools to build the files:

- [CMake](https://www.cmake.org)
- [Pandoc](https://pandoc.org)
- [pdftk](https://www.pdflabs.com/tools/pdftk-server), [pdftk-java](https://gitlab.com/pdftk-java/pdftk) or [Ghostscript](https://www.ghostscript.com)

### Setting up your repo

This repository is designed to work as a submodule to a git repository. If
starting your repo from scratch, first create the directory you want the
laboratory notebook to be in. Then initialize git and set up the submodule
to these build files.

```sh
git init
git submodule add https://github.com/kmorel/lab-notebook.git
```

Next, you will need to create a `CMakeLists.txt` file. The file needs to
include the `LabNotebook.cmake` file in this directory and then call the
`add_labnotes` function. Here is a simple, complete example.

```cmake
cmake_minimum_required(VERSION 3.13)

project(labnotes NONE)

include(lab-notebook/labnotes.cmake)

add_labnotes()
```

The `add_labnotes` command recognizes several options:

  * `TARGET <name>` (optional): Specify the name of the target created for
    the build system. If not specified, `labnotes` is used.
  * `OUTPUT_FILE <filename>` (optional): Specify the name of the output PDF
    file. If not specified, then the name of the target with `.pdf`
    attached (e.g., `labnotes.pdf`) is used.
  * `NEWEST_FIRST` or `OLDEST_FIRST`: If one of these flags is given, then
    the entries will be created with the most recent first or the most
    recent last. If neither is provided, then a CMake configuration
    variable is created that can be set with the `cmake` command.
  * `EXCLUDE_FROM_ALL`: By default, the labnotes pdf file will be added to
    the `all` target so that it is always created if no other target is
    specified on the build line. If this flag is provided, then the PDF
    will not be added to the `all` target, and you will have to
    specifically select it to build it.

Once you have your git set up and a `CMakeLists.txt`, [create a lab
entry](#creating-a-new-entry) or two to get started.

### Compiling

To compile the notebook, simply configure it with CMake and then run the
used build program. I highly recommend doing an out-of-source build to help
manage the files.

```sh
mkdir out
cd out
cmake ..
cmake --build .
```

The system builds each notebook entry independently, so parallel builds can
speed up the build immensely. I find the `ninja` program to be very good
for parallel builds.

```sh
mkdir out
cd out
cmake -G Ninja ..
ninja
```
