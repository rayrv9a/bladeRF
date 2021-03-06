#!/bin/bash
#
# @file generate.bash
#
# @brief Generates interactive documentation for bladeRF-cli
#
# This file is part of the bladeRF project
#
# Copyright (C) 2014 Ryan Tucker <bladerf@ryantucker.us>
# Copyright (C) 2014 Nuand LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#

[ -z "$1" ] && echo "usage: $0 inputfile.md" && exit 1

echo "Generating HTML doc..."
pandoc --standalone --self-contained --toc -f markdown -t html5 -o cmd_help.html $1

echo "Generating man page snippet..."
pandoc -f markdown -t man -o cmd_help.man $1

echo "Generating text version..."
pandoc --ascii --columns=70 -f markdown -t plain -o cmd_help.txt $1

echo "Generating include file..."
prevline=""
section=""
skip_to_usage=0
skip_to_first_header=1

# This keeps it from "smooshing" our indents.
IFS=$(printf '\t')

# Add a couple newlines to the end, to give the REPL a chance to
# empty itself.
echo >> cmd_help.txt
echo >> cmd_help.txt

# Heading!
cat > cmd_help.h <<EOF
/**
 * @file cmd_help.h
 *
 * @brief Autogenerated interactive CLI help
 *
 * This file is part of the bladeRF project
 *
 * Copyright (C) 2014 Nuand LLC
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

/**
 * WARNING: THIS FILE IS AUTOMATICALLY GENERATED BY GENERATE.BASH.
 * Any manual modifications to this file will be overwritten!
 * To edit the content of help strings, please edit $(basename $1)
 *
 * Last generated: $(date) by $(whoami)@$(hostname)
 */

#ifndef BLADERF_CLI_DOC_CMD_HELP_H__
#define BLADERF_CLI_DOC_CMD_HELP_H__

EOF

while read -r line
do
    # Escape backslash and double-quote characters
    line=$(sed 's/\\/\\\\/g' <<< "$line")
    line=$(sed 's/\"/\\"/g' <<< "$line")

    # Find section headings by looking for at least two -- on the line
    # immediately following them.
    if [ $(grep -c "^--" <<< "$line") -gt 0 ]
    then
        section=$prevline
        skip_to_usage=1
        skip_to_first_header=0
        echo ""
        echo ""
        echo "#define CLI_CMD_HELPTEXT_$section \\"

    # Omit anything above the Usage: line
    elif [ "$skip_to_usage" -eq 1 ]
    then
        if [ $(grep -c "^Usage:" <<< "$line") -gt 0 ]
        then
            skip_to_usage=0
            prevline=$line
        fi

    # Omit anything above the first heading
    elif [ "$skip_to_first_header" -eq 0 ]
    then
        echo "  \"$prevline\\n\" \\"
        prevline=$line

    # Just save the line for the next time around...
    else
        prevline=$line
    fi
done < cmd_help.txt >> cmd_help.h

# We end with a \, so throw an extra line in there to keep the preprocessor
# from exploding.  Also close out our wrapper.
echo >> cmd_help.h
echo "#endif // BLADERF_CLI_VERSION_H__" >> cmd_help.h

