#!/bin/bash
hg commit -m "ignore git files"
hg push
git add .hgignore
git commit -m "hg ignores git files"
git push --all
