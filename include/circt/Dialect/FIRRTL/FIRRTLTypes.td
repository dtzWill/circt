//===- FIRRTLTypes.td - FIRRTL Types Definition ------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This describes the FIRRTL types.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// FIRRTL Types Definitions
//===----------------------------------------------------------------------===//

def FIRRTLType : DialectType<FIRRTLDialect, CPred<"$_self.isa<FIRRTLType>()">,
  "FIRRTLType", "::circt::firrtl::FIRRTLType">;

def ClockType : DialectType<FIRRTLDialect, CPred<"$_self.isa<ClockType>()">,
    "clock", "::circt::firrtl::ClockType">,
  BuildableType<"ClockType::get($_builder.getContext())">;

def IntType : DialectType<FIRRTLDialect, CPred<"$_self.isa<IntType>()">,
 "sint or uint type", "::circt::firrtl::IntType">;

def SIntType : DialectType<FIRRTLDialect, CPred<"$_self.isa<SIntType>()">,
 "sint type", "::circt::firrtl::SIntType">;

def UIntType : DialectType<FIRRTLDialect, CPred<"$_self.isa<UIntType>()">,
 "uint type", "::circt::firrtl::UIntType">;

def AnalogType : DialectType<FIRRTLDialect, CPred<"$_self.isa<AnalogType>()">,
 "analog type", "::circt::firrtl::AnalogType">;

def BundleType : DialectType<FIRRTLDialect, CPred<"$_self.isa<BundleType>()">,
 "BundleType", "::circt::firrtl::BundleType">;

def FVectorType : DialectType<FIRRTLDialect, CPred<"$_self.isa<FVectorType>()">,
  "FVectorType", "::circt::firrtl::FVectorType">;

def SizedType : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<FIRRTLType>() && "
          "!$_self.cast<FIRRTLType>().hasUninferredWidth()">,
    "a sized type (contains no unifered widths)", "::circt::firrtl::FIRRTLType">;

def UInt1Type : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<UIntType>() && "
          "($_self.cast<UIntType>().getWidth() == 1 ||"
          " $_self.cast<UIntType>().getWidth() == None)">,
    "UInt<1> or UInt", "::circt::firrtl::UIntType">,
  BuildableType<"UIntType::get($_builder.getContext(), 1)">;

def AsyncResetType : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<AsyncResetType>()">,
    "AsyncReset", "::circt::firrtl::AsyncResetType">,
  BuildableType<"AsyncResetType::get($_builder.getContext())">;

def ResetType : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<ResetType>()">,
    "Reset", "::circt::firrtl::ResetType">,
  BuildableType<"ResetType::get($_builder.getContext())">;

def PassiveType : DialectType<FIRRTLDialect,
  CPred<"$_self.isa<FIRRTLType>() && $_self.cast<FIRRTLType>().isPassive()">,
  "a passive type (contain no flips)", "::circt::firrtl::FIRRTLType">;

//===----------------------------------------------------------------------===//
// FIRRTL Types Predicates
//===----------------------------------------------------------------------===//

def OneBitType : DialectType<FIRRTLDialect,
 CPred<"($_self.isa<IntType>() && $_self.cast<IntType>().getWidth() == 1) || "
   "($_self.isa<AnalogType>() && $_self.cast<AnalogType>().getWidth() == 1)">,
 "UInt<1>, SInt<1>, or Analog<1>", "::circt::firrtl::FIRRTLType">;

def AnyResetType : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<FIRRTLType>() && $_self.cast<FIRRTLType>().isResetType()">,
    "Reset", "::circt::firrtl::FIRRTLType">;

def AnyRegisterType : DialectType<FIRRTLDialect,
    CPred<"$_self.isa<FIRRTLType>() && "
          "$_self.cast<FIRRTLType>().isRegisterType()">,
    "a passive type that does not contain analog",
    "::circt::firrtl::FIRRTLType">;

def UIntSIntClockType : AnyTypeOf<[SIntType, UIntType, ClockType],
                                  "sint, uint, or clock",
                                  "::circt::firrtl::FIRRTLType">;

def OneBitCastableType : AnyTypeOf<
  [OneBitType, AnyResetType, AsyncResetType, ClockType],
  "1-bit uint/sint/analog, reset, asyncreset, or clock",
                                  "::circt::firrtl::FIRRTLType">;

//===----------------------------------------------------------------------===//
// FIRRTL Enum Definitions
//===----------------------------------------------------------------------===//

/// RUWAttr: Undefined/Old/New.
def RUW_Undefined: I32EnumAttrCase<"Undefined", 0>;
def RUW_Old: I32EnumAttrCase<"Old", 1>;
def RUW_New: I32EnumAttrCase<"New", 2>;

def RUWAttr: I32EnumAttr<"RUWAttr", "Read Under Write Enum",
                         [RUW_Undefined, RUW_Old, RUW_New]>;

def MemDir_Infer    : I32EnumAttrCase<"Infer", 0>;
def MemDir_Read     : I32EnumAttrCase<"Read", 1>;
def MemDir_Write    : I32EnumAttrCase<"Write", 2>;
def MemDir_ReadWrite: I32EnumAttrCase<"ReadWrite", 3>;

def MemDirAttr: I32EnumAttr<"MemDirAttr", "Memory Direction Enum",
                            [MemDir_Infer, MemDir_Read, MemDir_Write,
                              MemDir_ReadWrite]>;
