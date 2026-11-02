#!/bin/bash
# Bump allsources@root6.36 (ROOT 6.36.06, Geant4 11.3.2, VMC 2-1, geant3 4-4, ...) to the latest
# stable releases. URLs and MD5s of the tarballs as downloaded on 2026-11-02.
set -euo pipefail

# ROOT 6.40 requires these as system packages (or opt-in -Dbuiltin_*); installed here, not in the
# Dockerfile, so the shared base layer stays valid for the production profile
dnf -y install giflib-devel lz4-devel libzstd-devel gl2ps-devel
dnf clean all

cd /src/allsources

bump() { # <file> <old url part> <new url part> <old md5> <new md5>
	grep -q "$2" "$1" && grep -q "$4" "$1" || { echo "bump: $2 / $4 not found in $1" >&2; exit 1; }
	sed -i -e "s|$2|$3|" -e "s|$4|$5|" "$1"
}
bump root/CMakeLists.txt    root_v6.36.06    root_v6.40.04    2960b357c4cdc493618bf18b811b8549 1bb1dd3abfa9e1b672ddf9e57590967a
bump geant4/CMakeLists.txt  v11.3.2/geant4-v11.3.2 v11.4.3/geant4-v11.4.3 efb379ed6610fe52c16670b3606a2b0d 9e8627d98e03e44c4309a3ec3633c959
bump vmc/CMakeLists.txt     tags/v2-1.tar    tags/v2-2.tar    a8e01bf03fd74c909d88767ff684e219 c4b2496cced3c432596190c69cc6c913
bump vmc/CMakeLists.txt     tags/v4-4.tar    tags/v4-5.tar    669d80ad2ec32cad85bb7472f63d2dc7 2e6f552761e9f99966d1ce33aabd78e7
bump vmc/CMakeLists.txt     tags/v5-3-1.tar  tags/v5-5.tar    26bddb537b1602de12fb19a72bedc677 17771206349ad5c7dd40bd5f10f93055
bump vmc/CMakeLists.txt     tags/v6-7-p1.tar tags/v6-8.tar    a1ba8cfb767b5c92f5a92ccdd7819dc4 818142d29770973f8a25c93f5087dc90
bump gsoap/CMakeLists.txt gsoap_2.8.138.zip gsoap_2.8.146.zip d07c17f5c4c38833334d198386289c9f 2ae7b4c890147b060bbda631b4ae8ac0
# the environment scripts name the geant3 install directory
sed -i 's|Geant3-4\.4\.0|Geant3-4.5.0|' thistr16.sh tr16.env.in

# xerces 3.3.0: dlcdn.apache.org only serves the current release, archive.apache.org keeps it
sed -i 's|https://dlcdn.apache.org//xerces/|https://archive.apache.org/dist/xerces/|' xerces/CMakeLists.txt

# allsources' root/allow-unknown-args.patch (lets `root` ignore unknown command line options) no
# longer applies to ROOT 6.40: replace it with a port (only the context and the exit code differ)
cat > root/allow-unknown-args.patch <<'PATCH'
--- a/core/rint/src/TRint.cxx
+++ b/core/rint/src/TRint.cxx
@@ -176,11 +176,16 @@
    if (exitOnUnknownArgs && argc != nullptr && *argc > 1) {
       // Early exit if there are remaining unrecognized options
       // This branch supposes that TRint is created as a result of using the `root` command
-      for (auto n = 1; n < *argc; n++) {
-         std::cerr << "root: unrecognized option '" << argv[n] << "'\n";
+
+      if (strcmp(argv[1], "--allow-unknown-args")) {
+
+         for (auto n = 1; n < *argc; n++) {
+            std::cerr << "root: unrecognized option '" << argv[n] << "'\n";
+         }
+         std::cerr << "Try 'root --help' for more information.\n";
+         TApplication::Terminate(2);
+
       }
-      std::cerr << "Try 'root --help' for more information.\n";
-      TApplication::Terminate(2);
    }
 
    fNcmd          = 0;
PATCH

# ROOT 6.40 removed the pgsql option (and errors out on options it doesn't know)
sed -i '/\${ROOT_SQL_OPTION}/d' root/CMakeLists.txt
