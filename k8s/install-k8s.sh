#!/usr/bin/env bash
# Install the Kubernetes command line tools this setup expects:
#
#   kubectl        the client itself
#   krew           kubectl's plugin manager
#   ctx, ns        krew plugins — these are what `k ctx` and `k ns` run
#   helm           asked separately
#   argocd         asked separately
#
#   ./k8s/install-k8s.sh          apply
#   ./k8s/install-k8s.sh --dry    print what would change
#
# install.sh runs this too. Every command here is the one its project's own
# documentation gives; the comment above each says which page.
#
# The aliases and the krew PATH entry live in zsh/zshrc, not here.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib.sh
source "$REPO/lib.sh"

KREW_BIN="${KREW_ROOT:-$HOME/.krew}/bin"
export PATH="$KREW_BIN:$PATH"

# kubectl and krew publish one build per architecture under these names.
case "$(uname -m)" in
  x86_64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *)
    ARCH=""
    ;;
esac

log "kubernetes"

if [ -z "$ARCH" ]; then
  log "  no kubectl build for $(uname -m) — skipping this section"
  exit 0
fi

core_missing=()
command -v kubectl >/dev/null 2>&1 || core_missing+=(kubectl)
command -v kubectl-krew >/dev/null 2>&1 || core_missing+=(krew)
command -v kubectl-ctx >/dev/null 2>&1 || core_missing+=(ctx)
command -v kubectl-ns >/dev/null 2>&1 || core_missing+=(ns)

if [ ${#core_missing[@]} -eq 0 ]; then
  log "  already installed: kubectl, krew, ctx, ns"
elif ! confirm "Missing: ${core_missing[*]}. Install now?"; then
  log "  not installing them"
else
  if ! command -v kubectl >/dev/null 2>&1; then
    # https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
    log "  kubectl"
    (
      cd "$(mktemp -d)"
      version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
      curl -LO "https://dl.k8s.io/release/$version/bin/linux/$ARCH/kubectl"
      curl -LO "https://dl.k8s.io/release/$version/bin/linux/$ARCH/kubectl.sha256"
      # The download is plain HTTPS from a redirector, so check the published
      # checksum before anything runs as root.
      echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    )
  fi

  if ! command -v kubectl-krew >/dev/null 2>&1; then
    # https://krew.sigs.k8s.io/docs/user-guide/setup/install/
    log "  krew"
    (
      cd "$(mktemp -d)"
      KREW="krew-linux_$ARCH"
      curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/$KREW.tar.gz"
      tar zxf "$KREW.tar.gz"
      "./$KREW" install krew
    )
  fi

  # ctx and ns are the kubectx and kubens programs packaged as krew plugins,
  # so kubectl finds them as subcommands and `k ctx` works through the alias.
  for plugin in ctx ns; do
    if ! command -v "kubectl-$plugin" >/dev/null 2>&1; then
      log "  krew plugin: $plugin"
      kubectl krew install "$plugin"
    fi
  done
fi

if command -v helm >/dev/null 2>&1; then
  log "  helm already installed: $(helm version --short 2>/dev/null)"
elif confirm "helm is not installed. Install it? (adds an apt repository)"; then
  # https://helm.sh/docs/intro/install/
  log "  helm"
  HELM_BUILDKITE_APT_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
  sudo apt-get install curl gpg apt-transport-https --yes
  curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey > "${TMPDIR:-/tmp}/helm.gpg"
  # Checking the fingerprint means a swapped key is caught here rather than
  # trusted for every apt update from now on.
  if [ "$(gpg --show-keys --with-colons "${TMPDIR:-/tmp}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)" != "$HELM_BUILDKITE_APT_KEY_ID" ]; then
    log "  unexpected helm apt key id — not adding the repository"
    exit 1
  fi
  gpg --dearmor < "${TMPDIR:-/tmp}/helm.gpg" | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
    | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
  sudo apt-get update
  sudo apt-get install -y helm
fi

if command -v argocd >/dev/null 2>&1; then
  log "  argocd already installed: $(argocd version --client --short 2>/dev/null)"
elif confirm "argocd is not installed. Install it?"; then
  # https://argo-cd.readthedocs.io/en/stable/cli_installation/
  log "  argocd"
  (
    cd "$(mktemp -d)"
    curl -sSL -o "argocd-linux-$ARCH" "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-$ARCH"
    sudo install -m 555 "argocd-linux-$ARCH" /usr/local/bin/argocd
  )
fi

if command -v kubectl >/dev/null 2>&1; then
  # zshrc puts ~/.zsh/completions on fpath, so compinit finds _kubectl there
  # and loads it only when you actually complete a kubectl or k command.
  # Writing the file here keeps `kubectl completion zsh` out of every shell
  # start, which is worth about 75ms of the 0.22s one takes.
  COMPLETIONS="$HOME/.zsh/completions"
  if [ "$DRY" = 1 ]; then
    log "  would write $COMPLETIONS/_kubectl"
  else
    mkdir -p "$COMPLETIONS"
    kubectl completion zsh > "$COMPLETIONS/_kubectl"
    log "  wrote $COMPLETIONS/_kubectl"
    # compinit caches what it found in ~/.zcompdump and does not check for new
    # files every time. Dropping the cache makes the next shell see _kubectl.
    rm -f "$HOME"/.zcompdump*
  fi
fi

# install.sh prints its own closing message, so print this one only when the
# script was run on its own.
if [ "${TERMINAL_SETUP_NESTED:-}" != "1" ]; then
  log
  log "Done. Open a new terminal for the k alias and completion."
fi
