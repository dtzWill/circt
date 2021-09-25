# Comb Dialect Rationale

This document describes various design points of the Comb dialect, a common
dialect that is typically used in conjunction with the HW and SV dialects.
Please see the [RationaleHW.md](HW Dialect Rationale) for high level insight
on how these work together.  This follows in the spirit of
other [MLIR Rationale docs](https://mlir.llvm.org/docs/Rationale/).

- [Comb Dialect Rationale](#comb-dialect-rationale)
  - [Introduction](#introduction)
  - [Comb Operations](#comb-operations)
  - [Endianness: operand ordering and internal representation](#endianness-operand-ordering-and-internal-representation)
  - [Bitcasts](#bitcasts)
  - [Cost Model](#cost-model)

## Introduction

The Comb dialect contains a collection of operations reflecting a mid-level
compiler IR for combinational logic.   It is *not* designed to model
SystemVerilog or any other hardware design language directly.  Instead, it is
designed to be easy to analyze and transform, and be a flexible and extensible
substrate that may be extended with higher level dialects mixed into it.

## Comb Operations

TODO: Why is add variadic?  Why consistent operand types instead of allowing
implicit extensions?

**No "Replication", "ZExt", or "Complement" Operators**

We choose to omit several operators that you might expect, in order to make the
IR more regular, easy to transform, and have fewer canonical forms.

 * No `~x` complement operator: instead use `comb.xor(x, -1)`.

 * No `{42{x}}` Replication operator (System Verilog 11.4.12.1) to replicate an
   operand a constant N times.  We decided that this was redundant and just
   sugar for the `comb.concat` operator, so we just use `comb.concat` (with the
   same operand multiple times) instead.

 * No zero extension operator to add high zero bits.  This is strictly redundant
   with `concat(zero, value)`.  The `hw.sext` operator exists because it
   efficiently models large sign extensions which are common, and would require
   many operands if modeled as a concat operator (in contrast, a zero extension
   always requires a single zero value).

The absence of these operations doesn't affect the expressive ability of the IR,
and ExportVerilog will notice these and generate the compact Verilog syntax.

**No multibit mux operations**

The comb dialect in CIRCT doesn't have a first-class multibit mux.  Instead we
prefer to use two array operations to represent this.  For example, consider
a 3-bit condition:

```
 hw.module @multibit_mux(%a: i32, %b: i32, %c: i32, %idx: i3) -> (%out: i32) {
   %x_i32 = sv.constantX : i32
   %tmpArray = hw.array_create %a, %b, %x_i32, %b, %c, %x_i32 : i32
   %result   = hw.array_get %tmpArray[%idx] : !hw.array<6xi32>
   hw.output %result: i32
 }
```

This gets lowered into (something like) this Verilog:

```
module multibit_mux(
  input  [31:0] a, b, c,
  input  [2:0]  idx,
  output [31:0] out);

  wire [5:0][31:0] _T = {{a}, {b}, {32'bx}, {b}, {c}, {32'bx}};
  assign out = _T[idx];
endmodule
```

In this example, the last X element could be dropped and generate
equivalent code.

We believe that synthesis tools handle the correctly and generate efficient
netlists.  For those that don't (e.g. Yosys), we have a `disallowPackedArrays`
LoweringOption that legalizes away multi-dimensional arrays as part of lowering.

While we could use the same approach for single-bit muxes, we choose to have a
single bit `comb.mux` operation for a few reasons:

 * This is extremely common in hardware, and using 2x the memory to represent
   the IR would be wasteful.
 * This are many peephole and other optimizations that apply to it.

We discussed these design points at length in an [August 11, 2021 design
meeting](https://docs.google.com/document/d/1fOSRdyZR2w75D87yU2Ma9h2-_lEPL4NxvhJGJd-s5pk/edit#heading=h.ygmlwiic5e1y), and
discussed the tradeoffs of adding support for a single-operation mux.  Such a
move has some advantages and disadvantages:

1) It is another operation that many transformations would need to be aware of,
   e.g. verilog emission would have to handle it, and peephole optimizations
   would have to be aware of array_get and comb.mux.
2) We don't have any known analyses or optimizations that are difficult to
   implement with the current representation.

We agreed that we'd revisit in the future if there were a specific reason to
add it.  Until then we represent the array_create/array_get pattern for
frontends that want to generate this.

**Zero Bit Integers**

Combinatorial operations like add and multiply work on values of signless
standard integer types, e.g. `i42`, but they do not allow zero bit inputs.  This
design point is motivated by a couple of reasons:

1) The semantics of some operations (e.g. `hw.sext`) do not have an obvious
   definition with a zero bit input.

1) Zero bit operations are useless for operations that are definable, and their
   presence makes the compiler more complicated.

On the second point, consider an example like `hw.mux` which could allow zero
bit inputs and therefore produce zero bit results.  Allowing that as a design
point would require us to special case this in our cost models, and we would
have that optimizes it away.

By rejecting zero bit operations, we choose to put the complexity into the
lowering passes that generate the HW dialect (e.g. LowerToHW from FIRRTL).

Note that this decision only affects the core operations in the HW dialect
itself - it is perfectly reasonable to define your operations and mix them into
other HW constructs.  Also, certain other operations do support zero bit
declarations in limited ways:

 - The `hw.module` operation allows zero bit ports, since it supports an open
   type system.  They are dropped from Verilog emission.
 - Interface signals are allowed to be zero bits wide.  They are dropped from
   Verilog emission.

## Endianness: operand ordering and internal representation

Certain operations require ordering to be defined (i.e. `hw.concat`,
`hw.array_concat`, and `hw.array_create`). There are two places where this
is relevant: in the MLIR assembly and in the MLIR C++ model.

In MLIR assembly, operands are always listed MSB to LSB (big endian style):

```mlir
%msb = hw.constant 0xEF : i8
%mid = hw.constant 0x7 : i4
%lsb = hw.constant 0xA018 : i16
%result = hw.concat %msb, %mid, %lsb : (i8, i4, i16) -> i28
// %result is 0xEF7A018
```

**Note**: Integers are always written in left-to-right lexical order. Operand
ordering for `hw.concat` was chosen to be consistent with simply abutting
them in lexical order.

```mlir
%1 = hw.constant 0x1 : i4
%2 = hw.constant 0x2 : i4
%3 = hw.constant 0x3 : i4
%arr123 = hw.array_create %1, %2, %3 : i4
// %arr123[0] = 0x3
// %arr123[1] = 0x2
// %arr123[2] = 0x1

%arr456 = ... // {0x4, 0x5, 0x6}
%arr78  = ... // {0x7, 0x8}
%arr = hw.array_concat %arr123, %arr456, %arr78 : !hw.array<3 x i4>, !hw.array<3 x i4>, !hw.array<2 x i4>
// %arr[0] = 0x6
// %arr[1] = 0x5
// %arr[2] = 0x4
// %arr[3] = 0x3
// %arr[4] = 0x2
// %arr[5] = 0x1
```

**Note**: This ordering scheme is unintuitive for anyone expecting C
array-like ordering. In C, arrays are laid out with index 0 as the least
significant value and the first element (lexically) in the array literal. In
the CIRCT _model_ (assembly and C++ of the operation creating the array), it
is the opposite -- the most significant value is on the left (e.g. the first
operand is the most significant). The indexing semantics at runtime, however,
differ in that the element zero is the least significant (which is lexically
on the right).

In the CIRCT C++ model, lists of values are in lexical order. That is, index
zero of a list is the leftmost operand in assembly, which is the most
significant value.

```cpp
ConcatOp result = builder.create<ConcatOp>(..., {msb, lsb});
// Is equivalent to the above integer concatenation example.
ArrayConcatOp arr = builder.create<ArrayConcatOp>(..., {arr123, arr456});
// Is equivalent to the above array example.
```

**Array slicing and indexing** (`array_get`) operations both have indexes as
operands. These indexes are the _runtime_ index, **not** the index in the
operand list which created the array upon which the op is running.

## Bitcasts

The bitcast operation represents a bitwise reinerpretation (cast) of a value.
This always synthesizes away in hardware, though it may or may not be
syntactically represented in lowering or export language. Since bitcasting
requires information on the bitwise layout of the types on which it operates,
we discuss that here. All of the types are _packed_, meaning there is never
padding or alignment.

- **Integer bit vectors**: MLIR's `IntegerType` with `Signless` semantics are
used to represent bit vectors. They are never padded or aligned.
- **Arrays**: The HW dialect defines a custom `ArrayType`. The in-hardware
layout matches C -- the high index of array starts at the MSB. Array's 0th
element's LSB located at array LSB.
- **Structs**: The HW dialect defines a custom `StructType`. The in-hardware
layout matchss C -- the first listed member's MSB corresponds to the struct's
MSB. The last member in the list shares its LSB with the struct.
- **Unions**: The HW dialect's `UnionType` could contain the data of any of the
member types so its layout is defined to be equivalent to the union of members
type bitcast layout. In cases where the member types have different bit widths,
all members start at the 0th bit and are padded up to the width of the widest
member. The value with which they are padded is undefined.

**Example figure**

```
15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0 
-------------------------------------------------
| MSB                                       LSB | 16 bit integer vector
-------------------------------------------------
                         | MSB              LSB | 8 bit integer vector
-------------------------------------------------
| MSB      [1]       LSB | MSB     [0]      LSB | 2 element array of 8 bit integer vectors
-------------------------------------------------

      13 12 11 10  9  8  7  6  5  4  3  2  1  0 
                            ---------------------
                            | MSB           LSB | 7 bit integer vector
      -------------------------------------------
      | MSB     [1]     LSB | MSB    [0]    LSB | 2 element array of 7 bit integer vectors
      -------------------------------------------
      | MSB a LSB | MSB b[1] LSB | MSB b[0] LSB | struct
      -------------------------------------------  a: 4 bit integral
                                                   b: 2 element array of 5 bit integer vectors
```

## Cost Model

As a very general mid-level IR, it is important to define the principles that
canonicalizations and other general purpose transformations should optimize for.
There are often many different ways to represent a piece of logic in the IR, and
things will work better together if we keep the compiler consistent.

First, unlike something like LLVM IR, keep in mind that the HW dialect is a
model of hardware -- each operation generally corresponds to an instance of
hardware, it is not an "instruction" that is executed by an imperative CPU.
As such, the primary concerns are area and latency, not "number of operations
executed".  As such, here are important concerns that general purpose
transformations should consider, ordered from most important to least important.

**Simple transformations are always profitable**

Many simple transformations are always a good thing, this includes:

1) Constant folding.
2) Simple strength reduction (e.g. divide to shift).
3) Common subexpression elimination.

These generally reduce the size of the IR in memory, can reduce the area of a
synthesized design, and often unblock secondary transformations.

**Reducing widths of non-trivial operations is always profitable**

It is always a good idea to reduce the width of non-trivial operands like add,
multiply, shift, divide, and, or (etc) since it produces less hardware and
enables other simplifications.  This is even true if it grows the IR size by
increasing the number of truncations and extensions in the IR.

That said, it is a bad idea to *duplicate* operations to reduce widths: for
example, it is better to have one large multiply with many users than to clone
it because one user only needs some of the output bits.

**Don't get overly tricky with divide and remainder**

Divide operations (particularly those with non-constant divisors) generate a lot
of hardware, and can have long latencies.  As such, it is a generally bad idea
to do anything to an individual instance of a divide that can increase its
latency (e.g. merging a narrow divide with a wider divide and using a subset of
the result bits).

**Constants and moving bits around is free**

Operations for constants, truncation, zero/sign extension, concatenation of 
signals, and other similar operations are considered free since they generally
do not synthesize into hardware.  All things being equal it is good to reduce
the number of instances of these (to reduce IR size and increase canonical form)
but it is ok to introduce more of these to improve on other metrics above.

**Ordering Concat and Extract**

The`concat(extract(..))` form is preferred over the `extract(concat(..))` form,
because

- `extract` gets "closer" to underlying `add/sub/xor/op` operations, giving way
  optimizations like narrowing.
- the form gives a more accurate view of the values that are being depended on.
- redundant extract operations can be removed from the concat args lists, eg:
  `cat(extract(a), b, c, extract(d))`

Both forms perform similarly on hardware, since they are simply bit-copies.
