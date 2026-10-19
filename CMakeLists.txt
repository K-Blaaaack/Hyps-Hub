cmake_minimum_required(VERSION 3.21)

project(HypsHub
    VERSION 0.1.7
    DESCRIPTION "Hyps Hub - a native Linux desktop client for the Hyps CLI"
    HOMEPAGE_URL "https://github.com/K-Blaaaack/Hyps-Hub"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(GNUInstallDirs)
include(CTest)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Qt 6 的 Q_OBJECT/moc 头在 GCC 16 触发该警告，不是项目代码问题。
    add_compile_options(-Wno-sfinae-incomplete)
endif()

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Quick Qml QuickControls2 Svg DBus Widgets)

qt_standard_project_setup()

# ---------------------------------------------------------------------------
# 版本信息
# ---------------------------------------------------------------------------
set(HYPS_HUB_GIT_COMMIT "unknown")
if(DEFINED ENV{HYPS_HUB_GIT_COMMIT}
   AND NOT "$ENV{HYPS_HUB_GIT_COMMIT}" STREQUAL "")
    # Release 从 git archive 的源码 tar 构建，没有 .git；工作流传入 GITHUB_SHA。
    set(HYPS_HUB_GIT_COMMIT "$ENV{HYPS_HUB_GIT_COMMIT}")
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
    find_package(Git QUIET)
    if(GIT_FOUND)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" rev-parse --short=12 HEAD
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            OUTPUT_VARIABLE HYPS_HUB_GIT_COMMIT
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
    endif()
endif()
if(NOT HYPS_HUB_GIT_COMMIT)
    set(HYPS_HUB_GIT_COMMIT "unknown")
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/version.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/version.h"
    @ONLY
)

# ---------------------------------------------------------------------------
# 应用
# ---------------------------------------------------------------------------
set(HYPS_HUB_CORE_SOURCES
    src/app/apppaths.cpp
    src/app/appsettings.cpp
    src/app/thememanager.cpp
    src/app/logmodel.cpp
    src/app/task.cpp
    src/app/taskmanager.cpp
    src/app/notifier.cpp
    src/app/appcontroller.cpp
    src/app/directorymodel.cpp

    src/adapter/processrunner.cpp
    src/adapter/environmentreport.cpp
    src/adapter/configfile.cpp
    src/adapter/configmanager.cpp
    src/adapter/gamecatalog.cpp
    src/adapter/hypsadapter.cpp

    src/runtime/runtimemanager.cpp
    src/diagnostics/diagnostics.cpp
)

set(HYPS_HUB_CORE_HEADERS
    src/app/apppaths.h
    src/app/appsettings.h
    src/app/thememanager.h
    src/app/logmodel.h
    src/app/task.h
    src/app/taskmanager.h
    src/app/notifier.h
    src/app/appcontroller.h
    src/app/directorymodel.h

    src/adapter/processrunner.h
    src/adapter/environmentreport.h
    src/adapter/configfile.h
    src/adapter/configmanager.h
    src/adapter/gamecatalog.h
    src/adapter/hypsadapter.h

    src/runtime/runtimemanager.h
    src/diagnostics/diagnostics.h
)

qt_add_library(hyps-hub-core STATIC
    ${HYPS_HUB_CORE_SOURCES}
    ${HYPS_HUB_CORE_HEADERS}
)

target_include_directories(hyps-hub-core PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)

target_compile_definitions(hyps-hub-core PUBLIC
    QT_NO_CAST_FROM_ASCII
    QT_NO_CAST_TO_ASCII
    QT_USE_QSTRINGBUILDER
)

target_link_libraries(hyps-hub-core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::QuickControls2
    Qt6::Svg
    Qt6::DBus
)

qt_add_executable(hyps-hub src/main.cpp)
target_link_libraries(hyps-hub PRIVATE hyps-hub-core Qt6::Widgets)

# ---------------------------------------------------------------------------
# QML 与资源
# ---------------------------------------------------------------------------
set(HYPS_HUB_QML
    qml/Main.qml

    qml/components/MicroLabel.qml
    qml/components/ChamferedPanel.qml
    qml/components/StripeRuler.qml
    qml/components/ArkButton.qml
    qml/components/ArkTag.qml
    qml/components/ArkProgress.qml
    qml/components/GridBackdrop.qml
    qml/components/PageHeader.qml
    qml/components/SectionHeader.qml
    qml/components/ToggleSwitch.qml
    qml/components/ToggleRow.qml
    qml/components/ConfigField.qml
    qml/components/CodeEditor.qml
    qml/components/RawEditorDialog.qml
    qml/components/PathField.qml
    qml/components/FilePicker.qml
    qml/components/LogView.qml
    qml/components/EmptyState.qml
    qml/components/ConfirmDialog.qml
    qml/components/TaskItem.qml
    qml/components/InfoRow.qml
    qml/components/ValidationList.qml
    qml/components/StatCard.qml
    qml/components/NavIcon.qml
    qml/components/NavRail.qml
    qml/components/TopBar.qml

    qml/pages/OnboardingPage.qml
    qml/pages/HomePage.qml
    qml/pages/GamesPage.qml
    qml/pages/TasksPage.qml
    qml/pages/ConfigPage.qml
    qml/pages/DiagnosticsPage.qml
    qml/pages/SettingsPage.qml
    qml/pages/AboutPage.qml
)

qt_add_resources(hyps-hub "hyps-hub-qml"
    PREFIX "/"
    FILES
        ${HYPS_HUB_QML}
)

qt_add_resources(hyps-hub "hyps-hub-assets"
    PREFIX "/"
    FILES
        assets/hyps-hub.svg
        assets/noise.png
        assets/stripe.png
)

# ---------------------------------------------------------------------------
# 安装
# ---------------------------------------------------------------------------
install(TARGETS hyps-hub RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

install(FILES packaging/hyps-hub.desktop
    DESTINATION "${CMAKE_INSTALL_DATADIR}/applications"
)

install(FILES assets/hyps-hub.svg
    DESTINATION "${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps"
)

install(FILES
    README.md
    LICENSE.md
    docs/install.md
    docs/troubleshooting.md
    docs/development.md
    docs/architecture.md
    docs/research.md
    docs/verification.md
    docs/credits.md
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/hyps-hub"
)

install(FILES docs/design/README.md
    DESTINATION "${CMAKE_INSTALL_DATADIR}/doc/hyps-hub"
    RENAME design.md
)

install(FILES licenses/GPL-3.0-only.txt
    DESTINATION "${CMAKE_INSTALL_DATADIR}/licenses/hyps-hub"
)

# ---------------------------------------------------------------------------
# 测试
# ---------------------------------------------------------------------------
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
