{ pkgs ? import <nixpkgs> { } }:
let
  my-python = pkgs.python311;
  libclang-python = my-python.pkgs.buildPythonPackage rec {
    pname = "libclang";
    version = "14.0.6";
    src = my-python.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-kFKoKE2IRphPb6gmsddGCmbTsjpIbXgmM7QrbjtBh4k=";
    };
    meta = with pkgs.lib; {
      homepage = "https://pypi.org/project/libclang";
    };
    doCheck = false;
  };
  python-with-packages = my-python.withPackages (p: [
    libclang-python
  ]);
  my-llvm = pkgs.llvmPackages_14;
  packages = (with my-llvm; [
    clang
    libclang.lib
    llvm.out
    llvm.lib
    python-with-packages
  ]);
  pkgPaths = pkgs.lib.lists.forEach packages (x: x.name + " " + x);
  pathsString = pkgs.lib.strings.concatStringsSep "\n" pkgPaths;
in
pkgs.mkShell {
  inherit packages;
  shellHook = ''
    export LIBCLANG_LIBRARY_PATH=${my-llvm.libclang.lib}/lib
    export PYTHONPATH=${python-with-packages}/${python-with-packages.sitePackages}
    echo "--- package paths ---"
    echo "${pathsString}"
    echo "--- python path ---"
    which python
    echo PYTHONPATH=$PYTHONPATH
    build () {
      clang++ $1 -std=c++11 -g -lclang -o $2
    }
  '';
}
