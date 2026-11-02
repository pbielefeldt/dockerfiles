#!/bin/bash
# Explora fixes for the latest ROOT / Geant4. Runs in the explora source directory, after the
# plugins have been copied to 3rdParty/.
set -euo pipefail

# ROOT >= 6.3x prints `root-config --version` as 6.40.04 instead of 6.24/06; every copy of
# FindROOT.cmake (Explora and the plugins) takes the version apart assuming the old format.
# Convert it back right after it has been read.
find . -name FindROOT.cmake -print0 \
	| xargs -0 sed -i '/OUTPUT_VARIABLE ROOTVERSION)/a\  STRING(REGEX REPLACE "^([0-9]+)\\\\.([0-9]+)\\\\.([0-9]+)$" "\\\\1.\\\\2/\\\\3" ROOTVERSION "${ROOTVERSION}")'

# ROOT >= 6.34 has no Pythia6 interface (libEGPythia6) any more. Explora only links it so that the
# geant3 library resolves; geant3 v4-x builds and runs without it, so make it optional.
sed -i 's|^\(\s*\)LIST(APPEND GEANT3VMC_LIBRARIES "${ROOT_PYTHIA6_LIB}")|\1IF(ROOT_PYTHIA6_LIB)\n\1\tLIST(APPEND GEANT3VMC_LIBRARIES "${ROOT_PYTHIA6_LIB}")\n\1ENDIF(ROOT_PYTHIA6_LIB)|' cmake/modules/FindGEANT3VMC.cmake
grep -q 'IF(ROOT_PYTHIA6_LIB)' cmake/modules/FindGEANT3VMC.cmake

# ROOT 6.40 added AddFirst(obj, opt) / AddAt(obj, idx, opt) to TRefArray (they forward to the
# versions CBTRefArray overrides): bring them back into scope instead of hiding them
# (-Werror=overloaded-virtual)
sed -i 's|^\(\s*\)virtual void AddAt(TObject \*obj, Int_t idx);|&\n\1using TRefArray::AddFirst;\n\1using TRefArray::AddAt;|' dataobj/include/CBTRefArray.h
grep -q 'using TRefArray::AddAt;' dataobj/include/CBTRefArray.h

# ROOT headers no longer include TMath.h indirectly: add it wherever TMath:: is used
grep -rlZ 'TMath::' --include='*.cpp' --include='*.cxx' --include='*.h' --include='*.hh' . \
	| xargs -0 -I{} sh -c 'grep -q "include.*TMath.h" "$1" || sed -i "0,/^#include/s//#include <TMath.h>\n#include/" "$1"' _ {}

# compression settings: ROOT 6.40 removed ROOT::ECompressionAlgorithm and ROOT::kZLIB, kLZMA, kLZ4, ...
sed -i -e 's|ROOT::ECompressionAlgorithm|ROOT::RCompressionSetting::EAlgorithm::EValues|' \
	-e 's|ROOT::kUseGlobalSetting|ROOT::RCompressionSetting::EAlgorithm::kUseGlobal|' \
	-e 's#ROOT::k\(ZLIB\|LZMA\|LZ4\)#ROOT::RCompressionSetting::EAlgorithm::k\1#' \
	plugins/io/CBTRootTreeOutput.cpp plugins/io/CBTRawdataTreeOutput.cpp

# TClass::kHasCustomStreamerMember is gone, there is an accessor
sed -i 's|GetClass()->TestBit(TClass::kHasCustomStreamerMember)|GetClass()->HasCustomStreamerMember()|' plugins/io/CBTRootTreeOutput.cpp

# TH1::AddBinContent(Int_t, UInt_t) is ambiguous now
sed -i 's|AddBinContent(bin,value)|AddBinContent(bin,(Double_t)value)|' plugins/monitor/CBTHStdScaler.cpp

# geant4_vmc >= 5.4 builds a multithreaded application by default (TG4RunConfiguration's last
# argument defaults to true), which needs TVirtualMCApplication::CloneForWorker() in the user
# application. Explora's applications are not thread-safe: ask for the sequential one, which is
# also what Geant4 10.7 / geant4_vmc 5.3 did.
sed -i -e 's|new TG4RunConfiguration("geomRoot",lPhysicList,lTrackProcessList)|new TG4RunConfiguration("geomRoot",lPhysicList,lTrackProcessList,false,false)|' \
	-e 's|lTrackProcessList+"\\"));");|lTrackProcessList+"\\",false,false));");|' vmc/geant4/CBTGeant4MC.cpp
[ "$(grep -c 'false,false' vmc/geant4/CBTGeant4MC.cpp)" = 2 ]
