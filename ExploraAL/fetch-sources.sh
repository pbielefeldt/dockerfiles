#!/bin/bash
#
# Fetch all (private) sources needed by the ExploraAL Dockerfile into vendor/:
#   vendor/explora/              TpcExplora (git checkout, or a copy of a local source tree)
#   vendor/allsources/           allsources superbuild (ROOT, Geant3/4, VMC, ...)
#   vendor/plugins/<Name>/       every plugin listed in explora's 3rdParty/ExternalPlugins.txt
#   vendor/PLUGINS               names of the vendored plugins (one per line)
#   vendor/VERSIONS              name, url and commit of everything fetched
#
# Run this on the host (VPN may be required for agthoma). Credentials are read from .env
# (see .env.example) and handed to git via GIT_ASKPASS, so they never show up in URLs,
# logs, .git/config or the docker build context.
#
# Usage: ./fetch-sources.sh
# Env:   EXPLORA_URL, EXPLORA_REF       explora repository and branch/tag/commit
#        EXPLORA_SRC                    use this local explora source tree instead of cloning
#        ALLSOURCES_URL, ALLSOURCES_REF allsources repository and branch/tag/commit
#        ENV_FILE                       credentials file (default: .env next to this script)

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="${HERE}/vendor"

EXPLORA_URL="${EXPLORA_URL:-https://agthoma.hiskp.uni-bonn.de/gitlab/AGKetzer/tpc/explora.git}"
EXPLORA_REF="${EXPLORA_REF:-f31bc421bbd14534215ef2cbdbc5b6bc85b7149c}"
EXPLORA_SRC="${EXPLORA_SRC:-}"
ALLSOURCES_URL="${ALLSOURCES_URL:-https://agthoma.hiskp.uni-bonn.de/gitlab/CB/software/allsources.git}"
ALLSOURCES_REF="${ALLSOURCES_REF:-07a7f3d687149d394814873be4a8ad251a140b1f}"
ENV_FILE="${ENV_FILE:-${HERE}/.env}"

if [ -f "${ENV_FILE}" ]; then
	set -a
	# shellcheck disable=SC1090
	. "${ENV_FILE}"
	set +a
else
	echo "warning: ${ENV_FILE} not found, cloning without credentials" >&2
fi

# askpass helper: git calls it with the prompt as $1 ("Username for ..." / "Password for ...")
ASKPASS="$(mktemp)"
trap 'rm -f "${ASKPASS}"' EXIT
cat > "${ASKPASS}" <<'EOF'
#!/bin/sh
case "$1" in
	Username*) printf '%s\n' "${FETCH_USER}" ;;
	*) printf '%s\n' "${FETCH_TOKEN}" ;;
esac
EOF
chmod 700 "${ASKPASS}"

# select credentials by host
set_credentials() {
	local url="$1"
	FETCH_USER=""
	FETCH_TOKEN=""
	case "${url}" in
		https://agthoma.hiskp.uni-bonn.de/*)
			FETCH_USER="${AG_THOMA_GITLAB_USERNAME:-}"
			FETCH_TOKEN="${AG_THOMA_GITLAB_TOKEN:-}" ;;
		https://gitlab.uni-bonn.de/*)
			FETCH_USER="${UNI_BONN_GITLAB_USERNAME:-}"
			FETCH_TOKEN="${UNI_BONN_GITLAB_TOKEN:-}" ;;
	esac
	export FETCH_USER FETCH_TOKEN
}

# clone <url> <ref|""> <dest> <keep_git:yes|no>; prints the checked-out commit
clone() {
	local url="$1" ref="$2" dest="$3" keep_git="$4"
	set_credentials "${url}"
	rm -rf "${dest}"
	GIT_ASKPASS="${ASKPASS}" GIT_TERMINAL_PROMPT=0 \
		git -c credential.helper= clone --quiet --no-checkout "${url}" "${dest}" >&2
	if [ -n "${ref}" ]; then
		git -C "${dest}" -c advice.detachedHead=false checkout --quiet "${ref}" >&2
	else
		git -C "${dest}" checkout --quiet >&2
	fi
	git -C "${dest}" rev-parse HEAD
	if [ "${keep_git}" != "yes" ]; then
		rm -rf "${dest}/.git"
	fi
}

mkdir -p "${VENDOR}"
rm -rf "${VENDOR}/plugins"
mkdir -p "${VENDOR}/plugins"
: > "${VENDOR}/PLUGINS"
: > "${VENDOR}/VERSIONS"

# explora: keep .git, explora generates gitinfo.h (revision info) from it
if [ -n "${EXPLORA_SRC}" ]; then
	echo "copying explora from ${EXPLORA_SRC}..."
	rm -rf "${VENDOR}/explora"
	mkdir -p "${VENDOR}/explora"
	tar -C "${EXPLORA_SRC}" \
		--exclude=./.env --exclude='./build*' --exclude=./.claude \
		-cf - . | tar -C "${VENDOR}/explora" -xf -
	sha="$(git -C "${VENDOR}/explora" rev-parse HEAD 2>/dev/null || echo "local-copy")"
	printf '%s\t%s\t%s\n' explora "${EXPLORA_SRC}" "${sha}" >> "${VENDOR}/VERSIONS"
else
	echo "fetching explora (${EXPLORA_REF})..."
	sha="$(clone "${EXPLORA_URL}" "${EXPLORA_REF}" "${VENDOR}/explora" yes)"
	printf '%s\t%s\t%s\n' explora "${EXPLORA_URL}" "${sha}" >> "${VENDOR}/VERSIONS"
fi

echo "fetching allsources (${ALLSOURCES_REF})..."
sha="$(clone "${ALLSOURCES_URL}" "${ALLSOURCES_REF}" "${VENDOR}/allsources" no)"
printf '%s\t%s\t%s\n' allsources "${ALLSOURCES_URL}" "${sha}" >> "${VENDOR}/VERSIONS"

# ExternalPlugins.txt lines: <Name> GIT_REPOSITORY <url> [GIT_TAG <ref>] [...]
while read -r -a fields; do
	[ "${#fields[@]}" -eq 0 ] && continue
	[[ "${fields[0]}" == \#* ]] && continue
	name="${fields[0]}"
	url=""
	ref=""
	for ((i = 1; i < ${#fields[@]} - 1; i++)); do
		case "${fields[$i]}" in
			GIT_REPOSITORY) url="${fields[$((i + 1))]}" ;;
			GIT_TAG) ref="${fields[$((i + 1))]}" ;;
		esac
	done
	if [ -z "${url}" ]; then
		echo "error: no GIT_REPOSITORY for plugin ${name}" >&2
		exit 1
	fi

	echo "fetching plugin ${name}..."
	sha="$(clone "${url}" "${ref}" "${VENDOR}/plugins/${name}" no)"
	if [ ! -f "${VENDOR}/plugins/${name}/CMakeLists.txt" ]; then
		echo "error: plugin ${name} has no CMakeLists.txt" >&2
		exit 1
	fi
	echo "${name}" >> "${VENDOR}/PLUGINS"
	printf '%s\t%s\t%s\n' "${name}" "${url}" "${sha}" >> "${VENDOR}/VERSIONS"
done < "${VENDOR}/explora/3rdParty/ExternalPlugins.txt"

echo
echo "done. vendored sources:"
column -t -s $'\t' "${VENDOR}/VERSIONS"
