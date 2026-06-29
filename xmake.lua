set_project("tyghbn")
set_version("1.0.0")
set_xmakever("2.8.7")

add_moduledirs("scripts/xmake")

set_languages("cxx20")

option("use_modules")
    set_default(true)
    set_showmenu(true)
    set_description("Enable C++20 module support")

option("pic")
    set_default(true)
    set_showmenu(true)
    set_description("Enable Position Independent Code (-fPIC)")
option_end()

if has_config("pic") then
    add_cxflags("-fPIC")
end

-- Dependency declarations
-- =======================

-- We need to set `cmake = false` to avoid invoking CMake when it's actually
-- not needed. doctest can work without CMake.
add_requires("doctest", {configs = {cmake = false}})

-- Target delcarations
-- ===================

target("or_else")
    if has_config("use_modules") then
        set_kind("static")
        -- .cppm interface files must be made public.
        add_files("modules/or_else.cppm", { public = true })
    else
        set_kind("headeronly")
    end
    add_headerfiles("include/(tyghbn/or_else.hpp)")
    add_includedirs("include", { public = true })

target("add_one")
    set_kind("static")
    if has_config("use_modules") then
        -- .cppm interface files must be made public.
        add_files("modules/add_one.cppm", { public = true })
    end
    add_headerfiles("include/(tyghbn/add_one.hpp)")
    add_includedirs("include", { public = true })
    add_files("src/add_one.cpp")

target("tyghbn")
    if has_config("use_modules") then
        set_kind("static")
        -- .cppm interface files must be made public.
        add_files("modules/tyghbn.cppm", { public = true })
    else
        set_kind("headeronly")
    end
    add_deps("or_else", "add_one")
    add_headerfiles("include/(tyghbn/tyghbn.hpp)")
    add_includedirs("include", { public = true })

target("tests")
    set_kind("binary")
    add_packages("doctest")
    add_files(
        "tests/test_main.cpp",
        "tests/test_add_one.cpp",
        "tests/test_or_else.cpp"
    )
    add_deps("tyghbn")
    if has_config("use_modules") then
        add_defines("TYGHBN_USE_MODULES")
    end

    -- Uses the project root as the working directory
    set_rundir("$(projectdir)")

    add_tests("default", { realtime_output = true })

-- Task delcarations
-- =================


task("test-report")
    set_menu({
        usage = "xmake test-report",
        description =
            "Run tests and generate test reports\n" ..
            "- JUnit format: build/test-report.xml\n" ..
            "- Text summary: build/test-report.txt"
        ,
    })
    on_run(function ()
        import("core.project.config")
        config.load()

        os.exec("xmake -y")

        local output_dir = config.builddir()
        local junit_results_path = path.join(output_dir, "test-report.xml")
        os.rm(junit_results_path)
        local test_status = os.execv(
            "xmake",
            {
                "run",
                "tests",
                "--reporters=junit",
                "--out=" .. junit_results_path,
            },
            {
                try = true,
                stdout = os.nuldev(),
                stderr = os.nuldev(),
            }
        )

        import("doctest_helpers")
        local text_results_path = path.join(output_dir, "test-report.txt")
        local stats = doctest_helpers.convert_junit_to_text(
            junit_results_path,
            text_results_path
        )

        io.write(io.readfile(text_results_path) .. "\n")

        if stats.num_failures ~= 0 then
            raise(stats.num_failures .. " test cases failed")
        end
    end)

