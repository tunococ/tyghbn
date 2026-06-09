# sorted_array_tower

A modern C++ library for efficient sorted array operations using C++20.

## Features

- **Template-based SortedArrayTower** data structure with automatic sorted insertion
- **C++20 Support** - Uses concepts and requires clauses for type safety
- **Dual Compilation Modes** - Supports both traditional headers and C++20 modules
- **Efficient Operations** - Binary search for $O((\log n)^2)$ lookups
- **Comprehensive Testing** - Full test suite using doctest framework
- **Modern Build System** - CMake with Conan dependency management

## Usage

## Development

### Prerequisites

- C++ compiler that supports C++20 (GCC 15 or newer, Clang 18 or newer)
- CMake 4.3.2 or newer
- Conan 2.0 or newer

#### Notes on other dependencies

C++ module support
- GNU Make doesn't support C++ modules or multi-config builds.
  - Ninja version 1.12.0 or newer can support both.
- `clang` needs `clang-scan-deps` command to be available.

Coverage information
- [`gcovr`]((https://gcovr.com/en/stable/installation.html) is needed to
  generate coverage reports.
- GCC needs `gcov`. It must be the same version as `gcc`.
- Clang needs `llvm-cov`. It must be the same version as `clang`.

### Build process

The build process consists of the following steps:
1. Conan install stage.
2. CMake configure stage.
3. CMake build stage.

Before you start building, you should be aware if your *build generator* is a
single-config generator or a multi-config generator, as the build process
differs slightly in [step 2](#2-cmake-configure-stage) below.

<!-- TODO: Expand on Conan profiles and generators -->

### 1. Conan install stage

There are two build types exposed by Conan: debug and release.
You need to run `conan install` to prepare for each build type.

- debug:
  
  ```bash
  conan install . --build=missing -s build_type=Debug
  ```

- release:

  ```bash
  conan install . --build=missing -s build_type=Release
  ```

You can prepare for both build types by running both commands.

#### Predefined profiles in [.pr](.pr)

This repository provides some predefined Conan profiles in the subdirectory
[.pr](.pr). There two 3 types of profiles:

- Base profiles: You should use these to specify which compiler to use.
  - [clang](.pr/clang): Use Clang as the compiler.
  - [gcc](.pr/gcc): Use GCC as the compiler.
- Generator add-ons: Add this profile to an existing profile to choose Ninja
  as the generator.
  - [ninja-debug](.pr/ninja-debug): Use Ninja for a single-config debug build.
    This profile already includes `-s build_type=Debug`.
  - [ninja-release](.pr/ninja-release): Use Ninja for a single-config release
    build. This profile already includes `-s build_type=Release`.
  - [ninja-multi-debug](.pr/ninja-multi-debug): Use Ninja for a multi-config
    build, and prepare dependencies for the debug build. This profile already
    includes `-s build_type=Debug`.
  - [ninja-multi-release](.pr/ninja-multi-release): Use Ninja for a
    multi-config build, and prepare dependencies for the release build. This
    profile already includes `-s build_type=Release`.
- Combined profiles: Shortcuts that are combinations of the two options above.
  - [clang-debug](.pr/clang-debug): Same as `clang` and `ninja-debug`.
  - [clang-release](.pr/clang-release): Same as `clang` and `ninja-release`.
  - [clang-multi-debug](.pr/clang-multi-debug): Same as `clang` and
    `ninja-multi-debug`.
  - [clang-multi-release](.pr/clang-multi-release): Same as `clang` and
    `ninja-multi-release`.
  - [gcc-debug](.pr/gcc-debug): Same as `gcc` and `ninja-debug`.
  - [gcc-release](.pr/gcc-release): Same as `gcc` and `ninja-release`.
  - [gcc-multi-debug](.pr/gcc-multi-debug): Same as `gcc` and
    `ninja-multi-debug`.
  - [gcc-multi-release](.pr/gcc-multi-release): Same as `gcc` and
    `ninja-multi-release`.

All the combined profiles assume that Ninja is the generator because it
supports both C++ modules and multi-config builds.

As an example, you can use

```bash
conan install . --build=missing -pr .pr/clang-multi-debug
conan install . --build=missing -pr .pr/clang-multi-release
```

or

```bash
conan install . --build=missing -pr .pr/clang -pr .pr/ninja-debug
conan install . --build=missing -pr .pr/clang -pr .pr/ninja-release
```

to prepare for both build types and specify that you want to use Clang as the
compiler and Ninja as the generator for a multi-config build.

#### Using modules vs using headers

By default, this library will be built for a consumer that uses C++ modules.
To use headers instead, append `-o use_modules=False` to the `conan install`
command. For example,

```bash
conan install . --build=missing -pr .pr/gcc-debug -o '&:use_modules=False'
```

will prepare a build system for a library that use headers, where the compiler
is GCC and the build mode is debug.



### 2. CMake configure stage

If you are using a single-config generator, choose the preset consistent with
the build type you chose earlier.

- single-config, debug:

  ```bash
  cmake --preset conan-debug
  ```

- single-config, release:

  ```bash
  cmake --preset conan-release
  ```

You can run both commands if you ran `conan install` for both build types.

If you are using a multi-config generator, you only need to run one command and
it will cover both build types.

- multi-config:

  ```bash
  cmake --preset conan-default
  ```

*Note: If you want to generate coverage reports, you must add the option
`-DTYGHBN_ENABLE_COVERAGE=ON` to the command at this stage.
See [below](#generating-code-coverage-reports) for more information.*

### 3. CMake build stage

- debug:

  ```bash
  cmake --build --preset conan-debug
  ```

- release:

  ```bash
  cmake --build --preset conan-release
  ```

*Note: You can only compile code in the build type that you prepared earlier.*

### Running tests

After you have successfully compiled the code with `cmake --build`, you can run
tests by issuing a `ctest` command. Use the same preset as what you used when
you compiled your code with `cmake --build`.

- For the debug build:

  ```bash
  ctest --preset conan-debug
  ```

- For the release build:

  ```bash
  ctest --preset conan-release
  ```

### Generating code coverage reports

To generate coverage reports, you need to
- have this project as the top-level project.
- have [`gcovr`](https://gcovr.com/en/stable/installation.html) installed.
- (for GCC) have `gcov` command available, and with the same version as `gcc`.
- (for Clang) have `llvm-cov` command available, and with the same version as
  `clang`.

Code coverage instrumentation can be generated by adding
`-DTYGHBN_ENABLE_COVERAGE=ON` to the CMake configure command in the
[CMake configure stage](#2-cmake-configure-stage) *when this project is the
top-level project*.

- single-config generator (debug):

  ```bash
  cmake --preset conan-debug -DTYGHBN_ENABLE_COVERAGE=ON
  ```

- single-config generator (release):

  ```bash
  cmake --preset conan-release -DTYGHBN_ENABLE_COVERAGE=ON
  ```

- multi-config generator:

  ```bash
  cmake --preset conan-default -DTYGHBN_ENABLE_COVERAGE=ON
  ```

After configuring, the coverage reports can be built with

```bash
cmake --build --preset conan-debug --target coverage
```

or

```bash
cmake --build --preset conan-release --target coverage
```

depending on the build type.

*Note: A coverage report generated from a release build might not be accurate.
It is generally better to generate a coverage report from a debug build.*

The HTML report will be in `build/Debug/coverage_report/` or
`build/Release/coverage_report/`, depending on the build type.
(Note the capitalization.)
Open `index.html` inside the directory in a web browser to view it.

Alternatively, you can serve the HTML file with Python's http.server.
For example,

```bash
python3 -m http.server --directory build/Debug/coverage_report 8080
```

will make the coverage report from the debug build available at
`localhost:8080`.

### Troubleshooting

- In order to use Clang with C++ modules, you will need `clang-scan-deps` to
  be available. It is a part of [Extra Clang Tools](
    https://clang.llvm.org/extra/index.html).
- In order to generate coverage information with `gcc`, `gcov` must be
  accessible and have the same version as `gcc`.
- In order to generate coverage information with `clang`, `llvm-cov` must be
  accessible and have the same version as `clang`.

### `just` scripts

`just` commands are provided for convenience.
To use them, install [just](https://github.com/casey/just) version 1.51.0 or
newer, then type `just --list` to see available commands.
Also, make sure that you have Ninja installed as these commands rely on
Ninja-based profiles.

Below is a summary of available `just` commands:

- ```bash
  just clean
  ```

  Removes the [`build`](build) directory.

- ```bash
  just init [{debug | release} [<compiler> [{cov | -} [{mod | -}]]]]
  ```

  Does [step 1](#1-conan-install-stage) and [step 2](#2-cmake-configure-stage)
  with a given build type (`debug` or `release`), a given compiler (default
  to `gcc`), and Ninja single-config as the generator.
  If the second last argument contains `cov` as a substring, the code coverage
  report generation will be enabled. (If absent, it defaults to `cov`.)
  If the last argument contains `mod` as a substring, the code will be compiled
  for C++ modules. (If absent, it defaults to `mod`.)

  Examples:
  - ```bash
    just init debug clang -
    ```
    Prepares for the debug build, using Clang as the compiler, without the
    `coverage` CMake target. The library will be built as a C++ module.
  
  - ```bash
    just init release gcc with-coverage -
    ```
    Prepares for the release build, using GCC as the compiler, with the
    `coverage` CMake target. The library will be built for classic header
    `#include`.

- ```bash
  just init-single [<compiler> [cov | -]]
  ```

  Initializes both build types by passing the supplied arguments to
  `just init debug` and `just init release`.

- ```bash
  just init-multi [<compiler> [cov | -]]
  ```

  Does [step 1](#1-conan-install-stage) and [step 2](#2-cmake-configure-stage)
  with a given compiler (default to `gcc`) and Ninja multi-config as the
  generator.
  If the last argument contains `cov` as a substring, the code coverage report
  generation will be enabled. If the last argument is not specified, it will
  default to `cov`.

  Examples:

  - ```bash
    just init-multi clang -
    ```

    Uses Clang as the compiler and Ninja multi-config as the generator.
    Code coverage report generation will be disabled.
  
  - ```bash
    just init-multi
    ```

    Uses GCC as the compiler and Ninja multi-config as the generator.
    Code coverage report generation will be enabled.

- ```bash
  just build {debug | release} [...args]
  ```

  Builds the code for the given build type. This simply calls

  ```bash
  cmake --build --preset conan-{debug | release} ...args
  ```

- ```bash
  just test {debug | release}
  ```

  Runs tests for the given build type.

  The code must have been built before running tests.

  After the test is run, the test results in JUnit format will be stored in
  `build/<Build_type>/report.xml` where `Build_type` is the capitalized version
  of the specified build type.

- ```bash
  just build-cov {debug | release}
  ```

  Builds the code coverage report for the given build type.
  This will automatically build and run tests, and generate the coverage report
  in the directory `build/<Build_type>/coverage_report`, where `<Build_type>`
  is the capitalized version of the specified build type.

  **Prerequisites:**
  - The build system must have been initialized with coverage information
    enabled.
  - Relevant programs must be installed. See
    [Generating code coverage reports](#generating-code-coverage-reports)
    for more information.

- ```bash
  just show-cov {debug | release} [<port>]
  ```

  Shows the code coverage report for the given build type as a web page at
  `http://localhost:<port>`. The default port is 8070.

  This will only work after the coverage report has been generated.

There are also `just` shortcuts that assume some default arguments:

- `just cl` ⇒ `just clean`.
- `just id` ⇒ `just init debug`.
- `just ir` ⇒ `just init release`.
- `just is` ⇒ `just init-single`.
- `just im` ⇒ `just init-multi`.
- `just ihd` ⇒ `just init debug gcc cov -`.
- `just ihr` ⇒ `just init release gcc cov -`.
- `just ihs` ⇒ `just init-single gcc cov -`.
- `just ihm` ⇒ `just init-multi gcc cov -`.
- `just bd` ⇒ `just build debug`.
- `just br` ⇒ `just build release`.
- `just ba` ⇒ `just bd; just br`.
- `just td` ⇒ `just test debug`.
- `just tr` ⇒ `just test release`.
- `just ta` ⇒ `just td; just tr`.
- `just bcd` ⇒ `just build-cov debug`.
- `just bcr` ⇒ `just build-cov release`.
- `just bca` ⇒ `just bcd; just bcr`.
- `just scd` ⇒ `just show-cov debug`.
- `just scr` ⇒ `just show-cov release`.

Just commands that don't have arguments can be combined in a single line.
For example,

- ```bash
  just clean is bc sc
  ```
  will clean the build directory, initialize the build system, build the
  code coverage report, and display it.

#### Composite `just` commands for CI

- ```bash
  just clean-build [<build_type> [<compiler> [<coverage> [<modules>]]]]
  ```

  Cleans the [build](build) directory, initializes the build system with the
  given options (with `just init <build_type> <compiler> <coverage> <modules>`
  ), then builds the code (with `just build <build_type>`).

- ```bash
  just clean-test [<build_type> [<compiler> [<coverage> [<modules>]]]]
  ```

  Does `just clean-build`, followed by `just test <build_type>`.

- ```bash
  just clean-cov [<build_type> [<compiler> [<modules>]]]
  ```

  Does `just clean-build` with `coverage=cov`, followed by
  `just build-cov <build_type>`.

- ```bash
  just check-builds
  ```

  Cleans and builds for the debug build for the 4 combinations:
  - GCC with C++ modules
  - GCC with headers
  - Clang with C++ modules
  - Clang with headers

  This is meant to be a big check whether the code compiles or not.

- ```bash
  just make-reports [<compiler> [<modules>]]
  ```

  Cleans, builds, runs tests to generate a test report (in
  <build/Debug/report.xml>), and a coverage report (in
  <build/Debug/coverage_report>).

### Docker

Some Dockerfiles for development are provided in the [ci](ci) subdirectory.
You can use the provided <ci/compose.yaml> to simplify building docker images
and running containers locally. Some `just` commands are also provided for
convenience.

- ```bash
  just run-docker [<variant> [<stage> [...args]]]
  ```

  Builds an ephemeral Docker container from the image at the specified `stage`
  in `Dockerfile.<variant>`, and run the command specified in `...args`.
  Files in this repository will be copied into the container at directory
  `/workspace` before the command is run.

  - `variant`: A suffix of a Dockerfile in the [ci](ci) subdirectory.
    For example, putting `ubuntu` will use
    [ci/Dockerfile.ubuntu](ci/Dockerfile.ubuntu).
    If `variant` is not specified, it defaults to `alpine`.
  - `stage`: A *stage* in the Dockerfile. This should be `gcc` or `full`.
    The `gcc` stage has a smaller image than `full` as it does not have
    Clang and related tools.
    If `stage` is not specified, it defaults to `gcc`.
  - `args`: The command to run on the container. If not specified, it defaults
    to `sh`, which effectively brings up an interactive shell of the container.
    (The container will be destroyed after the shell session ends.)

- ```bash
  just create-docker [<variant> [<stage> [<name> [...args]]]]
  ```

  Creates a Docker container with the specified `name` from the image at the
  specified `stage` in `Dockerfile.<variant>`, and run the command specified in
  `...args` in detached mode.
  Files in this repository will be copied into the container at directory
  `/workspace` before the command is run.

  - `variant`: A suffix of a Dockerfile in the [ci](ci) subdirectory.
    For example, putting `ubuntu` will use
    [ci/Dockerfile.ubuntu](ci/Dockerfile.ubuntu).
    If `variant` is not specified, it defaults to `alpine`.
  - `stage`: A *stage* in the Dockerfile. This should be `gcc` or `full`.
    The `gcc` stage has a smaller image than `full` as it does not have
    Clang and related tools.
    If `stage` is not specified, it defaults to `gcc`.
  - `name`: The name of the container. If not specified, it defaults to
    `<variant>-<stage>`. If a container with the specified name already exists,
    it will be stopped and deleted first.
  - `args`: The command to run on the container. If not specified, it defaults
    to `tail -f /dev/null`, which effectively does nothing except keeping the
    container alive.

- ```bash
  just clean-docker-images [<prefix>]
  ```

  Calls `docker rmi` on all images whose tags have the specified `prefix`.
  If `prefix` is not specified, it defaults to `tyghbn-`, which is the prefix of
  `name` in [compose.yaml](ci/compose.yaml).

Example:

- ```bash
  just run-docker ubuntu full just check-builds
  ```

## Code documentation

**Prerequisite: [Doxygen](https://www.doxygen.nl/) version 1.9.8 or newer**

- ```bash
  just doc
  ```

  Create the code documentation in `build/doc`.

- ```bash
  just clean-doc
  ```

  Remove `build/doc`.

- ```bash
  just show-doc [<port>]
  ```

  Show the doc as an webpage at `http://localhost:<port>`.
  The default `port` is 8060.