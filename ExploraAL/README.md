# ExploraAL – TpcExplora development image on AlmaLinux

Build scripts for a Docker/Podman image that contains a complete, ready-to-use **TpcExplora** development environment on **AlmaLinux 9**:

- the **allsources** dependency stack (ROOT, Geant4, Geant3, VMC, VGM, CLHEP, Pythia6, …), built from source,
- **GenFit2**, required by the TPC tracking plugin,
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

| Component | Version | Source |
|---|---|---|
| Base image | AlmaLinux 9.8 (gcc 11.5, CMake 3.26) | `almalinux:9.8` |
| allsources | commit `07a7f3d` (branch `root6.28`) | agthoma GitLab `CB/software/allsources` |
| ↳ ROOT | 6.28/06 (C++14; pythia6, xml, gdml, opengl, fftw3, roofit, minuit2) | |
| ↳ Geant4 | 10.7.4, including data sets | |
| ↳ CLHEP / VMC / VGM | 2.4.4.0 / 1.1.p1 / 4.9 | |
| ↳ geant3 / geant4_vmc | 3.9.p1 / 5.4.p1 | |
| ↳ Pythia6, xerces-c, gsl, fftw, dawn | 6.4 (patched), 3.2.4, 2.7, 3.3.10, 3.90b | |
| GenFit2 | tag `02-03-00` | github.com/GenFit/GenFit |
| Explora | commit `f31bc421` (master, 2026-10-29) | agthoma GitLab `AGKetzer/tpc/explora` |
| 3rdParty plugins | default + custom lists in explora, plus `ExternalPlugins.txt` at their current HEAD | agthoma GitLab, gitlab.uni-bonn.de |

The exact commits of everything that was fetched are recorded in `vendor/VERSIONS`, which is copied to `/src/VERSIONS` in the image. The image labels `explora.ref`, `allsources.ref` and `genfit.ref` hold the main refs.

> **Note:** the current production machine runs ROOT 6.24/06, Geant3 3.8 and Geant4 10.7, with GenFit `43665fca` (tag `02-00-01`).
> This image uses the newer allsources `root6.28` line. A variant pinned to the production versions (allsources `2d35bde`) is planned.
> ROOT is not fully backwards compatible, so validate results before you use them for physics.

Layout inside the image:

| Path | Content |
|---|---|
| `/opt/CB/allsources` | allsources install prefix (`$ALLSOURCES`, `$ROOTSYS`, `$G4SYS`) |
| `/opt/genfit` | GenFit install (`$GENFIT` = `/opt/genfit/lib`, `$GENFIT_INCDIR`) |
| `/opt/explora` | Explora install (`$EXPLORA_HOME`), 3rdParty plugins in `/opt/explora/3rdParty` |
| `/src/TpcExplora` | Explora sources (git checkout, incl. the vendored plugins under `3rdParty/`) |
| `/src/allsources`, `/src/GenFit-02-03-00` | sources of allsources and GenFit |
| `/build/explora` | Explora build tree; run `make && make install` here to rebuild |
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
| Build time | about 1.5–2 h with `JOBS=16`; ROOT and Geant4 take most of it |
| Disk | ≥ 25 GB free: about 10 GB of temporary build tree in the allsources step, plus image layers |
| RAM | ≥ 16 GB recommended for `JOBS=16`; about 2 GB per parallel compile job |
| Final image | about 5.2 GB, including the Geant4 data sets |

Network access during the build is needed only for public downloads: AlmaLinux and EPEL packages, and the ROOT, Geant4, VMC, GenFit, … tarballs referenced by allsources.
No credentials are used inside the build.

## Quick start

```bash
git clone https://github.com/pbielefeldt/dockerfiles.git
cd dockerfiles/ExploraAL

cp .env.example .env        # fill in your GitLab usernames and tokens
./fetch-sources.sh          # clones explora, allsources and the private plugins into vendor/
./make.sh                   # builds the image exploraal:dev (1.5-2 h)

docker run --rm -it exploraal:dev                 # interactive shell, environment loaded
docker run --rm exploraal:dev explora -h          # run a single command
```

## Step by step

### 1. Credentials

Copy `.env.example` to `.env` and fill in the username and token for both GitLab instances.
`.env` is listed in `.gitignore` and `.dockerignore`, so it can't be committed and never reaches the docker build context or the image.

If you keep the file somewhere else, point the fetch script to it: `ENV_FILE=/path/to/.env ./fetch-sources.sh`.

### 2. Fetch the sources

