---
title: "Run MOSS Plagiarism Checker on Jupyter Notebooks"
date: 2023-04-20
draft: false
categories:
  - Python
tags:
  - moss
  - plagiarism detection
---

## MOSS

[MOSS](https://theory.stanford.edu/~aiken/moss/) (Measure of Software Similarity) is a system to to determine the similarity of programs. It's most commonly used to detect plagiarism in programming classes. It was developed in 1994 by David A. Aiken, Robert Sedgewick, and Andrew W. Appel at Stanford University.

### MOSS for Plagiarism Detection

[MOSS](https://theory.stanford.edu/~aiken/moss/) (Measure of Software Similarity) is a great tool for catching plagiarism because it can identify even small similarities that may not be obvious to the human eye. MOSS works by comparing the source code of two or more files. It does this by breaking the code down into tokens, which are the smallest meaningful units of code. A token could be a variable name, a function name, or a keyword. MOSS then compares the tokens in each file to see how many of them are the same.

## Preprocessing Jupyter Notebooks

To run MOSS on Jupyter notebooks, you first have to convert the `.ipynb` files to `.py` scripts. This can be done either using `nbconvert` on a command line environment or manually extracting the code using `nbformat`.

### Method 1 - convert all cells using `nbconvert`

To keep all cells (including Markdown), use `nbconvert`.

```bash
# install nbconvert
$ pip install nbconvert
```

```bash
# convert all Jupyter notebooks to Python (`.py`) files
$ jupyter nbconvert *.ipynb --to python
```

### Method 2 - extract code cells with fine-grained controls

In some cases, you may want to programmatically extract code. This enables you to manually add rules in weeding out unwanted cells. The Python code below checks whether a cell is a code cell and does not contain `'# EXCLUDE THIS CELL'`.

```python
import nbformat

nb = nbformat.read(notebook_path, as_version=4)
user_code = ''

for cell in nb.cells:
    if cell.cell_type == 'code' and '# EXCLUDE THIS CELL' not in cell.source:
        user_code += cell.source + '\n\n'


p = Path(notebook_path)
output_path = os.path.join(p.parent, p.stem + '.py')

with open(output_path, mode='w', encoding='utf-8') as f:
    f.write(user_code)

print(f'Extracted user code to {output_path}')
```

## Running MOSS

Assume we are working with the following directory structure with two different sections.

```
# directory structure
- section-A
    - student1.py
    - student2.py
    - student3.py
- section-B
    - student4.py
    - student5.py
    - student6.py
- basefile.py
```

### Basic command line usage

```bash
 $ ./moss.pl -l python -c "Sample Assignment MOSS Results" ./**/*.py
```

- `-l python` specifies the programming language
- `-c "Sample Assignment MOSS Results"` sets the title of the session
- `./**/*.py` is used to upload all files in both `section-A` and `section-B` directories.

### Adding a base file

If the students were given a "starter notebook" (a template file with instructions and instructor-supplied code), you can optionally supply a "base file" option.

```bash
 $ ./moss.pl -l python -c "Sample Assignment MOSS Results" -b basefile.py ./**/*.py
```

## Storing Results

MOSS results are kept on the `moss.stanford.edu` server for 14 days. Use `wget` to clone the site locally.

```bash
$ wget --mirror --convert-links -e robots=off http://moss.stanford.edu/results/1/1234567890123/
```

- `--mirror` makes an offline mirror of a site recursively
- `--convert-links` converts absolute links to relative links so that the links work even if the offline mirror can be moved around
- `-e robots=off` is used to bypass `robots.txt` and download individual comparison files
