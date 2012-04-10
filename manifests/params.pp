class continuum::params {
    include continuum

    $version = $::continuum::version
    $download_maven_repo = $::continuum::download_maven_repo
    $download_mirror = $::continuum::download_mirror
    $user = $::continuum::user
    $group = $::continuum::group
    $user_home = $::continuum::user_home
    $shared_secret_password = $::continuum::shared_secret_password
}