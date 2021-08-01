#!/bin/bash

# --------------------------------------------------------------------------------------------- #
# Git History Fixer                                                                             #                                                
# @author Utkarsh Priyam (utk003)                                                               #
# @version Sunday, August 1, 2021                                                             #
# --------------------------------------------------------------------------------------------- #
# Clears most of the Git history of the repository specified by the script's directory argument #
#                                                                                               #
# See: git filter-branch documentation (https://git-scm.com/docs/git-filter-branch)             #
# --------------------------------------------------------------------------------------------- #

# ------------------------------------------------------------------------------ #
# LICENSE:                                                                       #
# ------------------------------------------------------------------------------ #
# MIT License                                                                    #
#                                                                                #
# Copyright (c) 2021 Utkarsh Priyam                                              #
#                                                                                #
# Permission is hereby granted, free of charge, to any person obtaining a copy   #
# of this software and associated documentation files (the "Software"), to deal  #
# in the Software without restriction, including without limitation the rights   #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      #
# copies of the Software, and to permit persons to whom the Software is          #
# furnished to do so, subject to the following conditions:                       #
#                                                                                #
# The above copyright notice and this permission notice shall be included in all #
# copies or substantial portions of the Software.                                #
#                                                                                #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  #
# SOFTWARE.                                                                      #
# ------------------------------------------------------------------------------ #

# check input dir
[ -z "$1" ] && echo "git repo directory not specified" && exit

# switch to target dir
cd $1

# first pass clear
git remote prune origin && git repack && git prune-packed && git reflog expire --expire=1.month.ago && git gc --aggressive

# clear extraneous files
git filter-branch --tag-name-filter cat --index-filter 'git rm -r --cached --ignore-unmatch filename' --prune-empty -f -- --all

# delete back-up files
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now

# push changes
git push origin --force --all
git push origin --force --tags
