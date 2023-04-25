A dockerfile for building a bigloo setup that can compile to wasm via emscripten.

Example:

```
docker build .
docker run --rm -it --entrypoint bash <imagehash>
$ echo '(module hello) (display "hello world") (newline)' > hello.scm
$ /opt/bigloo/bin/bigloo -O3 hello.scm -o hello.js -cc /emsdk/upstream/emscripten/emcc -copt '-O3 -sASYNCIFY -sEXIT_RUNTIME  -L/opt/bigloo-wasm/lib/bigloo/4.5a -I/bigloo-wasm/gmp/gmp-6.2.1/'
$ emsdk/node/14.18.2_64bit/bin/node hello.js
```

The `EMULATE_FUNCTION_POINTER_CASTS` option is required because of the use of
function pointer casts in Bigloo-produced C code. See [this emscripten doc page](https://emscripten.org/docs/porting/guidelines/function_pointer_issues.html)
for details. Using this option requires the additional `max-func-params` option.

---

The patches this Dockerfile depends on are licensed under GPLv2 under the same terms as the original Bigloo code.

This Dockerfile itself is licensed under the MIT license
