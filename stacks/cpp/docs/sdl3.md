# SDL3 platform layer

Read this when working in `src/platform/` or adding anything that needs SDL. Game logic never includes an SDL header.

## Boundary

- Every SDL3 and ImGui-backend call lives in `src/platform/`. Game logic (ECS systems, simulation, UI state) talks to it through plain C++ types: an input snapshot, a frame/render interface, a clock.
- This keeps game logic unit-testable with Catch2 without a window or GPU, and keeps the relaxed lint config contained.
- No raw owning pointer crosses the boundary.

## Lint config

`src/platform/.clang-tidy` inherits the root config and disables three checks that fire on almost every SDL interop call:

| Check | Why it fires |
| --- | --- |
| `cppcoreguidelines-pro-type-reinterpret-cast` | `void*` pixel buffers and userdata |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | Surface rows (`pixels + pitch`) |
| `cppcoreguidelines-pro-type-vararg` | `SDL_SetError`, `SDL_snprintf` |

`cppcoreguidelines-owning-memory` stays on. SDL returns plain pointers, not `gsl::owner`, so it doesn't fire; ownership is handled by the handles below. Anything else that fires gets fixed, or gets a `NOLINT(<check>)` with the reason on that line.

## Ownership

SDL handles are owned by `std::unique_ptr` with custom deleters, defined once in `src/platform/sdl_handles.hpp`:

```cpp
struct WindowDeleter {
    void operator()(SDL_Window* window) const noexcept { SDL_DestroyWindow(window); }
};
using WindowHandle = std::unique_ptr<SDL_Window, WindowDeleter>;
// Same pattern: SDL_Renderer / SDL_DestroyRenderer, SDL_GPUDevice / SDL_DestroyGPUDevice, ...
```

`SDL_Init` / `SDL_Quit` pair in one RAII object created at the top of `main`.

## Errors and logging

- SDL3 reports failure with a `bool` (or a null pointer). Check every call and attach `SDL_GetError()` to the thrown or logged error.
- Log through spdlog, not `SDL_Log`. This also avoids most vararg calls.

## Dependencies

Fetch SDL3, ImGui, EnTT, spdlog and Catch2 with `FetchContent_Declare(... SYSTEM)` (CMake 3.25+), so their headers are treated as system headers and clang-tidy ignores them. Root `.clang-tidy` also excludes `_deps/`, and CI's `run-clang-tidy` only lints `src/` and `include/`.
