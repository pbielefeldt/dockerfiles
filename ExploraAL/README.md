# ExploraAL – TpcExplora development image on AlmaLinux

Build scripts for a Docker/Podman image that contains a complete, ready-to-use **TpcExplora** development environment on **AlmaLinux 9**, with the versions used in production:

- the **allsources** dependency stack (ROOT 6.24/06, Geant4 10.07.p01, Geant3 3.8, VMC, VGM, CLHEP, …), built from source,
- **GenFit2** `02-00-01`, required by the TPC tracking plugin,
- **Explora** (the TPC fork) at commit `1083c0bd` (branch `wip-philipp`), built and installed,
- all **3rdParty plugins**: the default set, the TPC plugins from `CustomPlugins.txt`, and the private plugins from `ExternalPlugins.txt` at the commits pinned there.

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

| Component | Version |
|---|---|
| Base image | AlmaLinux 9.8 (gcc 11.5, CMake 3.26) |
| allsources | commit `2d35bde` (2022-07-28) |
| ↳ ROOT | 6.24/06 (C++14; pythia6, xml, gdml, opengl, fftw3, roofit, minuit2) |
| ↳ Geant4 | 10.7.1 (= 10.07.p01), including data sets |
| ↳ CLHEP | 2.4.4.0 |
| ↳ VMC / geant3 | v1-0-p3 / 3.8 |
| ↳ VGM / geant4_vmc | 4.9 / 5.3 |
| ↳ xerces-c, gsl, fftw, dawn | 3.2.3, 1.11, 3.2.2, 3.90b |
| ↳ gSOAP | 2.8.135 (2.8.82 is no longer downloadable) |
| ↳ Pythia6 | 6.4 (patched) |
| GenFit2 | tag `02-00-01` (commit `43665fca`) |
| Explora | commit `1083c0bd` (branch **`wip-philipp`**) |
| Private plugins | the commits pinned in Explora's `3rdParty/ExternalPlugins.txt`: CBTTpcDrift `dc994657`, CBTVertexCorrection `335a1c10`, ExportTrackPoints `85727ea3`, CBTMCPrimeClusterer `1d05902f`, CBTTpcEventDisplay `a411d415` |

These are the versions of the production machine (ROOT 6.24/06, Geant3 3.8.0, Geant4 10.07, GenFit `43665fca`).
The image can't be bit-for-bit identical to that machine: the operating system, the compiler (gcc 11.5), gSOAP and the Pythia6/ROOT build options may differ.

The exact commit of every component is in `/src/VERSIONS` in the image. The image labels `explora.ref`, `allsources.ref` and `genfit.ref` hold the main refs.

Layout inside the image:

| Path | Content |
|---|---|
| `/opt/CB/allsources` | allsources install prefix (`$ALLSOURCES`, `$ROOTSYS`, `$G4SYS`) |
| `/opt/genfit` | GenFit install (`$GENFIT` = `/opt/genfit/lib`, `$GENFIT_INCDIR`) |
| `/opt/explora` | Explora install (`$EXPLORA_HOME`), 3rdParty plugins in `/opt/explora/3rdParty` |
| `/src/TpcExplora` | Explora sources (git checkout, incl. the vendored plugins under `3rdParty/`) |
| `/src/allsources`, `/src/GenFit-02-00-01` | sources of allsources and GenFit |
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
Both instances may only be reachable from the university network or via VPN.

**Tools:**
- `git` and `bash` on the host.
- **Docker** (with BuildKit), or **Podman** ≥ 4. `make.sh` detects Podman and adds `--format docker`, which the build needs.

**Resources**, measured on a 16-core machine:

| | |
|---|---|
| Build time | about 1.5 h with `JOBS=16`; ROOT and Geant4 take most of it. Rebuilding only Explora takes 15–20 min |
| Disk | ≥ 30 GB free: about 10 GB of temporary build tree in the allsources step, plus image layers |
| RAM | ≥ 16 GB recommended for `JOBS=16`; about 2 GB per parallel compile job |
| Final image | about 4.5 GB, including the Geant4 data sets |

Network access during the build is needed only for public downloads: AlmaLinux and EPEL packages, and the ROOT, Geant4, VMC, GenFit, … tarballs referenced by allsources.
No credentials are used inside the build.

