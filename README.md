# tyghbn

Repository template for C++ library package development


## Objectives

This repository contains example code of a C++ library package project.
You can choose to build with or without the C++ module support.

The development workflow has been tested with the following software installed:

- [CMake](https://cmake.org/) 4.3.2
- [GCC](https://gcc.gnu.org/) 15
- [Clang](https://clang.llvm.org/) 18
  - [Extra Clang Tools](https://clang.llvm.org/extra/index.html) 18
  - [LLVM](https://llvm.org/) 18
- [Python3](https://www.python.org/) 3.11.2
- [Conan](https://conan.io/) 2.28.1
- [Gcovr](https://gcovr.com/) 8.6
- [Docker](https://www.docker.com/) 29.5.3
- [Just](https://just.systems/) 1.15.0
- [Doxygen](https://www.doxygen.nl/) 1.18.0
  - [Graphviz](https://graphviz.org/) 2.43.0

## How to use this template

### Renaming

This template is for a C++ library package. The package is named `Tyghbn`.
This name was chosen to be easy to type, and unique enough to find and replace.
There are 3 variants of this name that occur in files in this repository:

- `Tyghbn`: Used in [`conanfile.py`](conanfile.py) as a Python class name and
  in Doxygen comment for the main page ([here](include/tyghbn/tyghbn.hpp)).
- `TYGHBN`: Used in variable names in scripts and C++ macros.
- `tyghbn`: Used in C++ code as a namespace name, module names, and header file
  names.

You should rename these strings with proper variants of your project name in
all files, as well as rename all files and subdirectories with `tyghbn` in
their names.


### C++ code structure

This template puts C++ code into 3 subdirectories:
- [`include`](include): Header files that expose the public interface.
- [`src`](src): `.cpp` files that implement non-template entities.
- [`modules`](modules): `.cppm` files that expose C++ modules as the public
  interface.

To support both the header style and the C++ module style, the main code logic
must be independent of C++ modules. That means the main implementation must be
in the traditional C++ style: header files in [`include`](include) and 
implementation files in [`src`](src).
The C++ module interfaces, defined in [`modules`](modules), simply export 
entities from header files in [`include`](include). `.cppm` files in
[`modules`](modules) show how to make a C++ module interface from a header
file.

The file [`include/tyghbn/tyghbn.hpp`](include/tyghbn/tyghbn.hpp) is an
umbrella interface that includes the other two header files: `add_one.hpp`
and `or_else.hpp`.
In the [`modules`](modules) subdirectory, each of the `.cppm` files defines
a C++ module from a header file of the same name.
Note that [`tyghbn.cppm`](modules/tyghbn.cppm) does not include
[`tyghbn.hpp`](include/tyghbn/tyghbn.hpp). Instead, it `imports` the other two
`.cppm` files, similar to how [`tyghbn.hpp`](include/tyghbn/tyghbn.hpp)
includes the other two `.hpp` files.

Test code lives in [`tests`](tests).
The test library used here is [doctest](https://github.com/doctest/doctest).
You can change the test library easily by modifying the dependency in
[`conanfile.py`](conanfile.py) and in [`CMakeLists.txt`](CMakeLists.txt).
Read below for more details.


### CMakeLists.txt

To support choosing between compiling for C++ modules or not, a variable named
`TYGHBN_USE_MODULES` can be set during the build configuration time to specify
this choice. When you call `conan install`, the Conan option `use_modules` will
translate to `TYGHBN_USE_MODULES` in CMake.
This logic lives in `Tyghbn.generate` in [`conanfile.py`](conanfile.py).

[`CMakeLists.txt`](CMakeLists.txt) defines 3 main library targets:

- `add_one`
- `or_else`
- `tyghbn`

Each library target has one header file in [`include/tyghbn`](include/tyghbn)
and one module file in [`modules`](modules) of the same name.
The header file exposes a traditional interface, while the module file exposes
a C++ module interface. Note that the directory structure of
[`modules`](modules) is simpler than [`include/tyghbn`](include/tyghbn) as it
does not need a nested `tyghbn` inside for disambiguation.

**Base `-legacy` library targets**

For each of the main library targets, we also have a base `-legacy` library.
For the non-C++-module case (when `TYGHBN_USE_MODULES` is not `ON`), this is
exactly the same as the main library target. For the C++-module case, a `.cppm`
file is added on top of the base `-legacy` library.

The type of the CMake library target of `add_one-legacy` is not the
same as `or_else-legacy` because `or_else-legacy` is a header-only library,
but `add_one-legacy` is not. The `if` conditional blocks attempt to unify this
divergence, which is arguably a historical quirk of CMake.

- When you are making a library without `.cpp` files, you can use the CMake
  code in the `TEMPLATE_BLOCK: Library without cpp files` as your guide.

- When you are making a library with `.cpp` files, you can use the CMake code
  in the `TEMPLATE_BLOCK: Library with cpp files` as your guide.


**Umbrella library target**

The base `-legacy` umbrella target is an `INTERFACE` library because it does
not add any code on top of its submodules.
The place you will need to modify is the list of submodules inside
`target_link_libraries(tyghbn-legacy ...)`.


**Test library**

This project uses [`doctest`](https://github.com/doctest/doctest) as the test
library, but you can switch to a different library by modifying the following
things:

- The function `Tyghbn.requirements()` in [conanfile.py](conanfile.py).
- CMake code in `TEMPLATE_BLOCK: Test library initialization` and
  `TEMPLATE_BLOCK: Test library finalization` in
  [CMakeLists.txt](CMakeLists.txt).


## Development instructions

### Prerequisites

- C++ compiler that supports C++20 (GCC 15 or newer, Clang 18 or newer)
- CMake 4.3.2 or newer
- Conan 2.0 or newer

#### Additional dependencies

- **For C++ module support**
  - GNU Make doesn't support C++ modules.
    [Ninja](https://ninja-build.org/) (version 1.12.0 or newer) is a
    recommended replacement.
  - `clang` needs `clang-scan-deps` command to be available.
    You might need to install
    [extra Clang tools](https://clang.llvm.org/extra/), and make sure
    `clang-scan-deps` is available from the command line.

- **For coverage information**
  - [`gcovr`](https://gcovr.com/en/stable/installation.html) is needed to
    generate coverage reports.
  - GCC needs `gcov`. It is usually included with `gcc`. You only need to make
    sure that it is available at the command line and that it has the same
    version as `gcc`.
  - Clang needs [`llvm-cov`](https://llvm.org/docs/CommandGuide/llvm-cov.html)
    to be available at the command line.
    You might need to install [`llvm`](https://llvm.org/) with the same version
    as your installation of `clang`.

- **For `just` commands**
  - [`just`](https://github.com/casey/just) provides more ergonomic commands
    for common command-line tasks.
    If you install `just`, you can use [`just` commands](#just-scripts)
    defined in [`justfile`](justfile).

- **For development in a Docker container**
  - The [`ci`](ci) subdirectory contains some Dockerfiles and a
    [`compose.yaml`](ci/compose.yaml) that helps with making development-ready
    Docker images and containers. See the [`Docker section`](#docker) for
    more information.

- **For Doxygen documentation**
  - You will need [Doxygen](https://www.doxygen.nl/) version 1.9.8 or newer as
    C++ module support was not available before that.
  - Doxygen has a dependency on [Graphviz](https://graphviz.org/), so you might
    need to install it too.

### Development workflow

The development environment can be separated into the following stages:
1. [Conan install](#1-conan-install-stage)
2. [CMake configure](#2-cmake-configure-stage)
3. [CMake build](#3-cmake-build-stage)
4. [CTest](#4-ctest-stage)


### 1. Conan install stage

> **Prerequisite**: You need to have a Conan profile that contains your system
> configuration. This is generally done by calling
> ```bash
> conan profile detect --force
> ```

This stage prepares the `build` subdirectory for building.
The command to run is

```bash
conan install . --build=missing [...args]
```

`[...args]` specifies choices to be made at this stage, which are:
- Build type: There are four build types that CMake recognizes:

  - `Debug`
  - `Release`
  - `RelWithDebInfo`
  - `MinSizeRel`

  You choose the build type by appending `-s build_type=...` to the
  `conan install` command.
  If you omit `-s`, the default is `Release`.
- Compiler: Your default profile contains a default compiler, but you can
  override it.
  - You will actually need to override the C++ standard version in your
    default profile because our code needs C++20, but `conan profile detect` 
    usually creates a profile with an older C++20 standard.
  - This repository provides the following Conan profiles for compiler choices:
    - [`.pr/gcc`](.pr/gcc): The GCC version is also fixed to >= 15.
    - [`.pr/clang`](.pr/clang): The Clang version is also fixed to >= 18.
  
  You can choose the compiler by appending `-pr .pr/...` to the
  `conan install` command.
- Build generator: Your default generator is dependent on your operating
  system, but you can override it.
  - There are two types of *build generators*: single-config, and multi-config.
    The difference between these two types does not affect the workflow except
    in [step 2](#2-cmake-configure-stage) when you call
    `cmake --preset conan-...`.
  - This repository provides the following Conan profiles to override your
    default generator with [Ninja](https://ninja-build.org/):
    - [`.pr/ninja`](.pr/ninja): `Ninja`
    - [`.pr/ninja-multi`](.pr/ninja-multi): `Ninja Multi-Config`
  
  You can choose the generator by appending `-pr .pr/...` to the
  `conan install` command.
- C++ module support: This repository supports building the package with and
  without C++ module interfaces. Appending one of the following options to
  the `conan install` command to make the choice:
  - `-o '&:use_modules=True'`: build with C++ module support
  - `-o '&:use_modules=False'`: build without C++ module support
  
  If not specified, `use_modules` defaults to `True`.

**Examples**

- ```bash
  conan install . --build=missing -pr .pr/gcc -s build_type=Debug
  ```
  - Build type: `Debug`
  - Build generator: OS-provided
  - Compiler: GCC
  - C++ module support: enabled

- ```bash
  conan install . --build=missing -pr .pr/clang -pr .pr/ninja-multi -o '&:use_modules=False'
  ```
  - Build type: `Release`
  - Build generator: Ninja multi-config
  - Compiler: GCC
  - C++ module support: disabled

- ```bash
  conan install . --build=missing -pr .pr/gcc -pr .pr/ninja -o '&:use_modules=True' -s build_type=RelWithDebInfo
  ```
  - Build type: `RelWithDebInfo`
  - Build generator: Ninja
  - Compiler: GCC
  - C++ module support: enabled

You can run `conan install` multiple times with different build types to
prepare multiple build types at once, but you should not vary other options.
You will have to remove the `build` subdirectory and `CMakeUserPresets.json` if
you want to vary other options.


### 2. CMake configure stage

This is where the difference between a single-config generator and a
multi-config generator matters.

- Single-config:
  ```bash
  cmake --preset conan-<buildtype>
  ```
  This has to be executed for each build type that you have previously
  prepared with `conan install` in [step 1](#1-conan-install-stage),
  and `buildtype` is a lowercase version of the build type.

  For example, if you want to use `Debug` and `MinSizeRel`, you will need to run
  two commands
  ```bash
  cmake --preset conan-debug
  cmake --preset conan-minsizerel
  ```
  Note that `debug` and `minsizerel` are in lowercase.

- Multi-config:
  ```bash
  cmake --preset conan-default
  ```
  You only need to run this once.


#### Coverage information

If you want to generate coverage reports, you must append
`-DTYGHBN_ENABLE_COVERAGE=ON` to the `cmake --preset` command.
See the section [Generating code coverage reports](#generating-code-coverage-reports)
below for more information.


### 3. CMake build stage

To build the code, execute

```bash
cmake --build --preset conan-<buildtype>
```

for each `<buildtype>` that you have prepared earlier.
For example,

```bash
cmake --build --preset conan-debug
```

will compile and build the package for the `Debug` build.


### 4. CTest stage

After you have successfully compiled the code with `cmake --build`, you can run
tests by issuing a `ctest` command. The format is similar to `cmake --build`:

```bash
ctest --preset conan-<buildtype> [...args]
```

For example,

```bash
ctest --preset conan-debug
```

will run tests for the `Debug` build.


### Generating code coverage reports

**Prerequisites**: To generate coverage reports, you need to

- have this project as the top-level project.
- have [`gcovr`](https://gcovr.com/en/stable/installation.html) installed.
- (for GCC) have `gcov` command available, and with the same version as `gcc`.
- (for Clang) have `llvm-cov` command available, and with the same version as
  `clang`.

Provided that all the requirements above are met,
code coverage instrumentation can be generated by adding
`-DTYGHBN_ENABLE_COVERAGE=ON` to the CMake configure command in the
[CMake configure stage](#2-cmake-configure-stage).
Remember that there is a difference at this stage between using a single-config
generator and using a multi-config generator.

**Example**
- Single-config generator
  ```bash
  cmake --preset conan-default -DTYGHBN_ENABLE_COVERAGE=ON
  ```
  prepares coverage instrumentation for the `Debug` build.
- Multi-config generator
  ```bash
  cmake --preset conan-default -DTYGHBN_ENABLE_COVERAGE=ON
  ```
  prepares coverage instrumentation for all build types.


After configuring, the coverage reports can be made by building the `coverage`
target, i.e., passing `--target coverage` to the `cmake --build` command in
[stage 3](#3-cmake-build-stage).

**Example**

- ```bash
  cmake --build --preset conan-debug --target coverage
  ```
  runs tests in the `Debug` mode and generates a coverage report.

If this runs successfully, the coverage report will be generated in the
directory `build/<BuildType>/coverage_report/` in 4 formats:

- `summary.txt`: Plaintext summary
- `summary.md`: Markdown summary
- `cobertura.xml`: Cobertura XML
- `index.html`: HTML page


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

Below is a summary of `just` commands available in [`justfile`](justfile):

- ```bash
  just clean
  ```

  Removes the [`build`](build) directory and
  [`CMakeUserPresets.json`](CMakeUserPresets.json).

- ```bash
  just init [<build_type> [<compiler> [{cov | -} [{mod | -}]]]]
  ```

  Does [step 1](#1-conan-install-stage) and [step 2](#2-cmake-configure-stage)
  with a given build type (`debug`, `release`, `relwithdebinfo`, or
  `minsizerel`), a given compiler (default to `gcc`), and Ninja single-config
  as the generator.
  Note that `<build_type>` is in lowercase.

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

  Initializes all build types for the given compiler and coverage option.
  This simply calls `just init` 4 times, each for one build type.

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
  just build <build_type> [...args]
  ```

  Builds the code for the given build type. This simply calls

  ```bash
  cmake --build --preset conan-<build_type> ...args
  ```

- ```bash
  just test <build_type> [...args]
  ```

  Runs tests for the given build type.
  This is similar to

  ```bash
  ctest --preset conan-<build_type> ...args
  ```

  with additional options to output the test result in 2 formats:

  - `build/<BuildType>/test-report.xml`: JUnit XML
  - `build/<BuildType>/test-report.txt`: Plaintext
  
  where `BuildType` is the capitalized PascalCase version of the specified
  build type.

  Note that the code must have been built before running tests.

- ```bash
  just build-cov <build_type>
  ```

  Builds the code coverage report for the given build type.
  This will automatically build and run tests, and generate the coverage report
  in the directory `build/<BuildType>/coverage_report`, where `<BuildType>`
  is the capitalized PascalCase version of the specified build type.

  **Prerequisites:**
  - The build system must have been initialized with coverage information
    enabled.
  - Relevant programs must be installed. See
    [Generating code coverage reports](#generating-code-coverage-reports)
    for more information.

- ```bash
  just show-cov <build_type> [<port>]
  ```

  Shows the code coverage report for the given build type as a web page at
  `http://localhost:<port>`. The default port is 8070.
  
  This command requires `python3` to be available at the command line.
  The coverage report must have been generated before calling `just show-cov`.

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

These shortcuts support only `Debug` and `Release` build types.
If you want to use `MinSizeRel` or `RelWithDebInfo`, you will have to type the
full commands.

**One-line command**

`just` commands that don't have arguments can be combined in a single line.
For example,

- ```bash
  just clean is bc sc
  ```
  will clean the build directory, initialize the build system, build the
  code coverage report, and display it.

Note that a single line call with multiple `just` commands will not execute
the same command listed more than once, so
`just clean id bd td clean im bd td` will not work properly because
`just clean` will be executed only once.

#### Composite `just` commands

- ```bash
  just fresh-build [<build_type> [<compiler> [<coverage> [<modules>]]]]
  ```

  Cleans the [build](build) directory, initializes the build system with the
  given options (with `just init <build_type> <compiler> <coverage> <modules>`
  ), then builds the code (with `just build <build_type>`).

- ```bash
  just fresh-test [<build_type> [<compiler> [<coverage> [<modules>]]]]
  ```

  Does `just fresh-build`, followed by `just test <build_type>`.

- ```bash
  just fresh-cov [<build_type> [<compiler> [<modules>]]]
  ```

  Does `just fresh-build` with `coverage=cov`, followed by
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
  [`build/Debug/report.xml`](build/Debug/report.xml), and a coverage report (in
  [`build/Debug/coverage_report`](build/Debug/coverage_report).

### Docker

Some Dockerfiles for development are provided in the [ci](ci) subdirectory.
You can use the provided [`ci/compose.yaml`](ci/compose.yaml) to simplify
building docker images and running containers locally. Some `just` commands are
also provided for convenience.

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

  Show the doc as a webpage at `http://localhost:<port>`.
  The default `port` is 8060.

  This command requires `python3` to be available at the command line.
  The documentation must have been generated before calling `just show-doc`.

- ```bash
  just docx [<port>]
  ```

  Same as `just clean-doc && just doc && just show-doc <port>`.
  The default `port` is 8060.
