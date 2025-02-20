//===-- Passes.td - Transforms pass definition file --------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains definitions for passes within the Transforms/ directory.
//
//===----------------------------------------------------------------------===//

#ifndef CIRCT_TRANSFORMS_PASSES
#define CIRCT_TRANSFORMS_PASSES

include "mlir/Pass/PassBase.td"
include "mlir/Rewrite/PassUtil.td"

def FlattenMemRef : Pass<"flatten-memref", "::mlir::ModuleOp"> {
  let summary = "Flatten memrefs";
  let description = [{
    Flattens multidimensional memories and accesses to them into
    single-dimensional memories.}];
  let constructor = "circt::createFlattenMemRefPass()";
  let dependentDialects = ["memref::MemRefDialect"];
}

def FlattenMemRefCalls : Pass<"flatten-memref-calls", "::mlir::ModuleOp"> {
  let summary = "Flatten memref calls";
  let description = [{
    Flattens calls to functions which have multidimensional memrefs as arguments.
    This is done by casting memref arguments through memref.subview operations.
    Any called functions which had their type signatures changes will be replaced
    by a private function definition with the new signature.
    It is up to users of this pass to define how these rewritten functions are
    to be implemented.}];
  let constructor = "circt::createFlattenMemRefCallsPass()";
  let dependentDialects = ["memref::MemRefDialect"];
}

#endif // CIRCT_TRANSFORMS_PASSES
