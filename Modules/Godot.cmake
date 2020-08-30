# Distributed under the OSI-approved BSD 3-Clause License.

#[==========================================================================[.rst:
Godot
-----

This module provides properties target properties and functions used to
build and integrate godot-cpp based *script* libraries within a Godot Egine
project.

Functions
^^^^^^^^^

.. command:: godot_register_library

   Register an existing library target as a godot-cpp module.

   .. code-block:: cmake

      godot_register_library(<TARGET>)

   This function registeres the given target as being a godot-cpp module.
   It generates the required :literal:`.gdnlib` library descriptor and
   registers it for installation into the path specified by the
   :prop_tgt:`GODOT_BINARY_INSTALL_DIR` property on the given target. It
   also registers the shared library target as for installation into the
   OS-appropriate subdirectory of :prop_tgt:`GODOT_BINARY_INSTALL_DIR`.

   The given target must be a shared library target.

.. command:: godot_register_class

   Register a class in an existing target to be exported for use in Godot

   .. code-block:: cmake

      godot_register_class(<TARGET>
        <CLASS>
      )

   This function registeres the given class within the given target as
   a Godot Native 1.1 script. It generates the required :literal:`.gdns`
   script and registers it for installation into the path specified by the
   :prop_tgt:`GODOT_BINARY_INSTALL_DIR` property on the given target.

   The given target must habe previously been registered as a godot-cpp
   module using :command:`godot_register_library`.

Target Properties
^^^^^^^^^^^^^^^^^

.. toctree::
   :maxdepth: 1

   ../prop_tgt/GODOT_BINARY_INSTALL_DIR

#]==========================================================================]

find_package("GodotEngine")

define_property(TARGET PROPERTY "GODOT_BINARY_INSTALL_DIR"
  BRIEF_DOCS "The binary installation directory of the Godot project"
  FULL_DOCS "This property defines the directory in which the target will be installed in order for Godot to find it."
)

function(godot_register_library TARGET)
  _godot_target_assert_shared_library("${TARGET}")
  _godot_target_check_registered("${TARGET}" NO)
  _godot_target_ensure_absolute_install("${TARGET}")
  _godot_target_check_install_dir(INSTALL_DIR "${TARGET}")
  _godot_target_get_library_install_dir(LIBRARY_INSTALL_DIR "${TARGET}")
  _godot_generate_resource_id(RESOURCE_ID)

  file(MAKE_DIRECTORY "${LIBRARY_INSTALL_DIR}")

  set_target_properties("${TARGET}" PROPERTIES
    _GODOT_REGISTERED YES
    _GODOT_RESOURCE_ID ${RESOURCE_ID}
  )

  message(STATUS "Godot: Registering library ${TARGET}")

  set(LIBRARY_DESCRIPTOR_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}.gdnlib")
  set(LIBRARY_DESCRIPTOR "")

  ### [general] Section
  string(APPEND LIBRARY_DESCRIPTOR "[general]\n\n")
  string(APPEND LIBRARY_DESCRIPTOR "singleton=false\n")
  string(APPEND LIBRARY_DESCRIPTOR "load_once=true\n")
  string(APPEND LIBRARY_DESCRIPTOR "symbol_prefix=\"godot_\"\n")
  string(APPEND LIBRARY_DESCRIPTOR "reloadable=true\n")
  string(APPEND LIBRARY_DESCRIPTOR "\n")

  ### [entry] Sections
  string(APPEND LIBRARY_DESCRIPTOR "[entry]\n\n")
  string(APPEND LIBRARY_DESCRIPTOR "X11.64=\"res://bin/linux/lib${TARGET}.so\"\n")
  string(APPEND LIBRARY_DESCRIPTOR "Windows.64=\"res://bin/windows/${TARGET}.dll\"\n")
  string(APPEND LIBRARY_DESCRIPTOR "OSX.64=\"res://bin/macos/lib${TARGET}.dylib\"\n")
  string(APPEND LIBRARY_DESCRIPTOR "\n")

  ### [dependencies] Sections
  string(APPEND LIBRARY_DESCRIPTOR "[dependencies]\n\n")
  string(APPEND LIBRARY_DESCRIPTOR "X11.64=[ ]\n")
  string(APPEND LIBRARY_DESCRIPTOR "Windows.64=[ ]\n")
  string(APPEND LIBRARY_DESCRIPTOR "OSX.64=[ ]\n")

  file(WRITE "${LIBRARY_DESCRIPTOR_FILE}" ${LIBRARY_DESCRIPTOR})
  add_custom_command(TARGET "${TARGET}"
    COMMAND "${CMAKE_COMMAND}"
    ARGS "-E" "copy_if_different" "${LIBRARY_DESCRIPTOR_FILE}" "${INSTALL_DIR}"
    COMMAND "${CMAKE_COMMAND}"
    ARGS "-E" "copy_if_different" $<TARGET_FILE:${TARGET}> "${LIBRARY_INSTALL_DIR}"
    COMMENT "Installing library and library descriptor for ${TARGET}"
  )
endfunction()

