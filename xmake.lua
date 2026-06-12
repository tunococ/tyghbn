set_project("tyghbn")
set_version("1.0.0")
set_xmakever("2.9.0")

-- C++20 standard
set_languages("cxx20")

-- ============================================================================
-- Package dependencies (must be at root scope, before option())
-- ============================================================================

add_requires("doctest", {system = false})

-- ============================================================================
-- Include directories (shared by all targets)
-- ============================================================================

add_includedirs("include", {public = true})

-- ============================================================================
-- Options
-- ============================================================================

option("use_modules")
    set_default(true)
    set_showmenu(true)
    set_description("Enable C++20 module support")

-- ============================================================================
-- Resolve context flags once
-- ============================================================================

local use_modules = has_config("use_modules")

-- ============================================================================
-- Library: or_else (header-only, or static with module support)
-- ============================================================================

target("or_else")
    if use_modules then
        set_kind("static")
        add_files("modules/or_else.cppm")
    else
        set_kind("headeronly")
    end
    set_targetdir("$(builddir)/$(mode)/lib")
    add_headerfiles("include/tyghbn/or_else.hpp")

-- ============================================================================
-- Library: add_one (always has compiled sources)
-- ============================================================================

target("add_one")
    set_kind("static")
    set_targetdir("$(builddir)/$(mode)/lib")
    add_headerfiles("include/tyghbn/add_one.hpp")
    add_files("src/add_one.cpp")
    if use_modules then
        add_files("modules/add_one.cppm")
    end

-- ============================================================================
-- Umbrella library: tyghbn
-- ============================================================================

target("tyghbn")
    if use_modules then
        set_kind("static")
        add_files("modules/tyghbn.cppm")
        add_extrafiles("modules/add_one.cppm")
        add_extrafiles("modules/or_else.cppm")
        add_deps("or_else", "add_one")
    else
        set_kind("headeronly")
        add_deps("or_else", "add_one")
    end
    set_targetdir("$(builddir)/$(mode)/lib")
    add_headerfiles("include/tyghbn/tyghbn.hpp")

-- ============================================================================
-- Tests
-- ============================================================================

target("test_tyghbn")
    set_kind("binary")
    set_targetdir("$(builddir)/$(mode)/bin")
    add_packages("doctest")
    add_files("tests/test_main.cpp", "tests/test_add_one.cpp", "tests/test_or_else.cpp")
    add_deps("tyghbn")
    if use_modules then
        add_defines("TYGHBN_USE_MODULES")
    end

-- ============================================================================
-- Custom targets / aliases
-- ============================================================================

task("run_tests")
    on_run(function ()
        import("core.project.project")
        os.exec("$(builddir)/$(mode)/bin/test_tyghbn")
    end)
    set_menu {usage = "xmake run_tests", description = "Run all tests"}