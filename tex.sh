#!/usr/bin/env bash

# tex.sh:
#   Helper script for compiling latex documents.
#
#   When bound to a global alias, the script
#   makes it easy to compile a latex project
#   from any child directory of the project.
#
# Author  : Everett
# Created : 2020-10-19 06:59
# Github  : https://github.com/antiqueeverett/

# -- remove line breaks from compilation output
export error_line=254
export half_error_line=238
export max_print_line=1000

# -- share variables
main="main.tex"   # name of main latex project file
draft="draft.tex" # name of secondary latex project file
location=""       # path to main/draft latex project file
textonly=""       # flag to build draft
pdf=""            # compiled pdf file
texformat=""         # compiled pdf file

# -- show compiled pdf
#    args: $1 main latex project file
show() {
    if [ -f "$pdf" ]; then
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            gio open "$pdf"
        else
            [[ "$OSTYPE" == "darwin" ]]
            open "$pdf"
        fi
    else
        echo "-- couldn't find pdf file"
    fi
}

# -- remove pdflatex compilation cache files
clean() {
    rm -rf ./*.aux ./*.log ./*.bbl ./*.out ./*.toc ./*.gz ./*.lof ./*.lot ./*.cut ./*.blg ./*.nav ./*.snm ./*.bcf ./*.xml ./*.upa ./*.upb ./*.equ ./*.alg ./*.exc ./*.rep
}

# -- check for bib units
bibUnits() {
    if compgen -G "bu*" >/dev/null; then
        bibtex bu
        bibtex bu1
    fi
}

# -- compile pdf
#    args: $1 main latex project file
compile() {
    local file=${1/tex/pdf} # output '*.pdf' file
    local aux=${1/tex/aux}  # output '*.aux' file

    if [ -f "$file" ]; then rm -f "$file"; fi

    printf "\n(1/4) compilation args: -draftmode -halt-on-error -file-line-error"
    pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(2/4) compiling bibliographies"
    if [ -f "$aux" ]; then bibtex "$aux"; fi | grep 'warning\|error\|critical\|Warning\|Error\|Critical' | grep -v "(There was 1 error message)"
    bibUnits

    printf "\n(3/4) compilation args: -draftmode -halt-on-error -file-line-error"
    pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(4/4) compilation args: -interaction=nonstopmode\n\n"
    pdflatex -interaction=nonstopmode "$1" >/dev/null 2>&1

    pdf="$file"
}

# -- compile text only pdf
#    args: $1 main latex project file
compileTextonly() {
    local file=${1/tex/pdf} # output '*.pdf' file
    local aux=${1/tex/aux}  # output '*.aux' file

    if [ -f "$file" ]; then rm -f "$file"; fi

    printf "\n(1/4) compilation args: -draftmode -halt-on-error -file-line-error"
    pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(2/4) compiling bibliographies"
    if [ -f "$aux" ]; then bibtex "$aux"; fi | grep 'warning\|error\|critical\|Warning\|Error\|Critical' | grep -v "(There was 1 error message)"
    bibUnits

    printf "\n(3/4) compilation args: -draftmode -halt-on-error -file-line-error"
    pdflatex -draftmode -interaction=nonstopmode "$1" | grep 'error\|critical\|Error\|Critical' | grep -v "(/"

    printf "\n(4/4) compilation args: -interaction=nonstopmode\n\n"
    pdflatex -interaction=nonstopmode "$1" >/dev/null 2>&1

    pdf="$file"
}

# -- find main project file
#    args: $1 main project file
autofind() {
    topmost=10

    # traverse parent directories upward and find main latex project file
    for ((maxwalk = topmost; maxwalk > 0; --maxwalk)); do
        for file in *.tex; do
            if [ "$file" = "$main" ]; then
                if grep -w -q 'documentclass' "$PWD/$file"; then
                    location=$file
                    true
                    return
                fi
            fi
        done
        cd "../"
    done

    false
}

# -- verify file type
isTexFile() {
    fileExtension='.tex'
    if echo "$1" | grep -q "$fileExtension"; then
        true
    else
        false
    fi
}

# -- show usage
showUsage() {
    printf "\n-- invalid arguments specified"
    printf "\n-- example usage:>_ tex.sh myproject.tex\n\n"
}

# -- evaluate arguments
checkargs() {
    echo "$@"
    if (($# > 3)); then
        showUsage
        false
    else
        if isTexFile "$1"; then
            main="$1"

            for i in "$@"; do
                if [ "$i" = "-draft" ]; then
                    textonly="Yes"
                fi
                if [ "$i" = "-tex" ]; then
                    texformat="Yes"
                fi
            done
        else
            false
            showUsage
        fi
        true
    fi
}

buildProject() {
    if autofind "$main"; then
        echo "-- found $main"
        compile "$location"
        clean
        show "$pdf"
    else
        echo "-- couldn't find $main file"
    fi
}

buildDraft() {
    if autofind "$draft"; then
        echo "-- found $draft"
        compileTextonly "$location"
        clean
        show
    else
        echo "-- couldn't find $main file"
    fi
}

toText() {
    pdftotext draft.pdf draft.txt
    echo `tr '\n' ' ' < draft.txt` > draft.txt
}

toTexFormat() {
   mv ~/Downloads/draft.edited.docx ./
   docx2txt.pl draft.edited.docx
   mv draft.edited.txt draft.txt
   sed -e 's/\./\.\'$'\n''\%\'$'\n''/g' draft.txt
   #perl -pe 's/\./\.\n\%\n/g' draft.txt
   rm -rf draft.edited.docx
}

# -- autofind main latex project file
if [ $# -eq 0 ]; then
    printf "\n-- no arguments were specified\n"
    printf "\n-- searching for %s\n" "$main"
    buildProject

else
    if checkargs "$@"; then
        # printf "\n-- searching for %s\n" "$main"
        if [ "$textonly" = "Yes" ]; then
            echo "-- compiling 'textonly' draft"
            main="$draft"
            buildDraft
            toText
        fi
        if [ "$texformat" = "Yes" ]; then
            toTexFormat
        fi
    buildProject
    fi
fi
