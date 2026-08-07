#pragma once

#include <concepts>
#include <numeric>
#include <ranges>

namespace mathkit {

template <typename T>
concept arithmetic = std::integral<T> || std::floating_point<T>;

template <arithmetic T>
[[nodiscard]] constexpr T add(T lhs, T rhs) noexcept {
  return lhs + rhs;
}

template <std::ranges::input_range R>
  requires arithmetic<std::ranges::range_value_t<R>>
[[nodiscard]] constexpr std::ranges::range_value_t<R> sum(const R& values) {
  return std::accumulate(std::ranges::begin(values), std::ranges::end(values),
                         std::ranges::range_value_t<R>{});
}

}  // namespace mathkit