```bash
./fetch-sources.sh
```

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
| `EXPLORA_REF` | `f31bc421…` | Explora branch, tag or commit |
| `EXPLORA_URL` | agthoma `AGKetzer/tpc/explora.git` | Explora repository |
| `EXPLORA_SRC` | – | Copy a **local** Explora source tree instead of cloning, e.g. your working copy or an unpacked zip; build directories and `.env` are skipped |
| `ALLSOURCES_REF` | `07a7f3d…` | allsources branch, tag or commit |
| `ALLSOURCES_URL` | agthoma `CB/software/allsources.git` | allsources repository |
| `ENV_FILE` | `./.env` | credentials file |

The private plugin list comes from Explora's own `3rdParty/ExternalPlugins.txt`. A different Explora ref can therefore bring a different plugin set.

### 3. Build

```bash
./make.sh
```

`make.sh` builds `exploraal:dev` with all CPUs. It passes the fetched refs from `vendor/VERSIONS` as image labels, and it never pushes.
Settings: `TAGNAME=exploraal:test`, `JOBS=8`, `CONTAINER_TOOL=podman`.

Equivalent manual call:

```bash
docker build --build-arg JOBS=16 -t exploraal:dev .
podman build --format docker --build-arg JOBS=16 -t exploraal:dev .   # podman: --format docker is required
```

Build arguments: `JOBS` (parallel compile jobs, default 8) and `GENFIT_REF` (GenFit tag, default `02-03-00`).

The build steps are separate layers, in this order: system packages → allsources → GenFit → Explora + plugins.
After a change to the Explora sources, only the last layers are rebuilt, which takes minutes. Any change to `vendor/allsources` or the package list triggers the full 1.5–2 h build.

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
git clone https://gitlab.uni-bonn.de/grp_agketzer/cb-tpc/ExploraConfigs.git   # about 11 GB
docker run --rm -v "$PWD/ExploraConfigs":/cfg -w /cfg/Geant4_test exploraal:dev bash -c '
  mkdir -p out
  explora -b use_geant4.xml \
    --override:CBTVirtualMCEventProcessor.event_count=5 \
    --override:CBTVirtualMCAliceModel.container=alice_model_steps \
    --override:CBTRootTreeOutput.OutputPath=out
  explora -b reco_Geant4.xml -f=out/use_geant4_tmp-mu-sim.root --override:CBTRootTreeOutput.OutputPath=out'