## Quick start

```bash
git clone https://github.com/pbielefeldt/dockerfiles.git
cd dockerfiles/ExploraAL

cp .env.example .env            # fill in your GitLab usernames and tokens
./fetch-sources.sh              # clones explora, allsources and the private plugins into vendor/
./make.sh                       # builds exploraal:1083c0bd-root6.24.06 (about 1.5 h)

docker run --rm -it exploraal:1083c0bd-root6.24.06              # interactive shell, environment loaded
docker run --rm exploraal:1083c0bd-root6.24.06 explora -h       # run a single command
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
| `vendor/plugins/<Name>/` | every plugin listed in `vendor/explora/3rdParty/ExternalPlugins.txt`, at its `GIT_TAG` |
| `vendor/PLUGINS`, `vendor/VERSIONS` | plugin names; name, URL and commit of everything fetched |

Tokens are passed to git through a temporary `GIT_ASKPASS` helper. They never appear in URLs, logs or `.git/config`.

Options (environment variables):

| Variable | Default | Meaning |
|---|---|---|
| `ENV_FILE` | `./.env` | credentials file |
| `EXPLORA_REF` | `1083c0bd…` (`wip-philipp`) | Explora commit |
| `EXPLORA_URL` | agthoma `AGKetzer/tpc/explora.git` | Explora repository |
| `ALLSOURCES_REF` | `2d35bde…` | allsources commit |
| `ALLSOURCES_URL` | agthoma `CB/software/allsources.git` | allsources repository |

The private plugin list and their commits come from Explora's own `3rdParty/ExternalPlugins.txt`.
The recipe is made for the refs above; other refs, in particular newer ROOT versions in allsources, need changes to it.

### 3. Build

```bash
./make.sh
```

`make.sh` builds `exploraal:<first 8 characters of the Explora commit>-root6.24.06` with all CPUs. It passes the fetched refs from `vendor/VERSIONS` as image labels, and it never pushes.
Settings: `TAGNAME=exploraal:test`, `JOBS=8`, `CONTAINER_TOOL=podman`.

Equivalent manual call:

```bash
docker build --build-arg JOBS=16 -t exploraal:dev .
podman build --format docker --build-arg JOBS=16 -t exploraal:dev .   # podman: --format docker is required
```

> **Keep `JOBS` the same between builds.** Build arguments are part of the layer cache key, so a different `JOBS` value rebuilds ROOT and Geant4 from scratch.

The build steps are separate layers, in this order: system packages → allsources → GenFit → Explora + plugins.
After a change to the Explora sources, only the last layers are rebuilt, which takes 15–20 minutes. Any change to `vendor/allsources`, to `allsources.sh`, or to the package list triggers the full build.

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
- The simulation writes `out/use_geant4_tmp-mu-sim.root` within a few seconds per event.
- The reconstruction processes all 5 events in a few seconds and fills the `TpcTrackingQA` histograms in `out/reco_Geant4_…_Histos.root`.

Notes:
- `-n=` does **not** limit Geant4/VMC runs. Their event count comes from `CBTVirtualMCEventProcessor`'s `event_count`, so override that.
- The `alice_model_steps` override works around a container-name mismatch inside `use_geant4.xml`: `CBTVirtualMCAliceModel` writes `alice_model`, but `CBTTpcDrift` reads `alice_model_steps`.

A quick GenFit-only check is [GenFitExamples](https://github.com/pbielefeldt/GenFitExamples) (`GFResidualExample`). It builds against `$GENFIT`/`$GENFIT_INCDIR` inside the container, and its pulls should have mean ≈ 0 and σ ≈ 1.

## What the build changes, and why

The build uses the upstream sources unchanged, except for these fixes. Explora itself is built as it is.

**allsources** (`2d35bde`, `allsources.sh` and the `FFLAGS` in the `Dockerfile`), needed on AlmaLinux 9:

| Change | Reason |
|---|---|
| xerces 3.2.3 URL → `archive.apache.org` | removed from `apache.org/dist`; the archived file has the same MD5 |
| fftw 3.2.2 URL `ftp://` → `https://www.fftw.org/` | the FTP URL is not reachable; same file and MD5 |
| gSOAP 2.8.82 → 2.8.135 from SourceForge | SourceForge now only keeps releases ≥ 2.8.135, in a new directory layout. Only the online-monitor plugins use gSOAP |
| Pythia6 built with `-fcommon` | gcc ≥ 10 defaults to `-fno-common` (backport of allsources `3c75f08`) |
| Geant4 10.7 with the system expat: `-DEXPAT_LIBRARY` and `-DEXPAT_INCLUDE_DIR` passed explicitly | With CMake ≥ 3.2x, Geant4 10.7 writes `set(EXPAT_LIBRARY … CACHE <empty type>)` into `Geant4PackageCache.cmake` because `EXPAT_LIBRARY` isn't a cache variable. That breaks every later `find_package(Geant4)` (VGM, geant4_vmc). Making it one on the command line fixes it, and `GEANT4_USE_SYSTEM_EXPAT` stays on |
| `FFLAGS=-fallow-argument-mismatch` | gfortran ≥ 10 rejects the argument mismatches in the old Fortran code |

