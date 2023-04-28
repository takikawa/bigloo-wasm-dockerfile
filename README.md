A dockerfile for building a bigloo setup that can compile to wasm via emscripten.

Example:

```
docker build .
docker run --rm -it --entrypoint bash <imagehash>
$ echo '(module hello) (display "hello world") (newline)' > hello.scm
$ /opt/bigloo/bin/bigloo -O3 hello.scm -o hello.js -cc /emsdk/upstream/emscripten/emcc -copt '-O3 -sASYNCIFY -sEXIT_RUNTIME  -L/opt/bigloo-wasm/lib/bigloo/4.5a -I/bigloo-wasm/gmp/gmp-6.2.1/'
$ emsdk/node/15.14.0_64bit/bin/node hello.js
```

Depending on the example, you may also need to pass additional arguments such as
`-sEMULATE_FUNCTION_POINTER_CASTS=1 -s BINARYEN_EXTRA_PASSES="--pass-arg=max-func-params@70"`.

The `EMULATE_FUNCTION_POINTER_CASTS` option is required because of the use of
function pointer casts in Bigloo-produced C code. See [this emscripten doc page](https://emscripten.org/docs/porting/guidelines/function_pointer_issues.html)
for details. Using this option requires the additional `max-func-params` option.

Example for hopc (in the same container as above):

```
$ echo 'console.log("hello world");' > test.js
$ /opt/hop/bin/hopc --js-no-header test.js -o test-output.js --bigloo=/opt/bigloo/bin/bigloo -- -O3 -cc /emsdk/upstream/emscripten/emcc -ldopt "/opt/hop-wasm/lib/hop/3.6.0/libjs2scheme_s-3.6.0.a" -copt '-sSTACK_SIZE=655360 -sASYNCIFY -sERROR_ON_UNDEFINED_SYMBOLS=0 -sEMULATE_FUNCTION_POINTER_CASTS=1 -s BINARYEN_EXTRA_PASSES="--pass-arg=max-func-params@120" -L/opt/bigloo-wasm/lib/bigloo/4.5a -L/opt/hop-wasm/lib/hop/3.6.0 -I/bigloo-wasm/gmp/gmp-6.2.1/'
$ emsdk/node/15.14.0_64bit/bin/node test-output.js
```

So far I have not been able to get this hop-to-wasm result to run correctly.

---

The patches this Dockerfile depends on are licensed under GPLv2 under the same terms as the original Bigloo code.

This Dockerfile itself is licensed under the MIT license
