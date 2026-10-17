find_package(Qt6 REQUIRED COMPONENTS Test)

function(hyps_add_test name)
    qt_add_executable(${name} ${name}.cpp)
    target_link_libraries(${name} PRIVATE hyps-hub-core Qt6::Test)
    target_compile_definitions(${name} PRIVATE
        HYPS_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}"
        HYPS_HUB_TEST_BINARY="${CMAKE_BINARY_DIR}"
    )
    add_test(NAME ${name} COMMAND ${name})
    set_tests_properties(${name} PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;GSETTINGS_BACKEND=memory;TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/tmp"
    TIMEOUT 120
    )
endfunction()

hyps_add_test(tst_apppaths)
hyps_add_test(tst_configfile)
hyps_add_test(tst_environmentreport)
hyps_add_test(tst_processrunner)
hyps_add_test(tst_gamecatalog)
hyps_add_test(tst_runtimemanager)
hyps_add_test(tst_hypsadapter)
hyps_add_test(tst_diagnostics)

# 需要网络的真实克隆/CLI 调用：默认跳过，设置 HYPS_HUB_RUN_NETWORK_TESTS=1 后运行
hyps_add_test(tst_network_e2e)
set_tests_properties(tst_network_e2e PROPERTIES DISABLED TRUE)

# QML 启动冒烟测试（真实进程）
add_test(NAME tst_smoke
    COMMAND $<TARGET_FILE:hyps-hub> --smoke-test
)
set_tests_properties(tst_smoke PROPERTIES
    ENVIRONMENT "TMPDIR=${CMAKE_CURRENT_BINARY_DIR}/tmp;QT_QPA_PLATFORM=offscreen;QT_QUICK_BACKEND=software;GSETTINGS_BACKEND=memory;HYPS_HUB_DATA_DIR=${CMAKE_CURRENT_BINARY_DIR}/smoke-data;HYPS_HUB_CONFIG_DIR=${CMAKE_CURRENT_BINARY_DIR}/smoke-config;HYPS_HUB_STATE_DIR=${CMAKE_CURRENT_BINARY_DIR}/smoke-state"
    TIMEOUT 30
)

file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/fixtures" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/tmp")
