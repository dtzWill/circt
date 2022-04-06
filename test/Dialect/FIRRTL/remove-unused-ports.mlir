// RUN: circt-opt -pass-pipeline='firrtl.circuit(firrtl-remove-unused-ports)' %s -split-input-file | FileCheck %s
firrtl.circuit "Top"   {
  // CHECK-LABEL: firrtl.module @Top(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
  // CHECK-SAME :                    out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>)
  firrtl.module @Top(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                     out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c, %A_d_unused, %A_d_invalid, %A_d_constant = firrtl.instance A  @UseBar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d_unused: !firrtl.uint<1>, out d_invalid: !firrtl.uint<1>, out d_constant: !firrtl.uint<1>)
    // CHECK: %A_b, %A_c = firrtl.instance A @UseBar(in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    // CHECK-NEXT: firrtl.connect %A_b, %b
    // CHECK-NEXT: firrtl.connect %c, %A_c
    // CHECK-NEXT: firrtl.connect %d_unused, %{{invalid_ui1.*}}
    // CHECK-NEXT: firrtl.connect %d_invalid, %{{invalid_ui1.*}}
    // CHECK-NEXT: firrtl.connect %d_constant, %{{c1_ui1.*}}
    firrtl.connect %A_a, %a : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %A_b, %b : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %c, %A_c : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_unused, %A_d_unused : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_invalid, %A_d_invalid : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_constant, %A_d_constant : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // Check that %a, %d_unused, %d_invalid and %d_constant are removed.
  // CHECK-LABEL: firrtl.module private @Bar(in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>)
  // CHECK-NEXT:    firrtl.connect %c, %b
  // CHECK-NEXT:  }
  firrtl.module private @Bar(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                     out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    firrtl.connect %c, %b : !firrtl.uint<1>, !firrtl.uint<1>

    %invalid_ui1 = firrtl.invalidvalue : !firrtl.uint<1>
    firrtl.connect %d_invalid, %invalid_ui1 : !firrtl.uint<1>, !firrtl.uint<1>
    %c1_i1 = firrtl.constant 1 : !firrtl.uint<1>
    firrtl.connect %d_constant, %c1_i1 : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // Check that %a, %d_unused, %d_invalid and %d_constant are removed.
  // CHECK-LABEL: firrtl.module private @UseBar(in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) {
  firrtl.module private @UseBar(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                        out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c, %A_d_unused, %A_d_invalid, %A_d_constant = firrtl.instance A  @Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d_unused: !firrtl.uint<1>, out d_invalid: !firrtl.uint<1>, out d_constant: !firrtl.uint<1>)
    firrtl.connect %A_a, %a : !firrtl.uint<1>, !firrtl.uint<1>
    // CHECK: %A_b, %A_c = firrtl.instance A  @Bar(in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    firrtl.connect %A_b, %b : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %c, %A_c : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_unused, %A_d_unused : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_invalid, %A_d_invalid : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %d_constant, %A_d_constant : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // Make sure that %a, %b and %c are not erased because they have an annotation or a symbol.
  // CHECK-LABEL: firrtl.module private @Foo(in %a: !firrtl.uint<1> sym @dntSym, in %b: !firrtl.uint<1> [{a = "a"}], out %c: !firrtl.uint<1> sym @dntSym)
  firrtl.module private @Foo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) attributes {
    portAnnotations = [[], [{a = "a"}], []], portSyms = ["dntSym", "", "dntSym"]}
  {
    // CHECK: firrtl.connect %c, %{{invalid_ui1.*}}
    %invalid_ui1 = firrtl.invalidvalue : !firrtl.uint<1>
    firrtl.connect %c, %invalid_ui1 : !firrtl.uint<1>, !firrtl.uint<1>
  }

  // CHECK-LABEL: firrtl.module private @UseFoo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>)
  firrtl.module private @UseFoo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c = firrtl.instance A  @Foo(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    // CHECK: %A_a, %A_b, %A_c = firrtl.instance A @Foo(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    firrtl.connect %A_a, %a : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %A_b, %b : !firrtl.uint<1>, !firrtl.uint<1>
    firrtl.connect %c, %A_c : !firrtl.uint<1>, !firrtl.uint<1>
  }
}

// -----

