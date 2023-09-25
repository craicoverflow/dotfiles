SPACESHIP_DOCKER_SHOW=false
SPACESHIP_GOLANG_SHOW=false

SPACESHIP_KUBECTL_SHOW=true

SPACESHIP_KUBECTL_CONTEXT_COLOR_GROUPS=(
  # red if namespace is "kube-system"
  red    '\(kube-system)$'

  # else, green if "dev-01" is anywhere in the context or namespace
  green  '\(kind-)$'

  # else, red if context name ends with ".k8s.local" _and_ namespace is "system"
  red    '\.k8s\.local \(system)$'

  # else, yellow if the entire content is "test-" followed by digits, and no namespace is displayed
  yellow '^test-[0-9]+$'
)
