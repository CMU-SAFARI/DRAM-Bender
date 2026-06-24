#ifndef DRAMBENDER_API_HOST_INTERFACE_BYTE_STREAM_BUFFER_H
#define DRAMBENDER_API_HOST_INTERFACE_BYTE_STREAM_BUFFER_H

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <span>
#include <vector>

namespace DRAMBender::host_interface_internal {

class ByteStreamBuffer {
 public:
  void clear() {
    bytes_.clear();
    offset_ = 0;
  }

  size_t pending() const noexcept {
    return bytes_.size() - offset_;
  }

  void append(std::span<const std::byte> bytes) {
    if (bytes.empty()) {
      return;
    }
    compactIfUseful_();
    bytes_.insert(bytes_.end(), bytes.begin(), bytes.end());
  }

  size_t read(std::span<std::byte> dst) {
    const size_t count = std::min(dst.size(), pending());
    if (count == 0) {
      return 0;
    }

    std::memcpy(dst.data(), bytes_.data() + static_cast<std::ptrdiff_t>(offset_), count);
    offset_ += count;
    if (offset_ == bytes_.size()) {
      clear();
    }
    return count;
  }

 private:
  void compactIfUseful_() {
    if (offset_ == 0) {
      return;
    }
    if (offset_ == bytes_.size()) {
      clear();
      return;
    }
    if (offset_ < bytes_.size() / 2) {
      return;
    }

    bytes_.erase(bytes_.begin(), bytes_.begin() + static_cast<std::ptrdiff_t>(offset_));
    offset_ = 0;
  }

  std::vector<std::byte> bytes_;
  size_t offset_ = 0;
};

}  // namespace DRAMBender::host_interface_internal

#endif  // DRAMBENDER_API_HOST_INTERFACE_BYTE_STREAM_BUFFER_H
