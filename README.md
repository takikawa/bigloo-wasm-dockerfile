A dockerfile for building a bigloo setup that can compile to wasm via emscripten.

Example:

```
docker build .
docker run --rm -it --entrypoint bash <imagehash>
$ echo '(module num) (display-fixnum (+ 1 1) (current-output-port))' > num.scm
$ /opt/bigloo/bin/bigloo num.scm -o num.js -cc /emsdk/upstream/emscripten/emcc -copt '-sASYNCIFY -sEMULATE_FUNCTION_POINTER_CASTS=1 -sEXIT_RUNTIME -s BINARYEN_EXTRA_PASSES="--pass-arg=max-func-params@70" -L/opt/bigloo-wasm/lib/bigloo/4.5a -I/bigloo-wasm/gmp/gmp-6.2.1/'
$ emsdk/node/14.18.2_64bit/bin/node hello.js
```

This example does run, but currently prints the wrong result value. Other examples
involving printing and output ports don't seem to work very well.

The `EMULATE_FUNCTION_POINTER_CASTS` option is required because of the use of
function pointer casts in Bigloo-produced C code. See [this emscripten doc page](https://emscripten.org/docs/porting/guidelines/function_pointer_issues.html)
for details. Using this option requires the additional `max-func-params` option.

---

The patches this Dockerfile depends on are licensed under GPLv2 under the same terms as the original Bigloo code.

This Dockerfile itself is licensed under the MIT license
