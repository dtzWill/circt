//===-- LLHD.h - C API for LLHD dialect -----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "circt-c/Dialect/LLHD.h"
#include "circt/Dialect/LLHD/IR/LLHDDialect.h"
#include "mlir/CAPI/IR.h"
#include "mlir/CAPI/Registration.h"
#include "mlir/CAPI/Support.h"

MLIR_DEFINE_CAPI_DIALECT_REGISTRATION(LLHD, llhd, circt::llhd::LLHDDialect)