task("coverage-report")
    set_menu({
        usage = "xmake coverage-report",
        description = "Run tests and generate an HTML coverage report"
    })
    on_run(function ()
        import("lib.detect.find_tool")
        if not find_tool("gcovr") then
            raise("Error: 'gcovr' not found. Please install it first.")
        end

        import("core.project.config")
        config.load()
        if config.get("mode") ~= "coverage" then
            raise("Error: This task requires coverage mode." ..
                " Please run:\n" ..
                "    xmake f -m coverage\n" ..
                "    xmake coverage-report")
        end

        os.exec("xmake test")

        local output_dir = path.join(config.builddir(), "coverage_report")
        local output_file = path.join(output_dir, "index.html")
        os.rm(output_dir)
        os.mkdir(output_dir)

        local gcov_executable = "gcov"
        local toolchain = config.get("toolchain") or ""
        if toolchain:find("clang") then
            gcov_executable = "llvm-cov gcov"
        end
        print("Using gcov executable: %s", gcov_executable)

        print("Generating coverage report at: %s", output_file)
        os.execv("gcovr", {
            "-r", ".",
            "--exclude", "tests/",
            "--gcov-executable", gcov_executable,
            "--txt", path.join(output_dir, "report.txt"),
            "--html-details", path.join(output_dir, "index.html"),
            "--cobertura", path.join(output_dir, "cobertura.xml"),
            "--markdown", path.join(output_dir, "summary.md"),
            "--txt-summary"
        }, {
            stdout = path.join(output_dir, "summary.txt")
        })
        print("Coverage report generated. Open %s to view.", output_file)
    end)

task("clean-all")
    set_menu({
        usage = "xmake clean-all",
        description = "Clean all build artifacts and configuration"
    })
    on_run(function()
        os.exec("rm -rf build .xmake")
    end)

task("reports")
    set_menu({
        usage = "xmake reports",
        description = "Run tests and generate test and coverage reports"
    })
    on_run(function()
        -- Configure with coverage mode
        os.execv("xmake", {
            "config",
            "--mode=coverage",
            "--policies=build.sanitizer.address,build.sanitizer.undefined",
            "--cxflags=-fno-sanitize-recover=all",
            "--use_modules=n",
            "-y",
        })
        -- Note: We set use_modules=n here as a workaround for a bug in Xmake
        -- as build.sanitizer.undefined does not work with GCC 15 when
        -- use_modules=y, but this same configuration works fine with CMake.
        -- If you use a newer version of GCC or a newer version Xmake, you
        -- should try to change use_modules=y and see if it works or not.

        try
        {
            function()
                os.exec("xmake test-report")
                os.exec("xmake coverage-report")
            end,
            catch
            {
                function()
                    raise("coverage report not generated")
                end,
            },
        }
    end)

task("check-builds")
    set_menu({
        usage = "xmake check-builds",
        description = "Build in coverage mode with compiler and module configurations"
    })
    on_run(function()
        local configurations = {
            { toolchain = "gcc", use_modules = "y" },
            { toolchain = "gcc", use_modules = "n" },
            { toolchain = "clang", use_modules = "y" },
            { toolchain = "clang", use_modules = "n" },
        }

        for _, configuration in ipairs(configurations) do
            os.exec("xmake clean -y")

            local label = string.format(
                "toolchain=%s, use_modules=%s",
                configuration.toolchain,
                configuration.use_modules
            )

            print("Checking build: %s", label)

            -- Note: We disable build.sanitizer.undefined as a workaround as
            -- it does not work with GCC 15 when use_modules=y. However, this
            -- same configuration works fine with CMake, so this is likely a
            -- bug in Xmake. If you use a newer version of GCC or a newer
            -- version Xmake, you should try to enable
            -- build.sanitizer.undefined for all configurations.
            local policies = "build.sanitizer.address"
            if configuration.use_modules ~= "y" or
                configuration.toolchain ~= "gcc" then
                policies = policies .. ",build.sanitizer.undefined"
            end

            os.execv("xmake", {
                "config",
                "--mode=coverage",
                "--toolchain=" .. configuration.toolchain,
                "--use_modules=" .. configuration.use_modules,
                "--policies=" .. policies,
                "--cxflags=-fno-sanitize-recover=all",
                "-y",
            })

            os.exec("xmake")
            os.exec("xmake coverage-report")

            print("Build passed: %s", label)
        end
    end)

