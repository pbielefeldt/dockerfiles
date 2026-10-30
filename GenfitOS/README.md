# GenfitOS – GenFit2 on openSUSE Leap

Container image with the [GenFit2](https://github.com/GenFit/GenFit) track-fitting library, built from source on **openSUSE Leap 16.0**.
ROOT comes from the openSUSE [science repository](https://download.opensuse.org/repositories/science/).

| Component | Version | Source |
|---|---|---|
| Base image | openSUSE Leap 16.0 | `registry.opensuse.org/opensuse/leap:16.0` |
| ROOT | 6.32 (`root6-devel`) | openSUSE science repo |
| GenFit2 | `02-03-00` ([release-02-03-00](https://github.com/GenFit/GenFit/releases/tag/02-03-00)) | GitHub tarball, built in the image |
| Eigen / GoogleTest / GCC | from the Leap 16.0 and science repos | |

GenFit's own test suite runs **during the build**: `ctest` with `streamerTest`, `unitTests` and the gtests. The build fails if any test fails.

## Build

```bash
docker build --tag genfit:02-03-00 .
# another GenFit tag:            --build-arg GENFIT_REF=<tag>
# parallel compile jobs:         --build-arg JOBS=8
# podman: add --format docker
```

`make.sh` builds and pushes `pbielefeldt/genfit:02-03-00` and `pbielefeldt/genfit:latest` to Docker Hub.

## Use

```bash
docker run --rm -it -v "$PWD":/work genfit:02-03-00
```

Inside the container:

| Path / variable | Content |
|---|---|
| `/opt/genfit/lib` (`$GENFIT`) | `libgenfit2.so` and the ROOT dictionary `.pcm` files |
| `/opt/genfit/include` (`$GENFIT_INCDIR`) | GenFit headers |
| `/opt/genfit/src` | GenFit sources. They have to stay: the ROOT dictionaries reference the headers by their build-time path |
| `LD_LIBRARY_PATH`, `ROOT_INCLUDE_PATH` | preset to the GenFit lib and include directories |

**Compiled code (CMake):** find the library via `$GENFIT` and `$GENFIT_INCDIR`. [GenFitExamples/GFResidualExample](https://github.com/pbielefeldt/GenFitExamples) is a minimal example and builds as is:

```bash
git clone https://github.com/pbielefeldt/GenFitExamples.git
cmake -S GenFitExamples/GFResidualExample -B build && cmake --build build && ./build/GFResidualExample
```

**ROOT macros:** load the library first. GenFit installs no rootmap, so its classes don't autoload:

```bash
root -l -e 'gSystem->Load("libgenfit2")' my_macro.C+
```

Prefer compiled macros (`.C+`, ACLiC). In purely interpreted code, `IsA()` on GenFit objects returns `nullptr`. That is a GenFit/cling limitation, also seen with other ROOT builds, not specific to this image.

## Differences from upstream

**No `genfit::EventDisplay`.** openSUSE's `root6` is built without OpenGL, so it has no Eve, but GenFit 02-03-00 always builds its event display.
`genfit-no-eventdisplay.patch` therefore:
- removes the event display from the library: sources, dictionary and headers;
- drops the four examples that use it (`fitterTests`, `minimalFittingExample`, `minimalFittingExample2`, `measurementFactoryExample`);
- removes unused Eve includes from `streamerTest` and `unitTests`;
- links `ROOT::Geom`, `ROOT::EG` and `ROOT::Tree` directly. `ROOT::Eve` used to pull these in.

Track fitting and the test suite are otherwise unchanged. The patch can be dropped once openSUSE's ROOT includes Eve, or once GenFit makes the event display optional.

**`gcc13-c++` is installed in addition to the default gcc 15.** The `root6` package was built with gcc 13, and its interpreter (cling) runs `g++-13` to find the C++ standard library headers. Without it, every ROOT start prints `ERROR in cling::CIFactory::createCI(): cannot extract standard library include paths!`. cling then falls back to its precompiled headers, and simple macros still work, but the error is confusing and clutters logs. This is a missing dependency in the openSUSE package.
