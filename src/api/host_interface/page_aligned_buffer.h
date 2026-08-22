#ifndef DRAMBENDER_API_HOST_INTERFACE_PAGE_ALIGNED_BUFFER_H
#define DRAMBENDER_API_HOST_INTERFACE_PAGE_ALIGNED_BUFFER_H

#include <cstddef>
#include <cstdlib>
#include <limits>
#include <memory>
#include <new>
#include <utility>

namespace DRAMBender::host_interface_internal {

/**
 * @brief Growable page-aligned staging storage for DMA transfers.
 *
 * Growing the buffer discards its previous contents. Callers should reserve
 * the required capacity before populating it for a transfer.
 */
class PageAlignedBuffer {
 public:
  static constexpr std::size_t alignment = 4096;

  void ensure_capacity(std::size_t minimum_capacity) {
    if (minimum_capacity <= capacity_) {
      return;
    }

    if (minimum_capacity >
        std::numeric_limits<std::size_t>::max() - (alignment - 1)) {
      throw std::bad_alloc();
    }
    const std::size_t aligned_capacity =
        ((minimum_capacity + alignment - 1) / alignment) * alignment;

    void* raw_ptr = nullptr;
    if (::posix_memalign(&raw_ptr, alignment, aligned_capacity) != 0) {
      throw std::bad_alloc();
    }

    Buffer replacement(static_cast<std::byte*>(raw_ptr));
    buffer_ = std::move(replacement);
    capacity_ = aligned_capacity;
  }

  std::byte* data() noexcept { return buffer_.get(); }
  const std::byte* data() const noexcept { return buffer_.get(); }
  std::size_t capacity() const noexcept { return capacity_; }
  explicit operator bool() const noexcept { return buffer_ != nullptr; }

 private:
  struct FreeDeleter {
    void operator()(std::byte* ptr) const noexcept { std::free(ptr); }
  };

  using Buffer = std::unique_ptr<std::byte, FreeDeleter>;

  Buffer buffer_;
  std::size_t capacity_ = 0;
};

}  // namespace DRAMBender::host_interface_internal

#endif  // DRAMBENDER_API_HOST_INTERFACE_PAGE_ALIGNED_BUFFER_H
