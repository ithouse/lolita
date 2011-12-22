module Lolita
  module Support
    class Version
      def initialize
        @version = LOLITA_VERSION
      end

      def inspect
        @version
      end

      def major
        @version.split(".").first
      end

      def minor
        @version.split(".")[1]
      end

      def patch
        @version.split(".")[2]
      end

      def rc
        @version.split(".")[3] == "rc" && @version.split(".")[4]
      end
    end
  end
end