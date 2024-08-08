class Libmps < Formula
  desc "Memory Pool System"
  homepage "https://www.ravenbrook.com/project/mps/"
  url "https://github.com/Ravenbrook/mps/archive/refs/tags/release-1.118.0.tar.gz"
  sha256 "58c1c8cd82ff8cd77cc7bee612b94cf60cf6a6edd8bd52121910b1a23344e9a9"
  license "BSD-2-Clause"

  depends_on xcode: :build

  def install
    if OS.mac?
      # macOS build process
      # for build native but not universal binary
      # https://github.com/Ravenbrook/mps/blob/master/manual/build.txt
      xcodebuild "-scheme", "mps",
                 "-configuration", "Release",
                 "-project", "code/mps.xcodeproj",
                 "OTHER_CFLAGS=-Wno-error=unused-but-set-variable -Wno-unused-but-set-variable"

      # Install the static library
      lib.install "code/xc/Release/libmps.a"

      # Install header files
      include.install Dir["code/mps*.h"]

    else
      system "./configure", "--prefix=#{prefix}"
      system "make", "NOISY=1", "ARFLAGSPFM=s", "install"
    end
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include "mps.h"
      #include "mpscawl.h"
      #include "mpscamc.h"
      #include "mpsavm.h"

      int main() {
        mps_arena_t arena;
        mps_res_t res = mps_arena_create(&arena, mps_arena_class_vm(), 1024*1024);
        return (res == MPS_RES_OK) ? 0 : 1;
      }
    EOS
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lmps", "-o", "test"
    system "./test"
  end
end
