# ExploraAL – TpcExplora development image on AlmaLinux

Build scripts for a Docker/Podman image that contains a complete, ready-to-use **TpcExplora** development environment on **AlmaLinux 9**:

- the **allsources** dependency stack (ROOT, Geant4, Geant3, VMC, VGM, CLHEP, …), built from source, in two version sets: the **production** versions and the **latest** releases,
- **GenFit2**, required by the TPC tracking plugin (the production tag, or the latest one),
- **Explora** itself (the TPC fork), built and installed,
- all **3rdParty plugins**: the default set, the TPC plugins from `CustomPlugins.txt`, and the private plugins from `ExternalPlugins.txt`.

Explora, allsources and several plugins live in **private GitLab repositories**.
This directory therefore contains only the build recipe and no sources. You need access to those repositories to build the image (see [Requirements](#requirements)).
The resulting image contains private code. **Do not push it to a public registry**, see [Security and licensing](#security-and-licensing).

## Contents

- [What is in the image](#what-is-in-the-image)
- [Requirements](#requirements)
- [Quick start](#quick-start)
- [Step by step](#step-by-step)
- [Using the image](#using-the-image)
- [Smoke test](#smoke-test)
- [What the build changes, and why](#what-the-build-changes-and-why)
- [Known issues](#known-issues)
- [Troubleshooting](#troubleshooting)
- [Security and licensing](#security-and-licensing)

## What is in the image

| Component | Production versions (`…-root6.24.06`) | Latest versions (`…-root6.40.04`) |
|---|---|---|
| Base image | AlmaLinux 9.8 (gcc 11.5, CMake 3.26) | same |
| allsources | commit `2d35bde` (2022-07-28) | commit `aed50a0` (branch `root6.36`), with the versions below bumped by the recipe |
| ↳ ROOT | 6.24/06 (C++14; pythia6, xml, gdml, opengl, fftw3, roofit, minuit2) | 6.40.04 (C++17; xml, gdml, opengl, roofit, …; **no Pythia6**: ROOT removed it) |
| ↳ Geant4 | 10.7.1 (= 10.07.p01), including data sets | 11.4.3, including data sets |
| ↳ CLHEP | 2.4.4.0 | 2.4.7.1 |
| ↳ VMC / geant3 | v1-0-p3 / 3.8 | v2-2 / 4.5 |
| ↳ VGM / geant4_vmc | 4.9 / 5.3 | 5.5 / 6.8 |
| ↳ xerces-c, gsl, fftw, dawn | 3.2.3, 1.11, 3.2.2, 3.90b | 3.3.0, 2.8, 3.3.10, 3.90b |
| ↳ gSOAP | 2.8.135 | 2.8.146 |
| ↳ Pythia6 | 6.4 (patched) | – |
| GenFit2 | tag `02-00-01` (commit `43665fca`) | tag `02-03-00` |
| Explora | commit `0051a28e` or `e634933c` (branch **`wip-philipp`**) | commit `e634933c` |
| 3rdParty plugins | default and custom lists in Explora, plus `ExternalPlugins.txt` at the HEAD current at fetch time (the same plugin commits in all three images, see `/src/VERSIONS`) | same |

Explora is built from the **`wip-philipp`** branch, where current TPC development happens. Explora's `master` branch was last updated in 2022-06 and is far behind it.

The exact commit of every component is in `/src/VERSIONS` in the image. The image labels `profile`, `explora.ref`, `allsources.ref` and `genfit.ref` hold the main refs.

> **Production comparison:** the production machine runs ROOT 6.24/06, Geant3 3.8.0 and Geant4 10.07, with GenFit `43665fca`. The *production versions* images use exactly these.
> They can't be bit-for-bit identical to the production machine: the operating system, the compiler (gcc 11.5), gSOAP (the old release is no longer downloadable) and the Pythia6/ROOT build options may differ.
> The *latest versions* image is for checking how Explora behaves with current releases. ROOT is not fully backwards compatible, so **validate results against production** before you use them for physics. The few Explora source changes this needs are listed [below](#what-the-build-changes-and-why).

Layout inside the image:

| Path | Content |
|---|---|
| `/opt/CB/allsources` | allsources install prefix (`$ALLSOURCES`, `$ROOTSYS`, `$G4SYS`) |
| `/opt/genfit` | GenFit install (`$GENFIT` = `/opt/genfit/lib`, `$GENFIT_INCDIR`) |
| `/opt/explora` | Explora install (`$EXPLORA_HOME`), 3rdParty plugins in `/opt/explora/3rdParty` |
| `/src/TpcExplora` | Explora sources (git checkout, incl. the vendored plugins under `3rdParty/`) |
| `/src/allsources`, `/src/GenFit-<tag>` | sources of allsources and GenFit |
| `/build/explora` | Explora build tree |
| `/src/VERSIONS` | name, URL and commit of every fetched component |
| `/etc/explora.env` | the complete runtime environment, generated at build time |

## Requirements

**Access** (read permission) to these repositories:

| Host | Repositories |
|---|---|
| `agthoma.hiskp.uni-bonn.de/gitlab` | `AGKetzer/tpc/explora`, `CB/software/allsources`, `P.Bielefeldt/CBTTpcDrift`, `AGKetzer/tpc/CBTVertexCorrection` |
| `gitlab.uni-bonn.de` | `grp_agketzer/cb-tpc/3RDPP_ExportTrackPoints`, `…/3RDPP_PrimeClusterer`, `…/cbttpceventdisplay` |

You also need a **personal access token** with scope `read_repository` for each GitLab instance.
agthoma GitLab is usually only reachable from the university network or via VPN.

**Tools:**
- `git` and `bash` on the host.
- **Docker** (with BuildKit), or **Podman** ≥ 4. `make.sh` detects Podman and adds `--format docker`, which the build needs.

**Resources**, measured on a 16-core machine:

| | |
|---|---|
| Build time | about 1.5 h (production versions) to 2 h (latest versions) with `JOBS=16`; ROOT and Geant4 take most of it. Rebuilding only Explora takes 15–20 min |
| Disk | ≥ 30 GB free: about 10 GB of temporary build tree in the allsources step, plus image layers. Cached layers of several variants add up |
| RAM | ≥ 16 GB recommended for `JOBS=16`; about 2 GB per parallel compile job |
| Final image | about 4.5 GB (production versions) or 6.7 GB (latest versions), including the Geant4 data sets |

Network access during the build is needed only for public downloads: AlmaLinux and EPEL packages, and the ROOT, Geant4, VMC, GenFit, … tarballs referenced by allsources.
No credentials are used inside the build.

## Quick start

```bash
git clone https://github.com/pbielefeldt/dockerfiles.git
cd dockerfiles/ExploraAL

cp .env.example .env                       # fill in your GitLab usernames and tokens
PROFILE=production ./fetch-sources.sh      # clones explora, allsources and the private plugins into vendor/
./make.sh                                  # builds exploraal:production-e634933c (1.5-2 h)

docker run --rm -it exploraal:production-e634933c                 # interactive shell, environment loaded
docker run --rm exploraal:production-e634933c explora -h          # run a single command

# the latest ROOT 6.40 / Geant4 11.4 instead of the production versions:
PROFILE=latest ./fetch-sources.sh && ./make.sh                    # exploraal:latest-e634933c
```

## Step by step

### 1. Credentials

Copy `.env.example` to `.env` and fill in the username and token for both GitLab instances.
`.env` is listed in `.gitignore` and `.dockerignore`, so it can't be committed and never reaches the docker build context or the image.

If you keep the file somewhere else, point the fetch script to it: `ENV_FILE=/path/to/.env ./fetch-sources.sh`.

### 2. Fetch the sources

```bash
PROFILE=production ./fetch-sources.sh
```

`PROFILE` selects the dependency versions (a directory in `profiles/`, default `production`):

| Profile | Versions |
|---|---|
| `production` | ROOT 6.24/06, Geant4 10.7, geant3 3.8, GenFit 02-00-01 (allsources `2d35bde`) |
| `latest` | ROOT 6.40.04, Geant4 11.4.3, geant3 4.5, GenFit 02-03-00 (allsources `root6.36` plus version bumps, and the Explora source changes these versions need) |

The Explora commit is independent of the profile, e.g. `PROFILE=production EXPLORA_REF=0051a28e ./fetch-sources.sh`.

The script runs **on the host**, where your credentials and the VPN are. It fills `vendor/` (git-ignored):

| | |
|---|---|
| `vendor/explora/` | Explora at `EXPLORA_REF`. The `.git` directory is kept, so Explora's `gitinfo.h` shows the real revision |
| `vendor/allsources/` | allsources at `ALLSOURCES_REF` |
| `vendor/plugins/<Name>/` | every plugin listed in `vendor/explora/3rdParty/ExternalPlugins.txt`, at its `GIT_TAG` or default branch |
| `vendor/PLUGINS`, `vendor/VERSIONS` | plugin names; name, URL and commit of everything fetched |

Tokens are passed to git through a temporary `GIT_ASKPASS` helper. They never appear in URLs, logs or `.git/config`.

Options (environment variables):

| Variable | Default | Meaning |
|---|---|---|
| `PROFILE` | `production` | version set, see above |
| `EXPLORA_REF` | `e634933c…` (`wip-philipp`) | Explora branch, tag or commit |
| `EXPLORA_URL` | agthoma `AGKetzer/tpc/explora.git` | Explora repository |
| `EXPLORA_SRC` | – | Copy a **local** Explora source tree instead of cloning, e.g. your working copy or an unpacked zip; build directories and `.env` are skipped |
| `ALLSOURCES_REF` | from the profile | allsources branch, tag or commit |
| `ALLSOURCES_URL` | agthoma `CB/software/allsources.git` | allsources repository |
| `ENV_FILE` | `./.env` | credentials file |

The private plugin list comes from Explora's own `3rdParty/ExternalPlugins.txt`. A different Explora ref can therefore bring a different plugin set.

### 3. Build

```bash
./make.sh
```

`make.sh` builds `exploraal:<profile>-<first 8 characters of the Explora commit>` for the profile `vendor/` was fetched for, with all CPUs. It passes the fetched refs from `vendor/VERSIONS` as image labels, and it never pushes.
Settings: `TAGNAME=exploraal:test`, `JOBS=8`, `CONTAINER_TOOL=podman`.

Equivalent manual call:

```bash
docker build --build-arg PROFILE=production --build-arg GENFIT_REF=02-00-01 --build-arg JOBS=16 -t exploraal:dev .
podman build --format docker --build-arg PROFILE=production --build-arg GENFIT_REF=02-00-01 --build-arg JOBS=16 -t exploraal:dev .   # podman: --format docker is required
```

Build arguments: `PROFILE`, `GENFIT_REF` (GenFit tag; `make.sh` takes it from the profile) and `JOBS` (parallel compile jobs, default 8).

> **Keep `JOBS` the same between builds.** Build arguments are part of the layer cache key, so a different `JOBS` value rebuilds ROOT and Geant4 from scratch.

The build steps are separate layers, in this order: system packages → allsources → GenFit → Explora + plugins.
After a change to the Explora sources, only the last layers are rebuilt, which takes 15–20 minutes. Any change to `vendor/allsources`, to a profile's `profile.env`/`allsources.sh`, or to the package list triggers the full build.

## Using the image

The entrypoint loads the environment (ROOT, Geant4 data, Explora, GenFit) from `/etc/explora.env` and then runs the given command (default: `bash`).
Login shells (`bash -l`, `docker exec … bash -l`) load the same file via `/etc/profile.d/explora.sh`.

```bash
# interactive work on data in the current directory
docker run --rm -it -v "$PWD":/work -w /work exploraal:dev

# batch run of a config
docker run --rm -v "$PWD":/work -w /work exploraal:dev explora -b my_config.xml

# show the configuration attributes of a plugin
docker run --rm exploraal:dev explora -b --description:text:CBTTpcTracking
```

**Developing in the container:** the sources are in `/src/TpcExplora` and the build tree is `/build/explora`. To rebuild and install after a change, run `make -j$(nproc) && make install` in the build tree.
To work on your host checkout, mount it over `/src/TpcExplora` and rebuild. Changes inside a container are lost when it is removed, unless you mount a volume or commit the container.

**Apptainer/Singularity** (e.g. on a cluster), from a local image:

```bash
apptainer build exploraal.sif docker-daemon://exploraal:dev     # docker
podman save --format oci-archive -o exploraal.tar exploraal:dev  # podman ...
apptainer build exploraal.sif oci-archive://exploraal.tar        # ... then this
apptainer run exploraal.sif explora -h
```

`apptainer run` uses the image entrypoint. With `apptainer exec`/`shell`, run `source /etc/explora.env` first.

## Smoke test

There are no small, self-contained test inputs. The TPC simulation and reconstruction configs in the private `ExploraConfigs` repository work as an end-to-end test of Geant4/VMC, the TPC digitization, PSA, clustering, track finding and GenFit tracking:

```bash
git clone --filter=blob:none --sparse https://gitlab.uni-bonn.de/grp_agketzer/cb-tpc/ExploraConfigs.git
git -C ExploraConfigs sparse-checkout set Geant4_test Geometry fopi_testscript   # about 210 MB instead of 11 GB
docker run --rm -v "$PWD/ExploraConfigs":/cfg -w /cfg/Geant4_test exploraal:dev bash -c '
  mkdir -p out
  explora -b use_geant4.xml \
    --override:CBTVirtualMCEventProcessor.event_count=5 \
    --override:CBTVirtualMCAliceModel.container=alice_model_steps \
    --override:CBTRootTreeOutput.OutputPath=out
  explora -b reco_Geant4.xml -f=out/use_geant4_tmp-mu-sim.root --override:CBTRootTreeOutput.OutputPath=out'
```

Expected:
- Both commands exit with 0 and log no `ERROR`/`FATAL`. (Check the logs: `explora` also exits with 0 when an input file such as `../Geometry/…` is missing.)
- The simulation writes `out/use_geant4_tmp-mu-sim.root`. For the 5 events it takes about 14 s (Explora `e634933c`), or about 5 minutes with Explora `0051a28e`, before the pad-ID lookup was fixed (see [Known issues](#known-issues)).
- The reconstruction processes all 5 events in a few seconds and fills the `TpcTrackingQA` histograms in `out/reco_Geant4_…_Histos.root`.

Notes:
- `-n=` does **not** limit Geant4/VMC runs. Their event count comes from `CBTVirtualMCEventProcessor`'s `event_count`, so override that.
- The `alice_model_steps` override works around a container-name mismatch inside `use_geant4.xml`: `CBTVirtualMCAliceModel` writes `alice_model`, but `CBTTpcDrift` reads `alice_model_steps`.

The production and the latest versions images were compared: with Explora `e634933c` both give the same distributions within the statistics for 30 events (not bit-identical, Geant4 10.7 vs. 11.4). The production images with Explora `0051a28e` and `e634933c` give identical output.

A quick GenFit-only check is [GenFitExamples](https://github.com/pbielefeldt/GenFitExamples) (`GFResidualExample`). It builds against `$GENFIT`/`$GENFIT_INCDIR` inside the container, and its pulls should have mean ≈ 0 and σ ≈ 1.

## What the build changes, and why

The build uses the upstream sources unchanged, except for these minimal fixes. They live in the `Dockerfile` and in `profiles/<profile>/`, are commented there, and are all candidates for upstreaming.

**allsources, production profile** (`2d35bde`, `profiles/production/allsources.sh`):

| Change | Reason |
|---|---|
| xerces 3.2.3 URL → `archive.apache.org` | removed from `apache.org/dist`; the archived file has the same MD5 |
| fftw 3.2.2 URL `ftp://` → `https://www.fftw.org/` | the FTP URL is not reachable; same file and MD5 |
| gSOAP 2.8.82 → 2.8.135 from SourceForge | SourceForge now only keeps releases ≥ 2.8.135, in a new directory layout. Only the online-monitor plugins use gSOAP |
| Pythia6 built with `-fcommon` | gcc ≥ 10 defaults to `-fno-common` (backport of allsources `3c75f08`) |
| Geant4 10.7 with the system expat: `-DEXPAT_LIBRARY` and `-DEXPAT_INCLUDE_DIR` passed explicitly | With CMake ≥ 3.2x, Geant4 10.7 writes `set(EXPAT_LIBRARY … CACHE <empty type>)` into `Geant4PackageCache.cmake` because `EXPAT_LIBRARY` isn't a cache variable. That breaks every later `find_package(Geant4)` (VGM, geant4_vmc). Making it one on the command line fixes it, and `GEANT4_USE_SYSTEM_EXPAT` stays on |
| `FFLAGS=-fallow-argument-mismatch` | gfortran ≥ 10 rejects the argument mismatches in the old Fortran code |

**allsources, latest profile** (`root6.36` branch, `profiles/latest/allsources.sh`):

| Change | Reason |
|---|---|
| ROOT 6.36.06 → 6.40.04, Geant4 11.3.2 → 11.4.3, VMC v2-1 → v2-2, geant3 v4-4 → v4-5, VGM v5-3-1 → v5-5, geant4_vmc v6-7-p1 → v6-8, gSOAP 2.8.138 → 2.8.146 | latest releases (URLs and MD5s of the tarballs); the SourceForge file of gSOAP 2.8.138 was replaced and no longer matches its MD5 |
| `G3SYS` directory `Geant3-4.4.0` → `Geant3-4.5.0` in the environment scripts | follows the geant3 version |
| xerces 3.3.0 URL → `archive.apache.org` | `dlcdn.apache.org` only serves the current release |
| `root/allow-unknown-args.patch` ported | the patch no longer applied to `TRint.cxx` in ROOT 6.40 (only context and the exit code differ) |
| `pgsql` option removed from the ROOT arguments | ROOT 6.40 rejects it |
| `giflib-devel lz4-devel libzstd-devel gl2ps-devel` installed | ROOT 6.40 requires them as system packages |

**Explora, all profiles**, applied as `sed` at build time, needed for ROOT ≥ 6.26 and also valid for ROOT 6.24:

| Change | Reason |
|---|---|
| `CBTShowMagneticField.cpp`, `CBTVirtualMCMagneticFieldMap.cpp`: copy of `TGeoBBox` → `const TGeoBBox &` | ROOT 6.26 deleted the copy constructors of TGeo shapes (compile error). Behaviour unchanged |
| `dataobj/CBTRefArray.cpp`: reset `fSize = 0` where `fUIDs` is freed | Since ROOT 6.26, `TRefArray::Init()` only reallocates when the size changes. `CBTRefArray`'s assignment frees `fUIDs` beforehand, so from the second event on the copy wrote through a null pointer: segfault in `CBTVirtualMCStartPointStorage` |

**Explora, latest profile** (`profiles/latest/explora.sh`), needed for ROOT 6.40 and Geant4 11 / geant4_vmc 6.8:

| Change | Reason |
|---|---|
| `FindROOT.cmake` (Explora and every plugin): `root-config --version` converted from `6.40.04` to `6.40/04` | the version is parsed assuming the old format; CMake stops at configure time otherwise |
| `FindGEANT3VMC.cmake`: `libEGPythia6` is optional | ROOT removed the Pythia6 interface. Explora only links it so that geant3 resolves |
| `CBTRefArray.h`: `using TRefArray::AddFirst; using TRefArray::AddAt;` | ROOT 6.40 added `AddFirst(obj, opt)` and `AddAt(obj, idx, opt)` (they forward to the overridden versions); hiding them is an error with `-Werror=overloaded-virtual` |
| `#include <TMath.h>` where `TMath::` is used | ROOT headers no longer include it indirectly |
| `CBTRootTreeOutput.cpp`, `CBTRawdataTreeOutput.cpp`: `ROOT::ECompressionAlgorithm`, `ROOT::kZLIB`, … → `ROOT::RCompressionSetting::EAlgorithm::…`; `TClass::kHasCustomStreamerMember` → `HasCustomStreamerMember()` | removed in ROOT 6.40 |
| `CBTHStdScaler.cpp`: `AddBinContent(bin, (Double_t)value)` | the call with an `UInt_t` is ambiguous now |
| `CBTGeant4MC.cpp`: `TG4RunConfiguration(…, false, false)` | geant4_vmc ≥ 5.4 builds a multithreaded application by default. Explora's applications don't implement `CloneForWorker()`, and the run aborts without this. Sequential is what Geant4 10.7 did |

**Build integration:**

| Change | Reason |
|---|---|
| Private plugins built as local plugins: `ExternalPlugins.txt` emptied, names appended to `CustomPlugins.txt` | No credentials inside the build; cmake would otherwise `git clone` them |
| GenFit built from source, sources kept in `/src` | Not part of allsources. Its ROOT dictionaries reference headers by their absolute build-time path, so cling can't autoload `genfit::` classes without them. The prebuilt `libgenfit2.so` in `CBTGenfit2/genfit/lib` is excluded |
| `/opt/genfit/lib` registered with `ldconfig` | `libcbttpctracking.so` needs `libgenfit2.so` at runtime |
| `ROOT_INCLUDE_PATH` includes `/opt/explora/3rdParty/include` | cling autoloading of 3rdParty plugin classes (otherwise `Missing FileEntry for ….h`) |
| i686 packages (`glibc-devel`, `libstdc++-devel`, `libgfortran`, `libnsl`, `libxcrypt-compat`) | `CernZebraReader64` builds a 32-bit helper against shipped 32-bit CERNLIB libraries |
| Environment frozen into `/etc/explora.env` at build time (output of the `this*.sh` scripts discarded) | `thisroot.sh` locates itself via `BASH_ARGV`, which goes wrong whenever the sourcing script has arguments. `thisexplora.sh` prints a warning on ROOT ≥ 6.3x (`6.40.04` vs. `6.40/04`) that must not end up in the file |
| Local git snapshot commit if the Explora sources have no `.git` | Explora generates `gitinfo.h` from `.git`, and the build fails without it, e.g. for a zip download used via `EXPLORA_SRC` |

## Known issues

- **TPC simulation speed:** up to Explora `0051a28e`, `CBTTpcReadout` spent about 90% of the simulation time in `TpcPadPlane::fGetPadId()` (an O(number of bins) `TList` lookup per electron, about 60 s per event). Since `e634933c` the lookup uses a cached bin → pad-ID table: the 5-event smoke test takes about 14 s instead of 5 minutes, with identical output (see [Smoke test](#smoke-test)).
- **`TpcPadPlane` changed in `e634933c`** (`ClassDef` version 2, honeycomb accessors no longer inline). TPC plugins built separately against an older Explora (`CBTTpcPsa`, `CBTTpcDrift`, `CBTTpcEventDisplay`, …) must be rebuilt against this one; otherwise they stop with `undefined symbol: TpcPadPlane::fGetNumberOfPadsInList() const`. The plugins inside the images are built consistently.
- **Latest versions are not validated against production.** The five-event and 30-event tests run through and agree within statistics, but nothing beyond that has been compared. Changing the Geant4 or ROOT version can change physics (Geant4 10.7 → 11.4), file formats and numerical results.
- **No Pythia6 in the latest versions image** (ROOT removed `libEGPythia6`). Anything that needs Pythia6 through ROOT's `TPythia6` does not work there.
- **Geant4 runs sequentially.** With Geant4 11 the application would default to multithreaded, which Explora's applications don't support (see the build changes).
- **Warning on every start with the latest versions:** `thisexplora.sh` prints `WARNING: Active root version 6.40.04 not identical to the one used to build this explora (root version 6.40/04)`. It only compares the two spellings of the version and is harmless.
- Several 3rdParty plugins declare `cmake_minimum_required(VERSION 2.4.3)`. That only produces deprecation warnings with the image's CMake 3.26, but CMake ≥ 4 rejects it, so don't install a newer CMake in the image.
- Build output contains many compiler and CMake deprecation warnings from the older packages. They are expected.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `fetch-sources.sh`: `Authentication failed` / `could not read Username` | Missing or expired token in `.env`, or the token lacks `read_repository` |
| `fetch-sources.sh` hangs or times out for agthoma | Not on the university network: connect to the VPN |
| Build fails in the allsources step with a download error (404) or an MD5 mismatch | An upstream tarball moved or was replaced. Add a URL/checksum override to `profiles/<profile>/allsources.sh` next to the existing ones |
| `SHELL is not supported for OCI image format` warning | Podman without `--format docker`. Use `make.sh` or add the flag |
| `ERROR: must "cd where/root/is" before calling ". bin/thisroot.sh"` | `thisroot.sh`/`thistr16.sh` was sourced from a script with arguments. Use `source /etc/explora.env` instead |
| `cannot open shared object file: libgenfit2.so…` | Run commands through the entrypoint or a login shell, or run `ldconfig`. `/opt/genfit/lib` is registered in `/etc/ld.so.conf.d` |
| Build runs out of memory | Lower `JOBS`, e.g. `JOBS=4 ./make.sh` |

## Security and licensing

- `.env` holds personal GitLab tokens. It is excluded from git (`.gitignore`) and from the build context (`.dockerignore`). The fetched sources contain no credentials, and the build history of the image contains none either.
- The image contains **private, unpublished code** (Explora, allsources, plugins). Keep it local or in an access-restricted registry. Check the license terms of all components before you distribute it.
- The files in this directory (Dockerfile and scripts) are covered by the repository's license (MPL-2.0). The software they download and build keeps its own licenses.
