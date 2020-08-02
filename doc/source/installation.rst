Installation
------------

The easiest way to install this *Godot CMake* is to use the :literal:`FetchContent` CMake module:

.. code-block:: cmake

   include("FetchContent")

   FetchContent_Declare(
     "Godot"
     GIT_REPOSITORY https://github.com/fmorgner/godot-cmake.git
   )

   FetchContent_MakeAvailable("Godot")

   list(APPEND CMAKE_MODULE_PATH "${PROJECT_BINARY_DIR}/_deps/Godot/Modules")

   include("Godot")