function set_cmake_options
{
  # Set CMAKE_GENERATOR according to the build image
  if($Env:APPVEYOR_BUILD_WORKER_IMAGE -eq "Visual Studio 2017")
  {
    $Env:CMAKE_GENERATOR = "Visual Studio 15 2017 Win64";
  }
  elseif($Env:APPVEYOR_BUILD_WORKER_IMAGE -eq "Visual Studio 2015")
  {
    $Env:CMAKE_GENERATOR = "Visual Studio 14 2015 Win64";
  }
  else
  {
    $Env:CMAKE_GENERATOR = "Visual Studio 12 2013 Win64";
  }
  # Disable Python bindings in Debug builds
  if($Env:CONFIGURATION -eq "Debug")
  {
    $Env:CMAKE_ADDITIONAL_OPTIONS = "-DPYTHON_BINDING=OFF $Env:CMAKE_ADDITIONAL_OPTIONS";
  }
}

function git_dependency_parsing
{
  $_input = $args[0].split('#');
  if($args.length -gt 1)
  {
    $default_branch = $args[1];
  }
  else
  {
    $default_branch = "master";
  }
  Set-Variable -Name git_dep -Value $_input[0] -Scope Global;
  Set-Variable -Name git_dep_branch -Value $default_branch -Scope Global;
  if($_input.length -eq 2)
  {
    $git_dep_branch = $_input[1];
    Set-Variable -Name git_dep_branch -Value $git_dep_branch -Scope Global;
  }
  $git_dep_uri_base = $git_dep.split(':')[0];
  if($git_dep_uri_base -eq $git_dep)
  {
    $git_dep_uri = "git://github.com/" + $git_dep
    Set-Variable -Name git_dep_uri -Value $git_dep_uri -Scope Global;
  }
  else
  {
    Set-Variable -Name git_dep_uri -Value $git_dep -Scope Global;
    Set-Variable -Name git_dep -Value $git_dep.split(':')[1] -Scope Global;
  }
}

function setup_directories
{
  md $env:CMAKE_INSTALL_PREFIX
  if( -Not (Test-Path $Env:SOURCE_FOLDER) )
  {
    md $Env:SOURCE_FOLDER
  }
  if( -Not (Test-Path $Env:PKG_CONFIG_PATH) )
  {
    md $Env:PKG_CONFIG_PATH
  }
}

function setup_pkg_config
{
  appveyor DownloadFile http://ftp.gnome.org/pub/gnome/binaries/win32/glib/2.28/glib_2.28.8-1_win32.zip
  appveyor DownloadFile http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/pkg-config_0.26-1_win32.zip
  appveyor DownloadFile http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/gettext-runtime_0.18.1.1-2_win32.zip
  7z x glib_2.28.8-1_win32.zip -o"${env:CMAKE_INSTALL_PREFIX}" -r
  7z x pkg-config_0.26-1_win32.zip -o"${env:CMAKE_INSTALL_PREFIX}" -r
  7z x gettext-runtime_0.18.1.1-2_win32.zip -o"${env:CMAKE_INSTALL_PREFIX}" -r
}

function setup_build
{
  set_cmake_options
  setup_directories
  setup_pkg_config
}

function install_choco_dependencies
{
  ForEach($choco_dep in $Env:CHOCO_DEPENDENCIES.split(' '))
  {
    choco install $choco_dep -y
  }
}

function install_git_dependencies
{
  ForEach($g_dep in $Env:GIT_DEPENDENCIES.split(' '))
  {
    cd $Env:SOURCE_FOLDER
    git_dependency_parsing $g_dep
    git clone -b "$git_dep_branch" "$git_dep_uri" "$git_dep"
    cd $git_dep
    git submodule update --init
    if ($lastexitcode -ne 0){ exit $lastexitcode }
    md build
    cd build
    # For projects that use cmake_add_subfortran directory this removes sh.exe
    # from the path
    $Env:Path = $Env:Path -replace "Git","dummy"
    cmake ../ -G $Env:CMAKE_GENERATOR -DCMAKE_INSTALL_PREFIX="${Env:CMAKE_INSTALL_PREFIX}" -DMINGW_GFORTRAN="$env:MINGW_GFORTRAN" -DGIT="C:/Program Files/Git/cmd/git.exe" -DBUILD_TESTING=OFF ${Env:CMAKE_ADDITIONAL_OPTIONS}

    if ($lastexitcode -ne 0){ exit $lastexitcode }
    msbuild INSTALL.vcxproj /p:Configuration=${Env:CONFIGURATION}
    if ($lastexitcode -ne 0){ exit $lastexitcode }
    # Reverse our dirty work
    $Env:Path = $Env:Path -replace "dummy","Git"
  }
}

function install_dependencies
{
  install_choco_dependencies
  install_git_dependencies
}

function build_project
{
  cd $Env:PROJECT_SOURCE_DIR
  git submodule update --init
  if ($lastexitcode -ne 0){ exit $lastexitcode }
  md build
  cd build
  # See comment in dependencies regarding $Env:Path manipulation
  $Env:Path = $Env:Path -replace "Git","dummy"
  cmake ../ -G $Env:CMAKE_GENERATOR -DCMAKE_INSTALL_PREFIX="${Env:CMAKE_INSTALL_PREFIX}" -DMINGW_GFORTRAN="$env:MINGW_GFORTRAN" -DGIT="C:/Program Files/Git/cmd/git.exe" ${Env:CMAKE_ADDITIONAL_OPTIONS}
  if ($lastexitcode -ne 0){ exit $lastexitcode }
  msbuild INSTALL.vcxproj /p:Configuration=${Env:CONFIGURATION}
  if ($lastexitcode -ne 0){ exit $lastexitcode }
  $Env:Path = $Env:Path -replace "dummy","Git"
}

function test_project
{
  cd %PROJECT_SOURCE_DIR%/build
  ctest -N
  ctest --build-config ${Env:CONFIGURATION} --exclude-regex example
  if ($lastexitcode -ne 0)
  {
    type Testing/Temporary/LastTest.log
    exit $lastexitcode
  }
}
