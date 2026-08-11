#pragma once

#include <functional>
#include <memory>

#include "filesystem_def.h"

namespace Framework
{
class CStream;

using StreamFactory = std::function<std::unique_ptr<CStream>(const fs::path&)>;
}