```

Expected:
- Both commands exit with 0 and log no `ERROR`/`FATAL`.
- The simulation writes `out/use_geant4_tmp-mu-sim.root` and takes about 80 s per event (see [Known issues](#known-issues)).
- The reconstruction processes all 5 events in a few seconds and fills the `TpcTrackingQA` histograms in `out/reco_Geant4_…_Histos.root`.

Notes:
- `-n=` does **not** limit Geant4/VMC runs. Their event count comes from `CBTVirtualMCEventProcessor`'s `event_count`, so override that.
- The `alice_model_steps` override works around a container-name mismatch inside `use_geant4.xml`: `CBTVirtualMCAliceModel` writes `alice_model`, but `CBTTpcDrift` reads `alice_model_steps`.

A quick GenFit-only check is [GenFitExamples](https://github.com/pbielefeldt/GenFitExamples) (`GFResidualExample`). It builds against `$GENFIT`/`$GENFIT_INCDIR` inside the container, and its pulls should have mean ≈ 0 and σ ≈ 1.

## What the build changes, and why

The build uses the upstream sources unchanged, except for these minimal fixes. Each one is also commented in the `Dockerfile`, and all of them are candidates for upstreaming.

**allsources** (`07a7f3d`):

| Change | Reason |
|---|---|
| xerces URL → `archive.apache.org` | xerces 3.2.4 was removed from `apache.org/dist`; the archived file has the same MD5 |
| gsoap not built | gsoap 2.8.127 can't be downloaded any more. Nothing in allsources needs it, and in Explora only the online-monitor 3rdParty plugins do, which are not built |
| Geant4 with `-DGEANT4_USE_SYSTEM_EXPAT=OFF` | With CMake ≥ 3.2x, Geant4 10.7 writes an invalid `Geant4PackageCache.cmake` for the system expat (empty type for `EXPAT_LIBRARY`). That breaks every later `find_package(Geant4)`, which VGM and geant4_vmc need |

**Explora**, applied as `sed` at build time, needed for ROOT ≥ 6.26 and also valid for ROOT 6.24:

| Change | Reason |
|---|---|
| `CBTShowMagneticField.cpp`, `CBTVirtualMCMagneticFieldMap.cpp`: copy of `TGeoBBox` → `const TGeoBBox &` | ROOT 6.26 deleted the copy constructors of TGeo shapes (compile error). Behaviour unchanged |
| `dataobj/CBTRefArray.cpp`: reset `fSize = 0` where `fUIDs` is freed | Since ROOT 6.26, `TRefArray::Init()` only reallocates when the size changes. `CBTRefArray`'s assignment frees `fUIDs` beforehand (a ROOT ≤ 5.26 leak workaround), so from the second event on the copy wrote through a null pointer: segfault in `CBTVirtualMCStartPointStorage` |

**Build integration:**

| Change | Reason |
|---|---|
| Private plugins are built as local plugins: `ExternalPlugins.txt` emptied, names appended to `CustomPlugins.txt` | No credentials inside the build; cmake would otherwise `git clone` them |
| GenFit built from source, sources kept in `/src` | Not part of allsources. Its ROOT dictionaries reference headers by their absolute build-time path, so cling can't autoload `genfit::` classes without them. The prebuilt `libgenfit2.so` shipped in `CBTGenfit2/genfit/lib` is excluded (unknown ROOT ABI) |
| `/opt/genfit/lib` registered with `ldconfig` | `libcbttpctracking.so` needs `libgenfit2.so` at runtime |
| `ROOT_INCLUDE_PATH` includes `/opt/explora/3rdParty/include` | cling autoloading of 3rdParty plugin classes (otherwise `Missing FileEntry for ….h`) |
| i686 packages (`glibc-devel`, `libstdc++-devel`, `libgfortran`, `libnsl`, `libxcrypt-compat`) | `CernZebraReader64` builds a 32-bit helper against shipped 32-bit CERNLIB libraries |
| Environment frozen into `/etc/explora.env` at build time | `thisroot.sh` (sourced by `thistr16.sh`) finds its own location via `BASH_ARGV`, which goes wrong whenever the sourcing script has arguments, e.g. an entrypoint running a multi-line `bash -c` |
| Local git snapshot commit if the Explora sources have no `.git` | Explora generates `gitinfo.h` from `.git`, and the build fails without it, e.g. for a zip download used via `EXPLORA_SRC` |

## Known issues

- **Slow TPC simulation**, independent of the image and the ROOT version: `CBTTpcReadout` calls `TpcPadPlane::fGetPadId()` once per electron. That function calls `TH2Poly::GetBinContent()`, which runs `TList::At()`, an O(number of bins) walk through a list of about 15 500 FOPI pad bins. This accounts for about 90% of simulation time, roughly 80 s per event. A fix has been sketched for the plugin developers: cache the bin → pad-ID mapping once, so each lookup takes O(1).
- **ROOT 6.28 vs. production ROOT 6.24:** the two Explora fixes above were found by building and running. Other differences in behaviour that don't crash can't be ruled out, so compare results with production before relying on them.
- Several 3rdParty plugins declare `cmake_minimum_required(VERSION 2.4.3)`. That only produces deprecation warnings with the image's CMake 3.26, but CMake ≥ 4 rejects it, so don't install a newer CMake in the image.
- Build output contains many compiler and CMake deprecation warnings from the older packages. They are expected.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `fetch-sources.sh`: `Authentication failed` / `could not read Username` | Missing or expired token in `.env`, or the token lacks `read_repository` |
| `fetch-sources.sh` hangs or times out for agthoma | Not on the university network: connect to the VPN |
| Build fails in the allsources step with a download error (404) | An upstream tarball moved. Add a URL override next to the existing ones in the `Dockerfile` (the xerces fix is an example) |
| `SHELL is not supported for OCI image format` warning | Podman without `--format docker`. Use `make.sh` or add the flag |
| `ERROR: must "cd where/root/is" before calling ". bin/thisroot.sh"` | `thisroot.sh`/`thistr16.sh` was sourced from a script with arguments. Use `source /etc/explora.env` instead |
| `cannot open shared object file: libgenfit2.so…` | Run commands through the entrypoint or a login shell, or run `ldconfig`. `/opt/genfit/lib` is registered in `/etc/ld.so.conf.d` |
| Build runs out of memory | Lower `JOBS`, e.g. `JOBS=4 ./make.sh` |

## Security and licensing

- `.env` holds personal GitLab tokens. It is excluded from git (`.gitignore`) and from the build context (`.dockerignore`). The fetched sources contain no credentials, and the build history of the image contains none either.
- The image contains **private, unpublished code** (Explora, allsources, plugins). Keep it local or in an access-restricted registry. Check the license terms of all components before you distribute it.
- The files in this directory (Dockerfile and scripts) are covered by the repository's license (MPL-2.0). The software they download and build keeps its own licenses.
