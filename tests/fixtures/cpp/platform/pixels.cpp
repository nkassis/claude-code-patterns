#include <cstddef>
#include <cstdint>

// Typical SDL interop: write into a surface's void* pixel buffer.
void clearRow(void* pixels, int pitch, int row) {
    std::uint8_t* bytes =
        reinterpret_cast<std::uint8_t*>(pixels) + (static_cast<std::ptrdiff_t>(pitch) * row);
    bytes[0] = 0;
}
