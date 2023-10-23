# Scrap & Jag(g)

A pair of tools I wrote in an ADHD hyperfocus session, based around trying to make some CLI stuff less of a pain. YMMV

## Building/installation

If you want to run these scripts, grab a [Janet release](https://github.com/janet-lang/janet/releases).

If you want to compile th

## Scrap 

Scrap is a cli-style clibboard. Set it up by defining the `SCRAP_DIR` environment variable. Usage is shown below.

### Scrap usage


```cmd
  scrap: pipe data to/from a junk dir

  subcommands
  scrap put <name>: Saves stdin to name
  scrap get <name>: Cats <name> to stdout
  scrap add <name>: Appends stdin to name
  scrap map <name> <expr>: Passes each line of <name> through expr
  scrap ls <name?>: Lists the files in <name> scrap workspace, the current one if not provided
  scrap rm <name>: Deletes the <name> file in the current workspace
  scrap update <name> <expr>: Passes each line of <name> through the Janet expr <expr>, nil lines are removed
  scrap current: Gives the current scrap workspace
  scrap ws save <name?>: Saves the current set of scrap files to a backup folder. If <name>
  scrap ws load <name>: Clears the current scrap workspace, and then loads the workspace from <name>
  scrap ws ls: Lists the workspaces
```


## Jag(g): Janet Aggregate

This is a bit of an awk-alike, but using Janet

It works in 4 phases.

#### Sourcing Data

The following flags are supported for data sources. If no data source flags are supplied, stdin is used as the data source.

* `-F <file>` appends the contents of `<file>` to the list of inputs.
* `-C <constant>` appends `<constant>` to the list of inputs as-is.
* `-FE <env-var>` appends the contents of the file at the path of `<env-var>` to the list of inputs.
* `-E <env-var>` appends the contents of `<env-var>` to the list of inputs.
* `-I` appends the contents of `STDIN` to the list of inputs.

#### Extracting rows

* `-s <delim>` splits each input on `<delim>` to produce rows.
* `-re <regex>` uses `<regex>` to find rows in each input, returning an array of the capturing groups.

#### Transforming rows

For the following phases, there is the notion of an function-ish. A function-ish is a Janet expression that either:

- Refers to an existing function, like `sum`,`has` or ,`num`
- Or is a an expression that acts on one or more known parameters.

For instance, a mapper-ish that isn't a direct reference looks like `(fn [r] <mapper-ish>)`.
A reducer-ish is similar, but for `(fn [acc el] <reducer-ish>)`.


Using `-m <mapper-ish>` adds `<mapper-ish>` to the list of row mappers
Using `-f <mapper-ish>` adds `<mapper-ish>` as predicate to the row mappers, rejecting rows where `<mapper-ish>` returns `null`.
Using `-nf <mapper-ish>` adds `<mapper-ish>` as predicate to the row mappers, rejecting rows where `<mapper-ish>` anything *other* than `null`.
Using `-%` specifies that each row will be returning an array that should be flattened.

#### Aggregating rows


Using `-r <mapper-ish>` takes all the mapped rows, and gives them to `<mapper-ish>` as `r`, and then appends the result to the output array
Using `-r* <reducer-ish>` takes all of the mapped rows, and use `<reducer-ish>` as a reducer with the accumuulator assigned to `acc` and the curernt element assigned to `el`. It then appends the result to the output array
Using `-M <mapper-ish>` runs `<mapper-ish>` as a mapping function over the current output array, usually you'll want to use it *after* any `-r`/`-r*` calls
Using `-p <Prefix String>` prepends `<Prefix String>` to the pre-output array, which is printed before the output array.
Using `-j <string>` sets the output row joiner to `<string>`. By default, it is `\n`

### Special functions

The following functions in Jag have been set up to use the current row implicitly

- `columns: (& cols)` Wrapper around zipcoll, it treats `cols` as a list of keys, and the current row as a list of values, and turns the key/value pairs into a struct
- `has: (has patt &opt val)` Predicate to test if the current row contains `pat`. If `val` is passed, it is used instead of the current row.
- `num: (num val)` Parses `val` into a number, if possible.
- `regex: (patt &op val)` Performs a global spork/regex match on the current row. If `val` is passed, it is used instead of the current row.
- `split: (split delimeter &opt val)` Splits the row as a string using delimeter. If `val` is passed, it is used instead of the current row.


### Jag examples

#### Expanding PATH

```bash
# Posix
jag -E PATH -s :

# Windows 
jag -E PATH -s ;
```

#### Summing numbers from STDIN
```bash
$ echo 1,2,3 | jag -s , -m string/trim -m num -r sum 
# => 6
```

#### Getting the number of non-empty lines in jag.janet

```bash
jag -F jag.janet -m '(regex ".+")' -nf empty? -r length
```

#### Getting the `defn` lines out of jag.janet

```bash
jag -F jag.janet -re "(defn-?[^\n]+)" -nf empty? -m "(r 0)"
```

#### Building a list of tickets into a branch name

```bash
$ echo PROJ-34,PROJ-12,proj-577 | jag -re '([Pp][Rr][Oo][Jj])-(\d+)' -m "(update (thaw r) 0 string/ascii-upper)"  -r "(sorted-by |(num ($ 1)) r)" -M "(string/join r :-)" -j _ -p "tickets/"
# => tickets/PROJ-12_PROJ-34_PROJ-577

```

