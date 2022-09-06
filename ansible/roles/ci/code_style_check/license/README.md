This role checks whether the python and C++ files in a repository have appropriate copyright notices, as defined [here](https://shadowrobot.atlassian.net/wiki/spaces/SDSR/pages/594411521/Licenses).

It first checks the repository `LICENSE` file to determine whether the repository is public or private.

It then finds all .py, .c, .h, .cpp, .hpp, .msg, .yml, .yaml, .sh, .xml, .xacro, .dae, .launch files, and uses a regex match to check the copyright notice wording, year formatting, etc.

If you wish to exclude a file from copyright check (e.g. in the case of a file that doesn't belong to Shadow), create a file in the same directory as the file to be excluded, called `copyright_exclusions.cfg`. This file follows the same syntax as a `CPPLINT.cfg`, in that files are excluded using the `exclude_files=<regex>` directive. So the following file will exclude all files:

```
exclude_files=/*.
```

The following would excluce only .h files:

```
exclude_files=/*.h
```

And the following would exclude a specific file:

```
exclude_files=filename.c
```

Essentially, the string following `exclude_files` should be a regex matching the names of the files you want excluded.