module Lolita
  module Support
    # Lolita version in more friendly way.
    #     Lolita.version #=> 3.2.0 
    #     Lolita.version.major #=> 3
    #     Lolita.version.minor #=> 2
    class Version
      def initialize
        @version = LOLITA_VERSION
      end

      def inspect
        @version
      end

      def to_s
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