**Build integration:**

| Change | Reason |
|---|---|
| Private plugins built as local plugins: `ExternalPlugins.txt` emptied, names appended to `CustomPlugins.txt` | No credentials inside the build; cmake would otherwise `git clone` them |
| GenFit built from source, sources kept in `/src` | Not part of allsources. Its ROOT dictionaries reference headers by their absolute build-time path, so cling can't autoload `genfit::` classes without them. The prebuilt `libgenfit2.so` in `CBTGenfit2/genfit/lib` is excluded |
| `/opt/genfit/lib` registered with `ldconfig` | `libcbttpctracking.so` needs `libgenfit2.so` at runtime |
| `ROOT_INCLUDE_PATH` includes `/opt/explora/3rdParty/include` | cling autoloading of 3rdParty plugin classes (otherwise `Missing FileEntry for ….h`) |
| i686 packages (`glibc-devel`, `libstdc++-devel`, `libgfortran`, `libnsl`, `libxcrypt-compat`) | `CernZebraReader64` builds a 32-bit helper against shipped 32-bit CERNLIB libraries |
| Environment frozen into `/etc/explora.env` at build time | `thisroot.sh` locates itself via `BASH_ARGV`, which goes wrong whenever the sourcing script has arguments |

## Known issues

- Several 3rdParty plugins declare `cmake_minimum_required(VERSION 2.4.3)`. That only produces deprecation warnings with the image's CMake 3.26, but CMake ≥ 4 rejects it, so don't install a newer CMake in the image.
- Build output contains many compiler and CMake deprecation warnings from the older packages. They are expected.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `fetch-sources.sh`: `Authentication failed` / `could not read Username` | Missing or expired token in `.env`, or the token lacks `read_repository` |
| `fetch-sources.sh` hangs or times out | Not on the university network: connect to the VPN |
| Build fails in the allsources step with a download error (404) or an MD5 mismatch | An upstream tarball moved or was replaced. Add a URL/checksum override to `allsources.sh` next to the existing ones |
| `SHELL is not supported for OCI image format` warning | Podman without `--format docker`. Use `make.sh` or add the flag |
| `ERROR: must "cd where/root/is" before calling ". bin/thisroot.sh"` | `thisroot.sh`/`thistr16.sh` was sourced from a script with arguments. Use `source /etc/explora.env` instead |
| `cannot open shared object file: libgenfit2.so…` | Run commands through the entrypoint or a login shell, or run `ldconfig`. `/opt/genfit/lib` is registered in `/etc/ld.so.conf.d` |
| Build runs out of memory | Lower `JOBS`, e.g. `JOBS=4 ./make.sh` |

## Security and licensing

- `.env` holds personal GitLab tokens. It is excluded from git (`.gitignore`) and from the build context (`.dockerignore`). The fetched sources contain no credentials, and the build history of the image contains none either.
- The image contains **private, unpublished code** (Explora, allsources, plugins). Keep it local or in an access-restricted registry. Check the license terms of all components before you distribute it.
- The files in this directory (Dockerfile and scripts) are covered by the repository's license (MPL-2.0). The software they download and build keeps its own licenses.
