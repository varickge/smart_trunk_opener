**Last updated: September 5th, 2022**

This Readme is an in-depth explanation of the tools used to manage this repository and why they are used.

## `make` and `makefile`


`make` is a very popular build tool for complied programming languages like C/C++ used to automate and simplify
the build process. On a very high level this is achieved by listing each of the desired non-source files (e.g.
binaries to be compiled) and adding information about how to compute it from other (source) files. For a detailed
explanation of how `make` works please consult the official [website.](https://www.gnu.org/software/make/)

Since the build process in Python is by far less complex, we use `make` and a corresponding `makefile` with
a slightly different idea in mind: Instead of focusing on how to compile and link source files we almost
exclusively use the rules to expose commands (or series of commands) that every developer who contributes
to this repository will need.

This has many advantages:
- one single and clear interface for project management issues instead of multiple scattered shell scripts
- guaranteed reproducibility of complex command series and alignment across developers and projects
- possibility to automatically chain commands using `make`'s `prerequisites`
- simplified developer workflow by hiding complexity away

Even though not being a hard requirement, it is highly recommended to get a basic understanding of `make`.

As of today, the `makefile` exposes the following rules:
- `dep-install`: uses `pip-sync` to sync your virtual environment with the pinned requirements of
the `requirements/dev.txt` file. Automatically executes the rule below if changes have been made to an `.in` file
- `requirements/<filename>.txt`: uses pip-compile to compile `.in` files into pinned `.txt` files (is a
prerequisite of `dep-install`, you won't have to use this explicitly)
- `tests`: runs pytest with coverage
- `run-hooks`: executes defined pre-commit hooks on all files
- `cleanup`: removes the virtual environment, build artifacts and other files

You can execute any of these rules by running `make <rule>` **inside an activated virtual environment**!

**Note:** To prevent (accidental) misuse, commands that have an impact beyond the local repository scope (e.g. deployment
to remote environments) were purposefully not added to the `makefile`.


## Dependency management
This repository uses [pip-tools](https://github.com/jazzband/pip-tools#example-usage-for-pip-compile) in
combination with `pip` to manage and install Python dependencies. Pip-tools main contribution is to pin the
package versions to guarantee reproducibilty and stable tests.

**Background**:
If the versions of dependencies are not fixed (pinned) reproducibility can be an issue. This is especially a problem
once the virtual environment is recreated (e.g. in the CI/CD pipeline) or when new developers join the project.
Without pinned dependencies `pip` will always install the latest available versions which often aren't
backwards-compatible and render the behavior of the application unpredictable. In the worse case the code will
even fail to run. Since this is a problem that potentially occurs with every new release of a dependent package valuable
time constantly needs to be spent for fixing the resulting errors.

**Interaction**:
If you want to update or add new dependencies you should follow these steps:
1) Add your requirements to the suitable `requirements/*.in` file or to the `install_requires` section in `setup.py`
if you're planning to distribute the package. Only restrict the version if you know that you need to! However,
if you're not planning long-term maintenance of the package it is probably a good idea to restrict the major version.
2) Run `make dep-install` to compile `*.in` files into corresponding pinned `*.txt` files and to
sync your environment. Make sure to have your virtual environment activated!

>**Warning**:
>If pip-compile finds an existing `.txt` file that already fulfils the dependencies listed in the
>`*.in` files no changes will be made, even if updates are available. To compile from scratch, first delete the
>existing `.txt` files or check
>the [pip-tools documentation](https://github.com/jazzband/pip-tools#example-usage-for-pip-compile) for
>alternative approaches. A simple and quick solution would be to temporarily pin a package to the desired version
>in the `*.in` file for the duration of the compilation.


3) If package versions have changed make sure that your code is still running as desired.
It's strongly recommended to cover this by automatic tests!


>**Warning**:
>Never use plain `pip install <xy>` commands as this can easily break the
>synchronized environment and cause problems. Only interact via the `dep-install` rule of the
>`makefile` unless you exactly know what you're doing.


## `pre-commit` hooks

Usually each pre-commit hook is executed in a restricted and isolated environment with only its own dependencies
installed. This means that some hooks won't work properly once they need access to actual project dependencies or
build artifacts. Out of the currently used hooks this is the case for `pylint` and `mypy`.
Both tools need to have access to required third-party packages for a reliable report.
For more details you can refer to these two links
[[pylint](https://pylint.pycqa.org/en/latest/user_guide/installation/pre-commit-integration.html),
[mypy](https://jaredkhan.com/blog/mypy-pre-commit)]. Due to that these two hooks must be run as
[local hooks](https://pre-commit.com/#repository-local-hooks).

To run the hooks, inside your virtual environment execute:
```shell
make run-hooks  # executes 'pre-commit run -a'
```

or use the `pre-commit` CLI to make use of additional configuration options.


## Deployment and `semantic-release`

This section is only important if you plan to release/deploy your app. If this is the case it is important that you
read carefully and check the linked websites.

#### TL;DR

In order to deploy/release your application from a commit you have to:
>1) write semantic commit messages
>2) make the pipeline pass
>3) execute the manual `tag-release` pipeline step for the commit of your choice on the default branch

#### How to create a release?

Releases are implemented via tags (see below how they are created), i.e. once a repository tag has been created
on the default branch an automatic pipeline step is triggered to build and release the package on pypi. This
step can easily be altered in order to deploy to arbitrary infrastructures. The current configuration requires
the tag to be created by the `ML-BOT` (see below) - manually defined tags won't trigger a deployment.

#### How to create a tag?

Tags should represent the version of the application and follow the [Semantic Versioning](https://semver.org/) scheme
Please familiarize yourself with this convention! In a nutshell, while commits with bug fixes should increment the patch
and new features the minor version a breaking change must always increase the major version. Now, instead of manually
assigning versions/tags the idea is to write commit messages in such a way that they can automatically be parsed for the
respective changes. To make the messages machine-readable a common way is to follow the
[Conventional Commits Convention](https://www.conventionalcommits.org/en/v1.0.0/).

The tool we use for the actual parsing is the npm package
[`semantic-release`](https://semantic-release.gitbook.io/semantic-release/) which can configured via the
`.releaserc.template.json` file.
Please do read the documentation for details about the configuration and how to add additional plugins.
Workflow: `semantic-release` parses all commit messages since the previous release (tag) and based on their contents
creates a new tag with the calculated version number.

Please familiarize yourself with the following two links in order to understand how commit messages should be
structured and how they are parsed by default (can be configured via the config file).
**If your commit messages don't follow the expected format no release will be made!**
- https://www.conventionalcommits.org/en/v1.0.0/
- https://semantic-release.gitbook.io/semantic-release/#how-does-it-work


#### Who is the ML-BOT?

Creating a tag requires push rights to the repository. The recommended way to realize this is using access tokens
with appropriate rights that can be accessed via environment variables.
Currently, there is one
[group access token](https://git.intive-automotive.com/groups/MachineLearning/-/settings/access_tokens) with the name
`ML-BOT` registered in the Machine Learning Group in GitLab. Its associated value is exposed via
the `ML_BOT_ACCESS_TOKEN` CI variable
(see [here](https://git.intive-automotive.com/groups/MachineLearning/-/settings/ci_cd)).
`semantic-release` will use this token for its authentication when pushing tags.

You can read more about access tokens here:
- https://docs.gitlab.com/ee/security/token_overview.html
- https://docs.gitlab.com/ee/user/group/settings/group_access_tokens.html#group-access-tokens
