# System tests

## Run the benchmarking

> ℹ️ Ensure that the latest data for benchmarking is available.
>
> Our data is stored in a stand-alone repository:
> [anti-peeking.data](TODO). This repository is hooked as a
> submodule into this repository under `data`. The commands in this guide are executed from `anti-peeking.data` root. Since
> we use the repository as sub-module, all commands must be executed from `data`. You can skip the installation
> instructions in the [DVC guide](../data/README.md), because we installed  `dvc` already in `../.venv`.
>
> 1. Pull the latest state from the data submodule `git submodule update --remote data` (only command that must be executed from
>    project root).
> 2. Pull the latest data from `dvc`. Find more information in the [DVC guide](../data/README.md).
>
>
>
> If you would like to add new recordings to the benchmarking, please follow the guide [Add new
> data](../data/README.md#Add-new-data) and add the recordings in [`recs.yaml`](recs.yaml).


### Requirements

If you want to execute the benchmarking you have to run the pytest command **inside the benchmarking directory**:

```bash
# Run all tests, use default options
pytest
# Run test to produce visualizations (-> benchmarking/artifacts/images) on 4 CPUs with the c app on all recordings with scope `all`.
pytest -n4 --scope all ./tests/
```

After you executed the tests, a PDF report is generated (`benchmarking/artifacts/report_<branch>_<revision>.pdf`).


**Most relevant pytest commandline options**:
```
--help              Show the commandline help.
--scope={all,debug}
                    Scope of the tests. The scope for individual recordings is defined in recs.yaml.
--app={c,matlab,python}
                    Application that is used to generate predictions. If 'matlab' is selected, the anti-peeking will be
                    performed using the matlab runtime. If 'c' is selected, the generated C lib along with the python-
                    wrapper is used. Make sure you have loaded the right modules when running the benchmarking in the 
                    hpc environment. By default, the generated C code is used. 
-n numprocesses, --numprocesses=numprocesses
                    Shortcut for '--dist=load --tx=NUM*popen'. With 'auto', attempt to detect
                    physical CPU count. With 'logical', detect logical CPU count. If physical CPU
                    count cannot be found, falls back to logical count. This will be 0 when used
                    with --pdb.
-r chars            show extra test summary info as specified by chars: (f)ailed, (E)rror,
                    (s)kipped, (x)failed, (X)passed, (p)assed, (P)assed with output, (a)ll except
                    passed (p/P), or (A)ll. (w)arnings are enabled by default (see
                    --disable-warnings), 'N' can be used to reset the list. (default: 'fE').
-k EXPRESSION       only run tests which match the given substring expression. An expression is a
                    python evaluatable expression where all names are substring-matched against
                    test names and their parent classes. Example: -k 'test_method or test_other'
                    matches all test functions and classes whose name contains test_method' or
                    'test_other', while -k 'not test_method' matches those that don't contain
                    'test_method' in their names. -k 'not test_method and not test_other' will
                    eliminate the matches. Additionally keywords are matched to classes and
                    functions containing extra names in their 'extra_keyword_matches' set, as well
                    as functions which have names assigned directly to them. The matching is
                    case-insensitive.
```



## Test architecture

Our benchmarking environment is based on [``pytest``][pytest] as a central tool.
[``pytest``][pytest] allows us to build a complex test environment, which is able to

* run different tests on a list of recordings
* re-use intermediate results to decrease the runtime
* parallelize tests on multiple workers (e.g. CPU cores)
* collect all the results in a single place
* get a detailed analysis of the passed and failed tests

The central element in our test architecture are [pytest fixtures](https://pytest.org/fixture.html). The fixtures allow
us to re-use intermediate results like the output of our algorithm and run different tests upon the output, e.g. to
compare the range information, angle information, correct segments, etc. We set up fixtures in a hierarchical way to
make full use of their power (*simplified diagram - the names might differ in the real implementation and there might be
skipped intermediate fixtures*):

```
┌─────┐  ┌─────────────────┐
│ app │  │ radar_recording │─────────────────────────────┐
└─────┘  └─────────────────┘                             │
   │             ↓                                       ↓
   │       ┌────────────┐                          ┌───────────┐
   │       │ radar_data │                          │ label_dir │
   │       └────────────┘                          └───────────┘
   │             ↓                                       ↓
   │        ┌─────────┐                             ┌─────────┐
   └──────› │ run app │                             │ extract │
            └─────────┘                             └─────────┘
            ↙         ↘                             ↙        ↘
 ┌──────────────┐  ┌────────────┐    ┌──────────────────┐  ┌────────────────────┐
 │  app_kicks   │  │      -     │    │ reference_kicks  │  │          -         │
 └──────────────┘  └────────────┘    └──────────────────┘  └────────────────────┘
```

The starting point to run benchmarks is always a radar recording. We use the radar data inside and process it with an
app to get the application's segments and tracks. At the same point in time, we look inside the recording
directory for labels. We extract from the labels also tracks and segments.

Inside the tests, we access only the fixtures at the bottom (algo/label kicks). We can completely ignore
which app or labeling algorithm was used to produce the predictions. By doing this, we have an abstract layer in
between the actual test cases and the generation of test data, which allows us to easily exchange the used application
or to add a new one.


### Test functions

We do the actual comparisons of the algorithm and the reference in test cases. Fixtures can be easily accessed by
specifying them as function arguments:

```python
def test_number_of_tracks(input_app, input_reference):
    """Test if the number of tracks is correct."""
    assert len(input_app.kicks) == len(input_reference.kicks)
```

[``pytest``][pytest] provides a rich documentation how you write test cases. Additionally, you can have a look at 
already existing test cases and seek there for inspiration.



[pre-commit]: https://pre-commit.com/
[python]: https://www.python.org/
[pytest]: https://pytest.org
[venv]: https://docs.python.org/3/library/venv.html