function(godot_register_class TARGET CLASS)
  _godot_target_check_registered("${TARGET}" YES)
  _godot_target_check_install_dir(INSTALL_DIR "${TARGET}")
  _godot_target_get_resource_id(RESOURCE_ID "${TARGET}")
  _godot_target_get_registered_classed(REGISTERED_CLASSES "${TARGET}")

  if(${CLASS} IN_LIST "${GODOT_CLASSES}")
    message(FATAL_ERROR "Class ${TARGET}::${CLASS} has already been registered")
  endif()

  message(STATUS "Godot: Registering class ${TARGET}::${CLASS}")

  set(CLASS_DESCRIPTOR_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_${CLASS}.gdns")
  set(CLASS_DESCRIPTOR "")

  ### [gdresource] Section
  string(APPEND CLASS_DESCRIPTOR "[gd_resource type=\"NativeScript\" load_steps=2 format=2]\n")
  string(APPEND CLASS_DESCRIPTOR "\n")

  ### [ext_resource] Section
  string(APPEND CLASS_DESCRIPTOR "[ext_resource path=\"res://bin/${TARGET}.gdnlib\" type=\"GDNativeLibrary\" id=${RESOURCE_ID}]\n")
  string(APPEND CLASS_DESCRIPTOR "\n")

  ### [resource] Section
  string(APPEND CLASS_DESCRIPTOR "[resource]\n\n")
  string(APPEND CLASS_DESCRIPTOR "resource_name = \"${TARGET}\"\n")
  string(APPEND CLASS_DESCRIPTOR "class_name = \"${CLASS}\"\n")
  string(APPEND CLASS_DESCRIPTOR "library = ExtResource( ${RESOURCE_ID} )\n")
  string(APPEND CLASS_DESCRIPTOR "\n")

  file(WRITE "${CLASS_DESCRIPTOR_FILE}" ${CLASS_DESCRIPTOR})
  add_custom_command(TARGET "${TARGET}"
    COMMAND "${CMAKE_COMMAND}"
    ARGS "-E" "copy_if_different" "${CLASS_DESCRIPTOR_FILE}" "${INSTALL_DIR}"
    COMMENT "Installing class descriptor for ${TARGET}::${CLASS}"
  )
endfunction()

function(_godot_target_check_install_dir VAR TARGET)
  get_target_property(BINARY_INSTALL_DIR "${TARGET}" GODOT_BINARY_INSTALL_DIR)

  if(NOT BINARY_INSTALL_DIR)
    message(FATAL_ERROR "Target property GODOT_BINARY_INSTALL_DIR not set for target ${TARGET}")
  endif()

  set(${VAR} ${BINARY_INSTALL_DIR} PARENT_SCOPE)
endfunction()

function(_godot_target_ensure_absolute_install TARGET)
  _godot_target_check_install_dir(INSTALL_DIR "${TARGET}")

  if(NOT IS_ABSOLUTE "${INSTALL_DIR}")
    set(INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${INSTALL_DIR}")
    set_target_properties("${TARGET}" PROPERTIES
      GODOT_BINARY_INSTALL_DIR "${INSTALL_DIR}"
    )
  endif()
endfunction()

function(_godot_target_check_registered TARGET EXPECTED_VALUE)
  get_target_property(REGISTERED "${TARGET}" _GODOT_REGISTERED)

  if(REGISTERED STREQUAL "REGISTERED-NOTFOUND")
    set(REGISTERED NO)
  endif()

  if(REGISTERED AND NOT EXPECTED_VALUE)
    message(FATAL_ERROR "Target ${TARGET} is already registered as a Godot module")
  elseif(EXPECTED_VALUE AND NOT REGISTERED)
    message(FATAL_ERROR "Target ${TARGET} is not registered as a Godot module")
  endif()
endfunction()

function(_godot_generate_resource_id VAR)
  if(NOT DEFINED _GODOT_RESOURCE_ID)
    set(_GODOT_RESOURCE_ID "100000" CACHE INTERNAL "The global Godot resource id counter")
  endif()
  set(${VAR} ${_GODOT_RESOURCE_ID} PARENT_SCOPE)
  math(EXPR _GODOT_RESOURCE_ID "${_GODOT_RESOURCE_ID} + 1")
endfunction()

function(_godot_target_get_resource_id VAR TARGET)
  get_target_property(RESOURCE_ID "${TARGET}" _GODOT_RESOURCE_ID)

  if(NOT RESOURCE_ID)
    message(FATAL_ERROR "Target ${TARGET} is not registered as a Godot module")
  endif()

  set(${VAR} ${RESOURCE_ID} PARENT_SCOPE)
endfunction()

function(_godot_target_get_registered_classed VAR TARGET)
  get_target_property(GODOT_CLASSES "${TARGET}" _GODOT_CLASSES)

  if(NOT GODOT_CLASSES)
    set(GODOT_CLASSES "")
  endif()

  set(${VAR} ${GODOT_CLASSES} PARENT_SCOPE)
endfunction()

function(_godot_target_get_library_install_dir VAR TARGET)
  _godot_target_check_install_dir(INSTALL_DIR "${TARGET}")

  if(WIN32 OR MINGW)
    set(INSTALL_DIR "${INSTALL_DIR}/windows")
  elseif(UNIX)
    set(INSTALL_DIR "${INSTALL_DIR}/linux")
  elseif(APPLE)
    set(INSTALL_DIR "${INSTALL_DIR}/macos")
  else()
    message(FATAL_ERROR "Could not determine target platform")
  endif()

  set(${VAR} ${INSTALL_DIR} PARENT_SCOPE)
endfunction()

function(_godot_target_assert_shared_library TARGET)
  get_target_property(TYPE "${TARGET}" TYPE)
  if(NOT TYPE STREQUAL "SHARED_LIBRARY")
    message(FATAL_ERROR "Target ${TARGET} is not a shared library target")
  endif()
endfunction()
