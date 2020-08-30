include("FindPackageHandleStandardArgs")

find_program(GODOT_ENGINE_EXECUTABLE
  NAMES "godot" "org.godotengine.Godot"
  DOC "Path to the godot engine executable"
)

if(NOT GODOT_ENGINE_EXECUTABLE)
  return()
endif()

execute_process(COMMAND "${GODOT_ENGINE_EXECUTABLE}"
  "--version"
  OUTPUT_VARIABLE GODOT_ENGINE_VERSION
)

string(REGEX REPLACE "\.stable\.flathub" "" GODOT_ENGINE_VERSION "${GODOT_ENGINE_VERSION}")

find_package_handle_standard_args("GodotEngine"
  REQUIRED_VARS GODOT_ENGINE_EXECUTABLE
  VERSION_VAR GODOT_ENGINE_VERSION
)