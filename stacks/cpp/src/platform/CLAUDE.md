# src/platform/

The only place SDL3 and ImGui backend calls are allowed. Read `docs/sdl3.md` before changing anything here.
`.clang-tidy` in this folder relaxes three checks for SDL interop; do not add more without a reason in that file.
