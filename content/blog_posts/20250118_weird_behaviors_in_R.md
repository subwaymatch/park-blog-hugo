---
title: Peculiar Behaviors of the R Programming Language
date: 2025-01-18
categories:
  - R
---

Consider this R code where it creates an R vector.

```R
# create a vector
v <- c(1, 2, 3)
```

Here is a seemingly simple task - how do you print out the container type of the vector `v`?

In other words, I'm looking for a function that would print out "vector" if I pass `v` as an argument.

```R
some_function(v) # should return "vector"
```

Inspect the object using `typeof()`, `class()` and `mode()` functions.

```R
v <- c(1, 2, 3)

typeof(v) # returns "double"
class(v)  # returns "numeric"
mode(v)   # returns "numeric"
```

The technical differences of the three functions aside, they all do not return the data type of the container (e.g., a vector).

It turns out that there is NO WAY to get the data type of the container. The only workaround is to explicitly check whether the value is a vector using `is.vector()`.

```R
is.vector(v) # returns TRUE
```

If you are working with a dynamically created variable that can be one of many container types, there is no way of finding the container type without explicitly checking for each type using `is.some_type()`.

```R
is.list(v)
is.array(v)
is.vector(v)
```

This is only one of the many peculiar behaviors of the R programming language. Here is a compiled list.

### 1. Indexing starts at 1

In R, indexing starts at 1.

```R
v <- c(10, 20, 30)
print(v[1])  # Outputs 10 (first element)
```

### 2. Vector Recycling

When performing operations on vectors of unequal lengths, R automatically "recycles" the shorter vector to match the length of the longer one.

```R
c(1, 2, 3) + c(10, 20)
# Outputs: 11 22 13 (shorter vector recycled)
```

### 3. Function Argument Matching

R matches function arguments partially based on their names.

```R
seq(to = 10, len = 5)  # Works because 'len' matches 'length'
```

### 4. Implicit Type Conversion (Coercion)

R automatically converts types in vectors to ensure all elements have the same type.

```R
x <- c(1, "a", TRUE)
print(x)  # Outputs: "1" "a" "TRUE" (all coerced to characters)
```

### 5. Assignment Operators

While `=` is used for assignment, R programmers often use `<-`.

```R
x <- 5
y = 10  # Both are valid, but `<-` is idiomatic in R
```

### 6. Data Frame vs Matrix Handling

Data frames in R are treated differently than matrices. Accessing a single column of a data frame with `df[, 1]` might return a vector, not a smaller data frame.

```R
df <- data.frame(a = c(1, 2, 3), b = c(4, 5, 6))
class(df[, 1])  # Outputs: "numeric" (not "data.frame")
```

### 7. NA vs NULL

R has multiple "null-like" values:
`NA` represents missing data.
`NULL` represents nothingness (no object).

```R
x <- c(1, NA, 3)
print(length(x))  # Outputs 3
y <- NULL
print(length(y))  # Outputs 0
```

### 8. Dynamic Scope in <<- Operator

The `<<-` operator assigns variables to an environment outside the local function scope, which might feel strange compared to Python's global or nonlocal.

```R
f <- function() {
  x <<- 5  # Assigns in global scope
}
f()
print(x)  # Outputs 5
```

### 9. Non-Standard Evaluation (NSE)

R functions often use symbols or expressions directly, making it feel "magical." For instance, in `dplyr` you can refer to column names without quotes:

```R
library(dplyr)
df %>% select(column_name)  # No quotes needed for column_name
```

### 10. String Behavior

R uses `"` for strings by default, and single quotes (`'`) are rarely used.

```R
x <- "hello"  # Standard practice
y <- 'hello'  # Also valid, but less common
```

### 11. Weirdness with Single-Row/Column Data Frames

Accessing a single column or row might drop dimensions unless explicitly prevented.

```R
df <- data.frame(a = c(1, 2, 3), b = c(4, 5, 6))
df[1, ]  # Outputs a vector by default
df[1, , drop = FALSE]  # Keeps it as a data frame
```

### 12. Factor Handling

R has a special data type called "factors" for categorical variables. They can behave unpredictably if not converted to character or numeric types.

```R
x <- factor(c("a", "b", "a"))
as.character(x)  # Outputs: "a" "b" "a"
as.numeric(x)    # Outputs: 1 2 1 (underlying integer codes)
```

### 13. Indexing with TRUE/FALSE

Logical vectors can be used directly for indexing.

```R
x <- c(10, 20, 30)
print(x[c(TRUE, FALSE, TRUE)])  # Outputs: 10 30
```

### 14. Inconsistent Syntax

Some base R functions require unusual syntax compared to Python libraries:

```R
mean(x, na.rm = TRUE)  # na.rm removes NA values
```

## What makes R still attractive?

Despite some of R's peculiar behaviors, it's still useful and powerful.

### 1. ggplot2

One of R's standout features is ggplot2, a powerful visualization package for creating high-quality and customizable plots. It has a syntax rooted in the grammar of graphics, which allows intuitive and flexible data visualization.

### 2. CRAN Repository

R has one of the most comprehensive repositories of packages (via CRAN) that extend its functionality, especially for niche areas like bioinformatics, econometrics, spatial analysis, and machine learning.

### 3. Tidyverse packages

`dplyr` and `tidyr`, part of the tidyverse, allow for fast and intuitive data manipulation. `dplyr` provides a simple syntax for operations like filtering, summarizing, grouping, and joining datasets, while `tidyr` excels in reshaping data, making it easier to handle messy datasets.

### 4. RMarkdown + knitr

RMarkdown allows for the creation of dynamic, reproducible reports that combine code, output, and documentation. This is beneficial for data scientists who need to document their work or share their results with others. `knitr` allow for integrating R with various formats including LaTeX.