// Strict connect version.
firrtl.circuit "Top"   {
  // CHECK-LABEL: firrtl.module @Top(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
  // CHECK-SAME :                    out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>)
  firrtl.module @Top(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                     out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c, %A_d_unused, %A_d_invalid, %A_d_constant = firrtl.instance A  @UseBar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d_unused: !firrtl.uint<1>, out d_invalid: !firrtl.uint<1>, out d_constant: !firrtl.uint<1>)
    // CHECK: %A_b, %A_c = firrtl.instance A @UseBar(in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    // CHECK-NEXT: firrtl.strictconnect %A_b, %b
    // CHECK-NEXT: firrtl.strictconnect %c, %A_c
    // CHECK-NEXT: firrtl.strictconnect %d_unused, %{{invalid_ui1.*}}
    // CHECK-NEXT: firrtl.strictconnect %d_invalid, %{{invalid_ui1.*}}
    // CHECK-NEXT: firrtl.strictconnect %d_constant, %{{c1_ui1.*}}
    firrtl.strictconnect %A_a, %a : !firrtl.uint<1>
    firrtl.strictconnect %A_b, %b : !firrtl.uint<1>
    firrtl.strictconnect %c, %A_c : !firrtl.uint<1>
    firrtl.strictconnect %d_unused, %A_d_unused : !firrtl.uint<1>
    firrtl.strictconnect %d_invalid, %A_d_invalid : !firrtl.uint<1>
    firrtl.strictconnect %d_constant, %A_d_constant : !firrtl.uint<1>
  }

  // Check that %a, %d_unused, %d_invalid and %d_constant are removed.
  // CHECK-LABEL: firrtl.module private @Bar(in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>)
  // CHECK-NEXT:    firrtl.strictconnect %c, %b
  // CHECK-NEXT:  }
  firrtl.module private @Bar(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                     out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    firrtl.strictconnect %c, %b : !firrtl.uint<1>

    %invalid_ui1 = firrtl.invalidvalue : !firrtl.uint<1>
    firrtl.strictconnect %d_invalid, %invalid_ui1 : !firrtl.uint<1>
    %c1_i1 = firrtl.constant 1 : !firrtl.uint<1>
    firrtl.strictconnect %d_constant, %c1_i1 : !firrtl.uint<1>
  }

  // Check that %a, %d_unused, %d_invalid and %d_constant are removed.
  // CHECK-LABEL: firrtl.module private @UseBar(in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) {
  firrtl.module private @UseBar(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>,
                        out %d_unused: !firrtl.uint<1>, out %d_invalid: !firrtl.uint<1>, out %d_constant: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c, %A_d_unused, %A_d_invalid, %A_d_constant = firrtl.instance A  @Bar(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>, out d_unused: !firrtl.uint<1>, out d_invalid: !firrtl.uint<1>, out d_constant: !firrtl.uint<1>)
    firrtl.strictconnect %A_a, %a : !firrtl.uint<1>
    // CHECK: %A_b, %A_c = firrtl.instance A  @Bar(in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    firrtl.strictconnect %A_b, %b : !firrtl.uint<1>
    firrtl.strictconnect %c, %A_c : !firrtl.uint<1>
    firrtl.strictconnect %d_unused, %A_d_unused : !firrtl.uint<1>
    firrtl.strictconnect %d_invalid, %A_d_invalid : !firrtl.uint<1>
    firrtl.strictconnect %d_constant, %A_d_constant : !firrtl.uint<1>
  }

  // Make sure that %a, %b and %c are not erased because they have an annotation or a symbol.
  // CHECK-LABEL: firrtl.module private @Foo(in %a: !firrtl.uint<1> sym @dntSym, in %b: !firrtl.uint<1> [{a = "a"}], out %c: !firrtl.uint<1> sym @dntSym)
  firrtl.module private @Foo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) attributes {
    portAnnotations = [[], [{a = "a"}], []], portSyms = ["dntSym", "", "dntSym"]}
  {
    // CHECK: firrtl.strictconnect %c, %{{invalid_ui1.*}}
    %invalid_ui1 = firrtl.invalidvalue : !firrtl.uint<1>
    firrtl.strictconnect %c, %invalid_ui1 : !firrtl.uint<1>
  }

  // CHECK-LABEL: firrtl.module private @UseFoo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>)
  firrtl.module private @UseFoo(in %a: !firrtl.uint<1>, in %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) {
    %A_a, %A_b, %A_c = firrtl.instance A  @Foo(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    // CHECK: %A_a, %A_b, %A_c = firrtl.instance A @Foo(in a: !firrtl.uint<1>, in b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    firrtl.strictconnect %A_a, %a : !firrtl.uint<1>
    firrtl.strictconnect %A_b, %b : !firrtl.uint<1>
    firrtl.strictconnect %c, %A_c : !firrtl.uint<1>
  }
}

// -----

firrtl.circuit "UnusedOutput"  {
  // CHECK-LABEL: @Sub
  // CHECK-NOT:     out %c
  firrtl.module private @Sub(in %a: !firrtl.uint<1>, out %b: !firrtl.uint<1>, out %c: !firrtl.uint<1>) {
    // CHECK-NEXT: %[[c_wire:.+]] = firrtl.wire
    // CHECK-NEXT: firrtl.strictconnect %b, %[[c_wire]]
    firrtl.strictconnect %b, %c : !firrtl.uint<1>
    // CHECK-NEXT: %[[not_a:.+]] = firrtl.not %a
    %0 = firrtl.not %a : (!firrtl.uint<1>) -> !firrtl.uint<1>
    // CHECK-NEXT: firrtl.strictconnect %[[c_wire]], %[[not_a]]
    firrtl.strictconnect %c, %0 : !firrtl.uint<1>
  }
  // CHECK-LABEL: @UnusedOutput
  firrtl.module @UnusedOutput(in %a: !firrtl.uint<1>, out %b: !firrtl.uint<1>) {
    // CHECK: %sub_a, %sub_b = firrtl.instance sub
    %sub_a, %sub_b, %sub_c = firrtl.instance sub  @Sub(in a: !firrtl.uint<1>, out b: !firrtl.uint<1>, out c: !firrtl.uint<1>)
    firrtl.strictconnect %sub_a, %a : !firrtl.uint<1>
    firrtl.strictconnect %b, %sub_b : !firrtl.uint<1>
  }
}
