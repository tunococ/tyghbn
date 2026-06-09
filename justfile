# Remove build artifacts
clean:
    rm -rf build

# Detect Conan profile
detect:
    conan profile detect --force

# Initialize single-config build for a given build type
init build_type compiler='gcc' coverage='cov' modules='mod':
    conan install . --build=missing -pr .pr/{{ compiler }}-{{ build_type }} \
        -o '&:use_modules={{ if modules =~ 'mod' { 'True' } else { 'False' } }}'
    cmake --preset conan-{{ build_type }} \
        -DTYGHBN_ENABLE_COVERAGE={{ if coverage =~ 'cov' { 'ON' } else { 'OFF' } }}

# Initialize single-config build for both build types
init-single compiler='gcc' coverage='cov' modules='mod':
    just init debug {{ compiler }} {{ coverage }} {{ modules }}
    just init release {{ compiler }} {{ coverage }} {{ modules }}

# Initialize multi-config build
init-multi compiler='gcc' coverage='cov' modules='mod':
    conan install . --build=missing -pr .pr/{{ compiler }}-multi-debug \
        -o '&:use_modules={{ if modules =~ 'mod' { 'True' } else { 'False' } }}'
    conan install . --build=missing -pr .pr/{{ compiler }}-multi-release \
        -o '&:use_modules={{ if modules =~ 'mod' { 'True' } else { 'False' } }}'
    cmake --preset conan-default \
        -DTYGHBN_ENABLE_COVERAGE={{ if coverage =~ 'cov' { 'ON' } else { 'OFF' } }}

# Run `init debug`
id: (init 'debug')

# Run `init release`
ir: (init 'release')

# Run `init debug` and `init release`
is: id ir

# Run `init-multi`
im: init-multi

# Run `init debug`, but with use_modules=False
ihd: (init 'debug' 'gcc' 'cov' '-')

# Run `init release`, but with use_modules=False
ihr: (init 'release' 'gcc' 'cov' '-')

# Run `init debug` and `init release`, but with use_modules=False
ihs: ihd ihr

# Run `init-multi`, but with use_modules=False
ihm: (init-multi 'gcc' 'cov' '-')

# Build code
build build_type *args:
    cmake --build --preset conan-{{ build_type }} {{ args }}

bd: (build 'debug')

br: (build 'release')

ba: bd br

alias b := bd

# Run tests
test build_type *args:
    ctest --preset conan-{{ build_type }} \
        --output-junit test-report.xml \
        -O build/{{ \
            if lowercase(build_type) =~ 'rel' { 'Release' } else { 'Debug' } \
        }}/test-report.txt \
        --output-on-failure \
        {{ args }}

td: (test 'debug')

tr: (test 'release')

ta: td tr

# Run tests and generate a coverage report
build-cov build_type *args:
    just build {{ build_type }} --target coverage {{ args }}
    cat build/{{ \
            if lowercase(build_type) =~ 'rel' { 'Release' } else { 'Debug' } \
        }}/coverage_report/summary.txt

bcd: (build-cov 'debug')

bcr: (build-cov 'release')

bca: bcd bcr

# Show the coverage report in a web browser
show-cov build_type port='8070':
    python3 -m http.server --directory \
        build/{{ \
            if lowercase(build_type) =~ 'rel' { 'Release' } else { 'Debug' } \
        }}/coverage_report {{ port }}

scd: (show-cov 'debug')

scr: (show-cov 'release')


# Docker-related commands
# =======================

# Create an ephemeral container and run an interactive shell inside it.
run-docker variant='alpine' stage='full' *args='':
    VARIANT={{ variant }} docker compose -f ci/compose.yaml \
        run --rm -it {{ stage }} {{ args }}

# Create a new docker container.
create-docker variant='alpine' stage='full' name=(variant + '-' + stage) \
    *args='tail -f /dev/null':
    docker rm -f {{ name }} 2>/dev/null || true
    VARIANT={{ variant }} docker compose -f ci/compose.yaml \
        run -d --name {{ name }} {{ stage }} {{ args }}

# Remove Docker images matching a given prefix.
clean-docker-images prefix='tyghbn-':
    docker rmi $(docker images --format '{{{{.Repository}}:{{{{.Tag}}' | \
        grep '^{{ prefix }}') 2>/dev/null || true


# Composite commands for testing different configurations
# =======================================================

# Clean --> Build
clean-build build_type='debug' compiler='gcc' coverage='cov' modules='mod':
    just clean
    just init {{ build_type }} {{ compiler }} {{ coverage }} {{ modules }}
    just build {{ build_type }}

# Clean --> Test
clean-test build_type='debug' compiler='gcc' coverage='cov' modules='mod':
    just clean-build {{ build_type }} {{ compiler }} {{ coverage }} \
        {{ modules }}
    just test {{ build_type }}

# Clean --> Coverage report
clean-cov build_type='debug' compiler='gcc' modules='mod':
    just clean-build {{ build_type }} {{ compiler }} cov {{ modules }}
    just build-cov {{ build_type }}

# Try building code for different configurations.
check-builds:
    just clean-build debug gcc cov mod
    just clean-build debug gcc cov -
    just clean-build debug clang cov mod
    just clean-build debug clang cov -

# Make a test report and a coverage report in debug.
make-reports compiler='gcc' modules='mod':
    just clean
    just init debug {{ compiler }} cov {{ modules }}
    just bd td bcd


# Documentation
# =============

# Generate documentation with Doxygen
doc:
    mkdir -p build/doc
    doxygen Doxyfile

# Remove generated documentation
clean-doc:
    rm -rf build/doc

# Show documentation in a web browser
show-doc port='8060':
    python3 -m http.server --directory build/doc {{ port }}

# Clean the documentation directory, rebuild it, and display it.
docx port='8060':
    just clean-doc
    just doc
    just show-doc {{ port }}


