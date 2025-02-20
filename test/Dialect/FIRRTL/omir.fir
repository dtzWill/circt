; RUN: circt-translate -import-firrtl -split-input-file %s | FileCheck %s

; These tests use the regex "{{[^{}]+}}".  This will consume everything that
; isn't creating a new dictionary or closing the current dictionary.  This is
; effectively consuming all the members up to the next member.  This is used to
; try and limit what a given test is looking at.  E.g., most of the tests below
; ignore the location member (except for tests that explicitly check location
; behavior).  The regex above is used to skip over the location member.

; Check that an empty nodes array is accepted.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": []
  }
]]
  module Foo:
    skip

    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    class = "freechips.rocketchip.objectmodel.OMIRAnnotation",
    ; CHECK-SAME:    nodes = []

; // -----
; Check that an empty fields array produces an empty dictionary.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": [
      {
        "info":"",
        "id":"OMID:0",
        "fields":[]
      }
    ]
  }
]]
  module Foo:
    skip

    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    fields = {}

; // -----
; Check that missing fields produces an empty dictionary.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": [
      {
        "info":"",
        "id":"OMID:0"
      }
    ]
  }
]]
  module Foo:
    skip

    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    fields = {}

; // -----
; Test source locator behavior.  Check that both single and fused locators work
; and that source locators are convert to location attributes for both Object
; Model Nodes and Object Model Fields.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": [
      {
        "info":"@[A 0:1]",
        "id":"OMID:0",
        "fields":[
          {
            "info":"@[B 2:3]",
            "name":"x",
            "value":"OMReference:0"
          },
          {
            "info": "@[C 4:5 D 6:7]",
            "name":"y",
            "value":"OMReference:0"
          }
        ]
      }
    ]
  }
]]
  module Foo:
    skip

    ; CHECK-DAG:   [[locA:#loc[0-9]+]] = loc("A":0:1)
    ; CHECK-DAG:   [[locB:#loc[0-9]+]] = loc("B":2:3)
    ; CHECK-DAG:   [[locCD:#loc[0-9]+]] = loc(fused["C":4:5, "D":6:7])
    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    x = {{{[^{}]+}} info = [[locB]]
    ; CHECK-SAME:    y = {{{[^{}]+}} info = [[locCD]]
    ; CHECK-SAME:    id = "OMID:0", info = [[locA]]

; // -----
; Check that every OMIR string-encoded type and non-string-encoded types
; (integer, boolean, and double) all work.  Also, check that each field is
; properly converted to a dictionary and that each dictionary gets an "index"
; member which stores the original field order.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": [
      {
        "info":"",
        "id":"OMID:0",
        "fields":[
          {
            "info":"",
            "name":"a",
            "value":"OMReference:0"
          },
          {
            "info":"",
            "name":"b",
            "value":"OMBigInt:42"
          },
          {
            "info":"",
            "name":"c",
            "value":"OMLong:ff"
          },
          {
            "info":"",
            "name":"d",
            "value":"OMString:hello"
          },
          {
            "info":"",
            "name":"e",
            "value":"OMDouble:3.14"
          },
          {
            "info":"",
            "name":"f",
            "value":"OMBigDecimal:10.5"
          },
          {
            "info":"",
            "name":"g",
            "value":"OMDeleted:"
          },
          {
            "info":"",
            "name":"h",
            "value":"OMConstant:UInt<2>(\"h1\")"
          },
          {
            "info":"",
            "name":"i",
            "value":42
          },
          {
            "info":"",
            "name":"j",
            "value":true
          },
          {
            "info":"",
            "name":"k",
            "value":3.14
          }
        ]
      }
    ]
  }
]]
  module Foo:
    skip

    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    a = {index = 0 {{[^{}]+}} value = "OMReference:0"},
    ; CHECK-SAME:    b = {index = 1 {{[^{}]+}} value = "OMBigInt:42"},
    ; CHECK-SAME:    c = {index = 2 {{[^{}]+}} value = "OMLong:ff"},
    ; CHECK-SAME:    d = {index = 3 {{[^{}]+}} value = "OMString:hello"},
    ; CHECK-SAME:    e = {index = 4 {{[^{}]+}} value = "OMDouble:3.14"},
    ; CHECK-SAME:    f = {index = 5 {{[^{}]+}} value = "OMBigDecimal:10.5"},
    ; CHECK-SAME:    g = {index = 6 {{[^{}]+}} value = "OMDeleted:"},
    ; CHECK-SAME:    h = {index = 7 {{[^{}]+}} value = "OMConstant:UInt<2>(\22h1\22)"},
    ; CHECK-SAME:    i = {index = 8 {{[^{}]+}} value = 42 : i64},
    ; CHECK-SAME:    j = {index = 9 {{[^{}]+}} value = true},
    ; CHECK-SAME:    k = {index = 10 {{[^{}]+}} value = 3.14{{0+e\+0+}} : f64}

; // -----

; Check that every OMIR FIRRTL Target is replaced with an ID and that this ID is
; scattered into the circuit.
circuit Foo: %[[
  {
    "class":"freechips.rocketchip.objectmodel.OMIRAnnotation",
    "nodes": [
      {
        "info":"",
        "id":"OMID:0",
        "fields":[
          {
            "info":"",
            "name":"a",
            "value":"OMReferenceTarget:~Foo|Foo>a"
          },
          {
            "info":"",
            "name":"b",
            "value":"OMMemberReferenceTarget:~Foo|Foo>b"
          },
          {
            "info":"",
            "name":"c",
            "value":"OMMemberInstanceTarget:~Foo|Foo/c:C"
          },
          {
            "info":"",
            "name":"d",
            "value":"OMMemberInstanceTarget:~Foo|D"
          },
          {
            "info":"",
            "name":"e",
            "value":"OMInstanceTarget:~Foo|Foo/e:E"
          },
          {
            "info":"",
            "name":"f",
            "value":"OMInstanceTarget:~Foo|F"
          },
          {
            "info":"",
            "name":"g",
            "value":"OMDontTouchedReferenceTarget:~Foo|Foo>g"
          }
        ]
      }
    ]
  }
]]
  module C:
    skip

  module D:
    skip

  module E:
    skip

  module F:
    skip

  module Foo:
    wire a: UInt<1>
    wire b: UInt<1>
    wire g: UInt<1>

    inst c of C
    inst d of D
    inst e of E
    inst f of F

    ; CHECK-LABEL: firrtl.circuit "Foo"
    ; CHECK-SAME:    a = {{{[^{}]+}} value = {id = [[aID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    b = {{{[^{}]+}} value = {id = [[bID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    c = {{{[^{}]+}} value = {id = [[cID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    d = {{{[^{}]+}} value = {id = [[dID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    e = {{{[^{}]+}} value = {id = [[eID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    f = {{{[^{}]+}} value = {id = [[fID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-SAME:    g = {{{[^{}]+}} value = {id = [[gID:[0-9]+]] : i64, omir.tracker, path = {{"[a-zA-Z~|:/>]+"}}, type = {{"OM[a-zA-Z]+"}}
    ; CHECK-DAG:   firrtl.nla @[[Foo_eE_E:nla_[0-9]+]]
    ; CHECK-DAG:   firrtl.nla @[[Foo_cC_C:nla_[0-9]+]]
    ; CHECK:       firrtl.module private @C
    ; CHECK-SAME:    {circt.nonlocal = @[[Foo_cC_C]], class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[cID]] : i64}
    ; CHECK:       firrtl.module private @D
    ; CHECK-SAME:    {class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[dID]] : i64}
    ; CHECK:       firrtl.module private @E
    ; CHECK-SAME:    {circt.nonlocal = @[[Foo_eE_E]], class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[eID]] : i64}
    ; CHECK:       firrtl.module private @F
    ; CHECK-SAME:    {class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[fID]] : i64}
    ; CHECK:       firrtl.module @Foo
    ; CHECK-NEXT:  %a = firrtl.wire
    ; CHECK-SAME:    {class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[aID]] : i64}
    ; CHECK-NEXT:  %b = firrtl.wire
    ; CHECK-SAME:    {class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[bID]] : i64}
    ; CHECK-NEXT:  %g = firrtl.wire
    ; CHECK-SAME:    {class = "freechips.rocketchip.objectmodel.OMIRTracker", id = [[gID]] : i64}
