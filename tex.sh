#!/usr/bin/env bash

# tex.sh:
#   A script for compiling latex documents.
#
#   This script, when bound to a global alias
#   makes it easy to compile a latex project
#   from any child directory of the project.
#
# Author  : Everett
# Created : 2020-10-19 06:59
# Github  : https://github.com/antiqueeverett/

# print with less no line breaks
export max_print_line=1000
export error_line=254
export half_error_line=238

# clean
#   Cleans residual log files.
clean() {
    # use " ./ " so names with dashes won't become options
    rm -rf ./*.aux ./*.log ./*.bbl ./*.out ./*.toc ./*.gz ./*.lof ./*.lot ./*.cut ./*.blg ./*.nav ./*.snm ./*.bcf ./*.xml ./*.upa ./*.upb ./*.equ ./*.alg ./*.exc ./*.rep
}

compileSketch() {
    printf "\n(1/4): -draftmode -halt-on-error -file-line-error\n"
    pdflatex -draftmode -interaction=nonstopmode "check.tex" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(2/4): bibtex\n"
    if [ -f "check.aux" ]; then bibtex "check.aux"; fi | grep 'warning\|error\|critical\|Warning\|Error\|Critical'
        bibtex bu
        bibtex bu1

        printf "\n(3/4): -draftmode -halt-on-error -file-line-error"
        pdflatex -draftmode -interaction=nonstopmode "check.tex" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

        printf "\n(4/4): -interaction=nonstopmode\n"
        pdflatex -interaction=nonstopmode "check.tex" >/dev/null 2>&1

        pdftotext check.pdf check.txt
        echo `tr '\n' ' ' < check.txt` > check.txt
        #rm -rf check.pdf
    }

# compile
#   Compiles latex project.
#
# ARGUMENTS:
#   $1 name of main '*.tex' file
compile() {

    if [ -f "$pdf" ]; then rm -f "$pdf"; fi

    pdf=${1/tex/pdf} # output '*.pdf' file
    aux=${1/tex/aux} # output '*.aux' file

    printf "\n(1/4): -draftmode -halt-on-error -file-line-error\n"
    pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(2/4): bibtex\n"
    if [ -f "$aux" ]; then bibtex "$aux"; fi | grep 'warning\|error\|critical\|Warning\|Error\|Critical'
        bibtex bu
        bibtex bu1

        printf "\n(3/4): -draftmode -halt-on-error -file-line-error"
        pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

        printf "\n(4/4): -interaction=nonstopmode\n"
        pdflatex -interaction=nonstopmode "$1" >/dev/null 2>&1

        compileSketch
        clean
    }

# show
#   Opens '*.pdf' file.
show() {
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        gio open main.pdf
        gio open check.pdf
    else
        [[ "$OSTYPE" == "darwin" ]]
        open main.pdf
        open check.pdf
    fi
}

# findMain:
#   Finds main latex file.
#
# ARGUMENTS:
#   $1 name of main latex file
findMain() {
    topmost=10
    FOUND=

    #   traverse parent directories upward to find main.tex
    for ((maxwalk = topmost; maxwalk > 0; --maxwalk)); do
        for file in *.tex; do

            if [ "$file" = "$main" ]; then

                # grep -w
                #   select only those lines containing
                #   matches that form whole words
                #
                # grep -q (tip: remove for trouble shooting)
                #   do not write anything to standard output & exit
                #   immediately with zero status match is found
                #
                if grep -w -q 'documentclass' "$PWD/$file"; then
                    FOUND='yes'
                    echo "Found $main"

                    # compile latex project
                    compile "$file"

                    # open '*.pdf' file iff it exists
                    if [ -f "$pdf" ]; then show; fi

                    return # break loop if we find what we are looking for
                fi
            fi
        done
        cd "../"
    done
    if [ "$FOUND" = '' ]; then echo "$main not found"; fi
}

# setMainFile
#   Sets main '*.tex' project file to be searched for.
setMainFile() {
    echo "Searching for $main"
    main="$1"
    findMain "$main"
}

# isTextFile
#   Checks for a '*.tex' file argument.
# @retval
#   return true if latex file argument found.
isTexFile() {
    fileExtension='.tex'
    if echo "$1" | grep -q "$fileExtension"; then
        true
    else
        false
    fi
}

# checkargs
#   Safeguards arguments (naively) and
#     prints help execution directives.
checkargs() {
    if (($# > 2)); then
        echo "Invalid argument"
        echo "example:"
        echo "       >_ tex.sh main.tex"
        echo "       >_ tex.sh main.tex -j10"
    else
        if isTexFile "$1"; then
            setMainFile "$1"
        elif isTexFile "$2"; then
            setMainFile "$2"
        fi
    fi
}

# default behaviour sets 'main.tex'
#   as latex main project file
main="main.tex"
if [ $# -eq 0 ]; then
    echo "Searching for $main" # Iff no args are specified
    findMain "$main"           # ... find 'main.tex'
else
    checkargs "$@"
fi
